
Add-type -AssemblyName System.Drawing # Required for SkiaSharp
$packagespath = "G:\CSharp\GzeroFT232H\bin\Debug"

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
$firstdevice = $devices[0]
$selectdevice = [Iot.Device.Ft232h.Ft232hDevice]::new($firstdevice)
$selectdevice.GetDefaultI2cBusNumber()

# get device properties
#$selectdevice | gm

# get device by serial number, if known
# $devicebyserial = [Iot.Device.FtCommon.FtCommon]::GetDevices() | ? { $_.SerialNumber -eq "FTERYEPB" }

# # get pin from string
# [Iot.Device.Ft232H.Ft232HDevice]::GetPinNumberFromString("D0")
# [Iot.Device.Ft232H.Ft232HDevice]::GetPinNumberFromString("D1")
# [Iot.Device.Ft232H.Ft232HDevice]::GetPinNumberFromString("D2")
# [Iot.Device.Ft232H.Ft232HDevice]::GetPinNumberFromString("D3")
# [Iot.Device.Ft232H.Ft232HDevice]::GetPinNumberFromString("D4")
# [Iot.Device.Ft232H.Ft232HDevice]::GetPinNumberFromString("D5")
# [Iot.Device.Ft232H.Ft232HDevice]::GetPinNumberFromString("D6")



# Define the I2C settings
$busId = 0          # FT232H typically maps to bus 1 or channel "B"
$deviceAddress = 0x3C  # Common address for SSD1306 OLED displays
$Ssd1306Height = 64;
$Ssd1306Width = 128;

# Set up SkiaSharp image factory and font details
$skiaFactory = New-Object Iot.Device.Graphics.SkiaSharpAdapter.SkiaSharpImageFactory
[Iot.Device.Graphics.BitmapImage]::RegisterImageFactory($skiaFactory)

# Create I2C connection settings
$i2cSettings = [System.Device.I2c.I2cConnectionSettings]::new($busId, $deviceAddress)
Start-Sleep 2
# Initialize the I2C device using the FT232H configuration
$i2cDevice = $selectdevice.CreateI2cDevice($i2cSettings)
Start-Sleep 2

$ssd = [Iot.Device.Ssd13xx.Ssd1306]::new($i2cDevice, $Ssd1306Width, $Ssd1306Height)

# Test the device (optional, check if connection is established)
if ($i2cDevice -ne $null) {
    Write-Output "I2C device initialized successfully on channel $busId with address $([Convert]::ToString($deviceAddress, 16))."
} else {
    Write-Output "Failed to initialize the I2C device. Check connection settings."
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
DisplayText -displayDevice $ssd -line1Text "Yellow Section" -line2Text "Sky Blue Line 1" -line3Text "Sky Blue Line 1234567890" -fontSize 11