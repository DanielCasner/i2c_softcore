# Custom Softcore Demo
This project demonstrates how a simple, custom soft core can be used to more easily interface with digital sensors than a traditional state machine implementation.

## Example sensor
For this demo we use the [Linear Technology](http://www.linear.com) [LCT2991](http://www.linear.com/product/LTC2991) I2C voltage / current / temperature sensor. Because the LTC2991 has internal configuration and it's own state machine and a number of registers which need to be set, read and switched on, it makes a good test case for the complexity of interacting with digital sensors.

## Softcore
We implement a custom softcore "microcontroller" with an instruction set optimized specifically for communicating with an I2C sensor. We also create an assembly language and compiler for this processor in which we program it to operate the sensor. The MCU can operate from an embedded RAM or flash on the FPGA can be reprogrammed without resynthesizing the FPGA.
