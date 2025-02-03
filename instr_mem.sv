`timescale 1ns / 1ps

module instr_mem(
    input  logic [31:0] addr,
    output logic [31:0] readdata
    );
    
    logic [31:0] RAM[63:0];
    initial
       $readmemh("riscvtest.mem",RAM);
    assign readdata = RAM[addr[31:2]]; 
endmodule
