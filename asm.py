#!/usr/bin/env python3
"""
Assembler program for I2C Custom Soft Core.
This script will read in an assembly file and generate output to be included in FPGA RAM configuration to execute the
program on the I2C soft core MCU.
"""
__author__ = "Daniel Casner <www.danielcasner.org>"

import sys, os, re

## Number of internal MCU registers
NUM_PREG = 4
## Maximum number of output registers
NUM_OUT  = 16
## Maximum value that can go in a register, output, program counter, etc
MAX_VAL  = 255

## Counts what line of the program we are parsing right now to include in debug output
lineCounter = 0

## Counts the current instruction
instructionCounter = 0

## Stores pointers to labels in the code used for jumps
labels = {}

def evalArg(arg, ub, err):
    "Attempts to evaluate a string argument to a value, checks the upper and lower bounds and prints an error if nessisary"
    try:
        val = int(eval(arg))
        assert val >= 0 and val < ub
    except:
        sys.exit("Line {:d}: {}".format(lineCounter, err.format(arg)))
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
def evalPtr(label):
    "Evaluates a label to generate a pointer"
    if not label in labels:
        sys.exit("Line {:d}: Unknown label \"{}\"".format(lineCounter, label))
    else:
        return labels[label]

# Each instruction is reppresented in the python script as a function which accepts arguments and returns the
# instruction bytes.

class Instructions:
    "A class to contain instructions"
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
        ptr = evalPtr(args[0])
        return 0x5000 | ptr

    def jdec(args):
        reg = evalReg(args[0])
        ptr = evalPtr(args[0])
        return 0x6000 | reg << 8 | ptr

    def start(args):
        address = evalArg(args[0], 2**10-1, "Unable to evaluate \"{}\" as an I2C address")
        rdNwr   = evalBool(args[1])
        return 0x7000 | address << 1 | rdNwr

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
        ptr = evalPtr(args[0])
        return 0xA000 | ptr

    def stop(args):
        return 0x0004

instNames = [i for i in dir(Instructions) if not i.startswith("_")]

def parseLine(line, labelMode=False):
    "Parses one line of the program file"
    global lineCounter
    global instructionCounter
    lineCounter += 1
    code, *comment = line.split(";")
    if not code: # Comment only line
        return None
    elif re.match("^[a-zA-Z0-9_-]+:", code): # A label line
        labels[line.split(':')[0]] = instructionCounter
        return None
    elif not labelMode:
        inst, *args = code.split()
        if not inst in instNames:
            sys.exit("Line {:d}: Unknown instruction \"{}\"".format(lineCounter, inst))
        else:
            instructionCounter += 1
            return eval("Instructions.{}(args)".format(inst))

def parseFile(asmFile):
    "Parses the file and returns the program"
    global lineCounter
    global instructionCounter
    fh = open(asmFile, 'r')
    lines = fh.readlines()
    lineCounter = 0
    instructionCounter = 0
    for l in lines: parseLine(l, True) # Take a first pass to initalize the label
    lineCounter = 0
    instructionCounter = 0
    program = [i for i in [parseLine(l) for l in lines] if i is not None]
    return program

def writeBareHex(program, hexFile):
    "Writes out a hex file suitable for examining manually"
    fh = open(hexFile, 'w')
    for inst in program:
        fh.write("{:02x} {:02x}\r\n".format(inst >> 8, inst & 0xff))

def writeLatticeHex(program, hexFile):
    "Writes out a hex file suitable for inclusion in a lattice program"
    pass

if __name__ == '__main__':
    asmFile = sys.argv[1]
    basefn, ext = os.path.splitext(asmFile)
    hexFile = basefn + '.hex'
    writeBareHex(parseFile(asmFile), hexFile)
