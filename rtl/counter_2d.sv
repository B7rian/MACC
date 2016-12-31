//
// 2D (row & column) counter
//

`timescale 1ns / 100ps

module counter_2d(
    input CLK,
    input RST_L,
    input [9:0] row_max,
    input [9:0] col_max,
    input inc,
    output logic [9:0] row,
    output logic [9:0] col
);

reg [9:0] row_nxt;	// Next value for row count
reg [9:0] col_nxt;	// Next value for column count

// Combinational logic
always_comb begin
    if(!RST_L) begin
	row_nxt = 10'h0;
	col_nxt = 10'h0;
    end
    else begin
	if(inc) begin
        // TODO: Figure out why case...inside results in warning herer
	    unique case({(col >= col_max), (row >= row_max)})
		2'b00: begin
		    row_nxt = row;
		    col_nxt = col + 10'h1;
		end
		2'b01: begin
            row_nxt = row;
            col_nxt = col + 10'h1;
        end
		2'b10: begin
		    row_nxt = row + 10'h1;
		    col_nxt = 10'h0;
		end
		2'b11: begin
		    row_nxt = 10'h0;
		    col_nxt = 10'h0;
		end
	    endcase
	end
	else begin
	    row_nxt = row;
	    col_nxt = col;
	end
    end
end

// Flops
always_ff @(posedge CLK) begin
    row <= row_nxt;
    col <= col_nxt;
end


endmodule
