
# PowerShell Gadgets (PsGadgets)

## DISCLAIMER: I HAVE NO IDEA WHAT I'M DOING. Please dont expect any kind of structure or logic to this... I'm literally learning IoT and microcontroller stuff for the first time as I mess with this stuff. I guess check back every few months or so if you're interested in seeing how this project evolves.


## Project Overview

This project is a proof of concept to demonstrate how to use PowerShell with a FTDI FT232H board, like the Adafruit FT232H breakout board, to interface with various IoT devices, sensors, outputs, and accessories.  

To expand the capabilities of this project, wireless communication is necessary. Since the FT232H chip does not natively support wireless communication, we'll use an ESP32, like the WaveShare ESP32-S3 board, to handle WiFi and ESP-Now communication with peripheral modules and devices.

## FTDI tagging and labeling

Recently discovered that we can use the FT_Prog utility to tag and label FTDI devices. This is a game changer IMO because I have a bunch of FTDI devices and I can never remember which one is which. 

By tagging and labeling FTDI device EEPROM, we can categorize and differentiate devices by their device string descriptions and serial number prefixes. This allows us to interact with PSGadget devices in a PowerShell script without hardcoding the serial number of each device.

See also: [CategorizingFT232-Devices.md](./docs/CategorizingFT232-Devices.md)

## Compatibility with PowerShell 5.1 and 7.x

.NET IoT libraries are cross-targeting .NET Standard 2.0, .NET Core 3.1, and .NET 6.0. They can be used from any project targeting .NET Core 2.0 or higher, and also from .NET Framework. (https://github.com/dotnet/iot/tree/main)

Some stuff works in Windows PowerShell 5.1, like the serial port communication. 

However, displaying text on an OLED display requires PowerShell 7.x or later, in my experience.


## Example: PowerShell 5.1; Reading serial port stream from multiple wireless psgadget-io devices 

![alt text](image.png)

## Example: PowerShell 7.x; Monitoring memory usage info then displaying results on an SSD1306 OLED display

Demo file: `./examples/psgadget_demo.ps1`

```powershell
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

while(1){
    $meminfo = Get-MemoryInfo -Verbose:$false
    (Get-Date).DateTime
    $meminfo
    Display-Text -displayDevice $ssd -Header "Memory: $($meminfo.TotalMemoryMB)" -Body "Used: $($meminfo.UsedMemoryMB)`nFree: $($meminfo.FreeMemoryMB)"
    Start-Sleep -Seconds 1
}
```
![ssd1306 demo](./images/ssd1306_demo2.png)

## Updates

2024OCT23: Initial commit.

2024NOV02: Learned about FT_Prog utility to tag and label FTDI devices. Updated documentation to reflect this new information.

2025JAN09: Revisited displaying text on an SSD1306 OLED display. Cleaned up the function so its easier to use and lines can be separated by newline character, or automatically wrapping text based on character count. Found that font Lucinda Console works best for this display.