
# Working with ESP32 and MicroPython

## ESP32

The ESP32 is a low-cost, low-power system on a chip microcontroller with integrated Wi-Fi and dual-mode Bluetooth. 



| **Feature**               | **AiTek ESP-WROOM-32** | **Qt Py ESP32-S2**          | **WaveShare ESP32-S3-Zero** | **LilyGo ESP32-S3R8 T-Display** |
|---------------------------|-----------------------|-----------------------------|-----------------------------|---------------------------------|
| **Processor**             | ESP32-D0WDQ6 (240MHz) | ESP32-S2 (Single-core, 240MHz) | ESP32-S3 (Dual-core, 240MHz) | ESP32-S3 (Dual-core, 240MHz)    |
| **Memory**                | 520KB SRAM, 4MB Flash | 320KB SRAM, 4MB Flash       | 512KB SRAM, 4MB Flash, 2MB PSRAM | 512KB SRAM, 8MB Flash, 8MB PSRAM |
| **Wireless**              | Wi-Fi, Bluetooth 4.2  | Wi-Fi, No Bluetooth         | Wi-Fi, Bluetooth 5 (LE)     | Wi-Fi, Bluetooth 5 (LE)         |
| **GPIO Pins**             | 30 pins               | 13 pins (compact size)      | 24 pins                     | 24 pins                         |
| **Display**               | None                  | None                        | None                        | 1.9" TFT LCD                    |
| **USB Type**              | USB Type-C             | USB Type-C                  | USB Type-C                  | USB Type-C                      |
| **Best Use Case**         | General IoT, Prototyping | Small form-factor projects | Small form-factor projects | Display-based projects, IoT with visuals |


### Aitek ESP-WROOM-32

The ESP32 is a low-cost, low-power system on a chip microcontroller with integrated Wi-Fi and dual-mode Bluetooth. The ESP32 series employs a Tensilica Xtensa LX6 microprocessor in both dual-core and single-core variations and includes in-built antenna switches, RF balun, power amplifier, low-noise receive amplifier, filters, and power management modules.
https://lastminuteengineers.com/esp32-pinout-reference/
https://lastminuteengineers.com/esp32-wroom-32-pinout-reference/

![wroom32](/images/esp32-wroom32-30pinout.png)

## Waveshare ESP32-S3-Zero

The ESP32-S3-Zero is a low-cost, low-power system on a chip microcontroller with integrated Wi-Fi and Bluetooth. The ESP32-S3-Zero is equipped with a dual-core Xtensa LX7 CPU running at up to 240MHz, 512KB of SRAM, 4MB of Flash memory, and 2MB of PSRAM. The board supports Wi-Fi and Bluetooth connectivity and features a USB Type-C port, 24 GPIO pins, and a 1.9-inch TFT LCD display. It is suitable for small form-factor projects and IoT applications that require a display. For more details, visit Waveshare ESP32-S3-Zero. https://www.waveshare.com/esp32-s3-zero.htm

Wiki https://www.waveshare.com/wiki/ESP32-S3-Zero


![ESP32-S3FH4R2](/images/ESP32-S3FH4R2.png)

![ESP32-S3FH4R2 pinout](/images/waveshare_esp32-zero-pinout.png)

## Adafruit QT Py ESP32-S2 WiFi Dev Board with STEMMA QT

The Adafruit QT Py ESP32-S2 WiFi Dev Board is a small, low-cost development board featuring the ESP32-S2 microcontroller. It has a single-core Xtensa LX7 CPU running at up to 240MHz, 320KB of SRAM, and 4MB of Flash memory. The board supports Wi-Fi connectivity and features a USB Type-C port, STEMMA QT connector, and 13 GPIO pins. It is suitable for small form-factor projects and IoT applications. For more details, visit Adafruit QT Py ESP32-S2 WiFi Dev Board. https://www.adafruit.com/product/5325

https://learn.adafruit.com/adafruit-qt-py-esp32-s2

![QT Py ESP32-S2](/images/qtpy_esp32s2.png)

## Lilygo ESP32-S3 

**Not Beginner-friendly**

The ESP32-S3 is a highly integrated, low-power, 2.4 GHz Wi-Fi SoC solution that is designed to meet the needs of IoT applications. The ESP32-S3 is equipped with a 32-bit RISC-V core that operates up to 240 MHz. The ESP32-S3 is designed for low-power applications and is equipped with a rich set of peripherals, including Wi-Fi, Bluetooth, and a high-speed UART.

https://github.com/Xinyuan-LilyGO/lilygo-micropython

https://github.com/Xinyuan-LilyGO/T-Display-S3?tab=readme-ov-file 

![ESP32-S3R8](/images/lilygo_esp32_s3r8.png)


# Using Thonny

## Thonny allows easy method to install MicroPython on ESP32 board. 

Works for most boards common boards. However, some boards may require using esptool. 

Example: Installing microphython on generic ESP32-S3 board

![thonny](/images/thonny_options.png)

![thonny](/images/thonny_install.png)

# Using esptool

## Erase Flash using esptool

Windows
Chip ESP32-S2
Port COM5

```cmd
esptool.py --chip esp32s2 --port COM5 erase_flash
```
## Installing microphython on ESP32-S3 board with 4mb flash 

ESP32-S3FH4R2 Dual-Core Processor



Reminder: Erase flash first.

Link:
https://micropython.org/download/ESP32_GENERIC_S3/

```cmd
# Windows

# Erase Flash
esptool.py --chip esp32s3 --port COM5 erase_flash

# Install MicroPython
esptool --chip esp32s3 --port COM5 --baud 115200 write_flash -z 0x0 .\ESP32_GENERIC_S3-FLASH_4M-20240602-v1.23.0.bin
```

### Adafruit QT Py ESP32-S2 WiFi Dev Board with STEMMA QT
https://www.adafruit.com/product/5325
**No BLE** 
4 MB Flash & 2 MB PSRAM

Link:
https://micropython.org/download/ESP32_GENERIC_S2/


