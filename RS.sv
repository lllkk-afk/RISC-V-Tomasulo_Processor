`timescale 1ns / 1ps

module RS(
    //common//
    input logic         clk, reset,
    input logic [4:0]   rs,rt,rd,
    
    //regfile
    // I seperate into two just to avoid multi-driven problem
    input logic [31:0]  Aread_data1,
    input logic [31:0]  Aread_data2,
    output logic [ 4:0] Aread_addr1,
    output logic [ 4:0] Aread_addr2,
    output logic        Aread_valid1,
    output logic        Aread_valid2,
    input logic [31:0]  Lread_data1,
    input logic [31:0]  Lread_data2,
    output logic [ 4:0] Lread_addr1,
    output logic [ 4:0] Lread_addr2,
    output logic        Lread_valid1,
    output logic        Lread_valid2,
    output logic [4:0]  Reg_writeaddr,
    output logic [31:0] Reg_writedata,
    output logic        Reg_writevalid,
    
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
    output logic [31:0] Load1_addr,
    output logic [31:0] Load2_addr,
    output logic        Load1_valid,
    output logic        Load2_valid,
    output logic [31:0] Store1_addr,
    output logic [31:0] Store2_addr,
    output logic        Store1_valid,
    output logic        Store2_valid,
    output logic [31:0] Store1_data,
    output logic [31:0] Store2_data,
    output logic [ 3:0] Load1_tag,
    output logic [ 3:0] Load2_tag,
    output logic        LS_stall,   

    
    //cdb
    input logic         cdb_valid,
    input logic [3:0]   cdb_tag,
    input logic [31:0]  cdb_data
    );
    
    typedef struct packed {
        logic [3:0]  Tag;
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
                ARS[i].Busy     <= 0;
                ARS[i].Vj       <= 0;
                ARS[i].Vk       <= 0;
                ARS[i].Qj       <= 0;
                ARS[i].Qk       <= 0;
            end
            for (i = 0; i < 2; i ++) begin
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
            
            Reg_writeaddr <= 0;
            Reg_writedata <= 0;
            Reg_writevalid <= 0;
            
            Aread_addr1  <= 0;
            Aread_addr2  <= 0;
            Aread_valid1  <= 0;
            Aread_valid2  <= 0;
        end 
        
        else begin
            Aread_addr1  <= 0;
            Aread_addr2  <= 0;
            Aread_valid1  <= 0;
            Aread_valid2  <= 0;
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
            Reg_writeaddr <= 0;
            Reg_writedata <= 0;
            Reg_writevalid <= 0;
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
                        Aread_addr1    <= rs;
                        ARS[alloc].Vj <= Aread_data1;
                        ARS[alloc].Qj <= 0;
                    end
            
                    if (RegStat[rt].Qi != 0)
                        ARS[alloc].Qk <= RegStat[rt].Qi;  
                    else begin
                        Aread_addr2    <= rt;
                        ARS[alloc].Vk <= Aread_data2;
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
                        Aread_addr1    <= rs;
                        Aread_valid1   <= 1;
                        MRS[alloc].Vj <= Aread_data1;
                        MRS[alloc].Qj <= 0;
                    end
            
                    if (RegStat[rt].Qi != 0)
                        MRS[alloc].Qk <= RegStat[rt].Qi;  
                    else begin
                        Aread_addr2    <= rt;
                        Aread_valid2   <= 1;
                        MRS[alloc].Vk <= Aread_data2;
                        MRS[alloc].Qk <= 0;
                    end
            
                    MRS[alloc].Busy <= 1;
                    RegStat[rd].Qi <= MRS[alloc].Tag;
                    A_stall <= 0;  
                end
            end 
            
            
            // -------------------- Execute ------------------------               
           //add 
            for (i = 0; i < 3; i ++) begin
                if (ARS[i].Qj == 0 & ARS[i].Qk == 0 ) begin
                    case(i)
                        0:begin
                            adder1_start <= 1;
                            adder1_SrcA  <= ARS[i].Vj;
                            adder1_SrcB  <= ARS[i].Vk;   
                            adder1_tag   <= ARS[i].Tag;            
                          end
                        1:begin
                            adder2_start <= 1;
                            adder2_SrcA  <= ARS[i].Vj;
                            adder2_SrcB  <= ARS[i].Vk;    
                            adder2_tag   <= ARS[i].Tag;          
                          end
                        2:begin
                            adder3_start <= 1;
                            adder3_SrcA  <= ARS[i].Vj;
                            adder3_SrcB  <= ARS[i].Vk;    
                            adder3_tag   <= ARS[i].Tag;          
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
                           multi1_tag   <= MRS[i].Tag;           
                           end
                        1: begin
                           multi2_start <= 1;
                           multi2_SrcA  <= MRS[i].Vj;
                           multi2_SrcB  <= MRS[i].Vk;   
                           multi2_tag   <= MRS[i].Tag;              
                           end
                    endcase
                end
            end

            
            // -------------------- Write result ------------------------    
            
            for (i = 0; i < 32; i ++ ) begin
                if (RegStat[i].Qi == cdb_tag && cdb_valid) begin
                    Reg_writeaddr <= i;
                    Reg_writedata <= cdb_data;
                    Reg_writevalid <= 1;
                    RegStat[i].Qi <= 0;
                end
            end
            
            for (i = 0; i < 3; i ++ ) begin
                if (ARS[i].Qj == cdb_tag && cdb_valid) begin
                    ARS[i].Vj <= cdb_data;
                    ARS[i].Qj <= 0;
                end  
                if (ARS[i].Qk == cdb_tag && cdb_valid) begin
                    ARS[i].Vk <= cdb_data;
                    ARS[i].Qk <= 0;
                end         
                if (ARS[i].Tag == cdb_tag && cdb_valid) begin
                    ARS[i].Busy <= 0;
                end
            end
            
            for (i = 0; i < 2; i ++ ) begin
                if (MRS[i].Qj == cdb_tag && cdb_valid) begin
                    MRS[i].Vj <= cdb_data;
                    MRS[i].Qj <= 0;
                end  
                if (MRS[i].Qk == cdb_tag && cdb_valid) begin
                    MRS[i].Vk <= cdb_data;
                    MRS[i].Qk <= 0;
                end  
                if (MRS[i].Tag == cdb_tag && cdb_valid) begin
                    MRS[i].Busy <= 0;
                end       
            end
            
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
                LRS[i].Busy <= 0;
                LRS[i].Vj   <= 0;
                LRS[i].Vk   <= 0;
                LRS[i].Qj   <= 0;
                LRS[i].Qk   <= 0;
                LRS[i].Addr <= 0;
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
            
            Load1_addr   <= 0;
            Load2_addr   <= 0;
            Load1_valid  <= 0;
            Load2_valid  <= 0;
            Store1_addr  <= 0;
            Store2_addr  <= 0;
            Store1_valid <= 0;
            Store2_valid <= 0;
            Store1_data  <= 0;
            Store2_data  <= 0;
            Lread_addr1  <= 0;
            Lread_addr2  <= 0;
            Lread_valid1  <= 0;
            Lread_valid2  <= 0;
        end
        // -------------------- Issue ------------------------
       
        else begin
            Lread_addr1  <= 0;
            Lread_addr2  <= 0;
            Lread_valid1  <= 0;
            Lread_valid2  <= 0;
            Load1_addr   <= 0;
            Load2_addr   <= 0;
            Load1_valid  <= 0;
            Load2_valid  <= 0;
            Store1_addr  <= 0;
            Store2_addr  <= 0;
            Store1_valid <= 0;
            Store2_valid <= 0;
            Store1_data  <= 0;
            Store2_data  <= 0;
            
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
                        Lread_addr1   <= rs;
                        LRS[alloc].Vj <= Lread_data1; 
                        Lread_valid1  <= 1;
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
                        Lread_addr1   <= rs;
                        Lread_valid1  <= 1;
                        SRS[alloc].Vj <= Lread_data1; 
                        SRS[alloc].Qj <= 0;
                    end
                
                    if (RegStat[rt].Qi != 0)
                        SRS[alloc].Qk <= RegStat[rt].Qi; 
                    else begin
                        Lread_addr2   <= rt;
                        Lread_valid2  <= 1;
                        SRS[alloc].Vk <= Lread_data2; 
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
            end
            
        // -------------------- Execute ------------------------    
            
            for (i = 0; i < 2; i ++)begin
                if (LRS[i].Qj == 0 & front_tag == LRS[i].Tag) begin
                    if (i == 0) begin
                        Load1_addr   <= LRS[i].Vj + LRS[i].Addr;  
                        Load1_valid  <= 1;  
                        Load1_tag    <= LRS[i].Tag;                      
                    end
                    else begin
                        Load2_addr   <= LRS[i].Vj + LRS[i].Addr;
                        Load2_valid  <= 1;
                        Load2_tag    <= LRS[i].Tag;  
                    end
                end
            end
            
            // both execute and write for store
            for (i = 0; i < 2; i++) begin
                if (SRS[i].Qj == 0 && SRS[i].Qk == 0 && front_tag == SRS[i].Tag) begin
                    if (i == 0) begin
                        Store1_addr  <= SRS[i].Vj + SRS[i].Addr; 
                        Store1_data  <= SRS[i].Vk;
                        Store1_valid <= 1; 
                        SRS[i].Busy  <= 0;
                    end
                    else begin
                        Store2_addr  <= SRS[i].Vj + SRS[i].Addr; 
                        Store2_data  <= SRS[i].Vk;
                        Store2_valid <= 1;  
                        SRS[i].Busy  <= 0;
                    end
               end
            end                  
        end
    end
    

    
endmodule
