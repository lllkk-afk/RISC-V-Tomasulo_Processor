`timescale 1ns / 1ps

module CDB (  
    input  logic        clk, reset,  // Added clk and reset
    input  logic [31:0] adder1_data, adder2_data, adder3_data,
    input  logic [3:0]  adder1_tag,  adder2_tag,  adder3_tag,
    input  logic        adder1_valid, adder2_valid, adder3_valid,
    input  logic [31:0] multi1_data_lower, multi2_data_lower,
    input  logic [31:0] multi1_data_higher, multi2_data_higher,
    input  logic [3:0]  multi1_tag,  multi2_tag,
    input  logic        multi1_valid, multi2_valid,
    input  logic [31:0] mem_data,
    input  logic [3:0]  mem_tag,
    input  logic        mem_valid,
    output logic [31:0] Data_out,
    output logic [3:0]  Tag_out,
    output logic        Data_valid
);

// Register to hold the selected result
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        Data_valid <= 0;
        Data_out   <= 32'b0;
        Tag_out    <= 4'b0;
    end 
    else begin
        // Prioritization: Adder > Multiplier > Memory
        if (adder1_valid) begin
            Data_out   <= adder1_data;
            Tag_out    <= adder1_tag;
            Data_valid <= 1;
        end 
        else if (adder2_valid) begin
            Data_out   <= adder2_data;
            Tag_out    <= adder2_tag;
            Data_valid <= 1;
        end 
        else if (adder3_valid) begin
            Data_out   <= adder3_data;
            Tag_out    <= adder3_tag;
            Data_valid <= 1;
        end 
        else if (multi1_valid) begin
            Data_out   <= multi1_data_lower; // Lower part used as default
            Tag_out    <= multi1_tag;
            Data_valid <= 1;
        end 
        else if (multi2_valid) begin
            Data_out   <= multi2_data_lower;
            Tag_out    <= multi2_tag;
            Data_valid <= 1;
        end 
        else if (mem_valid) begin
            Data_out   <= mem_data;
            Tag_out    <= mem_tag;
            Data_valid <= 1;
        end 
        else begin
            Data_valid <= 0;
            Data_out   <= 32'b0;
            Tag_out    <= 4'b0;
        end
    end
end

endmodule
