`timescale 1ns / 1ps

module Arithmatic_unit(
    input logic clk, reset,
    input logic Add_en,
    input logic Mul_en,
    input logic [4:0] rs,rt,rd,
    input logic [31:0] read_data1,
    input logic [31:0] read_data2,
    input RegisterStat_t RegStat[32],
    input logic adder1_cdb_tag,
    input logic adder2_cdb_tag,
    input logic adder3_cdb_tag,
    output logic [31:0] adder1_result,
    output logic [31:0] adder2_result,
    output logic [31:0] adder3_result,
    output logic adder1_result_valid,
    output logic adder2_result_valid,
    output logic adder3_result_valid
    );
    
    
    typedef struct packed {
        logic [3:0]  Tag;
        logic [3:0]  Op;
        logic        Busy;
        logic [31:0] Vj;
        logic [31:0] Vk;
        logic [2:0]  Qj;
        logic [2:0]  Qk;
        logic [31:0] Addr;
    } RS_t;
    
    RS_t ARS[3];
    RS_t MRS[2];
    
    parameter ADD1  = 4'b0000;
    parameter ADD2  = 4'b0001;
    parameter ADD3  = 4'b0010;
    parameter MUL1  = 4'b0011;
    parameter MUL2  = 4'b0100;
    
    logic [2:0] Add_mask;
    logic [1:0] Mul_mask;
    logic       stall;
    
    assign Add_mask = {~ARS[2].Busy,~ARS[1].Busy,~ARS[0].Busy};
    assign Mul_mask = {~MRS[1].Busy,~MRS[0].Busy};
    
    logic        alloc;
    logic        adder1_start;
    logic        adder2_start;
    logic        adder3_start;    
    logic [31:0] adder1_SrcA;    
    logic [31:0] adder2_SrcA;  
    logic [31:0] adder3_SrcA; 
    logic [31:0] adder1_SrcB;    
    logic [31:0] adder2_SrcB;  
    logic [31:0] adder3_SrcB;   
    logic [31:0] adder1_tag;    
    logic [31:0] adder2_tag;  
    logic [31:0] adder3_tag;  

    integer i;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 3; i++) begin
                ARS[i].Op       <= 0;
                ARS[i].Busy     <= 0;
                ARS[i].Vj       <= 0;
                ARS[i].Vk       <= 0;
                ARS[i].Qj       <= 0;
                ARS[i].Qk       <= 0;
            end
            for (i = 0; i < 2; i ++) begin
                MRS[i].Op   <= 0;
                MRS[i].Busy <= 0;
                MRS[i].Vj   <= 0;
                MRS[i].Vk   <= 0;
                MRS[i].Qj   <= 0;
                MRS[i].Qk   <= 0;
            end      
            ARS[0].Tag     <= ADD1;
            ARS[1].Tag     <= ADD2;
            ARS[2].Tag     <= ADD3;
            MRS[0].Tag     <= MUL1;
            MRS[1].Tag     <= MUL2;
            stall          <= 0;  
            
            //Adder logic
            // 清零 Adder 相关信号
            adder1_start <= 0;
            adder2_start <= 0;
            adder3_start <= 0;
        
            adder1_SrcA  <= 0;
            adder2_SrcA  <= 0;
            adder3_SrcA  <= 0;
        
            adder1_SrcB  <= 0;
            adder2_SrcB  <= 0;
            adder3_SrcB  <= 0;
        
            adder1_tag   <= 0;
            adder2_tag   <= 0;
            adder3_tag   <= 0;
            
            adder1_result   <= 0;
            adder2_result   <= 0;
            adder3_result   <= 0;
        end 
        else begin
            // -------------------- Issue ------------------------
            alloc = -1;
            if (Add_en) begin
                casez(Add_mask)
                    3'b??1: alloc = 2;
                    3'b?10: alloc = 3;
                    3'b100: alloc = 4;
                endcase
                
                if (alloc == -1) begin
                    stall <= 1;  // RS is full, stall
                end 
                else begin
                    if (RegStat[rs].Qi != 0)
                        ARS[alloc].Qj <= RegStat[rs].Qi; 
                    else begin
                        ARS[alloc].Vj <= read_data1;
                        ARS[alloc].Qj <= 0;
                    end
            
                    if (RegStat[rt].Qi != 0)
                        ARS[alloc].Qk <= RegStat[rt].Qi;  
                    else begin
                        ARS[alloc].Vk <= read_data2;
                        ARS[alloc].Qk <= 0;
                    end
            
                    ARS[alloc].Busy <= 1;
                    RegStat[rd].Qi <= ARS[alloc].Tag;
                    stall <= 0;  
                end
            end
            else if (Mul_en) begin
                casez(Mul_mask)
                    2'b?1: alloc = 5;
                    2'b10: alloc = 6;
                endcase
                if (alloc == -1) begin
                    stall <= 1;  
                end 
                else begin
                    if (RegStat[rs].Qi != 0)
                        MRS[alloc].Qj <= RegStat[rs].Qi; 
                    else begin
                        MRS[alloc].Vj <= read_data1;
                        MRS[alloc].Qj <= 0;
                    end
            
                    if (RegStat[rt].Qi != 0)
                        MRS[alloc].Qk <= RegStat[rt].Qi;  
                    else begin
                        MRS[alloc].Vk <= read_data2;
                        MRS[alloc].Qk <= 0;
                    end
            
                    MRS[alloc].Busy <= 1;
                    RegStat[rd].Qi <= MRS[alloc].Tag;
                    stall <= 0;  
                end
            end 
            
            
            // -------------------- Execute ------------------------    
            adder1_start <= 0;
            adder2_start <= 0;
            adder3_start <= 0;
        
            adder1_SrcA  <= 0;
            adder2_SrcA  <= 0;
            adder3_SrcA  <= 0;
        
            adder1_SrcB  <= 0;
            adder2_SrcB  <= 0;
            adder3_SrcB  <= 0;
        
            adder1_tag   <= 0;
            adder2_tag   <= 0;
            adder3_tag   <= 0;
            
            adder1_result   <= 0;
            adder2_result   <= 0;
            adder3_result   <= 0;
                     
            //add
            for (i = 0; i < 3; i ++) begin
                if (ARS[i].Qj == 0 & ARS[i].Qk == 0 ) begin
                    case(i)
                        0:begin
                            adder1_start <= 1;
                            adder1_SrcA  <= ARS[i].Vj;
                            adder1_SrcB  <= ARS[i].Vk;             
                          end
                        1:begin
                            adder2_start <= 1;
                            adder2_SrcA  <= ARS[i].Vj;
                            adder2_SrcB  <= ARS[i].Vk;             
                          end
                        2:begin
                            adder3_start <= 1;
                            adder3_SrcA  <= ARS[i].Vj;
                            adder3_SrcB  <= ARS[i].Vk;             
                          end
                    endcase
                           
                end
            end 
        end
    end
    
    
    Adder adder1(
        .clk(clk),
        .reset(reset),
        .start(adder1_start),
        .SrcA(adder1_SrcA),
        .SrcB(adder1_SrcB),
        .Tag_in(adder1_tag),
        .cdb_tag(adder1_cdb_tag),
        .result_valid(adder1_result_valid),
        .Result(adder1_result)
    );
    
    Adder adder2(
        .clk(clk),
        .reset(reset),
        .start(adder2_start),
        .SrcA(adder2_SrcA),
        .SrcB(adder2_SrcB),
        .Tag_in(adder2_tag),
        .cdb_tag(adder2_cdb_tag),
        .result_valid(adder2_result_valid),
        .Result(adder2_result)
    );
   
    Adder adder3(
        .clk(clk),
        .reset(reset),
        .start(adder3_start),
        .SrcA(adder3_SrcA),
        .SrcB(adder3_SrcB),
        .Tag_in(adder3_tag),
        .cdb_tag(adder3_cdb_tag),
        .result_valid(adder3_result_valid),
        .Result(adder3_result)
    );
    


   
    
endmodule
