
# Matrix Accelerator for Snickerdoodle

This project aims to provide an IP block for snickerdoodle that can be used to
offload matrix operations from the Cortex-A9 included in the FPGA. This IP
should work on other Zynq-7000 boards but will only be tested on snickerdoodle. 

You can read about the snickerdoodle board at [krtkl.com](http://krtkl.com)

## Current Specifications

* Logic is in place to store 3 matrixes up to 4096 elements and read them 
back.  Currently, 64x64 matrix dimensions are hard-coded.

### To Do
* Functional test and debug
* Specify timing contraints and get a timing report
* Map I/O port and get implementtion to succeed
* Generate 1st bitstream
* Refactor testbench and perform more functional testing
* Added matrices B and C
* Add some multiply-accumulators and crunch some numbers!

## Target Specifications

* Support for matrices up to 64x64 in size 
    * H.265 uses 32x32, so 64x64 is plenty
    * Audio and RF DSP will probably need 1D array - need to research the 
      size.  Note that in audio, larger buffers increase system latency so 
      I don't expect anyone to want huge matrices here.
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

Another option is to give the matrix engine access to RAM. This would 
saturate a memory bus for every operation.  Some local storage is required
to keep from having to transfer all data over the bus.

### High-Level Usage

Input matrices are called matrix A and B.  The result is called matrix C.

1. Specify matrix A and B sizes and an operation via Size and Control 
registers. 
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

#### Matrix Size Register

This read/write register configures the engine matrices for a computation.  To
optimize system performance, this register should be written before any 
data is loaded into the engine, unless the data to be operated on is the 
result of a previous computation and is already there.  

Field | Bits  | Description
---   | ---   | --- 
AX    | 31:28 | Matrix A column address bit count.  Column count is 2^AX
AY    | 27:24 | Matrix A row address bit count.  Row count is 2^AY
BX    | 23:20 | Matrix B column address bit count.  Column count is 2^BX
BY    | 19:16 | Matrix B row address bit count.  Row count is 2^BY
CX    | 15:12 | Matrix C column address bit count.  Column count is 2^CX
CY    | 11:8  | Matrix C row address bit count.  Row count is 2^CY
DTP   | 7:0   | Data element type - See table

* The total matrix element count for _each_ matrix (indicated via AX, AY, BX, 
BY, CX, CY) must not exceed 4096.  

The DTP field in the Command register tells the engine what type of data is 
going to be loaded (or is loaded) for computation.

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

#### Command Register

This register tells the engine what operation to perform, where to get 
the data from, and where to put the result.

Field | Bits  | Description
---   | ---   | --- 
RSVD  | 31:28 | Reserved bits
SOP1  | 27:24 | Source operand 1 - see table below
RSVD  | 23:20 | Reserved bits
SOP2  | 19:16 | Source operand 2 - see table below
RSVD  | 15:12 | Reserved bits
DST   | 11:8  | Destination for result - see table below
CMD   | 7:0   | Operation to perform - see table below

Source operands and destintion data can be steered within the engine using 
the SOP1, SOP2, and DST fields.  Possible values for the fields are shown
below.  
* SOP1, SOP2, and DST values must all be unique - the same register
cannot be used as both source operands, or as a source operand and destination.
* DST must be internal storage of some type.  Streaming only to the output
register is not currently supported.

SOP1,2 Value | Description
---          | ---
0x0          | Matrix A input register - data will be loaded via PIO or DMA
0x1          | Matrix A internal storage
0x2          | Matrix B input register - data will be loaded via PIO or DMA
0x3          | Matrix B internal storage
0x4          | Matrix C input register - data will be loaded via PIO or DMA
0x5          | Matrix C internal storage
0x6 - 0xF    | Reserved

DST Value | Description
---          | ---
0x0          | Reserved
0x1          | Matrix A internal storage
0x2          | Reserved
0x3          | Matrix B internal storage
0x4          | Reserved
0x5          | Matrix C internal storage
0x6 - 0xF    | Reserved

Matrix operations can be specified via the CMD field using the encodings below.

CMD Value    | Description
---         | ---
0x00        | Reset engine
0x01        | Saturating matrix multiply
0x02 - 0x0F | TBD

#### Read Status Register A

This register can be read to determine the current read row and column for
matrix A. 

Field | Bits   | Description
---   | ---    | ---
ACRR  | 31:16  | Matrix A current row counter for read
ACCR  | 15:0   | Matrix A current column counter for read

#### Read Status Register B

This register can be read to determine the current read row and column for
matrix B. 

Field | Bits   | Description
---   | ---    | ---
BCRR  | 31:16  | Matrix B current row counter for read
BCCR  | 15:0   | Matrix B current column counter for read

#### Read Status Register C

This register can be read to determine the current read row and column for
matrix C. 

Field | Bits   | Description
---   | ---    | ---
CCRR  | 31:16  | Matrix C current row counter for read
CCCR  | 15:0   | Matrix C current column counter for read

#### Write Status Register A

This register can be read to determine the current write row and column for
matrix A. 

Field | Bits   | Description
---   | ---    | ---
ACRW  | 31:16  | Matrix A current row counter for write
ACCW  | 15:0   | Matrix A current column counter for write

#### Write Status Register B

This register can be read to determine the current write row and column for
matrix B. 

Field | Bits   | Description
---   | ---    | ---
BCRW  | 31:16  | Matrix B current row counter for write
BCCW  | 15:0   | Matrix B current column counter for write

#### Write Status Register C

This register can be read to determine the current write row and column for
matrix C. 

Field | Bits   | Description
---   | ---    | ---
CCRW  | 31:16  | Matrix C current row counter for write
CCCW  | 15:0   | Matrix C current column counter for write

#### Engine status register

Field | Bits | Description
--- |--- |---
RSVD | 31:8 | Reserved
STAT | 7:0 | Engine status - see table below

STAT Value | Description
--- | ---
0x0 | Idle
0x1 | Receiving data / operation in progress
0x2 | Calculation complete
0x3 | Error 
0x4 - 0xF | Reserved

#### Matrix Data In

One of these registers will be defined for each matrix (A, B, and C.)

Data must be right-justified in the register.  Registers are numbered using 
little-endian convention, so data will be in bit _n - 1_ to 0 for data size 
_n_.

Data must be loaded 1 entry at a time in row-major order. Data from a 1D or
2D array in the C language can be loaded in the order the data appears in 
memory. Packed data formats are not currently supported.

To stop the current operation and re-start the operation, write Status 1.

#### Matrix Data Out

This register allows the program to read the data from any matrix 
(A, B, or C.)

Data must be unloaded 1 entry at a time in row-major order.  Packed data 
formats are not currently supported.


# Design Information

## Challenges

### Matrix Storage

A lot of RAM could be used to store matrices with 32-bit samples and 
coefficients in them.  The Zynq 7010 has some options here:

1. Up to 2.1Mb of block RAM is offered, in 60 36kb chunks
2. Distributed RAM can be used, and utilizes some of the 17,600 LUT cells

My original plan was to offer 1024x1024 matrices, but each (of 3) would require
32Mb of RAM to store.  Some quick research shows that H.265 video codecs
require 32x32 matrices, and audio require 128x1 elements of storage.  Based on
this, 128kb will be allocated per matrix, allowing up to 4096 matrix elements
in any aspect ratio that is a power of 2.  For imaging, up to 64x64 matrices 
can be specified.  For audio or RF signals single 4096-element rows or 
columns can be used.

## Development Process

HDL designs implemented with FPGAs have a low build cost similar to sotware,
and are suitable for agile developement. 

* Releases will be done in small increments
* I'll do everything I can to make the design easy to change
* TDD is included. Testbenches and tests are written before each feature and 
  are included in the repository.
* Test benches will be UVM-ish but without using the UVM reference model





