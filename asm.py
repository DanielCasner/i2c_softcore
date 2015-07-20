#!/usr/bin/env python3
"""
Assembler program for I2C Custom Soft Core.
This script will read in an assembly file and generate output to be included in FPGA RAM configuration to execute the
program on the I2C soft core MCU.
"""
__author__ = "Daniel Casner <www.danielcasner.org>"

import sys, os

try:
    from bitarray import bitarray
except:
    sys.exit("""Python module \"bitarray\" couldn't be loaded.
You may want to try installing it by running:
    pip3 install bitarray
""")

## Number of internal MCU registers
NUM_PREG = 4
## Maximum number of output registers
NUM_OUT  = 16
## Maximum value that can go in a register, output, program counter, etc
MAX_VAL  = 255

lineCounter = 0

def evalArg(arg, ub, err):
    "Attempts to evaluate a string argument to a value, checks the upper and lower bounds and prints an error if nessisary"
    try:
        val = eval(arg)
        assert val >= 0 and val < up
    except:
        sys.exit("Line {:d}: {}".format(lineCounter, err.format(arg))
    else:
        return val

def evalReg(arg):
    "Evaluates an argument as a program register"
    return evalArg(arg, NUM_PREG, "Unable to evaluate \"{}\" as a program register index")
def evalOut(arg):
    "Evaluates an argument as an output channel"
    return evalArg(arg, NUM_OUT, "Unable to evaluate \"{}\" as an output channel index")
def evalVal(arg):
    "Evaluates an argument as a value"
    return evalArg(arg, MAX_VAL, "Unable to evaluate \"{}\" as a value")
def evalBool(arg):
    try:
        return bool(eval(arg))
    except:
        sys.exit("Line {:d}: Unable to parse \"{}\" as true / false".format(lineCounter, arg))

# Each instruction is reppresented in the python script as a function which accepts arguments and returns the
# instruction bytes.

def noop(args):
    return 0x0000

def reset(args):
    return 0x0001

def halt(args):
    return 0x0002

def rtrn(args):
    return 0x0003

def regwr(args):
    reg = evalReg(args[0])
    val = evalVal(args[1])
    return 0x1000 | reg << 8 | val

def outwr(args):
    out = evalOut(args[0])
    val = evalVal(args[1])
    return 0x2000 | out << 8 | val

def outrg(args):
    out = evalOut(args[0])
    reg = evalReg(args[1])
    return 0x3000 | out << 2 | reg

def sieq(args):
    reg = evalReg(args[0])
    val = evalVal(args[1])
    return 0x4000 | reg << 8 | val

def sine(args):
    reg = evalReg(args[0])
    val = evalVal(args[1])
    return 0x4400 | reg << 8 | val

def siand(args):
    reg = evalReg(args[0])
    val = evalVal(args[1])
    return 0x4800 | reg << 8 | val

def sior(args):
    reg = evalReg(args[0])
    val = evalVal(args[1])
    return 0x4c00 | reg << 8 | val

def jump(args):
    ptr = evalVal(args[0])
    return 0x5000 | val

def jdec(args):
    reg = evalReg(args[0])
    ptr = evalVal(args[0])
    return 0x6000 | reg << 8 | ptr

def start(args):
    address = evalArg(args[0], 2**10-1, "Unable to evaluate \"{}\" as an I2C address")
    rdNwr   = evalBool(args[1])
    return 0x7000 | address << 1 | readNwr

def wrc(args):
    val = evalVal(args[0])
    return 0x8000 | val

def wrr(args):
    reg = evalReg(args[0])
    return 0x8100 | reg

def outrd(args):
    out = evalOut(args[0])
    ack = evalBool(args[1])
    return 0x9000 | out << 1 | ack

def regrd(args):
    reg = evalReg(args[0])
    ack = evalBool(args[1])
    return 0x9100 | reg << 1 | ack

def nakj(args):
    ptr = evalVal(args[0])
    return = 0xA000 | ptr

def stop(args):
    return 0x0004
