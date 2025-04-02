# define path
$ftd2xxPath = "G:\MarkGzero\ftd2xxx_cs\FTD2XX.Net.1.2.1\lib\net45\FTDI2XX.dll"

# add library
Add-Type -path $ftd2xxPath


function Get-FTDIDeviceList {
    # Create new FTDI object instance
    $ftdi = [FTD2XX_NET.FTDI]::new()

    # Get number of devices
    [int]$deviceCount = 0
    $status = $ftdi.GetNumberOfDevices([ref]$deviceCount)

    if ($status -ne [FTD2XX_NET.FTDI+FT_STATUS]::FT_OK -or $deviceCount -eq 0) {
        Write-Error "No FTDI devices found or failed to enumerate."
        return $null
    }

    # Fetch device list
    $deviceList = New-Object 'FTD2XX_NET.FTDI+FT_DEVICE_INFO_NODE[]' $deviceCount
    $ftdi.GetDeviceList($deviceList) | Out-Null

    # Build enriched output
    $enrichedList = foreach ($dev in $deviceList) {
        $isOpen = $false

        # Try to open the device temporarily to check if it's in use
        $tempFtdi = [FTD2XX_NET.FTDI]::new()
        $tryStatus = $tempFtdi.OpenBySerialNumber($dev.SerialNumber)
        if ($tryStatus -eq [FTD2XX_NET.FTDI+FT_STATUS]::FT_OK) {
            $tempFtdi.Close() | Out-Null
            $isOpen = $false
        } else {
            $isOpen = $true
        }

        [PSCustomObject]@{
            IsBusy      = $isOpen
            IsOpen       = $isOpen
            Flags        = $dev.Flags
            Type         = $dev.Type
            ID           = $dev.ID
            LocId        = $dev.LocId
            SerialNumber = $dev.SerialNumber
            Description  = $dev.Description
            FtHandle = $dev.ftHandle
        }
    }

    $ftdi.Close() | Out-Null
    Remove-Variable ftdi -Force

    return $enrichedList
}


# function to initialize PSGadget
function New-PSGadget {
    [CmdletBinding()]
    param (
        [string]$SerialNumber = $null
    )

    # Create new FTDI object instance
    $ftdi = [FTD2XX_NET.FTDI]::new()

    if ($SerialNumber) {
        # Open device by serial number
        $status = $ftdi.OpenBySerialNumber($SerialNumber)
    } else {
    

    # Get number of devices
    [int]$deviceCount = 0
    $status = $ftdi.GetNumberOfDevices([ref]$deviceCount) | out-null

    if ($deviceCount -eq 0) {
        Write-Error "No FTDI devices found or failed to enumerate."
        return $null
    }

    # Fetch device list
    $deviceList = New-Object 'FTD2XX_NET.FTDI+FT_DEVICE_INFO_NODE[]' $deviceCount
    $ftdi.GetDeviceList($deviceList) | Out-Null

    if ($deviceCount -eq 1) {
        # Automatically select the first device if only one is found
        $choice = 0
    } else {
        # Show device selection prompt
        for($i = 0; $i -lt $deviceCount; $i++) {
            $dev = $deviceList[$i]
            # add index to object
            $dev | Add-Member -MemberType NoteProperty -Name Index -Value $i
        }

        $list = $deviceList | Where-object ftHandle -eq 0 | Format-Table | Out-String

        $choice = Read-Host "$list`nSelect available FTDI device by index: (0-$($list.count - 1))"

        if ($choice -notmatch '^\d+$' -or [int]$choice -ge $deviceCount) {
            Write-Error "Invalid selection."
            return $null
        }
    }

    # Open selected device
    $status = $ftdi.OpenByIndex([int]$choice)

    if ($status -ne [FTD2XX_NET.FTDI+FT_STATUS]::FT_OK) {

        # Check if the device is already open
        if ($status -eq [FTD2XX_NET.FTDI+FT_STATUS]::FT_DEVICE_NOT_OPENED) {
            Write-Error "Device is already open."
        } else {
            Write-Error "Failed to open device. Status: $status"

        }
        return $null
    }
    }
    
    # Continue with reset/init
    $ftdi.Purge([FTD2XX_NET.FTDI+FT_PURGE]::FT_PURGE_RX -bor [FTD2XX_NET.FTDI+FT_PURGE]::FT_PURGE_TX) | Out-Null
    $ftdi.ResetDevice() | Out-Null
    Start-Sleep -Milliseconds 100

    # Bit mode reset
    $ftdi.SetBitMode(0x00, [FTD2XX_NET.FTDI+FT_BIT_MODES]::FT_BIT_MODE_RESET) | Out-Null
    Start-Sleep -Milliseconds 50

    # Set bit mode MPSSE
    $ftdi.SetBitMode(0x00, [FTD2XX_NET.FTDI+FT_BIT_MODES]::FT_BIT_MODE_MPSSE) | Out-Null
    Start-Sleep -Milliseconds 50

    # get type
    [FTD2XX_NET.FTDI+FT_DEVICE]$type = 0
    if ($ftdi.GetDeviceType([ref]$type) -eq [FTD2XX_NET.FTDI+FT_STATUS]::FT_OK) {
        $type = $type.ToString()
        $ftdi | Add-Member -MemberType NoteProperty -Name DeviceType -Value $type
    } else {
        $ftdi | Add-Member -MemberType NoteProperty -Name DeviceType -Value ""
    }

    # get serial number
    [string]$serial = ""
    if ($ftdi.GetSerialNumber([ref]$serial) -eq [FTD2XX_NET.FTDI+FT_STATUS]::FT_OK) {
        $ftdi | Add-Member -MemberType NoteProperty -Name SerialNumber -Value $serial
    } else {
        $ftdi | Add-Member -MemberType NoteProperty -Name SerialNumber -Value ""
    }
    
    # get description
    [string]$description = ""
    if ($ftdi.GetDescription([ref]$description) -eq [FTD2XX_NET.FTDI+FT_STATUS]::FT_OK) {
        $ftdi | Add-Member -MemberType NoteProperty -Name Description -Value $description
    } else {
        $ftdi | Add-Member -MemberType NoteProperty -Name Description -Value ""
    }
    
    # Return the initialized FTDI object for further use
    return $ftdi
}


function Get-PSGadgetEEPROM {
    [CmdletBinding()]
    param (
        [FTD2XX_NET.FTDI]$Gadget
    )
    # Check if the FTDI device is initialized

    # Read EEPROM data
    try {
        $eeprom = [FTD2XX_NET.FTDI+FT232H_EEPROM_STRUCTURE]::new()
        $Gadget.ReadFT232HEEPROM([ref]$eeprom) | Out-Null
        if ($eeprom -eq $null) {
            Write-Error "Failed to read EEPROM data."
            return
        }
        $eeprom
        
    } catch {
        Write-Error "Failed to read EEPROM: $_"
        return
    }
}

function Write-MpsseCommand {
    param (
        [FTD2XX_NET.FTDI]$Ftdi,
        [byte[]]$Command
    )

    $bytesWritten = [uint32]0
    $status = $Ftdi.Write($Command, $Command.Length, [ref]$bytesWritten)

    if ($status -ne [FTD2XX_NET.FTDI+FT_STATUS]::FT_OK) {
        throw "FTDI Write failed. Status: $status"
    }

    if ($bytesWritten -ne $Command.Length) {
        Write-Warning "Incomplete write: only $bytesWritten of $($Command.Length) bytes sent"
    }
}

function Set-FtdiDeviceGpioPin {
    param (
        [FTD2XX_NET.FTDI]$Ftdi,
        [string]$Pin,
        [ValidateSet("Input", "Output")]
        [string]$Direction,
        [ValidateSet("High", "Low")]
        [string]$Value = "Low"
    )

    $bit = [int]$Pin.Substring(1)
    $isHighBank = $Pin.StartsWith("C")

    # Init GPIO state for each bank
    if (-not $script:GpioState) {
        $script:GpioState = [PSCustomObject]@{
            High = [PSCustomObject]@{
                Direction   = 0
                OutputValue = 0
            }
            Low = [PSCustomObject]@{
                Direction   = 0
                OutputValue = 0
            }
        }
    }

    $bankState = if ($isHighBank) { $script:GpioState.High } else { $script:GpioState.Low }

    # Update Direction and OutputValue
    if ($Direction -eq 'Output') {
        $bankState.Direction = $bankState.Direction -bor (1 -shl $bit)
        if ($Value -eq 'High') {
            $bankState.OutputValue = $bankState.OutputValue -bor (1 -shl $bit)
        } else {
            $bankState.OutputValue = $bankState.OutputValue -band -bnot (1 -shl $bit)
        }
    } else {
        $bankState.Direction = $bankState.Direction -band -bnot (1 -shl $bit)
        # Leave output value unchanged for inputs
    }

    # Build and send command
    $cmd = if ($isHighBank) {
        [byte[]](0x82, $bankState.OutputValue, $bankState.Direction)
    } else {
        [byte[]](0x80, $bankState.OutputValue, $bankState.Direction)
    }

    Write-MpsseCommand -Ftdi $Ftdi -Command $cmd
    Write-Verbose "Set GPIO → $Pin (Bank: $([string]::Format('{0:X2}', if ($isHighBank) { 0x82 } else { 0x80 })) Direction=$Direction, Value=$Value)"
}


function Get-FtdiDeviceGpioStatus {
    param (
        [FTD2XX_NET.FTDI]$Ftdi
    )

    # Read actual GPIO pin values
    $cmd = [byte[]](0x81)
    $Ftdi.Write($cmd, 1, [ref]([uint32]0)) | Out-Null

    $response = New-Object byte[] 1
    $Ftdi.Read($response, 1, [ref]([uint32]0)) | Out-Null
    $readValue = $response[0]

    0..7 | ForEach-Object {
        $bit = 1 -shl $_
        $isOutput = ($script:GpioState.Direction -band $bit) -ne 0
        $value = if ($isOutput) {
            if ($script:GpioState.OutputValue -band $bit) { "High" } else { "Low" }
        } else {
            if ($readValue -band $bit) { "High" } else { "Low" }
        }

        [PSCustomObject]@{
            Pin       = "C$_"
            Direction = if ($isOutput) { "Output" } else { "Input" }
            Value     = $value
        }
    }
}

function ledoff {
    param (
        [FTD2XX_NET.FTDI]$Ftdi
    )

    Set-FtdiDeviceGpioPin -Ftdi $Ftdi -Name "C0" -Direction "Output" -Value "High"
    Set-FtdiDeviceGpioPin -Ftdi $Ftdi -Name "C1" -Direction "Output" -Value "High"
    Set-FtdiDeviceGpioPin -Ftdi $Ftdi -Name "C2" -Direction "Output" -Value "High"
}

function Watch-FtdiPinChangeLoop {
    param (
        [FTD2XX_NET.FTDI]$Ftdi,
        [string]$Name,
        [int]$IntervalMs = 100,
        [ScriptBlock]$OnChange
    )

    $bit = [int]$Name.Substring(1)
    $prev = $null

    while ($true) {
        $cmd = [byte[]](0x81)
        $written = [uint32]0
        $Ftdi.Write($cmd, 1, [ref]$written) | Out-Null

        $buf = New-Object byte[] 1
        $read = [uint32]0
        $Ftdi.Read($buf, 1, [ref]$read) | Out-Null

        $current = ($buf[0] -band (1 -shl $bit)) -ne 0

        if ($prev -ne $null -and $current -ne $prev) {
            Write-Host "C3 changed: $current"
            & $OnChange.Invoke($current)
        }

        $prev = $current
        Start-Sleep -Milliseconds $IntervalMs
    }
}