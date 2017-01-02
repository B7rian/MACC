// 
// macc.v - a matrix accelerator for snickerdoodle/Xilinx Zync 70x0
//
// See README.md for detailed description
//
//---
// The MIT License (MIT)
//
// Copyright (c) 2017 Brian W Hughes
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including without
// limitation the rights to use, copy, modify, merge, publish, distribute,
// sublicense, and/or sell copies of the Software, and to permit persons to
// whom the Software is furnished to do so, subject to the following
// conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// 

`timescale 1ns / 100ps

module macc(
    input  CLK,
    input  RST_L,
    input  [2:0] wen, // 2 -> A, 1 -> B, 0 -> C
    input  [2:0] ren, // 2 -> A, 1 -> B, 0 -> C

    input  [31:0] matrix_a_in,
    output [31:0] matrix_a_out,

    input  [31:0] matrix_b_in,
    output [31:0] matrix_b_out,

    input  [31:0] matrix_c_in,
    output [31:0] matrix_c_out
);

wire [11:0] addr_to_matrix[2:0];	// Matrix RAM address A, B, C


//
// Instantiate control block and datapath for matrix A
// 

matrix_ctrl #(.ADDR_MSB(11)) ctrl_A (
    .CLK (CLK),
    .RST_L (RST_L),
    .we (wen[2]),
    .re (ren[2]),
    .max_col_count (12'h3f),
    .max_row_count (12'h3f),
    .a (addr_to_matrix[2])
);


// TODO: If timing fails, regenerate BRAM with output register
bram_32bx4096d_1cyc dp_A (
  .clka(CLK),
  .ena(1'b1),
  .wea(wen[2]),
  .addra(addr_to_matrix[2]), // 11:0
  .dina(matrix_a_in),    // input wire [31 : 0] dina
  .douta(matrix_a_out)   // output wire [31 : 0] douta
);


//
// Instantiate control block and datapath for matrix B
// 

matrix_ctrl #(.ADDR_MSB(11)) ctrl_B (
    .CLK (CLK),
    .RST_L (RST_L),
    .we (wen[1]),
    .re (ren[1]),
    .max_col_count (12'h3f),
    .max_row_count (12'h3f),
    .a (addr_to_matrix[1])
);


// TODO: If timing fails, regenerate BRAM with output register
bram_32bx4096d_1cyc dp_B (
  .clka(CLK),
  .ena(1'b1),
  .wea(wen[1]),
  .addra(addr_to_matrix[1]), // 11:0
  .dina(matrix_b_in),    // input wire [31 : 0] dina
  .douta(matrix_b_out)   // output wire [31 : 0] douta
);

//
// Instantiate control block and datapath for matrix C
// 

matrix_ctrl #(.ADDR_MSB(11)) ctrl_C (
    .CLK (CLK),
    .RST_L (RST_L),
    .we (wen[0]),
    .re (ren[0]),
    .max_col_count (12'h3f),
    .max_row_count (12'h3f),
    .a (addr_to_matrix[0])
);


// TODO: If timing fails, regenerate BRAM with output register
bram_32bx4096d_1cyc dp_C (
  .clka(CLK),
  .ena(1'b1),
  .wea(wen[0]),
  .addra(addr_to_matrix[0]), // 11:0
  .dina(matrix_c_in),    // input wire [31 : 0] dina
  .douta(matrix_c_out)   // output wire [31 : 0] douta
);



endmodule

