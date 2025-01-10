[cmdletbinding()]
param(
    $PackagesPath = "G:\MarkGzero\PSGadgets\lib" # Path to PSGadgets library folder
)

Add-type -AssemblyName System.Drawing # Required for SkiaSharp

gci $packagespath\*.dll | % {
    try {
        [System.Reflection.Assembly]::LoadFrom($_.FullName)
    } catch {
        Write-Verbose "Error loading assembly: $_"
    }
} 

# get all devices
$devices = [Iot.Device.FtCommon.FtCommon]::GetDevices()

# get display device
$ft_displaydevice = $devices | Where-Object { $_.Description -match "Display" } 

# set display device
$psgadget_display = [Iot.Device.Ft232h.Ft232hDevice]::new($ft_displaydevice)

if ($null -eq $psgadget_display) {
    Write-Error "No display device found."
    return
} else {
    Write-Verbose "Display device found: $($psgadget_display.Description)"
    $psgadget_display | Add-Member -MemberType NoteProperty -Name "ResolutionWidth" -Value 128
    $psgadget_display | Add-Member -MemberType NoteProperty -Name "ResolutionHeight" -Value 64
}

# Determine size of display based on Description
$description = $psgadget_display.Description
if ($description -match "64") {
    $psgadget_display.ResolutionHeight = 64
} elseif ($description -match "32") {
    $psgadget_display.ResolutionHeight = 32
}

# Show the display object
$psgadget_display 

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
} catch {
    Write-Error "Failed to create I2C SSD device: $_"
    return
}


# For testing, clear the screen (if supported by your SSD1306 device and assembly)
$ssd.ClearScreen()
Write-Verbose "Display cleared."

####################################

# Define the DisplayText function
# Define the DisplayText function with dual-section layout
function Display-Text {
    param (
        [Iot.Device.Graphics.GraphicDisplay] $displayDevice,
        [string] $Font = "Lucida Console",
        [string] $Header = "", # Top header section, 128 x 16 pixels
        [string] $Body = "",  # Bottom body section, 128 x 48 pixels
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
    } else {
        $line2Text = $Body.Substring(0, [Math]::Min(19, $Body.Length)).PadRight(19, " ")
        if ($Body.Length -gt 19) {
            $line3Text = $Body.Substring(19, [Math]::Min(19, $Body.Length - 19)).PadRight(19, " ")
        } else {
            $line3Text = "".PadRight(19, " ")
        }
    }

    $displayDevice.ClearScreen()

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
    $canvas.Clear([SkiaSharp.SKColors]::Black)

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
        UsedMemoryMB = $usedMemory
        FreeMemoryMB = $freeMemory
    }
}

write-host "`r`n`r`n"
Write-Host "################################################################"
Write-Host "#                     PsGadgets Demo:"
Write-Host "#                  SSD1306 OLED Display"
Write-Host "#             Adafruit FT232H Breakout Board"
Write-Host "#         Displaying: 'PsGadgets; Hello, PowerShell!'"
Write-Host "#"
Write-Host "################################################################"
Display-Text -DisplayDevice $ssd -Header "PsGadgets" -Body "Hello, PowerShell!"
Start-Sleep 5

write-host "`r`n`r`n"
Write-Host "################################################################"
Write-Host "#                     PsGadgets Demo:"
Write-Host "#                  SSD1306 OLED Display"
Write-Host "#             Adafruit FT232H Breakout Board"
Write-Host "#     Displaying: 'PsGadgets; PowerShell In The Real World.'"
Write-Host "#"
Write-Host "################################################################"
Display-Text -DisplayDevice $ssd -Header "PsGadgets" -Body "PowerShell`nIn The Real World."
Start-Sleep 5

write-host "`r`n`r`n"
Write-Host "################################################################"
Write-Host "#                     PsGadgets Demo:"
Write-Host "#                  SSD1306 OLED Display"
Write-Host "#             Adafruit FT232H Breakout Board"
Write-Host "#               Example: Memory Usage Monitor"
Write-Host "#"
Write-Host "################################################################"

# Example usage
while(1){
    $meminfo = Get-MemoryInfo -Verbose:$false
    (Get-Date).DateTime
    $meminfo
    Display-Text -displayDevice $ssd -Header "Memory: $($meminfo.TotalMemoryMB)" -Body "Used: $($meminfo.UsedMemoryMB)`nFree: $($meminfo.FreeMemoryMB)"
    Start-Sleep -Seconds 1
}