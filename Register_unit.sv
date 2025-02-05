`timescale 1ns / 1ps


module Register_unit(
    input  logic clk,
    output logic [31:0]  Aread_data1,
    output logic [31:0]  Aread_data2,
    input  logic [ 4:0]  Aread_addr1,
    input  logic [ 4:0]  Aread_addr2,
    output logic [31:0]  Lread_data1,
    output logic [31:0]  Lread_data2,
    input  logic [ 4:0]  Lread_addr1,
    input  logic [ 4:0]  Lread_addr2,
    input  logic         Lread_valid1,
    input  logic         Lread_valid2,
    input  logic [ 4:0]  Reg_writeaddr,
    input  logic [31:0]  Reg_writedata,
    input  logic         Reg_writevalid 
    );
    
    logic RegWrite;
    logic [ 4:0] readaddr1,readaddr2,writeaddr;
    logic [31:0] writedata, readdata1,readdata2;
    
    always_comb begin
        RegWrite = 0;
        Aread_data1 = 0;
        Aread_data2 = 0;
        Lread_data1 = 0;
        Lread_data2 = 0;

        if (Reg_writevalid) begin
            RegWrite = 1;
            writeaddr = Reg_writeaddr;
            writedata = Reg_writedata;
        end
    
    end
    
    
    
    RegisterFile rf(
        .clk(clk),
        .RegWrite(RegWrite),
        .readaddr1(readaddr1),
        .readaddr2(readaddr2),
        .writeaddr(writeaddr),
        .writedata(writedata),
        .readdata1(readdata1),
        .readdata2(readdata2)
    );
endmodule
