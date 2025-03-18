`timescale 1ns / 1ps

module Top_Nexys_tb;

    // Testbench Signals
    reg clk;
    reg btnU, btnC;
    wire [15:0] led;
    wire dp;
    wire [7:0] anode;
    wire [6:0] cathode;

    // Instantiate DUT (Device Under Test)
    Top_Nexys dut (
        .clk(clk),
        .btnU(btnU),
        .btnC(btnC),
        .led(led),
        .dp(dp),
        .anode(anode),
        .cathode(cathode)
    );

    // Clock Generation
    always #5 clk = ~clk; // 10ns clock period (100MHz)

    initial begin
        // Initialize Signals
        clk   = 0;
        btnU  = 0;
        btnC  = 0;
        
        $display("Reset Deasserted");
        
        #10000;
        // Simulate Button Press (btnU: 4Hz speed control)
        #100 btnU = 1;
        #10 btnU = 0;

        // Simulate Button Press (btnC: Pause)
        #200 btnC = 1;
        #10 btnC = 0;
        
        // Wait and Observe LED Output
        #500;
        
        // End Simulation
        $stop;
    end

    // Monitor Outputs
    initial begin
        $monitor("Time: %t | led = %b | cathode = %b | anode = %b", 
                 $time, led, cathode, anode);
    end

endmodule
