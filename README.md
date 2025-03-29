# LeNet-5 Hardware Accelerator

This repository contains all code and evaluation results for a hardware accelerated LeNet-5 architecture that was developed over the course of the project "RADL" at FAU (Friedrich-Alexander University Erlangen-Nuremberg).

This repository is structured as follows:

```bash
├── data                            # Contains data for test benches (e.g. intermediate results of LeNet-5)
├── LeNet-Accelerator               # The main Vivado Project used to test and integrate the hardware accelerator (includes the files from sim_1 and sources_1)
├── measurements                    # Evaluation data and helper scripts
├── reference
│   ├── simulation                  # The reference implementation of the LeNet-5 architecture
│   └── training                    # Scripts and data used to train the quantized LeNet-5 model
├── sim_1                           # VHDL test benches
├── sources_1                       # VHDL main sources for the hardware accelerator
└── SW-Integration
    ├── Vitis                       # Main Vitis project
    │   ├── app_accelerated         # Vitis project to benchmark the integrated hardware accelerator
    │   ├── app_accumulator         # Vitis project to test and run the benchmark of the integrated accumulator (unit for testing AXI-related stuff)
    │   ├── app_baseline            # Vitis project to benchmark the ported reference implementation (CPU only)
    │   ├── app_test
    │   ├── data                    # Image and layer data used in app_accelerated, app_baseline
    │   ├── platform_accelerated    # Platform that includes the LeNet-5 accelerator
    │   └── platform_accumulator    # Platform that includes the hardware accumulator (unit for testing AXI-related stuff)
    └── Vivado                      # Vivado project used to develop the hardware accumulator
```

## Performance Benchmarks

1. To run performance benchmarks for the [baseline](SW-Integration/Vitis/app_baseline/) (ported reference implementation), the [accumulator](SW-Integration/Vitis/app_accumulator/) and the [LeNet-5 hardware accelerator](SW-Integration/Vitis/app_accelerated/) open the corresponding Vitis project.
2. *Optional*: If you do want use the Ultra-96 v2 create a corresponding Vitis platform from the generated XSA files: [File for the accumulator](SW-Integration/Vivado/main_design_wrapper.xsa), [file for the LeNet-5 accelerator](LeNet-Accelerator/lenet_accel_main_wrapper.xsa). Now select the new platform for the app you want to run. **Note**: Make sure that stdout is mapped to the right output interface (e.g. for Ultra96-v2 you needed to select UART1 instead of UART0).
3. Power on the FPGA and connect it via UART/JTAG.
4. *Optional*: If you want to capture the latencies of the benchmark, just run `cd measurements && python record_output.py`. This will connect to the serial output of `/dev/ttyUSB1` at baud rate `115200` and put all measured latency in a json file. With this script you can still see the output as if you were connected with e.g. `minicom`, `picocom`, `putty`, etc.
5. Build the application and flash the device. **Note**: This can take some time as the binary includes all 10,000 images and 10,000 image labels (which is pretty big). *So, have some patience and grab yourself a cup of coffee in the mean time :)*

## Reference Implementation

### Requirements

- C++ 23
- CMake 3.20.0
- Protobuf (tested with version *3.21.12-9ubuntu1*, probably usable with older versions as well)
  - For Ubuntu: `sudo apt install protobuf-compiler` (this should also automatically install `libprotobuf`/`libprotobuf-dev`)

### Building & Running

```bash
mkdir build
cd build
cmake ..
make
./simulation
```

### Targets

The executable binary targets are:

- `benchmark_datatypes`: Run the accuracy benchmark for all combinations of different datatypes
- `npy_converter`: Pre-process and convert images from numpy format into binary format. This will already pre-process the images by applying the right datatype (e.g. quantization)
- `onnx_converter`: Pre-process, convert and serialize the layer data stored inside an onnx file into the format used by the software implementation. This will automatically convert weights into the right data format (e.g. by applying quantization) and will pre-determine all layers.
- `simulation`: The software reference simulation for desktop.
- `tests`: Custom tests. Only used for... testing :)
- `test_serialize`: Test that serializing the layers works as excepted.
