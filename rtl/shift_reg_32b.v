//
// 32-bit by 1024 stage shift register.
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

module shift_reg_32b(
    input  CLK,
    input  RST_L,
    input  [31:0] din,
    input  [1:0]  sel,
    output [31:0] dout
);

wire [31:0] shift_dout [0:1023];

// First register is a special case since input comes from port
reg2_32b R0(
    .CLK (CLK),
    .RST_L (RST_L),
    .din0 (din),	// Input for shift right
    .din1 (shift_dout[1]),	// Input for shift left
    .sel  (sel),
    .dout (shift_dout[0])
);

genvar i;

generate
    for(i = 1; i < 1023; i = i + 1)
    begin: shift_reg
	reg2_32b R(
	    .CLK (CLK),
	    .RST_L (RST_L),
	    .din0 (shift_dout[i - 1]),
	    .din1 (shift_dout[i + 1]),
	    .sel  (sel),
	    .dout (shift_dout[i])
	);
    end
endgenerate

// Last register is special case since input comes from port
reg2_32b R1023(
    .CLK (CLK),
    .RST_L (RST_L),
    .din0 (shift_dout[1022]),
    .din1 (din),
    .sel  (sel),
    .dout (shift_dout[1023])
);

endmodule

