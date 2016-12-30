//
// 32-bit multi-input register.  Connect to other elements to make a shift
// register
//

`timescale 1ns / 100ps

module reg2_32b(
    input  VDD,
    input  GND,
    input  CLK,
    input  RST_L,
    input  [31:0] din0,
    input  [31:0] din1,
    input  [1:0]  sel,
    output [31:0] dout
);

reg [31:0] d_nxt;	// Next state for data
reg [31:0] d;		// Current data value

assign dout = d;

always @(*) 
begin
    case(sel[1:0])
	2'b01:   d_nxt = din0;
	2'b10:   d_nxt = din1;
	default: d_nxt = d;
    endcase
end

always @(posedge CLK) 
begin
    d <= d_nxt;
end

endmodule
