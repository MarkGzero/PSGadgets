# Logging function
function Log-Message {
    param (
        [string]$Message,
        [string]$LogFile = "$($env:APPDATA)\local\Logs\SerialPortLog.txt"
    )
    
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
    Try-OpenSerialPort $serialPort
}

# Function to read data from the serial port with buffering and logging
function Read-PsGadgetSerialTraffic {
    [cmdletbinding()]
    param()
    
    $serialPort = Initialize-PsGadgetSerialPort
    if (-not $serialPort) {
        Write-Host "Failed to initialize the serial port."
        return
    }

    # Initialize buffer for storing partial data
    $buffer = ""

    try {
        while ($true) {
            # Check if data is available
            if ($serialPort.BytesToRead -gt 0) {
                # Read all available data and append to buffer
                $cdt = Get-Date -Format 'yyyyMMddTHHmmssfff'
                $data = $serialPort.ReadExisting()
                $buffer += $data
                write-verbose (Log-Message "Buffer after reading data: '$buffer'")  # Diagnostic output
                # Process lines if newline character(s) are present
                while ($buffer -match "^(.*?)(`r?`n)") {
                    $line = $matches[1].Trim()  # Extract full line, trimming any extra spaces
                    $buffer = $buffer.Substring($matches[0].Length)  # Remove processed line from buffer
                    # Log and display the complete line
                    Log-Message "$cdt Received: $line"
                    Write-Host "$cdt Received: $line"
                }
            }
            else {
                Start-Sleep -Milliseconds 100  # Small delay to reduce CPU usage
            }
        }
    }
    catch {
        Log-Message "Error reading from serial port: $($_.Exception.Message)"
    }
    finally {
        if ($serialPort -and $serialPort.IsOpen) {
            $serialPort.Close()
            $serialPort.Dispose()
            Log-Message "Serial port closed and disposed."
        }
    }
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
Read-PsGadgetSerialTraffic -Verbose
