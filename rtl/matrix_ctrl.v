//
// matrix_ctrl.v: Matrix read/write control block
//
// The main purpose of this block is to convert top-level control signals
// into addresses and a write enable that the datapath understands
//

`timescale 1ns / 100ps

module matrix_ctrl (
    input CLK,
    input RST_L,
    input we,
    input re,
    input [9:0] max_col_count,	// From configuration register
    input [9:0] max_row_count,	// From configuration register
    output reg [15:0] ram_sel,
    output reg [15:0] a,
    output [15:0] we_out
);


//
// Instantiate internal row and column counters for read and write
//

wire [9:0] rd_row;
wire [9:0] rd_col;
wire [9:0] wr_row;
wire [9:0] wr_col;

counter_2d read_counter(
    .CLK (CLK),
    .RST_L (RST_L),
    .row_max(max_row_count),
    .col_max(max_col_count),
    .inc (re),
    .row (rd_row),
    .col (rd_col)
);

counter_2d write_counter(
    .CLK (CLK),
    .RST_L (RST_L),
    .row_max(max_row_count),
    .col_max(max_col_count),
    .inc (we),
    .row (wr_row),
    .col (wr_col)
);


//
// Generate ram_sel and a from internal counters and write enable
//

always @(*)
begin
    if(we) begin
	ram_sel = (15'b1 << wr_row[9:6]);
	a = {wr_row[5:0], wr_col[9:0]};
    end
    else begin
	ram_sel = (15'b1 << rd_row[9:6]);
	a = {rd_row[5:0], rd_col[9:0]};
    end
end


// 
// Generate we_out from input state and internal counters
//

assign we_out = {16{we}} & ram_sel;

endmodule
