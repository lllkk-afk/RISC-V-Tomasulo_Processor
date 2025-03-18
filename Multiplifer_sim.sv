`timescale 1ns / 1ps

module Multiplier_sim;
    // Testbench Signals
    logic clk;
    logic reset;
    logic [31:0] SrcA;
    logic [31:0] SrcB;
    logic start;
    logic [3:0] Tag_in;
    logic [3:0] cdb_tag; 
    logic cdb_valid;
    logic ismultiply;  // New control signal to select multiplication/division
    logic [31:0] Mul;
    logic [31:0] Mulh;
    logic [31:0] Quotient;  // New for division
    logic [31:0] Remainder; // New for division
    logic mulvalid;   // multiply is valid
    logic divvalid;   // division is valid
    logic result_valid;

    // Instantiate DUT
    Multiplier uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .SrcA(SrcA),
        .SrcB(SrcB),
        .Tag_in(Tag_in),
        .cdb_tag(cdb_tag),
        .cdb_valid(cdb_valid),
        .ismultiply(ismultiply),
        .Tag_out(),
        .result_valid(result_valid),
        .Mul(Mul),
        .Mulh(Mulh),
        .Quotient(Quotient),
        .Remainder(Remainder),
        .mulvalid(mulvalid),
        .divvalid(divvalid)
    );

    // Clock Generation
    always #5 clk = ~clk; // 10ns period

    // Test Sequence
    initial begin
        $dumpfile("Multiplier_sim.vcd");
        $dumpvars(0, Multiplier_sim);

        // Initialize
        clk = 0;
        reset = 1;
        start = 0;
        SrcA = 0;
        SrcB = 0;
        ismultiply = 1;  // Default to multiplication

        // Release reset after 10ns
        #10 reset = 0;

        // Synchronize test cases to clock edges
        fork
            begin
                // Case 1: 10 * 2 = 20 (Multiplication, positive * positive)
ismultiply = 1;
apply_test(32'sd10, 32'sd2, 64'sd20); // 10 * 2 = 20
#10

// Case 2: 10 / 2 = 5 (positive/positive division)
ismultiply = 0;
apply_test(32'sd10, 32'sd2, {32'sd5, 32'sd0}); // Quotient = 5, Remainder = 0

// Case 3: 10 / -2 = -5 (positive/negative division)
ismultiply = 0;
apply_test(32'sd10, -32'sd2, {-32'sd5, 32'sd0}); // Quotient = -5, Remainder = 0

// Case 4: -10 / 2 = -5 (negative/positive division)
ismultiply = 0;
apply_test(-32'sd10, 32'sd2, {-32'sd5, 32'sd0}); // Quotient = -5, Remainder = 0

// Case 5: -10 / -2 = 5 (negative/negative division)
ismultiply = 0;
apply_test(-32'sd10, -32'sd2, {32'sd5, 32'sd0}); // Quotient = 5, Remainder = 0
            end
        join

        #10 $finish;
    end

    // Task to apply and check tests
    task apply_test(input logic [31:0] a, b, input logic signed [63:0] expected);
        begin
            @(negedge clk); // Wait for stable clock
            SrcA = a;
            SrcB = b;
            start = 1;
            @(negedge clk); // Hold start for one cycle
            start = 0;

            wait(result_valid); // Wait for result validity

            // Check results
            if (ismultiply) begin
                // For multiplication, check the combined result
                if ({Mulh, Mul} !== expected) begin
                    $display("Error: %d * %d = %h%h (Expected: %h)",
                             a, b, Mulh, Mul, expected);
                    $finish;
                end
                else
                    $display("Multiplication Test Passed: %d * %d = %d", a, b, $signed({Mulh, Mul}));
            end
            else begin
                // For division, check quotient and remainder
                if ({Quotient, Remainder} !== expected) begin
                    $display("Error: %d / %d = %h %h (Expected: %h)",
                             a, b, Quotient, Remainder, expected);
                    $finish;
                end
                else
                    $display("Division Test Passed: %d / %d = Quotient: %d, Remainder: %d", a, b, Quotient, Remainder);
            end
        end
    endtask
endmodule
