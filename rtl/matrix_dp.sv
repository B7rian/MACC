//
// matrix_dp.v: Datapath for 1024 by 1024 matrix with 32-bit values in it
//

`timescale 1ns / 100ps

module matrix_dp(
    input  VDD,
    input  GND,
    input  CLK,
    input  RST_L,
    input  [15:0] ram_sel,
    input  [15:0] a,
    input  [31:0] din,
    input  [15:0] we,
    output [31:0] dout
);

// work in progress - just try to get something to place & route right now

wire [31:0] ram_spo[15:0];	// Single port data output for each RAM
reg  ram_dout;			// Value to drive to output port
genvar i;


// RAM output mux - drive dout output port based on ram_sel input
// TODO: Possibly improve this implementation with IP block
// NOTE: In Verilog 2001, this is a priority encoder and doesn't need casez
always @(*)
begin
    case(ram_sel)
	16'h0001: ram_dout = ram_spo[0];
	16'h0002: ram_dout = ram_spo[1];
	16'h0004: ram_dout = ram_spo[2];
	16'h0008: ram_dout = ram_spo[3];

	16'h0010: ram_dout = ram_spo[4];
	16'h0020: ram_dout = ram_spo[5];
	16'h0040: ram_dout = ram_spo[6];
	16'h0080: ram_dout = ram_spo[7];

	16'h0100: ram_dout = ram_spo[8];
	16'h0200: ram_dout = ram_spo[9];
	16'h0400: ram_dout = ram_spo[10];
	16'h0800: ram_dout = ram_spo[11];

	16'h1000: ram_dout = ram_spo[12];
	16'h2000: ram_dout = ram_spo[13];
	16'h4000: ram_dout = ram_spo[14];
	default:  ram_dout = ram_spo[15];
    endcase
end
assign dout = ram_dout;


// Generate RAM blocks.  Each ram is 64k rows.  16 RAMs are required to 
// store 1024 rows
generate
    for(i = 0; i < 16; i = i + 1)
    begin: matrix_ram
	dist_mem_gen_0 U (
	    .a(a),      	// input wire [15 : 0] a
	    .d(din),    	// input wire [31 : 0] d
	    .clk(CLK),  	// input wire clk
	    .we(we[i]),    	// input wire we
	    .spo(ram_spo[i])    // output wire [31 : 0] spo
	 );
    end
endgenerate

endmodule

