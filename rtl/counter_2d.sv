//
// 2D (row & column) counter
//

`timescale 1ns / 100ps

module counter_2d(
    input VDD,
    input GND,
    input CLK,
    input RST_L,
    input [9:0] row_max,
    input [9:0] col_max,
    input inc,
    output [9:0] row,
    output [9:0] col
);

reg [9:0] row_nxt;	// Next value for row count
reg [9:0] col_nxt;	// Next value for column count
reg [9:0] row_int;	// Internal latched copy of row output
reg [9:0] col_int;	// Internal latched copy of column output

// Combinational logic
assign row = row_int;
assign col = col_int;

always_comb begin
    if(!RST_L) begin
	row_nxt = 16'h0;
	col_nxt = 16'h0;
    end
    else begin
	if(inc) begin
	    unique case({(col_int >= col_max), (row_int >= row_max)}) inside
		2'b0?: begin
		    row_nxt = row_int;
		    col_nxt = col_int + 10'h1;
		end
		2'b10: begin
		    row_nxt = row_int + 10'h1;
		    col_nxt = 16'h0;
		end
		2'b11: begin
		    row_nxt = 16'h0;
		    col_nxt = 16'h0;
		end
	    endcase
	end
	else begin
	    row_nxt = row_int;
	    col_nxt = col_int;
	end
    end
end

// Flops
always_ff @(posedge CLK) begin
    row_int <= row_nxt;
    col_int <= col_nxt;
end


endmodule
