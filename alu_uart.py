import serial
import time
import binascii
import math
import random
import string

def num_to_hex_frames(num):
    """ Convert a given number to hex data frames to be send to the FPGA over UART. """
    hex_num = hex(num)[2:].zfill(8)
    return "".join([hex_num[6:8], hex_num[4:6], hex_num[2:4], hex_num[0:2]])

def hex_frames_to_num(hex_frames):
    """ Convert hex data frames to number. """
    return "".join([hex_frames[6:8], hex_frames[4:6], hex_frames[2:4], hex_frames[0:2]])

def send_to_fpga(opcode, data):
    """ Send the given message to the FPGA board through COM and return the message received. """
    length = 4 + len(data) // 2
    len_lsb = hex(length % 256)[2:].zfill(2)
    len_msb = hex(length >> 8)[2:].zfill(2)
    hex_message = "{}00{}{}{}".format(opcode, len_lsb, len_msb, data)
    serial_port = '/dev/tty.usbserial-ibqDCLa91'  # Change as per your system
    baud_rate = 115200  # Set this to the baud rate configured on the FPGA
    try:
        ser = serial.Serial(serial_port, baud_rate, timeout=1)
        # Send data to FPGA
        transmit = bytes.fromhex(hex_message)
        #print("Sent: {}".format(transmit))
        ser.write(transmit)
        # Read response from FPGA
        time.sleep(0.1)  # Wait for the FPGA to respond
        if ser.in_waiting > 0:
            response = ser.read(ser.in_waiting)
            #print("Received: {}".format(response))
        # Close the serial port
        ser.close()
        return response
    except serial.SerialException as e:
        print(f"Error: {e}")

def echo(message):
    """ Send the message to the FPGA and expect to receive the same message back. """
    response = send_to_fpga(opcode="EC", data=message.encode().hex())
    if response.decode().strip() == message.strip():
        return True
    else:
        print("FAIL! Received {} instead of {}".format(response, message))
        return False

def add(*operands):
    """ Send the operands to the FPGA and expect to receive the sum of them back. """
    data = [num_to_hex_frames(x) for x in operands]
    response = send_to_fpga(opcode="AD", data="".join(data))
    result = hex_frames_to_num(response.hex())
    if int(result, 16) == sum(operands):
        return True
    else:
        return False

def multiply(*operands):
    """ Send the operands to the FPGA and expect to receive the product of them back. """
    data = [num_to_hex_frames(x) for x in operands]
    response = send_to_fpga(opcode="CA", data="".join(data))
    result = hex_frames_to_num(response.hex())
    if int(result, 16) == math.prod(operands):
        return True
    else:
        print("FAIL! Received {} instead of {}".format(int(result, 16), math.prod(operands)))
        return False

def divide(dividend, divisor):
    """ Send the operands to the FPGA and expect to receive the division of them back. """
    data = [num_to_hex_frames(x) for x in [dividend, divisor]]
    response = send_to_fpga(opcode="DE", data="".join(data))
    result_a = hex_frames_to_num(response.hex()[:8])
    result_b = hex_frames_to_num(response.hex()[8:])
    if int(result_a, 16) == dividend // divisor and int(result_b, 16) == dividend % divisor:
        return True
    else:
        print("FAIL! Received {}, {} instead of {}, {}".format(int(result_a, 16), int(result_b, 16), dividend // divisor, dividend % divisor))
        return False


if __name__ == "__main__":
    print("Running 1000 random 'echo' operations ... ", end="", flush=True)
    for _ in range(1000):
        message_len = random.randrange(start=5, stop=50)
        message = "".join(random.choice(string.ascii_letters + string.digits) for _ in range(message_len))
        if not echo(message):
            print("FAIL!")
            break
    else:
        print("PASS")
    print("Running 1000 random 'add' operations ... ", end="", flush=True)
    for _ in range(1000):
        num_ops = random.randrange(start=2, stop=10)
        ops = [random.randrange(start=0, stop=1000) for _ in range(num_ops)]
        if not add(*ops):
            print("FAIL!")
            break
    else:
        print("PASS")
    print("Running 1000 random 'multiply' operations ... ", end="", flush=True)
    for _ in range(1000):
        message_len = random.randrange(start=2, stop=5)
        ops = [random.randrange(start=0, stop=10) for _ in range(num_ops)]
        if not multiply(*ops):
            print("FAIL!")
            break
    else:
        print("PASS")
    print("Running 1000 random 'divide' operations ... ", end="", flush=True)
    for _ in range(1000):
        ops = [random.randrange(start=2, stop=10000) for _ in range(2)]
        if not divide(*ops):
            print("FAIL!")
            break
    else:
        print("PASS")
