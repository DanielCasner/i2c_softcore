;; Assembly program for custom soft core i2c controller to communicate with an LTC2991 sensor
; This program will be assembled by asm.py and the resulting hex file can be included in RAM block initalization for the
; FPGA project or the data can be written in later by some other mechanism.
; @author Daniel Casner <www.danielcasner.org>
start:
stop              ; Always begin with a stop to make sure the state is known
start 0b1001000 0 ; Start writing
wrc   0x06        ; Starting at address 0x06
nakj  start       ; If we get a nack, restart
wrc   0b01010101  ; Address 0x06: All filters disabled, all temperatures in K, all configured for differential voltage
wrc   0b01010101  ; Address 0x07: All filters disabled, all temperatures in K, all configured for differential voltage
wrc   0b00010100  ; Address 0x08: PWM disabled internal temperature in K with no filter
nakj  start       ; If we get a nack, restart
stop
start 0b1001000 0 ; Start writting
wrc   0x01        ; Starting at address 0x01
wrc   0b11111000  ; Enable all channels
nakj  start       ; Restart if we get nacked
stop
loop:             ; Program main loop
start 0b1001000 0 ; Start writing
wrc   0x00        ; At address 0
start 0b1001000 1 ; Switch to Reading
regrd 0 1         ; Read remote register 0 into our register 0
regrd 1 0         ; Read remote register 1 into our register 1 and NAK
stop
check_status:
sieq  0x00 0x00   ; Skip if all 0
jump  read        ; Go read all the data
jump  loop        ; Loop
read:
start 0b1001000 0 ; Start writing
wrc   0x0A        ; Starting at address 0x0A
start 0b1001000 1 ; Switch to Reading
outrd 0  1        ; Read to output 0x4
regrd 3  1
outrd 1  1
regrd 3  1
outrd 2  1
regrd 3  1
outrd 4  1
regrd 3  1
outrd 5  1
regrd 3  1
outrd 6  1
regrd 3  1
outrd 7  1
regrd 3  1
outrd 8  1
regrd 3  1
outrd 9  1
regrd 3  1
outrd 10 1
regrd 3  0
stop
rtrn
