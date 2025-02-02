`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/31/2025 10:11:26 PM
// Design Name: 
// Module Name: Controllogic
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


module Controllogic(
    input  logic [31:0] Instr,
    output logic [3:0] Op,
    output logic [2:0] ALUControl
    );
    
    //Instr
    logic [6:0]   opcode;
    logic [14:12] funct3;
    logic         funct7b5;
    logic         op5;
    assign opcode   = Instr[6:0];
    assign funct    = Instr[14:12];
    assign funct7b5 = Instr[30];
    assign op5      = Instr[5];
    
    logic [5:0] controls;
    logic [1:0] ALUOp;
    logic       Load,Store,Arithmatic;
    assign {ALUOp,Op} = controls;

    always_comb begin
        controls = 6'b0;
        case(opcode) 
            7'b0000011: controls = 11'b1_00_1_0_01_0_00_0; //lw
            7'b0100011: controls = 11'b0_01_1_1_xx_0_00_0; //sw
            7'b0110011: controls = 11'b1_xx_0_0_00_0_10_0; //R-type
            7'b1100011: controls = 11'b0_10_0_0_xx_1_01_0; //beq
            7'b0010011: controls = 11'b1_00_1_0_00_0_10_0; //I-type ALU
            7'b1101111: controls = 11'b1_11_x_0_10_0_xx_1; //jal
            default   : controls = 11'b0_00_0_0_00_0_00_0; 
        endcase
    end
    
    //if Op[5] => Arithmatic Instruction
    logic  Rtypesub;
    assign Rtypesub = op5 & funct7b5;

    always_comb begin
        case(ALUOp)
            2'b00:   ALUControl = 3'b000;  //ADD
            2'b01:   ALUControl = 3'b001;  //SUB
            default: case(funct3)
                       3'b000:     if (Rtypesub) ALUControl = 3'b001; else  ALUControl = 3'b000; 
                       3'b010:     ALUControl = 3'b101; //SLT
                       3'b110:     ALUControl = 3'b011; // OR
                       3'b111:     ALUControl = 3'b010; //AND
                       default:    ALUControl = 3'bx;
                     endcase
            endcase
    end

    

endmodule
