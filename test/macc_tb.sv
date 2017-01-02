//
// macc_tb.v - a test bench for the matrix accelerator
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

module macc_tb;


// MACC interface - move to header file sometime
interface macc_if;
    logic CLK;
    logic RST_L;
    logic [2:0] wen;
    logic [2:0] ren;
    logic [31:0] matrix_a_in;
    logic [31:0] matrix_a_out;
    logic [31:0] matrix_b_in;
    logic [31:0] matrix_b_out;
    logic [31:0] matrix_c_in;
    logic [31:0] matrix_c_out;
endinterface


// Matrix transaction (for 1 matrix, not all 3)
// Note: random variable not supported in vivado
class matrix_trans; 
    bit rd_nwrite;
    bit [31:0] wr_data;
endclass


// Sequencer to generate a bunch of matrix transactions
class matrix_seq;
    function new();
	// Make things predictable for now
	$srandom(100);
    endfunction

    function matrix_trans get_next_trans();
	matrix_trans t = new();
	t.rd_nwrite = $urandom_range(0, 1);
	t.wr_data = $urandom();
	return t;
    endfunction
endclass


// Driver converts transaction to DUT input signals and drives them
// Use interface aboe to create virtual interface
class matrix_driver;
    virtual macc_if m_if;

    function drive(matrix_trans t);
    endfunction
endclass


// Instiantiate interface to get all the signals we need to drive the DUT
macc_if m_if();


// Instantiate the MACC
macc macc_dut(
    .CLK 		(m_if.CLK),
    .RST_L              (m_if.RST_L),
    .wen		(m_if.wen),
    .ren		(m_if.ren),
    .matrix_a_in 	(m_if.matrix_a_in),
    .matrix_a_out 	(m_if.matrix_a_out),
    .matrix_b_in 	(m_if.matrix_b_in),
    .matrix_b_out 	(m_if.matrix_b_out),
    .matrix_c_in 	(m_if.matrix_c_in),
    .matrix_c_out 	(m_if.matrix_c_out)
);

// Make sure simulation ends
initial begin
    #140 $finish;
end

// Generate clock
initial begin
    m_if.CLK = 0;
    m_if.RST_L = 0;
    #100	// 100ns needed for global reset to settle in BRAM
    m_if.RST_L = 1;
end

always begin
    #1 m_if.CLK = ~m_if.CLK;
end

// Load A matrix and read back
initial begin
    m_if.matrix_a_in = 32'h00000000; m_if.wen[2] = 1'b0; m_if.ren[2] = 1'b0;
    #110
    @(negedge m_if.CLK)
    m_if.matrix_a_in = 32'hdeadbeef; m_if.wen[2] = 1'b1; m_if.ren[2] = 1'b0;
    @(negedge m_if.CLK)
    // Skip this one since write enable is 0
    m_if.matrix_a_in = 32'ha5a5a5a5; m_if.wen[2] = 1'b0; m_if.ren[2] = 1'b0;
    @(negedge m_if.CLK)
    m_if.matrix_a_in = 32'hfeed2b0b; m_if.wen[2] = 1'b1; m_if.ren[2] = 1'b0;
    @(negedge m_if.CLK)
    m_if.matrix_a_in = 32'h00000001; m_if.wen[2] = 1'b1; m_if.ren[2] = 1'b0;

    if(m_if.matrix_a_out != 32'hdeadbeef) begin
        $error("Matrix A read data mismatch = got %x expected deadbeef",
	       m_if.matrix_a_out);
    end

    @(negedge m_if.CLK)
    m_if.matrix_a_in = 32'hFFFFFFFF; m_if.wen[2] = 1'b0; m_if.ren[2] = 1'b1;
    if(m_if.matrix_a_out != 32'hfeed2b0b) begin
        $error("Matrix A read data mismatch = got %x expected feed2b0b",
	       m_if.matrix_a_out);
    end

    @(negedge m_if.CLK)
    if(m_if.matrix_a_out != 32'h00000001) begin
        $error("Matrix A read data mismatch = got %x expected 00000001",
	       m_if.matrix_a_out);
    end

    @(negedge m_if.CLK)
    m_if.matrix_a_in = 32'hFFFFFFFF; m_if.wen[2] = 1'b0; m_if.ren[2] = 1'b0;

end

endmodule
