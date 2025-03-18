`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/18/2025 10:51:36 PM
// Design Name: 
// Module Name: test_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module test_top(
    input  logic         clk,        // fundamental clock 1MHz
    input  logic         reset,
    output logic         done
);

  Tomasulo_top tomasulo_top(
      .clk(clk),
      .reset(reset),
      .reg_addr(),
      .reg_data(),
      .done(done)
    );
    
endmodule
