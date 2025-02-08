`timescale 1ns / 1ps

module RegisterFile(
    input  logic        clk,
    input  logic        RegWrite,
    input  logic [ 4:0] readaddr1,
    input  logic [ 4:0] readaddr2,
    input  logic [ 4:0] Lreadaddr1,
    input  logic [ 4:0] Lreadaddr2,
    input  logic [ 4:0] writeaddr,
    input  logic [31:0] writedata,
    output logic [31:0] readdata1,
    output logic [31:0] readdata2,
    output  logic [ 31:0] Lreaddata1,
    output  logic [ 31:0] Lreaddata2
    );
    
    logic [31:0] reg_file [31:0];
    integer k;
    
    assign readdata1 = (readaddr1 != 0) ? reg_file[readaddr1] : 0;  
    assign readdata2 = (readaddr2 != 0) ? reg_file[readaddr2] : 0;
    assign Lreaddata1 = (Lreadaddr1 != 0) ? reg_file[Lreadaddr1] : 0;  
    assign Lreaddata2 = (Lreadaddr2 != 0) ? reg_file[Lreadaddr2] : 0;
    
	always_ff @(negedge clk)
	  if (RegWrite) reg_file[writeaddr] <= writedata;	 
	
endmodule
