
# Matrix Accelerator for Snickerdoodle

This project aims to provide an IP block for snickerdoodle that can be used to
offload matrix operations from the Cortex-A9 included in the FPGA. This IP
should work on other Zync-7000 boards but will only be tested on snickerdoodle. 

You can read about the snickerdoodle board at [krtkl.com](http://krtkl.com)

## Current Specifications

* Logic is in place to store a single 1024x1024 matrix and read it back but 
I have only tested the first 3 writes and reads.

### To Do
* Specify timing contraints and get a timing report
* Map I/O port and get implementtion to succeed
* Generate 1st bitstream
* Refactor testbench and perform more functional testing
* Added matrices B and C
* Add some multiply-accumulators and crunch some numbers!

## Target Specifications

* Support for matrices up to 1024 x 1024 in size 
    * H.265 uses 32x32, so 1024x1024 is plenty
    * Audio and RF DSP will probably need 1D array - need to research the size  
* 8, 16, 32- bit signed or unsigned integer data supported
* Floating-point support TBD based on available Xilinx IP
* Saturating multiply and multiply-accumulate operations. Other functions TBD. 
* Each matrix has its own read/write register to support parallel data input
* 64-bit data interface for matrix load/store via AXI interface
* Data processed as it arrives at the input register to minimize latency
* Result from operation can be used in next operation without reading and 
  re-writing the data to a new location
* FPGA cell usage TBD

## Software Interface

### Background

You can skip this section if you just want to get something up and running. 

I´ve seen FFT offload engines on commercially available DSPs that are used
roughly like this:

1. Load matrix data into memory-mapped registers or special RAM
2. Specify some operation to perform
3. Wait for interrupt signalling completion. 

The seperated load and execute steps leave data sitting idle in the registers
while the entire load operation completes, adding latency to the overall 
system design. 

In this design, the setup order is modified to allow it to operate on data 
as soon as it becomes available. 

### High-Level Usage

Input matrices are called matrix A and B.  The result is called matrix C.

1. Specify matrix A and B sizes and an operation via control register. 
2. Load data into engine using memory mapped registers for input matrices.    
    * DMA is recommended to completely offload processor core.  
    * Data is processed by the engine as it is received. 
    * Seperate registers are provided for each input matrix, so multi-stream 
      DMA can be used
    * Data must be loaded a complete row at a time, left to right, 
      top-to-bottom.  
3. A few cycles after all the data is received, computation will be complete
   and and interrupt will fire. Read result out of engine from matrix C
   using PIO or DMA. 

### Register Definition

These definitions are subject to change

#### Command

This read/write register configures the engine for a computation.

Field | Bits | Description
---   | ---   | --- 
RSVD0 | 63:60 | Reserved
ARC   | 59:50 | Matrix A row count
RSVD1 | 49:46 | Reserved
ACC   | 45:36 | Matrix A column count
RSVD2 | 35:32 | Reserved
BRC   | 31:22 | Matrix B row count
RSVD3 | 21:18 | Reserved
BCC   | 17:8  | Matrix B column count
DTP   | 7:4 | Data element type - See table
OP    | 3:0 | Operation to perform - See table


DTP Value | Type
--- | --- 
0x0 | 8-bit unsigned data values
0x1 | 16-bit unsigned data values
0x2 | 32-bit unsigned values 
0x3 - 0x7 | Reserved
0x8 | 8-bit signed data values
0x9 | 16-bit signed data values
0xA | 32-bit signed values 
0xB - 0xF | Reserved


OP Value | Description
--- | ---
0x0 | Saturating matrix multiply
0x1 - 0xF | TBD

#### Status 1

Status register 1 can be read to determine the current engine state for 
data input and computation.

Field | Bits | Description
--- | --- | ---
RSVD0 | 63:60 | Reserved
ACR   | 59:50 | Matrix A current row counter
RSVD1 | 49:46 | Reserved
ACC   | 45:36 | Matrix A current column counter
RSVD2 | 35:32 | Reserved
BCR   | 31:22 | Matrix B current row counter
RSVD3 | 21:18 | Reserved
BCC   | 17:8  | Matrix B current column counter
RSVD4 | 7:2 | Reserved
STAT | 1:0 | Engine status

STAT Value | Description
--- | ---
0x0 | Idle
0x1 | Receiving data / operation in progress
0x2 | Calculation complete
0x3 | Error 

#### Status 2

Status register 2 can be read to determine the current engine state during 
a data read-out.

Field | Bits | Description
--- | --- | ---
RSVD0 | 63:60 | Reserved
ACR   | 59:50 | Matrix C current row counter
RSVD1 | 49:46 | Reserved
ACC   | 45:36 | Matrix C current column counter
RSVD2 | 31:0  | Reserved


#### Matrix Data In

One of these registers will be defined for each matrix (A, B, and C.)

Data must be right-justified in the register.  Registers are numbered using 
little-endian convention, so data will be in bit 0 to _n - 1_ for data size 
_n_.

Data must be loaded 1 entry at a time in row-major order. Data from a 1D or
3D C array can be loaded in the order the data appears in memory. Packed data 
formats are not currently supported.

To stop the current operation and re-start the operation, write Status 1.

#### Matrix Data Out

This register allows the program to read the data from any matrix 
(A, B, or C.)

Data must be unloaded 1 entry at a time in row-major order.  Packed data 
formats are not currently supported.


# Design Information

## Challenges

### Matrix Storage

A lot of RAM is required to store 3 1024x1024 matrices with 32-bit values in 
them.  The Zync parts being targeted have 36kb of block RAM available which
isn't nearly enough to store even 1 of the matrices.  I may have to reduce
the target matrix size, which isn't an issue as I haven't found any algorithms
that need something more than 32x32.

## Development Process

HDL designs implemented with FPGAs have a low build cost similar to sotware,
and are suitable for agile developement. 

* Releases will be done in small increments
* I'll do everything I can to make the design easy to change
* TDD is included. Testbenches and tests are written before each feature and 
  are included in the repository.
* Test benches will be UVM-ish but without using the UVM reference model





