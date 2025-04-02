Using FTDI FTD2xx.dll C# wrapper, its possible to interface with a FTDI FT232H device using PowerShell.

First, the FTDI driver must be installed. The FTDI driver can be downloaded from the FTDI website: 
[FTDI Drivers](https://ftdichip.com/drivers/d2xx-drivers/)

There are two components to the FTDI driver, the VCP and the D2XX driver: 
1. The D2XX driver is a proprietary driver that allows direct access to the FTDI chip, 
2. The VCP driver creates a virtual COM port that can be accessed using standard Windows serial port APIs.

The FTDI D2XX driver is recommended for use with the FT232H chip, as it provides more features and better performance than the VCP driver.

## MPSSE

The FT232H chip can be used in MPSSE (Multi-Protocol Synchronous Serial Engine) mode, which allows it to communicate with SPI, I2C, and JTAG devices.

FTDI releaed an MPSSE Programming Guide, which can be found here: 
[FTDI MPSSE Programming Guide](https://ftdichip.com/wp-content/uploads/2023/09/MPSSE_Programming_Guide.pdf)

## Basic interface

After driver install, the FTDI device can be accessed using the FTDI D2XX driver.

There is a C# wrapper for the FTDI D2XX driver, which can be found here:
[C# Wrapper]()

### Scripts

Example function to get a list of FTDI devices:
```powershell

function Get-FTDIDevices {
    # Load the FTDI D2XX driver
    Add-Type -Path "C:\path\to\FtdiD2xx.dll"

    # Get a list of FTDI devices
    $devices = [FtdiD2xx.Ftdi]::GetDeviceList()

    # Return the list of devices
    return $devices
}
```
