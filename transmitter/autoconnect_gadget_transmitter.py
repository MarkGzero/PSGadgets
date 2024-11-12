# TRANSMITTER CODE
# Dynamic Peer (Controller) Detection and Communication using ESP-NOW

import network
import espnow
import ubinascii
import time
import esp32
import uos
import urandom
import machine
import neopixel

# Constants and Initialization
PSGADGET_TYPE = "PsGadget-IO"  # simple input-output device
CTSSID = "PsGadget-CT"
RECEIVER_CHECK_INTERVAL = 1  # Interval to check for receiver in seconds
MESSAGE_SEND_INTERVAL = 5    # Interval to send messages to receiver in seconds

# Retrieve ESP32 details
MACHINE_TYPE = uos.uname().machine
SERIAL_NUMBER = ubinascii.hexlify(machine.unique_id()).decode()
print("Machine Type:", MACHINE_TYPE)
print("Serial Number:", SERIAL_NUMBER)

# Set up NeoPixel
power_pin = machine.Pin(38, machine.Pin.OUT)
power_pin.value(1)  # Enable power to the NeoPixel
np = neopixel.NeoPixel(machine.Pin(39), 1)

# Initialize Wi-Fi and ESP-NOW
wlan = network.WLAN(network.STA_IF)
wlan.active(True)
esp_now = espnow.ESPNow()
esp_now.active(True)

# Global variables
receiver_mac = None
message_received = False

# ESP-NOW Callback
def espnow_callback(_):
    global message_received
    message_received = True  # Set flag when any message is received

# Utility Functions
def random_neopixel_color():
    """Generate a random RGB color."""
    return (urandom.getrandbits(8), urandom.getrandbits(8), urandom.getrandbits(8))

def blink(color, delay=0.5):
    """Blink the NeoPixel with the given color."""
    np[0] = color
    np.write()
    time.sleep(delay)
    np[0] = (0, 0, 0)  # Turn off
    np.write()
    time.sleep(delay)

def battery_status():
    """Placeholder for battery status, returns a fixed value."""
    return "99"

def send_message():
    """Send a randomized message to the receiver."""
    try:
        cputemp = esp32.mcu_temperature()
        battery = battery_status()
        neopixel_color = random_neopixel_color()
        
        # Construct the message
        message = f"{PSGADGET_TYPE}|{SERIAL_NUMBER}|{MACHINE_TYPE}|{cputemp}|{battery}|rgb{neopixel_color}"
        esp_now.send(receiver_mac, message.encode('utf-8'))
        
        # Blink to indicate message sent
        blink(neopixel_color)
        print("Message sent:", message)
    except Exception as e:
        print(f"Failed to send message: {e}")

# Register ESP-NOW callback
esp_now.irq(espnow_callback)

# Receiver Detection Loop
print("Listening for receiver broadcasts...")
while receiver_mac is None:
    if message_received:
        message_received = False
        try:
            # Attempt to receive message from ESP-NOW
            mac, ssid = esp_now.recv()
            mac_address = ubinascii.hexlify(mac, ":").decode()
            
            # Verify SSID
            if CTSSID in ssid:
                receiver_mac = mac
                esp_now.add_peer(receiver_mac)
                print(f"Receiver found: {mac_address} with SSID '{ssid}'")
                print("Receiver added as a peer for communication.")
        except Exception as e:
            print("Failed to process broadcast message:", e)
    time.sleep(RECEIVER_CHECK_INTERVAL)

# Main Messaging Loop
print("Transmitter is now actively sending messages to the receiver.")
while True:
    send_message()
    time.sleep(MESSAGE_SEND_INTERVAL)
