# Initialize the PowerShell runspace for background execution
$runspace = [powershell]::Create().AddScript({
    function Log-Message {
        param (
            [string]$Message,
            [string]$LogFile = "$($env:APPDATA)\local\Logs\SerialPortLog.txt"
        )
        if (-not (Test-Path $LogFile)) {
            mkdir -Path (Split-Path $LogFile) -Force | Out-Null
            New-Item -Path $LogFile -ItemType File -Force | Out-Null
        }
        Add-Content -Path $LogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    }

    # Load required assemblies
    Add-Type -AssemblyName System.Drawing
    $packagesPath = "G:\MarkGzero\PSGadgets\lib"
    Get-ChildItem -Path "$packagesPath\*.dll" | ForEach-Object {
        try { [System.Reflection.Assembly]::LoadFrom($_.FullName) } catch { Log-Message "Error loading assembly: $_" }
    }

    # Initialize display device and log details
    $devices = [Iot.Device.FtCommon.FtCommon]::GetDevices()
    $ftDisplayDevice = $devices | Where-Object { $_.Description -match "Display" }
    if (-not $ftDisplayDevice) {
        Log-Message "No display device found."
        return
    }
    $psgadgetDisplay = [Iot.Device.Ft232h.Ft232hDevice]::new($ftDisplayDevice)
    $resolutionHeight = 64  # Default resolution height
    if ($ftDisplayDevice.Description -match "64") {
        $resolutionHeight = 64
    }
    $psgadgetDisplay | Add-Member -MemberType NoteProperty -Name "ResolutionWidth" -Value 128
    $psgadgetDisplay | Add-Member -MemberType NoteProperty -Name "ResolutionHeight" -Value $resolutionHeight
    Log-Message "Display device initialized: $($psgadgetDisplay.Description)"

    # Configure I2C settings
    $bus = $psgadgetDisplay.GetDefaultI2cBusNumber()
    $address = 0x3C
    Log-Message "Default I2C bus: $bus, Address: $([Convert]::ToString($address, 16))"

    try {
        $skiaFactory = New-Object Iot.Device.Graphics.SkiaSharpAdapter.SkiaSharpImageFactory
        [Iot.Device.Graphics.BitmapImage]::RegisterImageFactory($skiaFactory)
        $i2cSettings = [System.Device.I2c.I2cConnectionSettings]::new($bus, $address)
        $i2cDevice = $psgadgetDisplay.CreateI2cDevice($i2cSettings)
        Start-Sleep -Milliseconds 1000
        $ssd = [Iot.Device.Ssd13xx.Ssd1306]::new($i2cDevice, $psgadgetDisplay.ResolutionWidth, $psgadgetDisplay.ResolutionHeight)
        $ssd.ClearScreen()
        Log-Message "I2C device initialized and display cleared."
    } catch {
        Log-Message "Failed to initialize I2C SSD device: $($_.Exception.Message)"
        return
    }

    # Display text on the screen
    function DisplayText {
        param (
            [Iot.Device.Graphics.GraphicDisplay] $displayDevice,
            [string] $font = "Dejavu Sans",
            [string] $line1Text = "",
            [string] $line2Text = "",
            [string] $line3Text = "",
            [int] $fontSize = 8,
            [int] $width = 128,
            [int] $height = 64
        )
        $displayDevice.ClearScreen()
        $image = [Iot.Device.Graphics.BitmapImage]::CreateBitmap($width, $height, [Iot.Device.Graphics.PixelFormat]::Format32bppArgb)
        $canvas = $image.GetDrawingApi().Canvas
        $paint = New-Object SkiaSharp.SKPaint
        $paint.TextSize = $fontSize
        $paint.Color = [SkiaSharp.SKColors]::White
        $paint.IsAntialias = $true
        $paint.Typeface = [SkiaSharp.SKTypeface]::FromFamilyName($font)

        $canvas.Clear([SkiaSharp.SKColors]::Black)
        $canvas.DrawText($line1Text, 0, 8, $paint)
        $canvas.DrawText($line2Text, 0, 18, $paint)
        $canvas.DrawText($line3Text, 0, 28, $paint)

        $displayDevice.DrawBitmap($image)
        $paint.Dispose()
        $image.Dispose()
    }

    # Initialize the serial port
    function Initialize-SerialPort {
        if (-not $serialPort.IsOpen) {
            $serialPort.Open()
            Log-Message "Serial port opened on $($serialPort.PortName)"
        }
    }

    # Configure FTDI device
    $PsGadget_Controller = Get-PnpDevice | Where-Object {
        $_.Manufacturer -match "FTDI" -and $_.Status -eq "OK" -and $_.PNPDeviceId -match "\+CT.*"
    }
    $PortNumber = $PsGadget_Controller.FriendlyName -replace ".*\((COM\d+)\).*", '$1'
    if (-not $PortNumber) {
        Log-Message "No valid COM port found for the FTDI device."
        return
    }
    
    # Set up the serial port connection
    $serialPort = if ([System.IO.Ports.SerialPort]::GetPortNames() -contains $PortNumber) {
        [System.IO.Ports.SerialPort]::new($PortNumber, 9600, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)
    } else {
        Log-Message "Specified COM port not found."
        return
    }

    # Read from serial port and log responses
    function Read-FromSerialPort {
        try {
            Initialize-SerialPort
            while ($true) {
                try {
                    $response = $serialPort.ReadLine()
                    Log-Message "ESP32 response: $response"
                    if ($response -match '\(([^)]+)\) - Temperature: (\d+) - Random: (\d+)') {
                        $dateTimeParts = $matches[1] -split ',\s*'
                        $dateTime = "$($dateTimeParts[0])-$($dateTimeParts[1])-$($dateTimeParts[2]) $($dateTimeParts[3]):$($dateTimeParts[4]):$($dateTimeParts[5]).$($dateTimeParts[6])"
                        $temperature = [int]$matches[2]
                        $randomValue = [long]$matches[3]

                        DisplayText -displayDevice $ssd -line1Text "dt: $dateTime" -line2Text "temp: $temperature" -line3Text "rand: $randomValue" -fontSize 12
                        Log-Message "Parsed Data - Date/Time: $dateTime, Temperature: $temperature, Random: $randomValue"
                    } else {
                        Log-Message "Unexpected response format."
                    }
                } catch [System.TimeoutException] {
                    # Ignore read timeouts
                }
                Start-Sleep -Milliseconds 100
            }
        } catch {
            Log-Message "UART communication error: $($_.Exception.Message)"
        } finally {
            if ($serialPort.IsOpen) {
                $serialPort.Close()
                Log-Message "Serial port closed."
            }
        }
    }

    Read-FromSerialPort
})

# Run the script asynchronously
$runspace.Runspace = [runspacefactory]::CreateRunspace()
$runspace.Runspace.Open()
$runspace.BeginInvoke()

Write-Host "Script is running in the background and logging to $($env:APPDATA)\local\Logs\SerialPortLog.txt..."
