[cmdletbinding()]
param(
    $PackagesPath = "G:\MarkGzero\PSGadgets\lib" # Path to PSGadgets library folder
)


function Release-PsGadgetResources {
    param (
        [object] $DisplayDevice,
        [System.Device.I2c.I2cDevice] $i2cDevice,
        [Iot.Device.Ssd13xx.Ssd1306] $ssd
    )

    # Dispose of SSD
    if ($null -ne $ssd) {
        try {
            $ssd.Dispose()
            Write-Verbose "SSD device disposed successfully."
        }
        catch {
            Write-Error "Failed to dispose of SSD device: $_"
        }
        $ssd = $null
    }

    # Dispose of I2C Device
    if ($null -ne $i2cDevice) {
        try {
            $i2cDevice.Dispose()
            Write-Verbose "I2C device disposed successfully."
        }
        catch {
            Write-Error "Failed to dispose of I2C device: $_"
        }
        $i2cDevice = $null
    }

    # Dispose of Display or FT232H Device
    if ($null -ne $displayDevice) {
        try {
            if ($displayDevice -is [Iot.Device.Ft232h.Ft232hDevice]) {
                $displayDevice.Dispose()
                Write-Verbose "FT232H device disposed successfully."
            }
            elseif ($displayDevice -is [Iot.Device.Graphics.GraphicDisplay]) {
                $displayDevice.Dispose()
                Write-Verbose "Graphic display disposed successfully."
            }
            else {
                Write-Verbose "Unknown device type; skipping disposal."
            }
        }
        catch {
            Write-Error "Failed to dispose of display device: $_"
        }
        $displayDevice = $null
    }
}

function Display-Text {
    param (
        [Iot.Device.Graphics.GraphicDisplay] $displayDevice,
        [string] $Font = "Lucida Console",
        [string] $Header = "", # Top header section, 128 x 16 pixels
        [string] $Body = "", # Bottom body section, 128 x 48 pixels
        [int] $FontSize = 10, # Adjusted to fit between rows 1 and 15
        [int] $Width = 128,
        [int] $Height = 64
    )

    # Ensure lines are properly split and padded
    $line2Text = ""
    $line3Text = ""

    if ($Body -match "`n") {
        $lines = $Body -split "`n"
        $line2Text = $lines[0].Trim()
        $line3Text = if ($lines.Count -gt 1) { $lines[1].Trim() } else { "" }
    }
    else {
        $line2Text = $Body.Substring(0, [Math]::Min(19, $Body.Length)).PadRight(19, " ")
        if ($Body.Length -gt 19) {
            $line3Text = $Body.Substring(19, [Math]::Min(19, $Body.Length - 19)).PadRight(19, " ")
        }
        else {
            $line3Text = "".PadRight(19, " ")
        }
    }

    # Create the bitmap image
    $image = [Iot.Device.Graphics.BitmapImage]::CreateBitmap($Width, $Height, [Iot.Device.Graphics.PixelFormat]::Format32bppArgb)

    # Get the SKCanvas directly from the Canvas property
    $canvasWrapper = $image.GetDrawingApi()
    $canvas = $canvasWrapper.Canvas  # Access the actual SKCanvas

    # Set up paint for text with white color
    $paint = New-Object SkiaSharp.SKPaint
    $paint.TextSize = $FontSize
    $paint.Color = [SkiaSharp.SKColors]::White
    $paint.IsAntialias = $false
    $paint.Typeface = [SkiaSharp.SKTypeface]::FromFamilyName($Font)

    # Clear the canvas with black
    # $canvas.Clear([SkiaSharp.SKColors]::Black)

    # Draw text in respective sections
    # Line 1: Header fits between rows 1 and 15
    $headerY = 8 # Vertical baseline for the header to stay between rows 1-15
    $canvas.DrawText($Header, 0, $headerY, $paint)

    # Lines 2 and 3: Body in the bottom section (128 x 48 pixels)
    $line2Y = 18  # Adjust for better spacing
    $line3Y = 28
    $canvas.DrawText($line2Text, 0, $line2Y, $paint) # Line 2
    $canvas.DrawText($line3Text, 0, $line3Y, $paint) # Line 3

    # Draw the bitmap to the SSD1306 display
    $displayDevice.DrawBitmap($image)

    # Dispose of resources
    $paint.Dispose()
    $image.Dispose()
}

function Get-MemoryInfo {
    [cmdletbinding()]
    param ()
    $memory = Get-CimInstance -ClassName Win32_OperatingSystem
    $totalMemory = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
    $freeMemory = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
    $usedMemory = [math]::Round($totalMemory - $freeMemory, 2)
    [PSCustomObject]@{
        TotalMemoryMB = $totalMemory
        UsedMemoryMB  = $usedMemory
        FreeMemoryMB  = $freeMemory
    }
}


if ($null -ne $ssd) {
    Release-PsGadgetResources -DisplayDevice $psgadget_display -i2cDevice $i2cDevice -SSD $ssd
    write-verbose "Resources cleaned up. Wait a few seconds before reinitializing."
    $i = 5 
    while ($i -gt 0) {
        Write-Verbose "Waiting $i seconds..."
        Start-Sleep -Seconds 1
        $i--
    }
}

Add-type -AssemblyName System.Drawing # Required for SkiaSharp

gci $packagespath\*.dll | % {
    try {
        [void]([System.Reflection.Assembly]::LoadFrom($_.FullName))
    }
    catch {
        Write-Verbose "Error loading assembly: $_"
    }
} 

# get all devices
$devices = [Iot.Device.FtCommon.FtCommon]::GetDevices()

# search for display device
$ft_displaydevice = $devices | Where-Object { $_.SerialNumber -match "DS" }
if ($null -eq $ft_displaydevice) {
    Write-Error "No display device found."
    return
}
else {
    if ($ft_displaydevice.Description -match "64") {
        write-verbose "Display device found: $($ft_displaydevice.Description), height: 64"
        $resolutionHeight = 64
    }
    elseif ($ft_displaydevice.Description -match "32") {
        write-verbose "Display device found: $($ft_displaydevice.Description), height: 32"
        $resolutionHeight = 32
    }
    else {
        $resolutionHeight = 64
    }
}

# set display device
if ($null -ne $psgadget_display) {
    $psgadget_display.Dispose()
    $psgadget_display = $null
}

$psgadget_display = [Iot.Device.Ft232h.Ft232hDevice]::new($ft_displaydevice)

if ($null -eq $psgadget_display) {
    Write-Error "No display device found."
    return
}
else {
    Write-Verbose "Display device found: $($psgadget_display.Description)"
    $psgadget_display | Add-Member -MemberType NoteProperty -Name "ResolutionWidth" -Value 128
    $psgadget_display | Add-Member -MemberType NoteProperty -Name "ResolutionHeight" -Value 64
}

# Determine size of display based on Description
$description = $psgadget_display.Descriptionfreate
if ($description -match "64") {
    $psgadget_display.ResolutionHeight = 64
}
elseif ($description -match "32") {
    $psgadget_display.ResolutionHeight = 32
}

# Show the display object
Write-verbose ($psgadget_display).ToString() -join ","

# default bus number
# FT232H typically maps to bus 0
$bus = $psgadget_display.GetDefaultI2cBusNumber()
Write-Verbose "Default I2C bus number: $bus"
$address = 0x3C  # Common address for SSD1306 OLED displays
Write-Verbose "Default SSD1306 I2C address: $([Convert]::ToString($address, 16)) (decimal $address)"

# Initialize the I2C device using the FT232H configuration
# Dispose existing I2C device if it exists
if ($null -ne $i2cDevice) {
    $i2cDevice.Dispose()
    $i2cDevice = $null
}

# Create a new I2C device
try {

    # Set up SkiaSharp image factory and font details
    Write-Verbose "Setting up SkiaSharp image factory..."
    $skiaFactory = New-Object Iot.Device.Graphics.SkiaSharpAdapter.SkiaSharpImageFactory

    Write-Verbose "Registering SkiaSharp image factory..."
    [Iot.Device.Graphics.BitmapImage]::RegisterImageFactory($skiaFactory)

    Write-Verbose "Creating I2C device on bus $bus with address $([Convert]::ToString($address, 16))..."
    # Create I2C connection settings
    $i2cSettings = [System.Device.I2c.I2cConnectionSettings]::new($bus, $address)
    if ($null -ne $i2cDevice) {
        $i2cDevice.Dispose()
        $i2cDevice = $null
        Write-Verbose "Disposed of existing I2C device."
    }
    $i2cDevice = $psgadget_display.CreateI2cDevice($i2cSettings)
    Start-Sleep -Milliseconds 1000
    Write-Verbose "I2C device created."
    $ssd = [Iot.Device.Ssd13xx.Ssd1306]::new($i2cDevice, $psgadget_display.ResolutionWidth, $psgadget_display.ResolutionHeight)
}
catch {
    Write-Error "Failed to create I2C SSD device: $_"
    return
}


# For testing, clear the screen (if supported by your SSD1306 device and assembly)
$ssd.ClearScreen()
Write-Verbose "Display cleared."

####################################


write-host "`r`n`r`n"
Write-Host "################################################################"
Write-Host "#                     PsGadgets Demo:"
Write-Host "#                  SSD1306 OLED Display"
Write-Host "#             Adafruit FT232H Breakout Board"
Write-Host "#         Displaying: 'PsGadgets; Hello, PowerShell!'"
Write-Host "#"
Write-Host "################################################################"
Display-Text -DisplayDevice $ssd -Header "PsGadgets" -Body "Hello, PowerShell!"
Start-Sleep 2

write-host "`r`n`r`n"
Write-Host "################################################################"
Write-Host "#                     PsGadgets Demo:"
Write-Host "#                  SSD1306 OLED Display"
Write-Host "#             Adafruit FT232H Breakout Board"
Write-Host "#     Displaying: 'PsGadgets; PowerShell In The Real World.'"
Write-Host "#"
Write-Host "################################################################"
Display-Text -DisplayDevice $ssd -Header "PsGadgets" -Body "PowerShell`nIn The Real World."
Start-Sleep 2

write-host "`r`n`r`n"
Write-Host "################################################################"
Write-Host "#                     PsGadgets Demo:"
Write-Host "#                  SSD1306 OLED Display"
Write-Host "#             Adafruit FT232H Breakout Board"
Write-Host "#               Example: Memory Usage Monitor"
Write-Host "#"
Write-Host "################################################################"

# Example usage
while (1) {
    $meminfo = Get-MemoryInfo -Verbose:$false
    $t = (Get-Date).ToString("MM-dd HH:mm:ss")
    Display-Text -DisplayDevice $ssd -Header "PC Memory Utilization" -Body "$t`n [$($memInfo.TotalMemoryMB)MB] $($memInfo.UsedMemoryMB)"
    write-output "[$t] Using $($memInfo.UsedMemoryMB) of $($memInfo.TotalMemoryMB) MB"
    Start-Sleep -Seconds 1
}

#Error:
Write-Error: Failed to create I2C SSD device: Exception calling "CreateI2cDevice" with "1" argument(s): "Failed to open device PsGadget-Display64, status: DeviceNotOpen"