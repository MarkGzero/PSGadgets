# Receiver 
import network
import espnow
import ubinascii
import machine
from machine import Pin, UART
import time
import neopixel
import uos

# Get machine type for reference
machinetype = uos.uname().machine

# WS2812 LED Setup
# Define NeoPixel LED on pin 21
pin = Pin(21, Pin.OUT)
np = neopixel.NeoPixel(pin, 1)

# Ensure LED is off at the start
np[0] = (0, 0, 0)
np.write()

# Initialize UART with specified parameters
# FT232H TX is D0 which connects to the RX pin of ESP32-S3 (Pin 6)
# FT232H RX is D1 which connects to the TX pin of ESP32-S3 (Pin 5)
uart = UART(1, baudrate=9600, tx=Pin(6), rx=Pin(5))

def send_message_to_ft232h(message):
    """Send a message to the FT232H via UART."""
    try:
        print("Sending message to FT232H via UART:", message)  # Debug print
        uart.write(message + b'\n')  # Send the message over UART, adding newline for end of message
        print("Message sent successfully.")
    except Exception as e:
        print(f"UART message sending failed: {type(e).__name__} - {e}")

# Flash LED with specified color and duration
def flash_led(color, duration=0.5):
    """
    Flash the NeoPixel LED a specified color.
    :param color: Tuple with RGB values, e.g., (0, 0, 20) for blue
    :param duration: Duration of the flash in seconds
    """
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

# Define a callback function for receiving messages
def espnow_callback(_):
    try:
        mac, msg = esp_now.irecv()  # Get the received message
        if mac:
            flash_led((0, 0, 20))  # Flash blue for message received
            mac_str = ubinascii.hexlify(mac, ":").decode()
            msg_str = msg.decode('utf-8') if msg else "No message content"
            print(" ")
            print(f"Message received from {mac_str}: {msg_str}")
            print(" ")
            # Send message back to the FT232H via UART
            send_message_to_ft232h(msg_str.encode('utf-8'))
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
        flash_led((0, 50, 0), duration=0.1)  # Short green flash for readiness
        time.sleep(5)  # Check LED every 5 seconds
except KeyboardInterrupt:
    print("Program stopped by user.")
    np[0] = (0, 0, 0)  # Ensure LED is off on exit
    np.write()
