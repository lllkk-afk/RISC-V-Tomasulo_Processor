`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2025 02:10:51 AM
// Design Name: 
// Module Name: PC_logic
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


module PC_logic(
    input logic clk,reset,
    input logic A_stall,
    input logic LS_stall,
    output logic [31:0] PC
    );
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            PC <= 0;
        end
        else begin
            PC <= (A_stall|LS_stall) ? PC : PC + 4;
        end
    end
    
endmodule
