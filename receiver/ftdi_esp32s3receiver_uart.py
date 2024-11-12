# Receiver 
import network
import espnow
import ubinascii
import machine
from machine import Pin, UART
import time
import neopixel
import uos
import esp32

# Get machine type for reference
machinetype = uos.uname().machine


# WS2812 LED Setup
# Define NeoPixel LED on pin 21
# nppin = Pin(21, Pin.OUT)
# np = neopixel.NeoPixel(nppin, 1)
np = neopixel.NeoPixel(Pin(21,Pin.OUT), 1)

# Ensure LED is off at the start
np[0] = (0, 0, 0)
np.write()


# Initialize UART with specified parameters
# FT232H TX is D0 which connects to the RX pin of ESP32-S3 (Pin 6)
# FT232H RX is D1 which connects to the TX pin of ESP32-S3 (Pin 5)
uart = UART(1, baudrate=9600, tx=Pin(5), rx=Pin(6))

def send_message_to_ft232h(message):
    try:
        print("Sending message to FT232H via UART:", message)  # Debug print
        uart.write(message + b'\n')  # Send the message over UART, adding newline for end of message
        print("Message sent successfully.")
    except Exception as e:
        print(f"UART message sending failed: {type(e).__name__} - {e}")

# Flash LED with specified color and duration
def flash_led(color, duration=0.5):
    np[0] = color
    np.write()
    time.sleep(duration)
    np[0] = (0, 0, 0)  # Turn off LED after flash
    np.write()

# Initialize Wi-Fi in station mode for ESP-NOW
wlan = network.WLAN(network.STA_IF)
wlan.active(True)

# Initialize ESP-NOW for message reception
esp_now = espnow.ESPNow()
esp_now.active(True)

# broadcast mac address to nearby transmitters
mac_broadcast = b'\xff' * 6
esp_now.add_peer(mac_broadcast)

# format message as json
def format_jsonmessage(mac, message):
    # datetime, format as string
    dt = time.localtime()
    cdt = "{:04d}{:02d}{:02d}T{:02d}{:02d}{:02d}".format(dt[0], dt[1], dt[2], dt[3], dt[4], dt[5])
    # accessory esp32
    machinetype = uos.uname().machine
    macraw = wlan.config("mac")
    mac = ubinascii.hexlify(wlan.config("mac"), ":").decode()
    cputemp = esp32.mcu_temperature()
    accessoryJson = '{{"macraw":"{}","mac":"{}","type":"{}","cputemp":{}}}'.format(macraw, mac, machinetype, cputemp)
    # transmitter esp32
    transmitterJson = '{{"mac":"{}","message":"{}"}}'.format(mac, message)
    # json message
    jsonmessage = '{{"datetime":"{}, "accessory":{}, "transmitter":{}}}'.format(cdt, accessoryJson, transmitterJson)
    return jsonmessage

# Define a callback function for receiving messages
def espnow_callback(_):
    try:
        mac, msg = esp_now.irecv()  # Get the received message
        if mac:
            flash_led((0, 0, 20))  # Flash blue for message received
            print("Message received from", ubinascii.hexlify(mac, ":").decode(), ":", msg)
            # get json message
            jsonmsg = format_jsonmessage(mac, msg)
            print("Formatted JSON message:", jsonmsg)
            # send message to FT232H
            send_message_to_ft232h(jsonmsg)
        else:
            print("No message received.")
    except Exception as e:
        flash_led((20, 0, 0))  # Flash red for error
        print(f"Failed to receive or send message: {type(e).__name__} - {e}")

# Register the callback function with ESP-NOW
esp_now.irq(espnow_callback)

# Print device information
print(f"MachineType: {machinetype}")
print("My MAC address is:", ubinascii.hexlify(wlan.config("mac"), ":").decode())

# Main loop to keep the program running and listen for messages
try:
    while True:
        # Flash green briefly to show program is running
        flash_led((0, 50, 0), duration=0.3)  # Short green flash for readiness
        time.sleep(5)  # Check LED every 5 seconds
except KeyboardInterrupt:
    print("Program stopped by user.")
    np[0] = (0, 0, 0)  # Ensure LED is off on exit
    np.write()
