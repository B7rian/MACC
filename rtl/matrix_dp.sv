//
// matrix_dp.v: RAM with some registers to hide RAM read latency
//
//---
// The MIT License (MIT)
//
// Copyright (c) 2017 Brian W Hughes
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including without
// limitation the rights to use, copy, modify, merge, publish, distribute,
// sublicense, and/or sell copies of the Software, and to permit persons to
// whom the Software is furnished to do so, subject to the following
// conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// 

`timescale 1ns / 100ps

module matrix_dp #(parameter ADDR_MSB=11) (
    input  clka,
    input  wea,
    input  [ADDR_MSB:0] addra,
    input  [31:0] dina,
    input  shift,		// Shift control for read buffer
    input  [1:0] out_sel, 	// Output select for RAM or read buffer
    output logic [31:0] douta
);


// Instantiate RAM to hold matrix data
wire [31:0] ram_douta;

bram_32bx4096d_2cyc matrix_ram (
  .clka(clka),
  .ena(1'b1),
  .wea(wea),
  .addra(addra),
  .dina(dina),
  .douta(ram_douta)
);


// Create some buffers to hide RAM read latency.
// Shift order: BRAM -> read_buf[1] -> read_buf[0]
// TODO: Parameterize read buffer depth
logic [31:0] read_buf_nxt[1:0];
logic [31:0] read_buf[1:0];

assign read_buf_nxt[1] = shift ? ram_douta : read_buf[1];
assign read_buf_nxt[0] = shift ? read_buf[1] : read_buf[0];

always_ff @(posedge clka) begin
    read_buf <= read_buf_nxt;
end

// Data output mux
always_comb begin
    unique case(out_sel)
        // TODO: enum this sel signal
        2'b00: douta = read_buf[0];
	2'b01: douta = read_buf[1];
	2'b1?: douta = ram_douta;
    endcase
end


endmodule

