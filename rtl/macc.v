//
// macc.v - a matrix accelerator for snickerdoodle/Xilinx Zync 70x0
//
// See README.md for detailed description
//

`timescale 1ns / 100ps

module macc(
    input VDD,
    input GND,
    input CLK,
    input RST_L,
    input [2:0] wen, // 2 -> A, 1 -> B, 0 -> C
    input [2:0] ren, // 2 -> A, 1 -> B, 0 -> C
    input [31:0] matrix_a_in,
    output [31:0] matrix_a_out,
    input [31:0] matrix_b_in,
    output [31:0] matrix_b_out,
    input [31:0] matrix_c_in,
    output [31:0] matrix_c_out
);

wire [15:0] ram_sel_to_matrix[2:0];	// Matrix RAM select
wire [15:0] addr_to_matrix[2:0];	// Matrix RAM address
wire [15:0] we_to_matrix[2:0];		// Matrix write-enables


//
// Instantiate control block and datapath for matrix A
// 

matrix_ctrl ctrl_A (
    .VDD (VDD),
    .GND (GND),
    .CLK (CLK),
    .RST_L (RST_L),
    .we (wen[2]),
    .re (ren[2]),
    .max_col_count (10'h3ff),
    .max_row_count (10'h3ff),
    .ram_sel (ram_sel_to_matrix[2]),
    .a (addr_to_matrix[2]),
    .we_out (we_to_matrix[2])
);

matrix_dp dp_A(
    .VDD (VDD),
    .GND (GND),
    .CLK (CLK),
    .RST_L (RST_L),
    .ram_sel (ram_sel_to_matrix[2]),
    .a (addr_to_matrix[2]),
    .din (matrix_a_in),
    .we (we_to_matrix[2]),
    .dout (matrix_a_out)
);

// TODO: Add matrices B and C later
assign matrix_b_out = 32'h0;
assign matrix_c_out = 32'h0;

endmodule

