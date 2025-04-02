# Load Required Assemblies
Add-Type -AssemblyName System.Drawing

function Load-PsGadgetAssemblies {
    try {
        Add-Type -AssemblyName System.Drawing
        # Load necessary assemblies
        gci "G:\MarkGzero\PSGadgets\lib\*.dll" | ForEach-Object {
            try {
                ([System.Reflection.Assembly]::LoadFrom($_.FullName)) | Out-Null
            } catch {
                Write-Verbose "Error loading assembly: $_"
            }
        }
        Write-Verbose "PSGadget assemblies loaded."
    } catch {
        Write-Error "Failed to load PSGadget assemblies: $_"
    }
}

function Get-PsGadgets {

    Load-PsGadgetAssemblies
    # check if environment is ps version 5
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        # Load the PSGadget module
        Write-Output "PSGadget module is not fully supported in Windows PowerShell (version 5.1). Please use PowerShell version 7 or later."
        return
    } else {
        Load-PsGadgetAssemblies
    }
        
    $psgadgets = [Iot.Device.FtCommon.FtCommon]::GetDevices()
    if ($psgadgets.Count -eq 0) {
        Write-Output "No PSGadget devices found."
    }
}

# Define the Display Logic as a ScriptBlock
$scriptBlock = {
    [cmdletbinding()]
    param(
        
    )

    try {
        # Load necessary assemblies
        gci "G:\MarkGzero\PSGadgets\lib\*.dll" | ForEach-Object {
            try {
                [System.Reflection.Assembly]::LoadFrom($_.FullName)
            } catch {
                Write-Verbose "Error loading assembly: $_"
            }
        }

        # Initialize SSD variables
        $psgadget_display = $null
        $skiaFactory = $null
        $i2cDevice = $null
        if ($ssd -ne $null) {
            $ssd.Dispose()
            $ssd = $null
        }

        # Get all devices
        $devices = [Iot.Device.FtCommon.FtCommon]::GetDevices()
        $ft_displaydevice = $devices | Where-Object { $_.Description -match "Display" }

        # Initialize display device
        $psgadget_display = [Iot.Device.Ft232h.Ft232hDevice]::new($ft_displaydevice)
        if ($null -eq $psgadget_display) {
            Write-Error "No display device found."
            return
        }

        $psgadget_display | Add-Member -MemberType NoteProperty -Name "ResolutionWidth" -Value 128
        $psgadget_display | Add-Member -MemberType NoteProperty -Name "ResolutionHeight" -Value 64

        # Adjust display resolution if needed
        $description = $psgadget_display.Description
        if ($description -match "64") {
            $psgadget_display.ResolutionHeight = 64
        } elseif ($description -match "32") {
            $psgadget_display.ResolutionHeight = 32
        }

        # Set up I2C device
        $bus = $psgadget_display.GetDefaultI2cBusNumber()
        $address = 0x3C
        $i2cSettings = [System.Device.I2c.I2cConnectionSettings]::new($bus, $address)
        $i2cDevice = $psgadget_display.CreateI2cDevice($i2cSettings)

        # Initialize SSD1306
        $ssd = [Iot.Device.Ssd13xx.Ssd1306]::new($i2cDevice, $psgadget_display.ResolutionWidth, $psgadget_display.ResolutionHeight)
        $ssd.ClearScreen()

        # Function to Display Text
        function Display-Text {
            param (
                [Iot.Device.Graphics.GraphicDisplay] $displayDevice,
                [string] $Header = "",
                [string] $Body = "",
                [int] $FontSize = 10,
                [int] $Width = 128,
                [int] $Height = 64
            )

            $line2Text = ""
            $line3Text = ""
            if ($Body -match "`n") {
                $lines = $Body -split "`n"
                $line2Text = $lines[0].Trim()
                $line3Text = if ($lines.Count -gt 1) { $lines[1].Trim() } else { "" }
            } else {
                $line2Text = $Body.Substring(0, [Math]::Min(19, $Body.Length)).PadRight(19, " ")
                if ($Body.Length -gt 19) {
                    $line3Text = $Body.Substring(19, [Math]::Min(19, $Body.Length - 19)).PadRight(19, " ")
                } else {
                    $line3Text = "".PadRight(19, " ")
                }
            }

            $image = [Iot.Device.Graphics.BitmapImage]::CreateBitmap($Width, $Height, [Iot.Device.Graphics.PixelFormat]::Format32bppArgb)
            $canvasWrapper = $image.GetDrawingApi()
            $canvas = $canvasWrapper.Canvas

            $paint = New-Object SkiaSharp.SKPaint
            $paint.TextSize = $FontSize
            $paint.Color = [SkiaSharp.SKColors]::White
            $paint.IsAntialias = $false
            $paint.Typeface = [SkiaSharp.SKTypeface]::FromFamilyName("Lucida Console")

            $canvas.Clear([SkiaSharp.SKColors]::Black)
            $canvas.DrawText($Header, 0, 8, $paint)
            $canvas.DrawText($line2Text, 0, 18, $paint)
            $canvas.DrawText($line3Text, 0, 28, $paint)

            $displayDevice.DrawBitmap($image)

            $paint.Dispose()
            $image.Dispose()
        }

        # Function to Get Memory Info
        function Get-MemoryInfo {
            param ()
            $memory = Get-CimInstance -ClassName Win32_OperatingSystem
            $totalMemory = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
            $freeMemory = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
            $usedMemory = [math]::Round($totalMemory - $freeMemory, 2)
            [PSCustomObject]@{
                TotalMemoryMB = $totalMemory
                UsedMemoryMB = $usedMemory
                FreeMemoryMB = $freeMemory
            }
        }

        # Infinite Loop to Display Memory Info
        while ($true) {
            $memInfo = Get-MemoryInfo
            $t = (Get-Date).ToString("MM-dd HH:mm:ss")
            Display-Text -DisplayDevice $ssd -Header "PC Memory Utilization" -Body "Time: $t`n$($memInfo.TotalMemoryMB) - Using $($memInfo.UsedMemoryMB)"
            Start-Sleep -Seconds 1
        }
    } catch {
        Write-Error "Error in runspace: $_"
    }
}

# Create and Configure the Runspace
$runspace = [powershell]::Create()
$runspace.AddScript($scriptBlock)
$runspace.RunspacePool = [runspacefactory]::CreateRunspacePool(1, 5)
$runspace.RunspacePool.Open()

# Start the Runspace
$asyncResult = $runspace.BeginInvoke()

Write-Host "Runspace started. Use the following commands to manage it:"
Write-Host "Check status: `$runspace.InvocationStateInfo.State"
Write-Host "Stop the runspace: `$runspace.Stop()"
Write-Host "Retrieve output (if any): `$runspace.EndInvoke($asyncResult)"
