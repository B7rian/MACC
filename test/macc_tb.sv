//
// macc_tb.v - a test bench for the matrix accelerator
//


`timescale 1ns / 100ps

module macc_tb;

reg clk;			// System clock
reg rst_l;			// System reset
reg wen_a, wen_b, wen_c;	// Write enable for each matrix
reg ren_a, ren_b, ren_c;	// Read enable for each matrix
reg [31:0] a_in;		// Matrix A data input
reg [31:0] a_out;		// Matrix A data output
reg [31:0] b_in;		// Matrix B data input
reg [31:0] b_out;		// Matrix A data output
reg [31:0] c_in;		// Matrix B data input
reg [31:0] c_out;		// Matrix A data output


// Instantiate the MACC
macc macc_dut(
    .CLK 		(clk),
    .RST_L              (rst_l),
    .wen		({wen_a, wen_b, wen_c}),
    .ren		({ren_a, ren_b, ren_c}),
    .matrix_a_in 	(a_in),
    .matrix_a_out 	(a_out),
    .matrix_b_in 	(b_in),
    .matrix_b_out 	(b_out),
    .matrix_c_in 	(c_in),
    .matrix_c_out 	(c_out)

);

// Make sure simulation ends
initial begin
    #1000 $finish;
end

// Generate clock
initial begin
    clk = 0;
    rst_l = 0;
    #5
    rst_l = 1;
end

always begin
    #1 clk = ~clk;
end

// Load A matrix and read back
initial begin
    #10
    a_in = 32'h00000000; wen_a = 1'b0; ren_a = 1'b0;
    @(negedge clk)
    a_in = 32'hdeadbeef; wen_a = 1'b1; ren_a = 1'b0;
    @(negedge clk)
    // Skip this one since write enable is 0
    a_in = 32'ha5a5a5a5; wen_a = 1'b0; ren_a = 1'b0;
    @(negedge clk)
    a_in = 32'hfeed2b0b; wen_a = 1'b1; ren_a = 1'b0;
    @(negedge clk)
    a_in = 32'h00000001; wen_a = 1'b1; ren_a = 1'b0;

    if(a_out != 32'hdeadbeef) begin
        $error("Matrix A read data mismatch = got %x expected deadbeef",
	       a_out);
    end

    @(negedge clk)
    a_in = 32'hFFFFFFFF; wen_a = 1'b0; ren_a = 1'b1;
    if(a_out != 32'hfeed2b0b) begin
        $error("Matrix A read data mismatch = got %x expected feed2b0b",
	       a_out);
    end

    @(negedge clk)
    if(a_out != 32'h00000001) begin
        $error("Matrix A read data mismatch = got %x expected 00000001",
	       a_out);
    end

    @(negedge clk)
    a_in = 32'hFFFFFFFF; wen_a = 1'b0; ren_a = 1'b0;

end

endmodule
