# RECEIVER CODE - Continuous Broadcast and Message Reception
import network
import espnow
import ubinascii
import time
from machine import Pin, UART
import neopixel
import uos

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

# Helper functions
def current_datetime():
    dt = time.localtime()
    return "{:02d}{:02d}{:02d}T{:02d}{:02d}{:02d}".format(*dt[:6])

def read_known_devices():
    devices = {}
    try:
        with open(MACFILE, "r") as f:
            for line in f:
                parts = line.strip().split('|')
                if len(parts) == 2:  # Only process lines with exactly two parts
                    mac, timestamp = parts
                    devices[mac] = timestamp
                else:
                    print(f"Skipping malformed line in {MACFILE}: {line.strip()}")
    except OSError:
        print(f"Could not open {MACFILE}. It may not exist yet.")
    return devices

def write_known_devices(devices):
    with open(MACFILE, "w") as f:
        for mac, timestamp in devices.items():
            f.write(f"{mac}|{timestamp}\n")

def update_known_device(mac_address):
    devices = read_known_devices()
    new_device = mac_address not in devices
    devices[mac_address] = current_datetime()
    write_known_devices(devices)
    print(f"Device {'added' if new_device else 'updated'} in known devices.")

def send_message_to_ft232h(message):
    try:
        uart.write(message)
    except Exception as e:
        print(f"UART message sending failed: {e}")

def broadcast_message():
    try:
        mac = ubinascii.hexlify(wlan.config("mac"), ":").decode()
        message = f"{mac}:{wlan.config('essid') or CTSSID}"
        esp_now.send(BROADCAST_MAC, message.encode('utf-8'))
    except Exception as e:
        print("Failed to send broadcast message:", e)

def blink_led(message):
    try:
        # Extract RGB values from message
        # Example message: rgb(0,0,0)
        rgb_str = message[3:-1]
        # remove parentheses
        rgb_str = rgb_str.replace('(', '').replace(')', '')
        rgb = tuple(map(int, rgb_str.split(',')))
        print(f"Blinking LED with RGB: {rgb}")
        np[0] = rgb
        np.write()
        time.sleep(1)
        np[0] = (0, 0, 0)
        np.write()
    except ValueError:
        print("Invalid RGB format in message.")

# Callback to handle received messages from the transmitter
def espnow_callback(_):
    try:
        mac, espnowmsg = esp_now.recv()
        mac_str = ubinascii.hexlify(mac, ":").decode()
        print(f"Received message from {mac_str}: {espnowmsg}")
        
        # Decode message and parse components
        message_str = espnowmsg.decode('utf-8').split('|')
        if len(message_str) < 6:
            print("Malformed message received.")
            return

        gadget_type, serial_number, machine_type, cpu_temperature, battery_status, message = message_str
        print(f"Decoded message: {message_str}")
        
        # Add special character to indicate end of message
        espnowmsg += b'\n'
        # Send message to FT232H
        send_message_to_ft232h(espnowmsg)

        # Update or add device in known_devices.txt
        update_known_device(mac_str)

        # Blink LED if RGB message is received
        if message.startswith('rgb'):
            blink_led(message)
            
    except Exception as e:
        print("Failed to process message:", e)

# Register callback for ESP-NOW
esp_now.irq(espnow_callback)

# Main loop to broadcast and wait for incoming messages
print("Receiver is active, broadcasting and waiting for messages...")
while True:
    broadcast_message()
    time.sleep(5)
