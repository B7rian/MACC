//
// 32-bit by 1024 stage shift register.
//

`timescale 1ns / 100ps

module shift_reg_32b(
    input  VDD,
    input  GND,
    input  CLK,
    input  RST_L,
    input  [31:0] din,
    input  [1:0]  sel,
    output [31:0] dout
);

wire [31:0] shift_dout [0:1023];

// First register is a special case since input comes from port
reg2_32b R0(
    .VDD (VDD),
    .GND (GND),
    .CLK (CLK),
    .RST_L (RST_L),
    .din0 (din),	// Input for shift right
    .din1 (shift_dout[1]),	// Input for shift left
    .sel  (sel),
    .dout (shift_dout[0])
);

genvar i;

generate
    for(i = 1; i < 1023; i = i + 1)
    begin: shift_reg
	reg2_32b R(
	    .VDD (VDD),
	    .GND (GND),
	    .CLK (CLK),
	    .RST_L (RST_L),
	    .din0 (shift_dout[i - 1]),
	    .din1 (shift_dout[i + 1]),
	    .sel  (sel),
	    .dout (shift_dout[i])
	);
    end
endgenerate

// Last register is special case since input comes from port
reg2_32b R1023(
    .VDD (VDD),
    .GND (GND),
    .CLK (CLK),
    .RST_L (RST_L),
    .din0 (shift_dout[1022]),
    .din1 (din),
    .sel  (sel),
    .dout (shift_dout[1023])
);

endmodule

