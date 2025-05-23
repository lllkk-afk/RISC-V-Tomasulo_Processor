`timescale 1ns / 1ps

module Controllogic(
    input  logic [31:0] Instr,
    output logic [1:0] ImmSrc,
    output logic       Imminstr, // whether this is immediate instruction
    output logic Load_en, Store_en, Add_en, Multiply_en,
    output logic ismultiply,
    output logic isadd
    );
    
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7b5;
    logic       op5;
    logic [6:0] funct7;
    logic       funct7b0;

    assign opcode   = Instr[6:0];
    assign funct3   = Instr[14:12];
    assign funct7b5 = Instr[30];
    assign op5      = Instr[5];
    assign funct7b0 = Instr[25];

    logic [1:0] ALUOp;

    always_comb begin
        Load_en = 0;
        Store_en = 0;
        Imminstr = 0;
        

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
                ALUOp = 2'b11;
                ImmSrc = 2'b00;
                Imminstr = 1;
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
        ismultiply = 0;
        isadd      = 0;

        case(ALUOp)
            default: case(funct3)
                3'b000: begin 
                    if (Rtypesub) begin //SUB
                        Add_en = 1; 
                        isadd      = 0;
                    end
                    else if (funct7b0 & ALUOp ==2'b10) begin //MUL
                        Multiply_en = 1;
                        ismultiply = 1;
                    end
                    else begin  //ADD
                        Add_en = 1; 
                        isadd      = 1;
                    end
                end
                3'b100: begin                //DIV
                        Multiply_en = 1;
                        ismultiply = 0;
                        end 
            endcase
        endcase

       
    end

endmodule
