#!/usr/bin/env python3
"""
Assembler program for I2C Custom Soft Core.
This script will read in an assembly file and generate output to be included in FPGA RAM configuration to execute the
program on the I2C soft core MCU.
"""
__author__ = "Daniel Casner <www.danielcasner.org>"

import sys, os

try:
    import bitarray
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

def evalArg(arg, ub, err):
    "Attempts to evaluate a string argument to a value, checks the upper and lower bounds and prints an error if nessisary"
    try:
        val = eval(arg)
        assert val >= 0 and val < up
    except:
        sys.exit(err.format(arg))
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

# Each instruction is reppresented in the python script as a function which accepts arguments and returns the
# instruction bytes.

def noop(args):
    return 0, 0

def reset(args):
    return 0, 1

def halt(args):
    return 0, 2

def rtrn(args):
    return 0, 3

def regwr(args):
    reg = evalReg(args[0])
    val = evalVal(args[1])
    return ()

def stop(args):
    return 0, 4
