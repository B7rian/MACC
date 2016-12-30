//
// matrix_ctrl.v: Matrix read/write control block
//
// The main purpose of this block is to convert top-level control signals
// into addresses and a write enable that the datapath understands
//

`timescale 1ns / 100ps

module matrix_ctrl (
    input VDD,
    input GND,
    input CLK,
    input RST_L,
    input we,
    input re,
    input [9:0] max_col_count,	// From configuration register
    input [9:0] max_row_count,	// From configuration register
    output reg [15:0] ram_sel,
    output reg [15:0] a,
    output reg [15:0] we_out
);


//
// Instantiate internal row and column counters for read and write
//

wire [9:0] rd_row;
wire [9:0] rd_col;
wire [9:0] wr_row;
wire [9:0] wr_col;

counter_2d read_counter(
    .VDD (VDD),
    .GND (GND),
    .CLK (CLK),
    .RST_L (RST_L),
    .row_max(max_row_count),
    .col_max(max_col_count),
    .inc (re),
    .row (rd_row),
    .col (rd_col)
);

counter_2d write_counter(
    .VDD (VDD),
    .GND (GND),
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

reg [15:0] rs_nxt;
reg [15:0] a_nxt;

always @(*)
begin
    if(!RST_L) begin
	rs_nxt = 16'h0;
	a_nxt = 16'h0;
    end
    else begin
	if(we) begin
	    rs_nxt = (1'b1 << wr_row[9:6]);
	    a_nxt = {wr_row[5:0], wr_col[9:0]};
	end
	else begin
	    rs_nxt = (1'b1 << rd_row[9:6]);
	    a_nxt = {rd_row[5:0], rd_col[9:0]};
	end
    end
end


// 
// Generate we_out from input state and internal counters
//

wire we_out_nxt;
assign we_out_nxt = {16{we}} ^ rs_nxt;


//
// Flops
//

always @(posedge CLK) begin
    ram_sel <= rs_nxt;
    a <= a_nxt;
    we_out <= we_out_nxt;
end


endmodule
