#I2C Digital Sensor Softcore Documentation

The I2C digital sensor softcore operates on 16 bit instructions selected specifically to efficiently implement the task of controlling a digital sensor over the I2C bus. Instructions can contain a combination of program and data and may not all be one cycle execution.

| Instruction          		        | Assembly | Parameters                   | Binary                  |
|---------------------------------|----------|------------------------------|-------------------------|
| No operation			              | noop     | None                         | {0x0000}                |
| Reset                     	 	  | reset    | None                         | {0x0001}                |
| Halt                 	 	        | halt     | None                         | {0x0002}                |
| Return                          | rtrn     | None                         | {0x0003}                |
| Write to internal register      | regwr    | register[1:0], value[7:0]    | {0x1, 0b00, reg, val}   |
| Write to output                 | outwr    | output[3:0], value[7:0]      | {0x2, out, val}         |
| Copy register to output         | outrg    | output[3:0], register[1:0]   | {0x30, 0b00, out, reg}  |
| Skip next instruction if equal  | sieq     | register[1:0], value[7:0]    | {0x4, 0b00, reg, val}   |
| Skip next inst if not equal     | sine     | register[1:0], value[7:0]    | {0x4, 0b01, reg, val}   |
| Skip next inst if reg and val   | siand    | register[1:0], value[7:0]    | {0x4, 0b10, reg, val}   |
| Skip next inst if reg or val    | sior     | register[1:0], value[7:0]    | {0x4, 0b11, reg, val}   |
| Jump                            | jump     | pointer[7:0]                 | {0x50, pointer}         |
| Jump if not zero and decriment  | jdec     | register[1:0], pointer[7:0]  | {0x6, 0b00, reg, ptr}   |
| I2C start            		        | start    | i2c address[10:0]            | {0x7, 0b0, addr}        |
| I2C repeated start              | rstrt    | None                         | {0x7800}                |
| I2C write constant   		        | wrc      | value[7:0], ACK              | {0x8, 0b000, val, ack}  |
| I2C write register   		        | wrr      | register[1:0], ACK           | {0x820, 0b0, reg, ack}  |
| I2C read to output 		          | outrd    | output[3:0], ACK             | {0x90, 0b000, out, ack} |
| I2C read to register            | regrd    | register[1:0], ACK           | {0x980, 0b0, reg, ack}  |
| I2C stop                        | stop     | None                         | {0x0004}                |
