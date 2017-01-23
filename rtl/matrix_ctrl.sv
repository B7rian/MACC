//
// matrix_ctrl.v: Matrix read/write control block
//
// The main purpose of this block is to convert top-level control signals
// into addresses and a write enable that the datapath understands.  It also
// controls when the read buffer is written and read to hide RAM access time.
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

module matrix_ctrl #(parameter ADDR_MSB=11, MAT_IDX_SIZE_MSB=3) (
    input  CLK,
    input  RST_L,
    input  we,
    input  re,
    input  [MAT_IDX_SIZE_MSB:0] col_idx_size,
    input  [MAT_IDX_SIZE_MSB:0] row_idx_size,
    output logic wen_to_ram,
    output logic shift_to_dp,
    output logic [1:0] out_sel_to_dp,
    output logic [ADDR_MSB:0] a
);


//
// Instantiate internal row and column counters for read and write.  These
// will track the address being read and written by software, which may be
// different than the ones we're actually reading from the RAM due to the
// pre-read functionality.
//

wire [ADDR_MSB:0] rd_a;
wire [ADDR_MSB:0] rd_row;
wire [ADDR_MSB:0] rd_col;
wire [ADDR_MSB:0] wr_a;
wire [ADDR_MSB:0] wr_row;
wire [ADDR_MSB:0] wr_col;

counter_2d #(.MSB(ADDR_MSB), .MAT_IDX_SIZE_MSB(MAT_IDX_SIZE_MSB)) rd_counter (
    .CLK (CLK),
    .RST_L (RST_L),
    .row_idx_size (row_idx_size),
    .col_idx_size (col_idx_size),
    .inc (re),
    .a (rd_a),
    .row (rd_row),
    .col (rd_col)
);

counter_2d #(.MSB(ADDR_MSB), .MAT_IDX_SIZE_MSB(MAT_IDX_SIZE_MSB)) wr_counter (
    .CLK (CLK),
    .RST_L (RST_L),
    .row_idx_size (row_idx_size),
    .col_idx_size (col_idx_size),
    .inc (we),
    .a (wr_a),
    .row (wr_row),
    .col (wr_col)
);


logic [1:0] ram_dvalid;		// 1 -> internal latch, 0 -> dout
logic [1:0] ram_dvalid_nxt;
logic [1:0] rb_dvalid;		// 1 -> read_buf[1], 0 -> read_buf[0]
logic [1:0] rb_dvalid_nxt;
logic [1:0] rb_read_mask;	// Identifies which rb entry is read
logic [1:0] rd_ahead_cnt;	// Read-ahead amount for read_buf pre-load
logic [1:0] rd_ahead_cnt_nxt;


// Drive the RAM address and handle pre-read of data when RAM is being loaded.
// Once we're past the first few addresses, we can always look-ahead by the
// number of read buffers.
always_comb begin
    if(!RST_L) begin
	rd_ahead_cnt_nxt = 'h0;
    end
    else begin
	if((wr_a >= 'h2) & (rd_ahead_cnt < 'h2) & shift_to_dp) begin
	    rd_ahead_cnt_nxt = rd_ahead_cnt + 'h1;
	end
    end
end

always_ff @(posedge CLK) begin
    rd_ahead_cnt <= rd_ahead_cnt_nxt;
end

assign a = we ? wr_a : (rd_a + rd_ahead_cnt);


// Track which data sources are valid and shift data when RAM data is valid
// and space is available
always_comb begin
    if(!RST_L) begin
	ram_dvalid_nxt = 'h0;
	rb_read_mask = 'b00;
	rb_dvalid_nxt = 'h0;
    end
    else begin
	ram_dvalid_nxt[1] = ~we & (re | ((rd_ahead_cnt < 'h2) & (wr_a >= 'h2)));
	ram_dvalid_nxt[0] = ram_dvalid[1] 
			  | (ram_dvalid[0] 
			      & ~shift_to_dp
			      & ~(re & ~rb_dvalid[0] & ~rb_dvalid[1]));

	priority casez(rb_dvalid) 
	    'b10: rb_read_mask = 'b10;
	    'b?1: rb_read_mask = 'b01;
	    'b00: rb_read_mask = 'b00;
	endcase

	unique casez({re, shift_to_dp})
	    'b00: rb_dvalid_nxt = rb_dvalid;
	    'b10: rb_dvalid_nxt = rb_dvalid & ~rb_read_mask;
	    'b?1: rb_dvalid_nxt = {ram_dvalid[0], rb_dvalid[1]};
	endcase
    end

    priority casez(rb_dvalid)
	// TODO: enum this sel signal
	'b?1:    out_sel_to_dp = 'b00;
	'b10:    out_sel_to_dp = 'b01;
	default: out_sel_to_dp = 'b11;
    endcase

    shift_to_dp = ram_dvalid[0] & (re | ~rb_dvalid[0]);
end

always_ff @(posedge CLK) begin
    ram_dvalid <= ram_dvalid_nxt;
    rb_dvalid <= rb_dvalid_nxt;
end


// RAM write-enable is pretty straghitforward
assign wen_to_ram = we;


endmodule

