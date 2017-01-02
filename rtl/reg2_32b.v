//
// 32-bit multi-input register.  Connect to other elements to make a shift
// register
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

module reg2_32b(
    input  CLK,
    input  RST_L,
    input  [31:0] din0,
    input  [31:0] din1,
    input  [1:0]  sel,
    output [31:0] dout
);

reg [31:0] d_nxt;	// Next state for data
reg [31:0] d;		// Current data value

assign dout = d;

always @(*) 
begin
    case(sel[1:0])
	2'b01:   d_nxt = din0;
	2'b10:   d_nxt = din1;
	default: d_nxt = d;
    endcase
end

always @(posedge CLK) 
begin
    d <= d_nxt;
end

endmodule
