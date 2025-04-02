$global:PSGadgetScriptRoot = $PSScriptRoot

function Add-PsGadgetAssemblies {
    try {
        Add-Type -AssemblyName System.Drawing
        # Load necessary assemblies
        gci "$PSGadgetScriptRoot\..\lib\*.dll" | ForEach-Object {
            try {
                ([System.Reflection.Assembly]::LoadFrom($_.FullName)) | out-null
                Write-Verbose "Loaded assembly: $_"
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

    # check if environment is ps version 5
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        # Load the PSGadget module
        Write-Output "`r`nPSGadget module is not fully supported in Windows PowerShell (version 5.1). Reading serial port traffic Please use PowerShell version 7 or later.`r`n"
    } else {
        Add-PsGadgetAssemblies
    }
        
    $psgadgets = [Iot.Device.FtCommon.FtCommon]::GetDevices()
    if ($psgadgets.Count -eq 0) {
        Write-Output "No PSGadget devices found."
    } else {
        $psgadgets
    }
}

# Logging function
function Log-Message {
    param (
        [string]$Message,
        [string]$LogFile
    )
    $DateTimePrefix = $(Get-Date -Format 'yyyyMMdd_')
    $logFile = "$($env:APPDATA)\local\Logs\$DateTimePrefix$($LogFile)_PsGadgets_SerialPortLog.txt"
    $global:PSGadgetSerialLogFolder = split-path $logFile
    # Ensure log directory exists and log the message
    $logDir = (Split-Path -Path $LogFile)
    if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
    Add-Content -Path $LogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

# Initialize and configure the PsGadget Serial Port with retry logic
function Initialize-PsGadgetSerialPort {
    [CmdletBinding()]
    param ()

    # Detect FTDI device and extract the COM port number
    $PsGadget_Controller = Get-PnpDevice | Where-Object {
        $_.Manufacturer -match "FTDI" -and $_.Status -eq "OK" -and $_.PNPDeviceId -match "\+CT.*"
    }

    if (-not $PsGadget_Controller) {
        Log-Message "No FTDI device found."
        Write-Debug "No FTDI device found."
        return $null
    }

    Log-Message "FTDI device found: $($PsGadget_Controller.FriendlyName)"
    Write-Debug "FTDI device found: $($PsGadget_Controller.FriendlyName)"

    # Extract and validate COM port number
    $PortNumber = $PsGadget_Controller.FriendlyName -replace ".*\((COM\d+)\).*", '$1'
    if (-not $PortNumber) {
        Log-Message "No valid COM port found for the FTDI device."
        Write-Debug "No valid COM port found for the FTDI device."
        return $null
    }

    Log-Message "COM port found: $PortNumber"
    Write-Debug "COM port found: $PortNumber"

    # Initialize the SerialPort object
    $serialPort = [System.IO.Ports.SerialPort]::new($PortNumber, 9600, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)

    # Attempt to open the port with retries
    function Try-OpenSerialPort {
        param (
            [System.IO.Ports.SerialPort] $serialPort
        )

        for ($attempt = 1; $attempt -le 3; $attempt++) {
            try {
                # Explicitly close and dispose if already open
                if ($serialPort.IsOpen) {
                    Log-Message "Closing previously open serial port."
                    Write-Debug "Closing previously open serial port."
                    $serialPort.Close()
                    $serialPort.Dispose()
                }

                # Attempt to open the serial port
                $serialPort.Open()
                Log-Message "Serial port opened successfully on $PortNumber."
                Write-Debug "Serial port opened successfully on $PortNumber."
                return $serialPort
            } catch [System.UnauthorizedAccessException] {
                Log-Message "Access denied on attempt $attempt. Port may be in use. Retrying..."
                Write-Debug "Access denied on attempt $attempt. Retrying in 2 seconds..."
                Start-Sleep -Seconds 2
            } catch {
                Log-Message "Failed to open serial port: $($_.Exception.Message)"
                Write-Debug "Failed to open serial port: $($_.Exception.Message)"
                $serialPort.Dispose()
                return $null
            }
        }

        # If all attempts fail
        Log-Message "Failed to open serial port after multiple attempts."
        Write-Debug "Failed to open serial port after multiple attempts."
        return $null
    }

    # Attempt to open the serial port
    return Try-OpenSerialPort $serialPort
}

# Function to read data from the serial port with buffering and logging
function Read-PsGadgetSerialTraffic {
    [CmdletBinding()]
    param()
    
    # Initialize the serial port
    $serialPort = Initialize-PsGadgetSerialPort
    if (-not $serialPort) {
        Write-Host "Failed to initialize the serial port."
        return
    }

    # Buffer to store partial data until we get a complete line
    $buffer = ""

    try {
        while ($true) {
            # Check if data is available to read
            if ($serialPort.BytesToRead -gt 0) {
                # Read available data and append to buffer
                $data = $serialPort.ReadExisting()
                $buffer += $data

                # Process lines from buffer if newline characters are present
                while ($buffer -match "(.*?)(`r?`n)") {
                    $line = $matches[1].Trim()  # Extract the full line and trim spaces
                    $buffer = $buffer.Substring($matches[0].Length)  # Remove processed line from buffer
                    
                    # Log the received line with timestamp
                    $timestamp = Get-Date -Format 'yyyyMMddTHHmmssfff'
                    Write-Host "$timestamp Received: $line"  # Replace Log-Message with Write-Host
                    Log-Message "$timestamp Received: $line"
                }
            } else {
                # If no data, sleep briefly to avoid high CPU usage
                Start-Sleep -Milliseconds 100
            }
        }
    }
    catch {
        Write-Host "Error reading from serial port: $($_.Exception.Message)"
    }
    finally {
        # Ensure the serial port is closed and disposed if open
        if ($serialPort -and $serialPort.IsOpen) {
            $serialPort.Close()
            $serialPort.Dispose()
            $spObj = $serialPort | Out-String
            Write-Verbose "$spObj"
            Write-Host "Serial port object closed and disposed."
        }
    }
}

function Stop-PsGadgetSerialTraffic {
    # Check if the serial port is open
}


# Function to write data to the serial port
function Write-ToSerialPort {
    param (
        [System.IO.Ports.SerialPort] $serialPort,
        [string] $Message
    )

    if (-not $serialPort -or -not $serialPort.IsOpen) {
        Write-Host "Serial port is not open. Reinitializing..."
        $serialPort = Initialize-PsGadgeSerialPort
        if (-not $serialPort) {
            Write-Host "Failed to initialize the serial port."
            return
        }
    }

    try {
        $serialPort.WriteLine($Message)
        Log-Message "Sent message: $Message"
    }
    catch {
        Log-Message "Error writing to serial port: $($_.Exception.Message)"
    }
}

# Start reading from the serial port
# Read-PsGadgetSerialTraffic -Verbose

