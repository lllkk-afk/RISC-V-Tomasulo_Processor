`timescale 1ns / 1ps

module Adder(
    input logic clk,reset,
    input logic start,
    input logic [31:0] SrcA,
    input logic [31:0] SrcB,
    input logic [3:0] Tag_in,
    input logic [3:0] cdb_tag, // for clearing valid 
    input logic cdb_valid,
    output logic [3:0] Tag_out, // for write back reference
    output logic result_valid,
    output logic [31:0] Result,
    output logic        adder_release
    );
    
    logic result_valid_shift;
    
    assign adder_release = result_valid_shift & !result_valid;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            result_valid  <= 0;
            Result        <= 0;  
            result_valid_shift <= 0;
        end
        else begin
            if (start) begin
                Result        <= SrcA + SrcB;
                result_valid  <= 1;
            end
            
            if (result_valid && cdb_valid && (cdb_tag == Tag_in)) begin
                result_valid <= 0;
            end
            
            result_valid_shift <= result_valid;
            Tag_out    <= Tag_in;
        end
    end
    
endmodule
