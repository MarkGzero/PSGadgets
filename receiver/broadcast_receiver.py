# RECEIVER CODE - Continuous Broadcast and Message Reception
# waveshare esp32-s3
import network
import espnow
import ubinascii
import time
from machine import Pin, UART
import neopixel
import esp32
import uos

# PsGadgets SSID for controller
ctssid = "PsGadget-CT"

# file to store known devices mac addresses
# file should store mac|last connection datetime
macfile = "known_devices.txt"

uart = UART(1, baudrate=9600, tx=Pin(5), rx=Pin(6))

# Broadcast address for ESP-NOW
mac_broadcast = b'\xFF\xFF\xFF\xFF\xFF\xFF'

# Initialize Wi-Fi interface in station mode
wlan = network.WLAN(network.STA_IF)
wlan.active(True)

# Initialize ESP-NOW
esp_now = espnow.ESPNow()
esp_now.active(True)

# init neopixel WS2812 LED Setup
# Define NeoPixel LED on pin 21
nppin = Pin(21, Pin.OUT)
np = neopixel.NeoPixel(nppin, 1)

# Ensure LED is off at the start
np[0] = (0, 0, 0)
np.write()

# Add the broadcast address as a peer
try:
    esp_now.add_peer(mac_broadcast)
except Exception as e:
    print("Failed to add broadcast peer:", e)
    
def send_message_to_ft232h(message):
    try:
        print("Sending message to FT232H via UART:", message)  # Debug print
        uart.write(message + b'\n')  # Send the message over UART, adding newline for end of message
        print("Message sent successfully.")
    except Exception as e:
        print(f"UART message sending failed: {type(e).__name__} - {e}")

# Set up WS2812 LED on pin 21 for visual feedback
nppin = Pin(21, Pin.OUT)
np = neopixel.NeoPixel(nppin, 1)
np[0] = (0, 0, 0)
np.write()

def cdt(): # current date time
    dt = time.localtime()
    return "{:02d}{:02d}{:02d}T{:02d}{:02d}{:02d}".format(dt[0], dt[1], dt[2], dt[3], dt[4], dt[5])

# function to add mac address to known_devices.txt
def add_mac(mac):
    with open(macfile, "a") as f:
        f.write(f"{mac}|{cdt()}\n")
        
# function to check if mac address is in known_devices.txt
def check_mac(mac):
    with open(macfile, "r") as f:
        for line in f:
            if mac in line:
                return True
    return False
    
# Function to broadcast MAC and SSID as a simple string
def broadcast_message():
    try:
        mac_raw = wlan.config("mac")
        mac = ubinascii.hexlify(mac_raw, ":").decode()
        ssid = wlan.config("essid") or ctssid
        message = f"{mac}:{ssid}"
        # print("Broadcasting:", message)
        esp_now.send(mac_broadcast, message.encode('utf-8'))
    except Exception as e:
        print("Failed to send broadcast message:", e)
        
def blink_led(msg):
    if msg.startswith('rgb'):
        rgb = msg.replace('rgb', '') # remove the rgb prefix
        rgb = msg[1:-1] # remove the parenthesis
        rgb = rgb.split(',') # split the rgb values
        r = int(rgb[0])
        g = int(rgb[1])
        b = int(rgb[2])
        np[0] = (r, g, b)
        np.write()
        time.sleep(1)
        np[0] = (0, 0, 0)
        np.write()

# Callback to handle received messages from the transmitter
def espnow_callback(_):  # `_` is used to ignore the event parameter from irq
    try:
        # Receive the message directly from ESP-NOW
        mac, message = esp_now.recv()
        print("Received message from:", ubinascii.hexlify(mac, ":").decode(), "Message:", message)
        
        # Expected message Format/Contents:
        # gadget type | serial number | machine type | cpu temperature | message
        # [0] = gadget type
        # [1] = serial number
        # [2] = machine type
        # [3] = cpu temperature
        # [4] = battery status
        # [5] = message
        
        # Decode and print the received message
        message_decode = message.decode('utf-8')
        print("Decoded message:", message_decode)
        message_str = message_decode.split('|') # split the message
        
        # send msg to FT232H
        send_message_to_ft232h(message_decode)
        
        # check if mac address is in known_devices.txt
        if not check_mac(mac):
            # add mac and current datetime to known_devices.txt
            add_mac(mac)
            print("New device added to known devices.")
        else:
            print("Device already known.")
            # update last connection datetime
            with open(macfile, "r") as f:
                lines = f.readlines()
            with open(macfile, "w") as f:
                for line in lines:
                    if mac in line:
                        f.write(f"{mac}|{cdt()}\n")
                    else:
                        f.write(line)    
        # if msg_string[5] like 'rgb(n,n,n)', blink the led 
        if message_str[5].startswith('rgb'):
            blink_led(message_str[5]) # send the rgb message portion to blink_led function
                    
    except Exception as e:
        print("Failed to process message:", e)

# Register callback for ESP-NOW
esp_now.irq(espnow_callback)

# Main loop to broadcast and wait for incoming messages
print("Receiver is active, broadcasting and waiting for messages...")
while True:
    broadcast_message()
    time.sleep(5)  # Broadcast every 5 seconds

