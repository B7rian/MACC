//
// 2D (row & column) counter
//
// This is just a regular linear counter with some logic to convert the
// address to row and column indices
//

`timescale 1ns / 100ps

module counter_2d #(parameter MSB=11) (
    input CLK,
    input RST_L,
    input [MSB:0] row_max,
    input [MSB:0] col_max,
    input inc,
    output logic [MSB:0] a,	// Linerized address
    output logic [MSB:0] row,	// Row index
    output logic [MSB:0] col	// Column index
);

reg [MSB:0] a_nxt;	// Next value for address output
reg [MSB:0] row_nxt;	// Next value for row count
reg [MSB:0] col_nxt;	// Next value for column count

int i;			// Loop counter for log2 calculation


// Combinational logic 
always_comb begin
    if(!RST_L) begin
	a_nxt = 'h0;
    end
    else begin
	a_nxt = inc ? (a + 'b1) : a;
    end

    col_nxt = a_nxt & col_max;
    
    // Compute log2(col_max) to figure out how much to shift a_nxt to get row
    // col_max must be a power of 2 for this to work right.
    // Note: Could use case here but wouldn't parameterize well
    // Note 2: This looks horrible in schematic
    i = 0;
    while((i <= MSB) && col_max[i]) begin
       i++;
    end

    row_nxt = (a_nxt >> i) & row_max;
end


// Flops
always_ff @(posedge CLK) begin
    a <= a_nxt;
    row <= row_nxt;
    col <= col_nxt;
end


endmodule
