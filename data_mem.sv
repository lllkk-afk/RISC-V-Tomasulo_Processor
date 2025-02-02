`timescale 1ns / 1ps


module data_mem(
    input  logic        clk,we,
    input  logic [31:0] addr, writedata,
    output logic [31:0] readdata
    );
    
    logic [31:0] RAM[63:0];
    assign readdata = RAM[addr[31:2]]; //the last two bits are byte offset
    
    always_ff @(posedge clk)
        if (we) RAM[addr[31:2]] <= writedata;
        
 endmodule