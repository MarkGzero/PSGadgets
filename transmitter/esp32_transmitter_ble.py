import network
import espnow
import time
import ubinascii
import urandom
import esp32
import uos
import neopixel
import machine

# TRANSMITTER CODE
# this code is for Adafruit QtPy ESP32-S2
# other boards may require different pin assignments

# Power pin setup (GPIO38)
power_pin = machine.Pin(38, machine.Pin.OUT)
power_pin.value(1)  # Enable power to the NeoPixel

# Initialize NeoPixel on GPIO39
np = neopixel.NeoPixel(machine.Pin(39), 1)

# Initialize the Wi-Fi interface in station mode
wlan = network.WLAN(network.STA_IF)
wlan.active(True)

# Initialize ESP-NOW
esp_now = espnow.ESPNow()
esp_now.active(True)

# Define the MAC address of the receiver (update this with the actual MAC of your ESP32-S3)
mac_rcvr = b'4\xb7\xdaY\xd6 '  # Replace with the MAC address of your receiver
esp_now.add_peer(mac_rcvr)

machinetype = uos.uname().machine
macraw = wlan.config("mac")
mac = ubinascii.hexlify(macraw, ":").decode()

# get current time
def cdt():
    dt = time.localtime()
    # Format date-time with milliseconds
    return "{:02d}{:02d}{:02d}T{:02d}{:02d}{:02d}".format(dt[0], dt[1], dt[2], dt[3], dt[4], dt[5])

# Blink function 
def blink(color, delay=0.5):
    np[0] = color  # Set color
    np.write()     # Update NeoPixel
    time.sleep(delay)
    np[0] = (0, 0, 0)  # Turn off
    np.write()
    time.sleep(delay)
    
# error led blink
def errorblink():
    for i in range(2):
        blink((20, 0, 0), 0.2)
        
def no_receiver():
    for i in range(3):
        blink((20, 20, 0), 0.3)
        
# Function to send a message to the receiver
def send_message(message):
    try:
        esp_now.send(mac_rcvr, message)
        print("Message sent successfully")
        blink((0, 0, 20))  # Blue blink for successful
    except Exception as e:
        errorblink()
        print(f"Failed to send message: {e}")

# Main loop to send messages periodically
while True:
    
    # currenttime
    time = cdt()
    temp = esp32.mcu_temperature()
    # format message with | as delimiter
    message = '{}|{}|{}'.format(cdt, temp, rand)
    send_message(message)
    time.sleep(5)  # Send a message every 5 seconds (adjust as needed)

