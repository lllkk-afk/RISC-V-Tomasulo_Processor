`timescale 1ns / 1ps

typedef struct packed{
        logic [3:0]  Qi; //5+6 = 11 Qi = Tag
    } RegisterStat_t;
    
module LoadStore_unit(
    input logic clk, reset,
    input logic Load_en,
    input logic Store_en,
    input logic [4:0] rs,rt,rd,
    input logic [31:0] read_data1,
    input logic [31:0] read_data2,
    input logic [31:0] ext_imm,
    input RegisterStat_t RegStat[32],
    output logic stall,
    output logic RdTag,
    output logic [31:0] LoadAddress
    );
    
    parameter LOAD1  = 4'b0101;
    parameter LOAD2  = 4'b0110;
    parameter STORE1 = 4'b0111;
    parameter STORE2 = 4'b1000;
    
    //Data Structure
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
       
    RS_t LRS[2];
    RS_t SRS[2];
    
    logic [3:0] alloc;
    logic [1:0] Load_mask;
    logic [1:0] Store_mask;
    
    assign Load_mask = {~LRS[1].Busy,~LRS[0].Busy};
    assign Store_mask = {~SRS[1].Busy,~SRS[0].Busy};
    
    //fifo
    logic       push;
    logic       pop;
    logic [3:0] front_tag;
    
    integer i;
    always_ff @(posedge clk or posedge reset) begin
         if (reset) begin
            for (i = 0; i < 2; i++) begin
                LRS[i].Op   <= 0;
                LRS[i].Busy <= 0;
                LRS[i].Vj   <= 0;
                LRS[i].Vk   <= 0;
                LRS[i].Qj   <= 0;
                LRS[i].Qk   <= 0;
                LRS[i].Addr <= 0;
                SRS[i].Op   <= 0;
                SRS[i].Busy <= 0;
                SRS[i].Vj   <= 0;
                SRS[i].Vk   <= 0;
                SRS[i].Qj   <= 0;
                SRS[i].Qk   <= 0;
                SRS[i].Addr <= 0;
            end
            stall           <= 0; 
            LRS[0].Tag      <= LOAD1;    
            LRS[1].Tag      <= LOAD2;  
            SRS[0].Tag      <= STORE1;
            SRS[1].Tag      <= STORE2;

            push            <= 0;
            pop             <= 0;
            front_tag       <= 0;
        end
        // -------------------- Issue ------------------------
        else begin
            if (Load_en) begin
                alloc = -1;
                casez(Load_mask)
                    2'b?1: alloc = 0; 
                    2'b10: alloc = 1;
                endcase

                if (alloc == -1) begin
                    stall <= 1; 
                end 
                else begin
                    if (RegStat[rs].Qi != 0)
                        LRS[alloc].Qj <= RegStat[rs].Qi; 
                    else begin
                        LRS[alloc].Vj <= read_data1; 
                        LRS[alloc].Qj <= 0;
                    end
                
                    LRS[alloc].Addr   <= ext_imm; 
                    LRS[alloc].Busy   <= 1;
                    RdTag             <= LRS[alloc].Tag;
                
                    //push into FIFO
                    push    <= 1;
                end   
            end
            else if (Store_en) begin
                alloc = -1;
                casez(Store_mask)
                    2'b?1: alloc = 0; 
                    2'b10: alloc = 1;
                endcase
    
                if (alloc == -1) begin
                    stall <= 1; 
                end 
                else begin
                    if (RegStat[rs].Qi != 0)
                        SRS[alloc].Qj <= RegStat[rs].Qi; 
                    else begin
                        SRS[alloc].Vj <= read_data1; 
                        SRS[alloc].Qj <= 0;
                    end
                
                    if (RegStat[rt].Qi != 0)
                        SRS[alloc].Qk <= RegStat[rt].Qi; 
                    else begin
                        SRS[alloc].Vk <= read_data2; 
                        SRS[alloc].Qk <= 0;
                    end

                    SRS[alloc].Busy <= 1;
                    SRS[alloc].Addr <= ext_imm;
                    RdTag           <= SRS[alloc].Tag; 
                    push            <= 1;
                end
            end
            else begin
                push            <= 0;
                pop             <= 0;
                front_tag       <= 0;
            end
            
        // -------------------- Execute ------------------------    
            for (i = 0; i < 2; i ++)begin
                if (LRS[i].Qj == 0 & front_tag == LRS[i].Tag) begin
                    LRS[i].Addr <= LRS[i].Vj + LRS[i].Addr;
                end
            end
                      
        end
    end
    
    
    FIFO #(.FIFO_DEPTH(4), .TAG_WIDTH(4)) fifo (
        .clk(clk),
        .reset(reset),
        .push(push),
        .pop(pop),
        .push_tag(RdTag),
        .front_tag(front_tag)
    );
    
    
    
    
    
endmodule
