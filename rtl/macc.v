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

localparam RAM_ADDR_MSB     = 11;
localparam MAT_IDX_SIZE_MSB = 3;

// Signals for from each matrix control block to datapath
wire [RAM_ADDR_MSB:0] addr_to_ram[2:0];
wire wen_to_ram[2:0];
wire [1:0] out_sel_to_dp[2:0];
wire shift_to_dp[2:0];

// Use arrays of busses to make generate block a little easier
wire [31:0] matrix_in[2:0] = { matrix_a_in, matrix_b_in, matrix_c_in };
wire [31:0] matrix_out[2:0];
// Note: Vivado won't let me concat stuff on the left side of the assignment
assign matrix_a_out = matrix_out[2];
assign matrix_b_out = matrix_out[1];
assign matrix_c_out = matrix_out[0];


//
// Instantiate control block and datapath for each matrix
// 

generate
    for(genvar i = 2; i >= 0; i = i - 1) begin
	matrix_ctrl #(
	    .ADDR_MSB(RAM_ADDR_MSB), 
	    .MAT_IDX_SIZE_MSB(MAT_IDX_SIZE_MSB)
	) 
	m_ctrl (
	    .CLK (CLK),
	    .RST_L (RST_L),
	    .we (wen[i]),
	    .re (ren[i]),
	    .col_idx_size (4'h6),
	    .row_idx_size (4'h6),
	    .wen_to_ram (wen_to_ram[i]),
	    .shift_to_dp (shift_to_dp[i]),
	    .out_sel_to_dp (out_sel_to_dp[i]),
	    .a (addr_to_ram[i])
	);

	matrix_dp m_dp (
	  .clka (CLK),
	  .wea (wen_to_ram[i]),
	  .addra (addr_to_ram[i]),
	  .dina (matrix_in[i]),
	  .shift (shift_to_dp[i]),
	  .out_sel (out_sel_to_dp[i]),
	  .douta (matrix_out[i])
	);
    end
endgenerate

endmodule

