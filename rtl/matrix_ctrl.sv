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


//
// pre-read control: Determine how many addresses to read-ahead.  
//
// Usually this will be 2 (because there will be 2 entries in the read 
// buffer) but for the pre-load we'll need to start at 0 and work our 
// way up to 2
//

logic [1:0] read_ahead_cnt, read_ahead_cnt_nxt;
logic do_preread;

assign do_preread = (read_ahead_cnt < 'h2) & (wr_a >= 'h2) & ~we;

always_comb begin
    priority if(~RST_L) begin
	read_ahead_cnt_nxt = 'h0;
    end
    else if(do_preread) begin
	read_ahead_cnt_nxt = read_ahead_cnt + 'h1;
    end
    else begin
	read_ahead_cnt_nxt = read_ahead_cnt;
    end
end

always_ff @(posedge CLK) begin
    read_ahead_cnt <= read_ahead_cnt_nxt;
end

// Augment BRAM state machine read-enable to pre-read data when available
logic ram_re;
assign ram_re = re | do_preread;


// 
// Track BRAM read state and read buffer fill level
//

logic ram_dvalid;	// 1 when BRAM douta has new data
logic [1:0] rb_cnt;	// Number of entries in read buffer
logic rb_full;		// 1 when the read buffers are all full

bram_sm bram_state (
    .CLK (CLK),
    .RST_L (RST_L),
    .re (ram_re),
    .ram_dvalid (ram_dvalid)
);

read_buf_cnt rbc (
    .CLK (CLK),
    .RST_L (RST_L),
    .re (re),
    .ram_dvalid (ram_dvalid),
    .rb_cnt (rb_cnt),
    .rb_full (rb_full)
);


//
// Drive remaining outputs.  Mess with the read address so we can pre-read
// address 0 and 1 when available and are 2 address ahead of the counter above
// after that
//

assign wen_to_ram = we;
assign shift_to_dp = ram_dvalid & ~rb_full;
assign out_sel_to_dp = rb_cnt;
assign a = we ? wr_a : (rd_a + read_ahead_cnt);

endmodule

