# Get the FTDI device and extract the COM port number
$PsGadget_Controller = Get-PnpDevice | Where-Object {
    $_.Manufacturer -match "FTDI" -and $_.Status -eq "OK" -and $_.PNPDeviceId -match "\+CT.*"
}

$PortNumber = $PsGadget_Controller.FriendlyName -replace ".*\((COM\d+)\).*", '$1'

if ($PortNumber) {
    Write-Host "COM Port found: $PortNumber"

    # Attempt to retrieve the baud rate using CIM/WMI
    $ComPortConfig = Get-CimInstance -Namespace "ROOT\CIMV2" -ClassName "Win32_SerialPort" | Where-Object { $_.DeviceID -eq $PortNumber }

    if ($ComPortConfig) {
        $BaudRate = $ComPortConfig.MaxBaudRate
        Write-Host "Baud rate for $PortNumber $BaudRate"
    } else {
        Write-Warning "Unable to retrieve configuration for $PortNumber."
    }

    # Initialize the SerialPort object
    $serialPort = New-Object System.IO.Ports.SerialPort $PortNumber
    $serialPort.Handshake = [System.IO.Ports.Handshake]::None
    $serialPort.ReadTimeout = 500

    # Function to initialize and open the serial port
    function Initialize-SerialPort {
        if (-not $serialPort.IsOpen) {
            $serialPort.Open()
            Write-Output "Opened serial port on $($serialPort.PortName)"
        } else {
            Write-Output "Serial port is already open."
        }
    }

    # Function to read data from the serial port in a loop
    function Read-FromSerialPort {
        try {
            Initialize-SerialPort

            while ($true) {
                try {
                    # Read a line from the serial port
                    $response = $serialPort.ReadLine()
                    Write-Output "ESP32 response: $response"

                    # Expected response format: (2000, 1, 2, 4, 46, 19, 6, 2) - Temperature: 49 - Random: 2373658983
                    if ($response -match '\(([^)]+)\) - Temperature: (\d+) - Random: (\d+)') {
                        $dateTimeParts = $matches[1] -split ',\s*'
                        $temperature = [int]$matches[2]
                        $randomValue = [long]$matches[3]

                        # Combine date and time parts into a readable format
                        $dateTime = "$($dateTimeParts[0])-$($dateTimeParts[1])-$($dateTimeParts[2]) $($dateTimeParts[3]):$($dateTimeParts[4]):$($dateTimeParts[5]).$($dateTimeParts[6])"

                        # Display parsed data on the SSD1306 display
                        DisplayText -displayDevice $ssd -line1Text "dt: $dateTime" -line2Text "temp: $temperature" -line3Text "rand: $randomValue" -fontsize 13
                    } else {
                        Write-Host "Response format did not match the expected pattern."
                    }
                }
                catch [System.TimeoutException] {
                    # Ignore timeout exceptions
                }
                Start-Sleep -Milliseconds 100  # Delay to prevent overloading the serial port
            }
        }
        catch {
            Write-Output "Error in UART communication: $($_.Exception.Message)"
        }
        finally {
            # Ensure the port is closed after reading
            if ($serialPort.IsOpen) {
                $serialPort.Close()
                Write-Output "Closed serial port."
            }
        }
    }

    # Start the read loop
    Read-FromSerialPort
} else {
    Write-Warning "No valid COM port found for the FTDI device."
}
