//
// macc.v - a matrix accelerator for snickerdoodle/Xilinx Zync 70x0
//
// See README.md for detailed description
//

`timescale 1ns / 100ps

module macc(
    input  CLK,
    input  RST_L,
    input  [2:0] wen, // 2 -> A, 1 -> B, 0 -> C
    input  [2:0] ren, // 2 -> A, 1 -> B, 0 -> C

    input  [31:0] matrix_a_in,
    output [31:0] matrix_a_out,

    input  [31:0] matrix_b_in,
    output [31:0] matrix_b_out,

    input  [31:0] matrix_c_in,
    output [31:0] matrix_c_out
);

wire [11:0] addr_to_matrix[2:0];	// Matrix RAM address A, B, C


//
// Instantiate control block and datapath for matrix A
// 

matrix_ctrl #(.ADDR_MSB(11)) ctrl_A (
    .CLK (CLK),
    .RST_L (RST_L),
    .we (wen[2]),
    .re (ren[2]),
    .max_col_count (12'h3f),
    .max_row_count (12'h3f),
    .a (addr_to_matrix[2])
);


// TODO: If timing fails, regenerate BRAM with output register
bram_32bx4096d_1cyc dp_A (
  .clka(CLK),
  .ena(1'b1),
  .wea(wen[2]),
  .addra(addr_to_matrix[2]), // 11:0
  .dina(matrix_a_in),    // input wire [31 : 0] dina
  .douta(matrix_a_out)   // output wire [31 : 0] douta
);


// TODO: Add matrices B and C later
assign matrix_b_out = 32'h0;
assign matrix_c_out = 32'h0;

endmodule

