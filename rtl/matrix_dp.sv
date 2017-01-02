//
// matrix_dp.v: Datapath for 1024 by 1024 matrix with 32-bit values in it
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

module matrix_dp(
    input  CLK,
    input  RST_L,
    input  [15:0] ram_sel,
    input  [15:0] a,
    input  [31:0] din,
    input  [15:0] we,
    output logic [31:0] dout
);

// work in progress - just try to get something to place & route right now

wire [31:0] ram_spo[15:0];	// Single port data output for each RAM
genvar i;


// RAM output mux - drive dout output port based on ram_sel input
// TODO: Possibly improve this implementation with IP block
always_comb begin
    unique case(1'b1)
	ram_sel[0]: dout = ram_spo[0];
	ram_sel[1]: dout = ram_spo[1];
	ram_sel[2]: dout = ram_spo[2];
	ram_sel[3]: dout = ram_spo[3];

	ram_sel[4]: dout = ram_spo[4];
	ram_sel[5]: dout = ram_spo[5];
	ram_sel[6]: dout = ram_spo[6];
	ram_sel[7]: dout = ram_spo[7];

	ram_sel[8]: dout = ram_spo[8];
	ram_sel[9]: dout = ram_spo[9];
	ram_sel[10]: dout = ram_spo[10];
	ram_sel[11]: dout = ram_spo[11];

	ram_sel[12]: dout = ram_spo[12];
	ram_sel[13]: dout = ram_spo[13];
	ram_sel[14]: dout = ram_spo[14];
	ram_sel[15]: dout = ram_spo[15];
    endcase
end


// Generate RAM blocks.  Each ram is 64k rows.  16 RAMs are required to 
// store 1024 rows
generate
    for(i = 0; i < 16; i = i + 1)
    begin: matrix_ram
	dist_mem_gen_0 U (
	    .a(a),      	// input wire [15 : 0] a
	    .d(din),    	// input wire [31 : 0] d
	    .clk(CLK),  	// input wire clk
	    .we(we[i]),    	// input wire we
	    .spo(ram_spo[i])    // output wire [31 : 0] spo
	 );
    end
endgenerate

endmodule

