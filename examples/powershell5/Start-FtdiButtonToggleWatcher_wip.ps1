function Start-FtdiButtonToggleWatcher {
    param (
        [string]$SerialNumber,
        [string]$ButtonPin = "D7",
        [string]$LedPin = "C1",
        [string]$LogPath
    )

    # Ensure log file exists
    if (-not (Test-Path $LogPath)) {
        New-Item -Path $LogPath -ItemType File -Force | Out-Null
    }

    $runspace = [RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()

    $ps = [PowerShell]::Create()
    $ps.Runspace = $runspace

    $ps.AddScript({
        param($serial, $buttonPin, $ledPin, $logPath)

        function Write-Log {
            param([string]$msg)
            $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
            Add-Content -Path $logPath -Value "$timestamp $msg"
        }

        $dll = "G:\MarkGzero\ftd2xxx_cs\FTD2XX.Net.1.2.1\lib\net45\FTDI2XX.dll"
        if (-not ("FTD2XX_NET.FTDI" -as [type])) {
            Add-Type -Path $dll
            Write-Log "Loaded FTDI2XX.NET from $dll"
        }

        $ftdi = [FTD2XX_NET.FTDI]::new()
        $status = $ftdi.OpenBySerialNumber($serial)
        Write-Log "Opening device $serial → Status: $status"
        $ftdi.Get
        $LogPath = $env:APPDATA\local\Logs\

        if ($status -ne [FTD2XX_NET.FTDI+FT_STATUS]::FT_OK) {
            Write-Log "ERROR: Could not open FTDI device"
            throw "Could not open FTDI device"
        }

        $ftdi.Purge(3) | Out-Null
        $ftdi.ResetDevice() | Out-Null
        Start-Sleep -Milliseconds 100
        $ftdi.SetBitMode(0x00, 0x00) | Out-Null
        Start-Sleep -Milliseconds 50
        $ftdi.SetBitMode(0x00, 0x02) | Out-Null
        Start-Sleep -Milliseconds 50
        Write-Log "FTDI initialized and in MPSSE mode"

        $script:GpioState = [PSCustomObject]@{
            Direction = 0
            OutputValue = 0
        }

        function Write-MpsseCommand {
            param ([FTD2XX_NET.FTDI]$Ftdi, [byte[]]$Command)
            $written = [uint32]0
            $status = $Ftdi.Write($Command, $Command.Length, [ref]$written)
            Write-Log "Write Command: $($Command -join ', ') → Status: $status, Bytes: $written"
        }

        function Set-FtdiDeviceGpioPin {
            param ([FTD2XX_NET.FTDI]$Ftdi, [string]$Name, [string]$Direction, [string]$Value = "Low")
            $bit = [int]$Name.Substring(1)

            if ($Direction -eq 'Output') {
                $script:GpioState.Direction = $script:GpioState.Direction -bor (1 -shl $bit)
                if ($Value -eq 'High') {
                    $script:GpioState.OutputValue = $script:GpioState.OutputValue -bor (1 -shl $bit)
                } else {
                    $script:GpioState.OutputValue = $script:GpioState.OutputValue -band -bnot (1 -shl $bit)
                }
            } else {
                $script:GpioState.Direction = $script:GpioState.Direction -band -bnot (1 -shl $bit)
            }

            $cmd = [byte[]](0x82, $script:GpioState.OutputValue, $script:GpioState.Direction)
            Write-MpsseCommand -Ftdi $Ftdi -Command $cmd
            Write-Log "Set GPIO → $Name Direction=$Direction, Value=$Value"
        }

        function Get-PinValue {
            param ([FTD2XX_NET.FTDI]$Ftdi, [string]$Pin)
        
            $bit = [int]$Pin.Substring(1)
            $isHighBank = $Pin.StartsWith("C")
        
            # Use correct MPSSE command based on pin bank
            $cmd = if ($isHighBank) { 0x83 } else { 0x81 }
        
            $Ftdi.Write([byte[]]($cmd), 1, [ref]([uint32]0)) | Out-Null
        
            $buf = New-Object byte[] 1
            $Ftdi.Read($buf, 1, [ref]([uint32]0)) | Out-Null
        
            $val = ($buf[0] -band (1 -shl $bit)) -ne 0
            # Write-Log "Read GPIO → $Pin from $([Convert]::ToString($cmd, 16)) Raw=0x$("{0:X2}" -f $buf[0]) Value=$($val ? 'High' : 'Low')"
            $val = if ($val) { "High" } else { "Low" }
            return $val
        }
        

        # Setup
        Set-FtdiDeviceGpioPin -Ftdi $ftdi -Name $LedPin -Direction Output -Value High
        Set-FtdiDeviceGpioPin -Ftdi $ftdi -Name $buttonPin -Direction Input

        $ledState = "High"
        $lastState = Get-PinValue -Ftdi $ftdi -Pin $buttonPin
        $latch_triggered = $false
        Write-Log "Initial pin states → LED: $LedPin=$ledState, Button: $buttonPin=$lastState"

        while ($true) {
            $current = Get-PinValue -Ftdi $ftdi -Pin $buttonPin

            if (-not $latch_triggered -and $lastState -eq "Low" -and $current -eq "High") {
                $latch_triggered = $true
                $ledState = if ($ledState -eq "High") { "Low" } else { "High" }
                Set-FtdiDeviceGpioPin -Ftdi $ftdi -Name $LedPin -Direction Output -Value $ledState
                Write-Log "[TOGGLE] Button press detected on $buttonPin"
                Write-Log "[LED] $LedPin is now: $ledState"
            }

            if ($latch_triggered -and $current -eq "Low") {
                $latch_triggered = $false
                Write-Log "[RESET] Button released"
            }

            $lastState = $current
            Start-Sleep -Milliseconds 50
        }

    }) | Out-Null

    $ps.AddArgument($SerialNumber)
    $ps.AddArgument($ButtonPin)
    $ps.AddArgument($LedPin)
    $ps.AddArgument($LogPath)

    $asyncResult = $ps.BeginInvoke()

    return [PSCustomObject]@{
        Runspace     = $runspace
        PowerShell   = $ps
        AsyncResult  = $asyncResult
        LogPath      = $LogPath
    }
}
