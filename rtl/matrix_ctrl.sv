//
// matrix_ctrl.v: Matrix read/write control block
//
// The main purpose of this block is to convert top-level control signals
// into addresses and a write enable that the datapath understands
//

`timescale 1ns / 100ps

module matrix_ctrl #(parameter ADDR_MSB=11) (
    input CLK,
    input RST_L,
    input we,
    input re,
    input [ADDR_MSB:0] max_col_count,	// From configuration register
    input [ADDR_MSB:0] max_row_count,	// From configuration register
    output [ADDR_MSB:0] a
);


//
// Instantiate internal row and column counters for read and write
//

wire [ADDR_MSB:0] rd_a;
wire [ADDR_MSB:0] rd_row;
wire [ADDR_MSB:0] rd_col;
wire [ADDR_MSB:0] wr_a;
wire [ADDR_MSB:0] wr_row;
wire [ADDR_MSB:0] wr_col;

counter_2d #(.MSB(ADDR_MSB)) read_counter(
    .CLK (CLK),
    .RST_L (RST_L),
    .row_max(max_row_count),
    .col_max(max_col_count),
    .inc (re),
    .a (rd_a),
    .row (rd_row),
    .col (rd_col)
);

counter_2d #(.MSB(ADDR_MSB)) write_counter(
    .CLK (CLK),
    .RST_L (RST_L),
    .row_max(max_row_count),
    .col_max(max_col_count),
    .inc (we),
    .a (wr_a),
    .row (wr_row),
    .col (wr_col)
);

assign a = we ? wr_a : rd_a;

endmodule
