## FTDI Method Reference

```powershell
TypeName: FTD2XX_NET.FTDI

Name                   MemberType Definition
----                   ---------- ----------
Close                  Method     FTD2XX_NET.FTDI+FT_STATUS Close()
CyclePort              Method     FTD2XX_NET.FTDI+FT_STATUS CyclePort()
EEReadUserArea         Method     FTD2XX_NET.FTDI+FT_STATUS EEReadUserArea(byte[] UserAreaDataBuffer, [ref] uint32 numBytesRead)
EEUserAreaSize         Method     FTD2XX_NET.FTDI+FT_STATUS EEUserAreaSize([ref] uint32 UASize)
EEWriteUserArea        Method     FTD2XX_NET.FTDI+FT_STATUS EEWriteUserArea(byte[] UserAreaDataBuffer)
EraseEEPROM            Method     FTD2XX_NET.FTDI+FT_STATUS EraseEEPROM()
GetCOMPort             Method     FTD2XX_NET.FTDI+FT_STATUS GetCOMPort([ref] string ComPortName)
GetDescription         Method     FTD2XX_NET.FTDI+FT_STATUS GetDescription([ref] string Description)
GetDeviceID            Method     FTD2XX_NET.FTDI+FT_STATUS GetDeviceID([ref] uint32 DeviceID)
GetDeviceList          Method     FTD2XX_NET.FTDI+FT_STATUS GetDeviceList(FTD2XX_NET.FTDI+FT_DEVICE_INFO_NODE[] devicelist)
GetDeviceType          Method     FTD2XX_NET.FTDI+FT_STATUS GetDeviceType([ref] FTD2XX_NET.FTDI+FT_DEVICE DeviceType)
GetDriverVersion       Method     FTD2XX_NET.FTDI+FT_STATUS GetDriverVersion([ref] uint32 DriverVersion)
GetEventType           Method     FTD2XX_NET.FTDI+FT_STATUS GetEventType([ref] uint32 EventType)
GetLatency             Method     FTD2XX_NET.FTDI+FT_STATUS GetLatency([ref] byte Latency)
GetLibraryVersion      Method     FTD2XX_NET.FTDI+FT_STATUS GetLibraryVersion([ref] uint32 LibraryVersion)
GetLineStatus          Method     FTD2XX_NET.FTDI+FT_STATUS GetLineStatus([ref] byte LineStatus)
GetModemStatus         Method     FTD2XX_NET.FTDI+FT_STATUS GetModemStatus([ref] byte ModemStatus)
GetNumberOfDevices     Method     FTD2XX_NET.FTDI+FT_STATUS GetNumberOfDevices([ref] uint32 devcount)
GetPinStates           Method     FTD2XX_NET.FTDI+FT_STATUS GetPinStates([ref] byte BitMode)
GetRxBytesAvailable    Method     FTD2XX_NET.FTDI+FT_STATUS GetRxBytesAvailable([ref] uint32 RxQueue)
GetSerialNumber        Method     FTD2XX_NET.FTDI+FT_STATUS GetSerialNumber([ref] string SerialNumber)
GetTxBytesWaiting      Method     FTD2XX_NET.FTDI+FT_STATUS GetTxBytesWaiting([ref] uint32 TxQueue)
InTransferSize         Method     FTD2XX_NET.FTDI+FT_STATUS InTransferSize(uint32 InTransferSize)
OpenByDescription      Method     FTD2XX_NET.FTDI+FT_STATUS OpenByDescription(string description)
OpenByIndex            Method     FTD2XX_NET.FTDI+FT_STATUS OpenByIndex(uint32 index)
OpenByLocation         Method     FTD2XX_NET.FTDI+FT_STATUS OpenByLocation(uint32 location)
OpenBySerialNumber     Method     FTD2XX_NET.FTDI+FT_STATUS OpenBySerialNumber(string serialnumber)
Purge                  Method     FTD2XX_NET.FTDI+FT_STATUS Purge(uint32 purgemask)
Read                   Method     FTD2XX_NET.FTDI+FT_STATUS Read(byte[] dataBuffer, uint32 numBytesToRead, [ref] uint32 numBy...
ReadEEPROMLocation     Method     FTD2XX_NET.FTDI+FT_STATUS ReadEEPROMLocation(uint32 Address, [ref] uint16 EEValue)
ReadFT2232EEPROM       Method     FTD2XX_NET.FTDI+FT_STATUS ReadFT2232EEPROM(FTD2XX_NET.FTDI+FT2232_EEPROM_STRUCTURE ee2232)
ReadFT2232HEEPROM      Method     FTD2XX_NET.FTDI+FT_STATUS ReadFT2232HEEPROM(FTD2XX_NET.FTDI+FT2232H_EEPROM_STRUCTURE ee2232h)
ReadFT232BEEPROM       Method     FTD2XX_NET.FTDI+FT_STATUS ReadFT232BEEPROM(FTD2XX_NET.FTDI+FT232B_EEPROM_STRUCTURE ee232b)
ReadFT232HEEPROM       Method     FTD2XX_NET.FTDI+FT_STATUS ReadFT232HEEPROM(FTD2XX_NET.FTDI+FT232H_EEPROM_STRUCTURE ee232h)
ReadFT232REEPROM       Method     FTD2XX_NET.FTDI+FT_STATUS ReadFT232REEPROM(FTD2XX_NET.FTDI+FT232R_EEPROM_STRUCTURE ee232r)
ReadFT4232HEEPROM      Method     FTD2XX_NET.FTDI+FT_STATUS ReadFT4232HEEPROM(FTD2XX_NET.FTDI+FT4232H_EEPROM_STRUCTURE ee4232h)
ReadXSeriesEEPROM      Method     FTD2XX_NET.FTDI+FT_STATUS ReadXSeriesEEPROM(FTD2XX_NET.FTDI+FT_XSERIES_EEPROM_STRUCTURE eeX)
Reload                 Method     FTD2XX_NET.FTDI+FT_STATUS Reload(uint16 VendorID, uint16 ProductID)
Rescan                 Method     FTD2XX_NET.FTDI+FT_STATUS Rescan()
ResetDevice            Method     FTD2XX_NET.FTDI+FT_STATUS ResetDevice()
ResetPort              Method     FTD2XX_NET.FTDI+FT_STATUS ResetPort()
RestartInTask          Method     FTD2XX_NET.FTDI+FT_STATUS RestartInTask()
SetBaudRate            Method     FTD2XX_NET.FTDI+FT_STATUS SetBaudRate(uint32 BaudRate)
SetBitMode             Method     FTD2XX_NET.FTDI+FT_STATUS SetBitMode(byte Mask, byte BitMode)
SetBreak               Method     FTD2XX_NET.FTDI+FT_STATUS SetBreak(bool Enable)
SetCharacters          Method     FTD2XX_NET.FTDI+FT_STATUS SetCharacters(byte EventChar, bool EventCharEnable, byte ErrorCha...
SetDataCharacteristics Method     FTD2XX_NET.FTDI+FT_STATUS SetDataCharacteristics(byte DataBits, byte StopBits, byte Parity)
SetDeadmanTimeout      Method     FTD2XX_NET.FTDI+FT_STATUS SetDeadmanTimeout(uint32 DeadmanTimeout)
SetDTR                 Method     FTD2XX_NET.FTDI+FT_STATUS SetDTR(bool Enable)
SetEventNotification   Method     FTD2XX_NET.FTDI+FT_STATUS SetEventNotification(uint32 eventmask, System.Threading.EventWait...
SetFlowControl         Method     FTD2XX_NET.FTDI+FT_STATUS SetFlowControl(uint16 FlowControl, byte Xon, byte Xoff)
SetLatency             Method     FTD2XX_NET.FTDI+FT_STATUS SetLatency(byte Latency)
SetResetPipeRetryCount Method     FTD2XX_NET.FTDI+FT_STATUS SetResetPipeRetryCount(uint32 ResetPipeRetryCount)
SetRTS                 Method     FTD2XX_NET.FTDI+FT_STATUS SetRTS(bool Enable)
SetTimeouts            Method     FTD2XX_NET.FTDI+FT_STATUS SetTimeouts(uint32 ReadTimeout, uint32 WriteTimeout)
StopInTask             Method     FTD2XX_NET.FTDI+FT_STATUS StopInTask()
VendorCmdGet           Method     FTD2XX_NET.FTDI+FT_STATUS VendorCmdGet(uint16 request, byte[] buf, uint16 len)
VendorCmdSet           Method     FTD2XX_NET.FTDI+FT_STATUS VendorCmdSet(uint16 request, byte[] buf, uint16 len)
Write                  Method     FTD2XX_NET.FTDI+FT_STATUS Write(byte[] dataBuffer, int numBytesToWrite, [ref] uint32 numByt...
WriteEEPROMLocation    Method     FTD2XX_NET.FTDI+FT_STATUS WriteEEPROMLocation(uint32 Address, uint16 EEValue)
WriteFT2232EEPROM      Method     FTD2XX_NET.FTDI+FT_STATUS WriteFT2232EEPROM(FTD2XX_NET.FTDI+FT2232_EEPROM_STRUCTURE ee2232)
WriteFT2232HEEPROM     Method     FTD2XX_NET.FTDI+FT_STATUS WriteFT2232HEEPROM(FTD2XX_NET.FTDI+FT2232H_EEPROM_STRUCTURE ee2232h)
WriteFT232BEEPROM      Method     FTD2XX_NET.FTDI+FT_STATUS WriteFT232BEEPROM(FTD2XX_NET.FTDI+FT232B_EEPROM_STRUCTURE ee232b)
WriteFT232HEEPROM      Method     FTD2XX_NET.FTDI+FT_STATUS WriteFT232HEEPROM(FTD2XX_NET.FTDI+FT232H_EEPROM_STRUCTURE ee232h)
WriteFT232REEPROM      Method     FTD2XX_NET.FTDI+FT_STATUS WriteFT232REEPROM(FTD2XX_NET.FTDI+FT232R_EEPROM_STRUCTURE ee232r)
WriteFT4232HEEPROM     Method     FTD2XX_NET.FTDI+FT_STATUS WriteFT4232HEEPROM(FTD2XX_NET.FTDI+FT4232H_EEPROM_STRUCTURE ee4232h)
WriteXSeriesEEPROM     Method     FTD2XX_NET.FTDI+FT_STATUS WriteXSeriesEEPROM(FTD2XX_NET.FTDI+FT_XSERIES_EEPROM_STRUCTURE eeX)
IsOpen                 Property   bool IsOpen {get;}
```

## Close

**Purpose:** Closes the device connection

```powershell
$d1.Close()
```

## CyclePort

**Purpose:** Cycles USB port to re-enumerate the device

```powershell
$d1.CyclePort()
```

## EEReadUserArea

**Purpose:** Reads user EEPROM area

```powershell
$buffer = New-Object byte[] 64
[uint32]$bytesRead = 0
$d1.EEReadUserArea($buffer, [ref]$bytesRead)
```

## EEUserAreaSize

**Purpose:** Gets size of EEPROM user area

```powershell
[uint32]$size = 0
$d1.EEUserAreaSize([ref]$size)
```

## EEWriteUserArea

**Purpose:** Writes data to EEPROM user area

```powershell
$data = [byte[]](1,2,3,4)
$d1.EEWriteUserArea($data)
```

## EraseEEPROM

**Purpose:** Erases the entire EEPROM

```powershell
$d1.EraseEEPROM()
```

## GetCOMPort

**Purpose:** Gets assigned COM port

```powershell
[string]$comPort = ''
$d1.GetCOMPort([ref]$comPort)
```

## GetDescription

**Purpose:** Gets device description

```powershell
[string]$desc = ''
$d1.GetDescription([ref]$desc)
```

## GetDeviceID

**Purpose:** Gets the device ID

```powershell
[uint32]$id = 0
$d1.GetDeviceID([ref]$id)
```

## GetDeviceType

**Purpose:** Gets FTDI device type

```powershell
[FTD2XX_NET.FTDI+FT_DEVICE]$type = 0
$d1.GetDeviceType([ref]$type)
```

## GetDriverVersion

**Purpose:** Gets the driver version

```powershell
[uint32]$ver = 0
$d1.GetDriverVersion([ref]$ver)
```

## GetLatency

**Purpose:** Gets current latency timer value

```powershell
[byte]$lat = 0
$d1.GetLatency([ref]$lat)
```

## GetLibraryVersion

**Purpose:** Gets the library version

```powershell
[uint32]$libVer = 0
$d1.GetLibraryVersion([ref]$libVer)
```

## GetLineStatus

**Purpose:** Gets UART line status

```powershell
[byte]$status = 0
$d1.GetLineStatus([ref]$status)
```

## GetModemStatus

**Purpose:** Gets UART modem status

```powershell
[byte]$modem = 0
$d1.GetModemStatus([ref]$modem)
```

## GetRxBytesAvailable

**Purpose:** Gets number of bytes in RX queue

```powershell
[uint32]$rx = 0
$d1.GetRxBytesAvailable([ref]$rx)
```

## GetSerialNumber

**Purpose:** Gets device serial number

```powershell
[string]$sn = ''
$d1.GetSerialNumber([ref]$sn)
```

## GetTxBytesWaiting

**Purpose:** Gets bytes in TX queue

```powershell
[uint32]$tx = 0
$d1.GetTxBytesWaiting([ref]$tx)
```

## GetPinStates

**Purpose:** Reads FTDI pin states

```powershell
[byte]$pins = 0
$d1.GetPinStates([ref]$pins)
```

result of `127` mean 


## InTransferSize

**Purpose:** Sets the USB IN transfer size

```powershell
$d1.InTransferSize(512)
```

## OpenByDescription

**Purpose:** Opens device by description

```powershell
$d1.OpenByDescription("PsGadget-Controller")
```

## OpenByIndex

**Purpose:** Opens device by index

```powershell
$d1.OpenByIndex(0)
```

## OpenByLocation

**Purpose:** Opens device by USB location

```powershell
$d1.OpenByLocation(0)
```

## OpenBySerialNumber

**Purpose:** Opens device by serial number

```powershell
$d1.OpenBySerialNumber("CT9UMHFA")
```

## Purge

**Purpose:** Purges receive/transmit buffers

```powershell
$d1.Purge(3)  # 1=RX, 2=TX, 3=Both
```

## Read

**Purpose:** Reads data from device

```powershell
[byte[]]$buf = New-Object byte[] 64
[uint32]$read = 0
$d1.Read($buf, 64, [ref]$read)
```

## ReadEEPROMLocation

**Purpose:** Reads a specific EEPROM location

```powershell
[uint16]$val = 0
$d1.ReadEEPROMLocation(0, [ref]$val)
```

## ResetDevice

**Purpose:** Resets the device

```powershell
$d1.ResetDevice()
```

## SetBaudRate

**Purpose:** Sets baud rate

```powershell
$d1.SetBaudRate(9600)
```

## SetBitMode

**Purpose:** Sets bit mode (GPIO, MPSSE, etc.)

```powershell
$d1.SetBitMode(0xFF, 0x02)  # 0x02 = MPSSE
```

## SetBreak

**Purpose:** Enables/disables break condition

```powershell
$d1.SetBreak($true)
```

## SetCharacters

**Purpose:** Sets special UART characters

```powershell
$d1.SetCharacters(13, $true, 10, $true)
```

## SetDataCharacteristics

**Purpose:** Sets UART format

```powershell
$d1.SetDataCharacteristics(8, 1, 0)  # 8N1
```

## SetDTR

**Purpose:** Enables or disables DTR

```powershell
$d1.SetDTR($true)
```

## SetRTS

**Purpose:** Enables or disables RTS

```powershell
$d1.SetRTS($true)
```

## SetTimeouts

**Purpose:** Sets read/write timeouts

```powershell
$d1.SetTimeouts(5000, 5000)
```

## StopInTask

**Purpose:** Stops async USB tasks

```powershell
$d1.StopInTask()
```

## Write

**Purpose:** Writes data to device

```powershell
[byte[]]$buf = [byte[]](0x82, 0xF8, 0x07)
[uint32]$written = 0
$d1.Write($buf, $buf.Length, [ref]$written)
```

## WriteEEPROMLocation

**Purpose:** Writes to a specific EEPROM address

```powershell
$d1.WriteEEPROMLocation(0, 1234)
```

## WriteFT2232EEPROM

**Purpose:** Writes FT2232 EEPROM structure

```powershell
$ee = New-Object FTD2XX_NET.FTDI+FT2232_EEPROM_STRUCTURE
$d1.WriteFT2232EEPROM($ee)
```

## WriteFT2232HEEPROM

**Purpose:** Writes FT2232H EEPROM structure

```powershell
$ee = New-Object FTD2XX_NET.FTDI+FT2232H_EEPROM_STRUCTURE
$d1.WriteFT2232HEEPROM($ee)
```

## WriteFT232BEEPROM

**Purpose:** Writes FT232B EEPROM structure

```powershell
$ee = New-Object FTD2XX_NET.FTDI+FT232B_EEPROM_STRUCTURE
$d1.WriteFT232BEEPROM($ee)
```

## WriteFT232HEEPROM

**Purpose:** Writes FT232H EEPROM structure

```powershell
$ee = New-Object FTD2XX_NET.FTDI+FT232H_EEPROM_STRUCTURE
$d1.WriteFT232HEEPROM($ee)
```

## WriteFT232REEPROM

**Purpose:** Writes FT232R EEPROM structure

```powershell
$ee = New-Object FTD2XX_NET.FTDI+FT232R_EEPROM_STRUCTURE
$d1.WriteFT232REEPROM($ee)
```

## WriteFT4232HEEPROM

**Purpose:** Writes FT4232H EEPROM structure

```powershell
$ee = New-Object FTD2XX_NET.FTDI+FT4232H_EEPROM_STRUCTURE
$d1.WriteFT4232HEEPROM($ee)
```

## WriteXSeriesEEPROM

**Purpose:** Writes XSeries EEPROM structure

```powershell
$ee = New-Object FTD2XX_NET.FTDI+FT_XSERIES_EEPROM_STRUCTURE
$d1.WriteXSeriesEEPROM($ee)
```

## IsOpen

**Purpose:** Indicates if the device is open

```powershell
$d1.IsOpen
```
