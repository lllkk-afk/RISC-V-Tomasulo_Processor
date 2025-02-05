`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2025 02:11:21 AM
// Design Name: 
// Module Name: Tomasulo_top
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


module Tomasulo_top(
    input clk, reset
    );
    
    logic [31:0] PC, Instr;
    logic        A_stall, LS_stall;
    
    PC_logic pc_logic(
        .clk(clk),
        .reset(reset),
        .A_stall(A_stall),
        .LS_stall(LS_stall),
        .PC(PC) 
    );
    
    instr_mem i_mem(
        .addr(PC),
        .readdata(Instr)
    );
    
    Tomasulo tomasulo(
        .clk(clk), 
        .reset(reset),
        .instr(Instr),
        .A_stall(A_stall),
        .LS_stall(LS_stall)  
    );
    
endmodule
