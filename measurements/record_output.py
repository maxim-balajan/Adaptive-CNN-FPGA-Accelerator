import serial
import datetime
import os
import numpy as np

# Define the serial port and baud rate
serial_port = '/dev/ttyUSB1'
baud_rate = 115200

# File name for saving data
filename = str(datetime.datetime.now()).replace(":", "-")[:19] + ".csv"
dirname = os.path.join(os.getenv('PRJ_ROOT_PATH'), 'measurements')

# make sure the output directory exists
os.makedirs(dirname, exist_ok=True)

# Initialize the serial connection
ser = serial.Serial(serial_port, baud_rate)

# array for storing all samples
samples = []

try:
    with open(os.path.join(dirname, filename), "w") as file:
        file.write("Layer-Name, Mean, STD\n")
        first_obj = True
        while True:
            # Read a line from the serial port
            try:
                line_data = ser.readline()
                line = line_data.decode().strip()
            except UnicodeDecodeError:
                print("ERROR: could not parse line data " + str(line_data))
                continue

            print(line)

            if line.startswith("[BENCH-NAME]"):
                arg = line[13::]
                file.write(arg + ", ")
                first_obj = False
            elif line.startswith("[BENCH-INFO]"):
                arg = line[13:]

                samples.append(int(arg))

            elif line.startswith("[BENCH-STATUS]"):
                arg = line[15:]
                if arg.startswith("Finished"):
                    # remove outliers
                    samples = np.array(samples, dtype=np.uint64)
                    samples = samples[abs(samples - np.mean(samples)) < 2 * np.std(samples)]
                    # retrieve mean and std
                    file.write(str(float(np.mean(samples, dtype=np.uint64)) / 1e3) + "us, ")
                    file.write(str(float(np.std(samples, dtype=np.uint64)) / 1e3) + "us\n")

                    samples = []
                    first_obj = True
                    continue

# Handle keyboard interrupt to exit cleanly
except KeyboardInterrupt:
    while True:
        i = input("Interrupted. Do you want to keep the output file? (Y/n) ")

        if i == "n":
            # recording got interrupted, delete file
            os.unlink(os.path.join(dirname, filename))
            break

        if i == "y" or i == "":
            break

finally:
    ser.close()

print("Closed serial monitor...")
