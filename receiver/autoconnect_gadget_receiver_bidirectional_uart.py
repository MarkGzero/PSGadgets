import network
import espnow
import ubinascii
import time
import uasyncio as asyncio  # For async support
from machine import Pin, UART
import neopixel

# Constants
CTSSID = "PsGadget-CT"
MACFILE = "known_devices.txt"
BROADCAST_MAC = b'\xFF\xFF\xFF\xFF\xFF\xFF'

# Initialize UART, NeoPixel, and Wi-Fi in station mode
uart = UART(1, baudrate=9600, tx=Pin(5), rx=Pin(6))
wlan = network.WLAN(network.STA_IF)
wlan.active(True)
esp_now = espnow.ESPNow()
esp_now.active(True)
np = neopixel.NeoPixel(Pin(21, Pin.OUT), 1)

# Ensure LED is off at the start
np[0] = (0, 0, 0)
np.write()

# Add the broadcast MAC address as a peer
try:
    esp_now.add_peer(BROADCAST_MAC)
except Exception as e:
    print("Failed to add broadcast peer:", e)

# Function to broadcast message periodically
async def broadcast_task():
    while True:
        try:
            mac = ubinascii.hexlify(wlan.config("mac"), ":").decode()
            message = f"{mac}:{wlan.config('essid') or CTSSID}"
            esp_now.send(BROADCAST_MAC, message.encode('utf-8'))
        except Exception as e:
            print("Failed to send broadcast message:", e)
        await asyncio.sleep(5)

# Function to handle UART receiving
async def uart_receive_task():
    while True:
        if uart.any():  # Check if data is available on UART
            message = uart.readline().decode('utf-8').strip()
            print(f"Received over UART: {message}")
            if message == "status":
                # Respond with some status if requested
                uart.write("ESP32 status: Active\n")
            # Handle other commands or logic as needed
        await asyncio.sleep(0.1)  # Small delay to prevent busy waiting

# Function to send message over UART
async def uart_send_task(message):
    try:
        uart.write(message + "\n")
    except Exception as e:
        print(f"Failed to send message over UART: {e}")

# Function to handle received ESP-NOW messages
def espnow_callback(_):
    try:
        mac, espnowmsg = esp_now.recv()
        mac_str = ubinascii.hexlify(mac, ":").decode()
        print(f"Received ESP-NOW message from {mac_str}: {espnowmsg}")
        
        message_str = espnowmsg.decode('utf-8').split('|')
        if len(message_str) < 6:
            print("Malformed ESP-NOW message received.")
            return

        gadget_type, serial_number, machine_type, cpu_temperature, battery_status, message = message_str
        print(f"Decoded ESP-NOW message: {message_str}")

        # Send message over UART with a newline to mark the end of the message
        asyncio.create_task(uart_send_task(espnowmsg.decode('utf-8')))

        # Blink LED if RGB message is received
        if message.startswith('rgb'):
            blink_led(message)
            
    except Exception as e:
        print("Failed to process ESP-NOW message:", e)

# Helper function to blink LED
def blink_led(message):
    try:
        rgb_str = message[3:].strip("()")
        rgb = tuple(map(int, rgb_str.split(',')))
        np[0] = rgb
        np.write()
        time.sleep(1)
        np[0] = (0, 0, 0)
        np.write()
    except ValueError:
        print("Invalid RGB format in message.")

# Register callback for ESP-NOW
esp_now.irq(espnow_callback)

# Main function to start tasks
async def main():
    print("Starting UART and ESP-NOW tasks...")
    await asyncio.gather(broadcast_task(), uart_receive_task())

# Run main event loop
try:
    asyncio.run(main())
except KeyboardInterrupt:
    print("Program interrupted")
