#Requires -Version 6.0

<#
# Install libraries using nuget
# default path is $env:USERPROFILE\.nuget\packages, or use -OutputDirectory to specify a different path
nuget install Iot.Device.Bindings
nuget install System.Device.Gpio
#>

# load libraries
add-type -path $env:USERPROFILE\.nuget\packages\iot.device.bindings\3.1.0\lib\netstandard2.0\Iot.Device.Bindings.dll
Add-type -path $env:USERPROFILE\.nuget\packages\system.device.gpio\3.2.0\lib\netstandard2.0\System.Device.Gpio.dll

# get list of FT232H devices
$ftDevices = [Iot.Device.Ft232h.Ft232hDevice]::GetFt232H()

# assign PsGadget controller $ct1
$ct1 = $ftDevices | ? SerialNumber -match "CT*" | Select-Object -First 1
$psgadget_ct1 = [Iot.Device.Ft232h.Ft232hDevice]::new($ct1)
$psgadget_ct1_gpio = $psgadget_ct1.CreateGpioController()

# Define pin numbers
$pinBlue = [Iot.Device.Ft232h.Ft232hDevice]::GetPinNumberFromString("C2")
$pinGreen = [Iot.Device.Ft232h.Ft232hDevice]::GetPinNumberFromString("C1")
$pinRed = [Iot.Device.Ft232h.Ft232hDevice]::GetPinNumberFromString("C0")

# Open the pins first
$psgadget_ct1_gpio.OpenPin($pinRed)
$psgadget_ct1_gpio.OpenPin($pinGreen)
$psgadget_ct1_gpio.OpenPin($pinBlue)

function red {
    $psgadget_ct1_gpio.Write($pinRed, [System.Device.Gpio.PinValue]::Low)
    $psgadget_ct1_gpio.Write($pinGreen, [System.Device.Gpio.PinValue]::High)
    $psgadget_ct1_gpio.Write($pinBlue, [System.Device.Gpio.PinValue]::High)
}

function green {
    $psgadget_ct1_gpio.Write($pinRed, [System.Device.Gpio.PinValue]::High)
    $psgadget_ct1_gpio.Write($pinGreen, [System.Device.Gpio.PinValue]::Low)
    $psgadget_ct1_gpio.Write($pinBlue, [System.Device.Gpio.PinValue]::High)
}

function blue {
    $psgadget_ct1_gpio.Write($pinRed, [System.Device.Gpio.PinValue]::High)
    $psgadget_ct1_gpio.Write($pinGreen, [System.Device.Gpio.PinValue]::High)
    $psgadget_ct1_gpio.Write($pinBlue, [System.Device.Gpio.PinValue]::Low)
}


function yellow {
    $psgadget_ct1_gpio.Write($pinRed, [System.Device.Gpio.PinValue]::Low)
    $psgadget_ct1_gpio.Write($pinGreen, [System.Device.Gpio.PinValue]::Low)
    $psgadget_ct1_gpio.Write($pinBlue, [System.Device.Gpio.PinValue]::High)
}

function cyan {
    $psgadget_ct1_gpio.Write($pinRed, [System.Device.Gpio.PinValue]::High)
    $psgadget_ct1_gpio.Write($pinGreen, [System.Device.Gpio.PinValue]::Low)
    $psgadget_ct1_gpio.Write($pinBlue, [System.Device.Gpio.PinValue]::Low)
}

function magenta {
    $psgadget_ct1_gpio.Write($pinRed, [System.Device.Gpio.PinValue]::Low)
    $psgadget_ct1_gpio.Write($pinGreen, [System.Device.Gpio.PinValue]::High)
    $psgadget_ct1_gpio.Write($pinBlue, [System.Device.Gpio.PinValue]::Low)
}

function white {
    $psgadget_ct1_gpio.Write($pinRed, [System.Device.Gpio.PinValue]::Low)
    $psgadget_ct1_gpio.Write($pinGreen, [System.Device.Gpio.PinValue]::Low)
    $psgadget_ct1_gpio.Write($pinBlue, [System.Device.Gpio.PinValue]::Low)
}

function off {
    $psgadget_ct1_gpio.Write($pinRed, [System.Device.Gpio.PinValue]::High)
    $psgadget_ct1_gpio.Write($pinGreen, [System.Device.Gpio.PinValue]::High)
    $psgadget_ct1_gpio.Write($pinBlue, [System.Device.Gpio.PinValue]::High)
}

# Now set them to output mode, without sending power to the pins
$psgadget_ct1_gpio.SetPinMode($pinRed, [System.Device.Gpio.PinMode]::Output)
$psgadget_ct1_gpio.SetPinMode($pinGreen, [System.Device.Gpio.PinMode]::Output)
$psgadget_ct1_gpio.SetPinMode($pinBlue, [System.Device.Gpio.PinMode]::Output)