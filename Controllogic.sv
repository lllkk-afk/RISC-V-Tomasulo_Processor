`timescale 1ns / 1ps

module Controllogic(
    input  logic [31:0] Instr,
    output logic [2:0] ALUControl,
    output logic [1:0] ImmSrc,
    output logic Load_en, Store_en, Add_en, Multiply_en
    );
    
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7b5;
    logic       op5;
    logic [6:0] funct7;

    assign opcode   = Instr[6:0];
    assign funct3   = Instr[14:12];
    assign funct7b5 = Instr[30];
    assign op5      = Instr[5];
    assign funct7b0 = Instr[25];

    logic [10:0] controls;  
    logic [1:0] ALUOp;

    always_comb begin
        // 默认所有信号无效
        controls = 10'b0;
        Load_en = 0;
        Store_en = 0;
        Add_en = 0;
        Multiply_en = 0;

        case(opcode) 
            7'b0000011: begin  // lw (Load)
                ALUOp = 2'b00;
                ImmSrc = 2'b00;
                Load_en = 1;
            end

            7'b0100011: begin  // sw (Store)
                ALUOp = 2'b00;
                ImmSrc = 2'b01;
                Store_en = 1;
            end

            7'b0110011: begin  // R-type (Arith)
                ALUOp = 2'b10;
                ImmSrc = 2'bxx;
            end

            7'b1100011: begin  // beq (Branch)
                ALUOp = 2'b01;
                ImmSrc = 2'b10;
            end

            7'b0010011: begin  // I-type ALU
                ALUOp = 2'b10;
                ImmSrc = 2'b00;
            end

            7'b1101111: begin  // jal
                ALUOp = 2'bxx;
                ImmSrc = 2'b11;
            end
            
            default: begin
                ALUOp = 2'b00;
                ImmSrc = 2'b00;
            end
        endcase
    end

    logic Rtypesub;
    assign Rtypesub = op5 & funct7b5;

    always_comb begin
        Add_en = 0;
        Multiply_en = 0;

        case(ALUOp)
            2'b00:   ALUControl = 3'b000;  // ADD (用于 Load/Store)
            2'b01:   ALUControl = 3'b001;  // SUB (用于 Branch)
            default: case(funct3)
                3'b000: begin 
                    if (Rtypesub) begin
                        ALUControl = 3'b001; // SUB
                        Add_en = 1; 
                    end
                    else if (funct7b0) begin
                        ALUControl  = 3'b110; // MUL
                        Multiply_en = 1;
                    end
                    else begin
                        ALUControl = 3'b000; // ADD
                        Add_en = 1; 
                    end
                end
                3'b010: ALUControl = 3'b101; // SLT
                3'b110: ALUControl = 3'b011; // OR
                3'b111: ALUControl = 3'b010; // AND
                default: ALUControl = 3'bx;
            endcase
        endcase

       
    end

endmodule
