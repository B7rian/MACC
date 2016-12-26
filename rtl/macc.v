//
// macc.v - a matric accelerator for snickerdoodle/Xilinx Zync 70x0
//
// See README for detailed description
//

`timescale 1ns / 100ps

module macc(
    input VDD,
    input GND,
    input clk,
    input [2:0] wen,
    input [2:0] ren,
    input [31:0] matrix_a_in,
    input [31:0] matrix_a_out,
    input [31:0] matrix_b_in,
    input [31:0] matrix_b_out,
    input [31:0] matrix_c_in,
    input [31:0] matrix_c_out
);

assign matrix_a_out = matrix_a_in;
assign matrix_b_out = matrix_b_in;
assign matrix_c_out = matrix_c_in;


endmodule

