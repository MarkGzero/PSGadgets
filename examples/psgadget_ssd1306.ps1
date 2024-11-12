# Get pin from string
# [Iot.Device.Ft232H.Ft232HDevice]::GetPinNumberFromString("D0")
# [Iot.Device.Ft232H.Ft232HDevice]::GetPinNumberFromString("D1")
# [Iot.Device.Ft232H.Ft232HDevice]::GetPinNumberFromString("D2")
# [Iot.Device.Ft232H.Ft232HDevice]::GetPinNumberFromString("D3")
# [Iot.Device.Ft232H.Ft232HDevice]::GetPinNumberFromString("D4")
# [Iot.Device.Ft232H.Ft232HDevice]::GetPinNumberFromString("D5")
# [Iot.Device.Ft232H.Ft232HDevice]::GetPinNumberFromString("D6")

Add-type -AssemblyName System.Drawing # Required for SkiaSharp
$packagespath = "G:\MarkGzero\PSGadgets\lib"

gci $packagespath\*.dll | % {
    try {
        [System.Reflection.Assembly]::LoadFrom($_.FullName)
    } catch {
        Write-Host "Error loading assembly: $_"
    }
} 

# Load the Iot.Device.FtCommon and Iot.Device.Ft232h assemblies

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
    Write-Output "Display device found: $($psgadget_display.Description)"
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
Write-Host "Default I2C bus number: $bus"
$address = 0x3C  # Common address for SSD1306 OLED displays
Write-Host "Default SSD1306 I2C address: $([Convert]::ToString($address, 16)) (decimal $address)"

# Initialize the I2C device using the FT232H configuration
# Dispose existing I2C device if it exists
if ($null -ne $i2cDevice) {
    $i2cDevice.Dispose()
    $i2cDevice = $null
}

# Create a new I2C device
try {

    # Set up SkiaSharp image factory and font details
    Write-host "Setting up SkiaSharp image factory..."
    $skiaFactory = New-Object Iot.Device.Graphics.SkiaSharpAdapter.SkiaSharpImageFactory

    Write-Host "Registering SkiaSharp image factory..."
    [Iot.Device.Graphics.BitmapImage]::RegisterImageFactory($skiaFactory)

    Write-host "Creating I2C device on bus $bus with address $([Convert]::ToString($address, 16))..."
    # Create I2C connection settings
    $i2cSettings = [System.Device.I2c.I2cConnectionSettings]::new($bus, $address)
    if ($null -ne $i2cDevice) {
        $i2cDevice.Dispose()
        $i2cDevice = $null
        Write-Host "Disposed of existing I2C device."
    }
    $i2cDevice = $psgadget_display.CreateI2cDevice($i2cSettings)
    Start-Sleep -Milliseconds 1000
    Write-Host "I2C device created."
    $ssd = [Iot.Device.Ssd13xx.Ssd1306]::new($i2cDevice, $psgadget_display.ResolutionWidth, $psgadget_display.ResolutionHeight)
} catch {
    Write-Error "Failed to create I2C SSD device: $_"
    return
}


# For testing, clear the screen (if supported by your SSD1306 device and assembly)
$ssd.ClearScreen()
Write-Output "Display cleared."

####################################



# Define the DisplayText function
# Define the DisplayText function with dual-section layout
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

    # Create the bitmap image
    $image = [Iot.Device.Graphics.BitmapImage]::CreateBitmap($width, $height, [Iot.Device.Graphics.PixelFormat]::Format32bppArgb)

    # Get the SKCanvas directly from the Canvas property
    $canvasWrapper = $image.GetDrawingApi()
    $canvas = $canvasWrapper.Canvas  # Access the actual SKCanvas

    # Set up paint for text with white color
    $paint = New-Object SkiaSharp.SKPaint
    $paint.TextSize = $fontSize
    $paint.Color = [SkiaSharp.SKColors]::White
    $paint.IsAntialias = $true
    $paint.Typeface = [SkiaSharp.SKTypeface]::FromFamilyName($font)

    # Clear the canvas with black
    $canvas.Clear([SkiaSharp.SKColors]::Black)

    # Draw text in respective sections
    # Line 1 in the yellow section (top 128x16)
    $canvas.DrawText($line1Text, 0, 8, $paint)

    # Lines 2 and 3 in the sky blue section (bottom 128x48)
    $canvas.DrawText($line2Text, 0,18, $paint) # Start at row 16, allowing a line height space
    $canvas.DrawText($line3Text, 0,28, $paint)

    # Draw the bitmap to the SSD1306 display
    $displayDevice.DrawBitmap($image)

    # Dispose of resources
    $paint.Dispose()
    $image.Dispose()
}

# Call the DisplayText function with specified text for each section
#displayText -displayDevice $ssd -line1Text "-----------" -line2Text "PowerShell" -line3Text "                  Gadgets" -fontSize 13