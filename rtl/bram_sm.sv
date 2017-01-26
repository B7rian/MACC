//
// bram_sm.v: Xilinx BRAM state machine (but should work with any RAM)
//
// Track RAM read latency so we can coordinate the use of the output read
// buffers.
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

module bram_sm (
    input  CLK,
    input  RST_L,
    input  re,
    output logic ram_dvalid	// 1 when dout has new data to read
);

enum logic [1:0] {
    IDLE = 'b00,
    WAIT = 'b01,
    DVALID = 'b10,
    DVALID_PIPELINE = 'b11
} state, state_nxt;

always_comb begin
    if(~RST_L) begin
	state_nxt = IDLE;
    end
    else begin
	unique case({state, re})
	    {IDLE, 1'b0}: state_nxt = IDLE;
	    {IDLE, 1'b1}: state_nxt = WAIT;

	    {WAIT, 1'b0}: state_nxt = DVALID;
	    {WAIT, 1'b1}: state_nxt = DVALID_PIPELINE;

	    {DVALID, 1'b0}: state_nxt = DVALID;
	    {DVALID, 1'b1}: state_nxt = WAIT;

	    {DVALID_PIPELINE, 1'b0}: state_nxt = DVALID;
	    {DVALID_PIPELINE, 1'b1}: state_nxt = DVALID_PIPELINE;
	endcase
    end
end

always_ff @(posedge CLK) begin
    state <= state_nxt;
end

assign ram_dvalid = (state == DVALID) | (state == DVALID_PIPELINE);


endmodule

