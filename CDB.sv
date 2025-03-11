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
    input  logic        mulvalid1, divvalid1,mulvalid2,divvalid2,
    input  logic [31:0] mem_data1,mem_data2,
    input  logic [3:0]  mem_tag,
    input  logic        mem_valid1,mem_valid2,
    input  logic [31:0] Quotient1,Quotient2,Remainder1,Remainder2,
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
        // only one cycle
        if (Data_valid == 1) begin
            Data_valid <= 0;
        end
        // Prioritization: Adder > Multiplier > Memory
        else if (adder1_valid) begin
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
            if (mulvalid1) begin
                Data_out   <= multi1_data_lower; // Lower part used as default
                Tag_out    <= multi1_tag;
                Data_valid <= 1;
            end 
            else begin 
                Data_out   <= Quotient1; // Lower part used as default
                Tag_out    <= multi1_tag;
                Data_valid <= 1;
            end
        end 
        else if (multi2_valid) begin
            if (mulvalid2) begin
                Data_out   <= multi2_data_lower; // Lower part used as default
                Tag_out    <= multi2_tag;
                Data_valid <= 1;
            end 
            else begin 
                Data_out   <= Quotient2; // Lower part used as default
                Tag_out    <= multi2_tag;
                Data_valid <= 1;
            end
        end 
        else if (mem_valid1) begin
            Data_out   <= mem_data1;
            Tag_out    <= mem_tag;
            Data_valid <= 1;
        end 
        else if (mem_valid2) begin
            Data_out   <= mem_data2;
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
