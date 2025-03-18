module test_sim;

    // Testbench Signals
    reg clk;
    reg reset;
    wire done;

    // Instantiate DUT (Device Under Test)
    test_top dut (
        .clk(clk),
        .reset(reset),
        .done(done)
    );

    // Clock Generation (100MHz)
    always #5 clk = ~clk; // 10ns clock period

     initial begin
    // 初始化信号
    clk = 0;
    reset = 0;
    #15
    reset = 1;
    
    // 保持复位一段时间
    #10;
    reset = 0;
  end


endmodule

/*
`timescale 1ns / 1ps

module Top_Nexys_tb;

    // Testbench Signals
    reg clk;
    reg reset;
    reg btnU, btnC;
    wire [15:0] led;
    wire dp;
    wire [7:0] anode;
    wire [6:0] cathode;  
    wire done;

    // Instantiate DUT (Device Under Test)
    Top_Nexys dut (
        .clk(clk),
        .reset(reset),
        .btnU(btnU),
        .btnC(btnC),
        .led(led),
        .dp(dp),
        .anode(anode),
        .cathode(cathode),
        .done(done)
    );

    // Clock Generation
    always #5 clk = ~clk; // 10ns clock period (100MHz)

    initial begin
        // Initialize Signals
        clk   = 0;
        btnU  = 0;
        btnC  = 0;
        reset = 0;
        
        #20
        reset = 1;
        
        #20
        reset = 0;
        $display("Reset Deasserted");
        
        #1000;
        

    end


endmodule
*/