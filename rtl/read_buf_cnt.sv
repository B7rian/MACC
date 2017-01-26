//
// read_buf_cnt.v: Read buffer counter / state machine
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

module read_buf_cnt (
    input  CLK,
    input  RST_L,
    input  re,
    input  ram_dvalid,
    output logic [1:0] rb_cnt,
    output logic rb_full
);

logic [1:0] rb_cnt_nxt;

always_comb begin
    if(~RST_L) begin
	rb_cnt_nxt = 'h0;
    end
    else begin
	rb_cnt_nxt = rb_cnt;

	unique case(rb_cnt)
	    'h0: if(ram_dvalid & ~re) rb_cnt_nxt = rb_cnt + 'h1;
	    'h1: unique if(ram_dvalid & ~re) rb_cnt_nxt = rb_cnt + 'h1;
		 else if(~ram_dvalid & re) rb_cnt_nxt = rb_cnt - 'h1;
	    'h2: if(re) rb_cnt_nxt = rb_cnt - 'h1;
	endcase
    end
end

always_ff @(posedge CLK) begin
    rb_cnt <= rb_cnt_nxt;
end

assign rb_full = (rb_cnt == 'h2);

endmodule

