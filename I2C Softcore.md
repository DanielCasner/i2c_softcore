#I2C Digital Sensor Softcore Documentation

The I2C digital sensor softcore operates on 16 bit instructions selected specifically to efficiently implement the task of controlling a digital sensor over the I2C bus. Instructions can contain a combination of program and data and may not all be one cycle execution.

| Instruction          		  | Assembly | Parameters                   | Binary                  |
|---------------------------------|----------|------------------------------|-------------------------|
| No operation			  | noop     | None                         | {0x0000}                |
| Reset                	 	  | reset    | None                         | {0x0001}                |
| Halt                 	 	  | halt     | None                         | {0x0002}                |
| Write to internal register      | regwr    | register[1:0], value[11:0]   | {0x1, reg, val}         |
| Write to output                 | outwr    | output[3:0], value[7:0]      | {0x2, out, val}         |
| Jump if equal                   | jieq     | register[1:0], value[11:0]   | {0x3, reg, val}         |
| Jump if not equal               | jine     | register[1:0], value[11:0]   | {0x4, reg, val}         |
| Conditional jump and decriment  | jdec     | register[1:0], pointer[11:0] | {0x5, reg, ptr}         |
| I2C start            		  | start    | i2c address[10:0]            | {0x6, 0b0, addr}        |
| I2C repeated start              | rstrt    | None                         | {0x6, 0b1, addr}        |
| I2C write constant   		  | wrc      | value[7:0], ACK              | {0x7, 0b000, val, ack}  |
| I2C write register   		  | wrr      | register[1:0], ACK           | {0x720, 0b0, reg, ack}  |
| I2C read to output 		  | outrd    | output[3:0], ACK             | {0x80, 0b000, out, ack} |
| I2C read to register            | regrd    | register[1:0], ACK           | {0x800, 0b0, reg, ack}  |
| I2C stop                        | stop     | None                         | {0x0003}                |
