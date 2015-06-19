#I2C Digital Sensor Softcore Documentation

The I2C digital sensor softcore operates on 16 bit instructions selected specifically to efficiently implement the task of controlling a digital sensor over the I2C bus. Instructions can contain a combination of program and data and may not all be one cycle execution.

| Instruction        | Assembly | Parameters                | Binary |
|--------------------|----------|---------------------------|--------|
| No operation       | noop     | None                      | 0x0000 |
| Reset              | reset    | None                      |        |
| Halt               | halt     | None                      |        |
| Write to register  | regwr    | register[1:0], value[7:0] |        |
| I2C start          | start    | address[10:0]             |        |
| I2C write constant | wrc      | value[7:0], ACK           |        |
| I2C write register | wrr      | register[1:0], ACK        |        |
| I2C read
