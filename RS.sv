`timescale 1ns / 1ps

module RS(
    //common//
    input logic         clk, reset,
    input logic [4:0]   rs,rt,rd,
    input logic [31:0]  read_data1,
    input logic [31:0]  read_data2,
    
    //Arithmatic
    input logic         Add_en,
    input logic         Mul_en,
    output logic        adder1_start,
    output logic        adder2_start,
    output logic        adder3_start,    
    output logic [31:0] adder1_SrcA,    
    output logic [31:0] adder2_SrcA,  
    output logic [31:0] adder3_SrcA, 
    output logic [31:0] adder1_SrcB,    
    output logic [31:0] adder2_SrcB,  
    output logic [31:0] adder3_SrcB,   
    output logic [3:0]  adder1_tag,   
    output logic [3:0]  adder2_tag,  
    output logic [3:0]  adder3_tag,  
    output logic        multi1_start,
    output logic        multi2_start,
    output logic [31:0] multi1_SrcA,    
    output logic [31:0] multi2_SrcA,  
    output logic [31:0] multi1_SrcB,    
    output logic [31:0] multi2_SrcB,  
    output logic [3:0]  multi1_tag,   
    output logic [3:0]  multi2_tag,
    output logic        A_stall,
    
    //load or store
    input logic         Load_en,
    input logic         Store_en,
    input logic [31:0]  ext_imm,
    input logic [3:0]   front_tag,
    output logic        push,
    output logic        pop,
    output logic        RdTag,
    output logic [31:0] LoadAddress,
    output logic        LS_stall,   
    
    //cdb
    input logic         cdb_valid,
    input logic [3:0]   cdb_tag
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
    
    ///////////////////////////////////////////////Arithmatic//////////////////////////////////////////////////////    
    
    RS_t ARS[3];
    RS_t MRS[2];
    
    parameter ADD1  = 4'b0000;
    parameter ADD2  = 4'b0001;
    parameter ADD3  = 4'b0010;
    parameter MUL1  = 4'b0011;
    parameter MUL2  = 4'b0100;
    
    logic [2:0] Add_mask;
    logic [1:0] Mul_mask;
    
    assign Add_mask = {~ARS[2].Busy,~ARS[1].Busy,~ARS[0].Busy};
    assign Mul_mask = {~MRS[1].Busy,~MRS[0].Busy};
    
    logic        alloc;

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
            A_stall          <= 0;  
            
            //Adder logic
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
            
            //multiplier logic
            multi1_start <= 0;
            multi2_start <= 0;
            multi1_SrcA  <= 0;
            multi2_SrcA  <= 0;
            multi1_SrcB  <= 0;
            multi2_SrcB  <= 0;
            multi1_tag   <= 0;
            multi2_tag   <= 0;
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
                    A_stall <= 1;  // RS is full, stall
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
                    A_stall <= 0;  
                end
            end
            else if (Mul_en) begin
                casez(Mul_mask)
                    2'b?1: alloc = 5;
                    2'b10: alloc = 6;
                endcase
                if (alloc == -1) begin
                    A_stall <= 1;  
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
                    A_stall <= 0;  
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
            multi1_start <= 0;
            multi2_start <= 0;
            multi1_SrcA  <= 0;
            multi2_SrcA  <= 0;
            multi1_SrcB  <= 0;
            multi2_SrcB  <= 0;
            multi1_tag   <= 0;
            multi2_tag   <= 0;
  
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
            
            //multiply 
            for (i = 0; i < 2; i++) begin
                if (MRS[i].Qj == 0 & MRS[i].Qk == 0) begin
                    case (i)
                        0: begin
                           multi1_start <= 1;
                           multi1_SrcA  <= MRS[i].Vj;
                           multi1_SrcB  <= MRS[i].Vk;             
                           end
                        1: begin
                           multi2_start <= 1;
                           multi2_SrcA  <= MRS[i].Vj;
                           multi2_SrcB  <= MRS[i].Vk;             
                           end
                    endcase
                end
            end

            
            // -------------------- Write result ------------------------    
        end
    end
    
    ///////////////////////////////////////////////Load or Store///////////////////////////////////////////////////////
    parameter LOAD1  = 4'b0101;
    parameter LOAD2  = 4'b0110;
    parameter STORE1 = 4'b0111;
    parameter STORE2 = 4'b1000;
    

    RS_t LRS[2];
    RS_t SRS[2];
    
    logic [1:0] Load_mask;
    logic [1:0] Store_mask;
    
    assign Load_mask = {~LRS[1].Busy,~LRS[0].Busy};
    assign Store_mask = {~SRS[1].Busy,~SRS[0].Busy};
    

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
            LS_stall           <= 0; 
            LRS[0].Tag      <= LOAD1;    
            LRS[1].Tag      <= LOAD2;  
            SRS[0].Tag      <= STORE1;
            SRS[1].Tag      <= STORE2;

            push            <= 0;
            pop             <= 0;
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
                    LS_stall <= 1; 
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
                    LS_stall <= 1; 
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
                push_tag       <= 0;
            end
            
        // -------------------- Execute ------------------------    
            for (i = 0; i < 2; i ++)begin
                if (LRS[i].Qj == 0 & front_tag == LRS[i].Tag) begin
                    LRS[i].Addr <= LRS[i].Vj + LRS[i].Addr;
                end
            end
                      
        end
    end
    

    
endmodule
