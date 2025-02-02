`timescale 1ns / 1ps

module Imm_extend(
    input  logic  [31:7] instr,
    input  logic  [1 :0] immsrc,
    output logic  [31:0] immext
    );
    
    always_comb begin
        case(immsrc)
            // I-type  immediate = instr[31:20]
            2'b00:   immext = {{20{instr[31]}},instr[31:20]};
            // S-type  immediate = instr[31:25] + instr[11:7]
            2'b01:   immext = {{20{instr[31]}},instr[31:25],instr[11:7]};
            // B-type  immediate = instr[31] + instr[7] + instr[30:25] + instr[11:8] + 1'b0
            2'b10:   immext = {{20{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0}; //the first instr[30] combines into {20{instr[31]}}
            // J-type  immediate (20bits) =  instr[31] + instr[19:12] + instr[20] + instr[30:21] + 1'b0
            2'b11:   immext = {{12{instr[31]}},instr[19:12],instr[20],instr[30:21],1'b0};
            default: immext = 32'bx; 
        endcase
    end
    
endmodule
