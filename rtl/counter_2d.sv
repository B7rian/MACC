//
// 2D (row & column) counter
//
// This is just a regular linear counter with some logic to convert the
// address to row and column indices
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

module counter_2d #(parameter MSB=11, MAT_IDX_SIZE_MSB=3) (
    input CLK,
    input RST_L,
    input [MAT_IDX_SIZE_MSB:0] row_idx_size,
    input [MAT_IDX_SIZE_MSB:0] col_idx_size,
    input inc,
    output logic [MSB:0] a,	// Linerized address
    output logic [MSB:0] row,	// Row index
    output logic [MSB:0] col	// Column index
);

reg [MSB:0] a_nxt;	// Next value for address output
reg [MSB:0] row_nxt;	// Next value for row count
reg [MSB:0] col_nxt;	// Next value for column count

reg [MSB:0] col_max;	// Maximum column index
reg [MSB:0] row_max;	// Maximum row index


// Combinational logic 
always_comb begin
    if(!RST_L) begin
	a_nxt = 'h0;
    end
    else begin
	a_nxt = inc ? (a + 'b1) : a;
    end

    col_max = (1 << col_idx_size) - 1;
    row_max = (1 << row_idx_size) - 1;

    col_nxt = a_nxt & col_max;
    row_nxt = (a_nxt >> col_idx_size) & row_max;
end


// Flops
always_ff @(posedge CLK) begin
    a <= a_nxt;
    row <= row_nxt;
    col <= col_nxt;
end


endmodule
