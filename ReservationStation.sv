`timescale 1ns / 1ps

module ReservationStation(
    //common//
    input logic         clk, reset,
    input logic [4:0]   rs,rt,rd,
    
    //adder
    input logic         adder_release1,adder_release2,adder_release3,
    //regfile
    // I seperate into two just to avoid multi-driven problem
    input logic [31:0]  read_data1,read_data2,
    output logic [ 4:0] read_addr1,read_addr2,
    output logic [4:0]  Reg_writeaddr,
    output logic [31:0] Reg_writedata,
    output logic        Reg_writevalid,
    
    //Arithmatic
    input logic         Add_en,
    input logic         Mul_en,
    output logic        adder1_start,adder2_start,adder3_start,    
    output logic [31:0] adder1_SrcA,adder2_SrcA,adder3_SrcA, 
    output logic [31:0] adder1_SrcB,adder2_SrcB,adder3_SrcB,   
    output logic [3:0]  adder1_tag,adder2_tag,adder3_tag,  
    output logic        multi1_start,multi2_start,
    output logic [31:0] multi1_SrcA,multi2_SrcA,multi1_SrcB,multi2_SrcB,  
    output logic [3:0]  multi1_tag,multi2_tag,
    output logic        A_stall,
    
    //load or store
    input logic         Load_en,Store_en,
    input logic [31:0]  ext_imm,
    input logic [3:0]   front_tag,
    output logic        push,pop,
    output logic [3:0]  RdTag,
    output logic [31:0] Load1_addr,Load2_addr,
    output logic        Load1_valid,Load2_valid,
    output logic [31:0] Store1_addr,Store2_addr,
    output logic        Store1_valid,Store2_valid,
    output logic [31:0] Store1_data,Store2_data,
    output logic [ 3:0] Load1_tag,Load2_tag,
    output logic        LS_stall,   

    
    //cdb
    input logic         cdb_valid,
    input logic [3:0]   cdb_tag,
    input logic [31:0]  cdb_data,
    
    //imm
    input logic imminstr
    );
    
    typedef struct packed {
        logic [3:0]  Tag;
        logic        Fired;
        logic        Busy;
        logic [31:0] Vj;
        logic [31:0] Vk;
        logic [2:0]  Qj;
        logic [2:0]  Qk;
        logic [31:0] Addr;
    } RS_t;
    
    typedef struct packed{
        logic [3:0]  Qi; //5+4 = 9 Qi = Tag
    } RegisterStat_t;
    
    RegisterStat_t RegStat[32]; 
    ///////////////////////////////////////////////Arithmatic//////////////////////////////////////////////////////    
    
    RS_t ARS[3];
    RS_t MRS[2];
    
    parameter ADD1  = 4'b0001;
    parameter ADD2  = 4'b0010;
    parameter ADD3  = 4'b0011;
    parameter MUL1  = 4'b0100;
    parameter MUL2  = 4'b0101;
    
    logic [2:0] Add_mask;
    logic [1:0] Mul_mask;
    
    assign Add_mask = {~ARS[2].Busy,~ARS[1].Busy,~ARS[0].Busy};
    assign Mul_mask = {~MRS[1].Busy,~MRS[0].Busy};
    
    logic [1:0] alloc;
    
    
    assign A_stall = (Add_en && (&{ARS[0].Busy,ARS[1].Busy, ARS[2].Busy})) || 
                 (Mul_en && (&{MRS[0].Busy, MRS[1].Busy}));
    
    assign read_addr1 = rs;
    assign read_addr2 = rt;
                  
    integer i;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 3; i++) begin
                ARS[i].Busy     <= 0;
                ARS[i].Fired    <= 0;
                ARS[i].Vj       <= 0;
                ARS[i].Vk       <= 0;
                ARS[i].Qj       <= 0;
                ARS[i].Qk       <= 0;
            end
            for (i = 0; i < 2; i ++) begin
                MRS[i].Busy     <= 0;
                ARS[i].Fired    <= 0;
                MRS[i].Vj       <= 0;
                MRS[i].Vk       <= 0;
                MRS[i].Qj       <= 0;
                MRS[i].Qk       <= 0;
            end      
            ARS[0].Tag     <= ADD1;
            ARS[1].Tag     <= ADD2;
            ARS[2].Tag     <= ADD3;
            MRS[0].Tag     <= MUL1;
            MRS[1].Tag     <= MUL2;
            
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
            Reg_writevalid <= 0;            
        end 
        
        else begin

            adder1_start <= 0;
            adder2_start <= 0;
            adder3_start <= 0;
            multi1_start <= 0;
            multi2_start <= 0;
            Reg_writevalid <= 0;
            // -------------------- Issue ------------------------
            alloc = 3;
            if (Add_en) begin
                casez(Add_mask)
                    3'b??1: alloc = 0;
                    3'b?10: alloc = 1;
                    3'b100: alloc = 2;
                endcase
                
                if (alloc == 3) begin
                end 
                else begin
                    //RegStat[rs].Qi == cdb_tag && cdb_valid means RegStat is aviailable in the register, we neeed this since RegStat needs one cycle to update
                    if (RegStat[rs].Qi != 0)
                        ARS[alloc].Qj <= RegStat[rs].Qi; 
                    else begin
                        
                        ARS[alloc].Vj <= read_data1;
                        ARS[alloc].Qj <= 0;
                    end
            
                    if (RegStat[rt].Qi != 0)
                        ARS[alloc].Qk <= RegStat[rt].Qi;  
                    else begin
                        if (imminstr) begin
                            ARS[alloc].Vk <= ext_imm;
                            ARS[alloc].Qk <= 0;
                        end
                        else begin
                            ARS[alloc].Vk <= read_data2;
                            ARS[alloc].Qk <= 0;
                        end
                    end
            
                    ARS[alloc].Busy <= 1;
                    RegStat[rd].Qi <= ARS[alloc].Tag;
                end
            end
            else if (Mul_en) begin
                casez(Mul_mask)
                    2'b?1: alloc = 0;
                    2'b10: alloc = 1;
                endcase
                if (alloc == 3) begin
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
                     
                end
            end 
            
            
            // -------------------- Execute ------------------------               
           //add 
            for (i = 0; i < 3; i ++) begin
                if (!ARS[i].Fired & ARS[i].Qj == 0 & ARS[i].Qk == 0 & ARS[i].Busy) begin
                    case(i)
                        0:begin
                            adder1_start <= 1;
                            ARS[i].Fired <= 1;
                            adder1_SrcA  <= ARS[i].Vj;
                            adder1_SrcB  <= ARS[i].Vk;   
                            adder1_tag   <= ARS[i].Tag;         
                          end
                        1:begin
                            adder2_start <= 1;
                            ARS[i].Fired <= 1;
                            adder2_SrcA  <= ARS[i].Vj;
                            adder2_SrcB  <= ARS[i].Vk;    
                            adder2_tag   <= ARS[i].Tag;         
                          end
                        2:begin
                            adder3_start <= 1;
                            ARS[i].Fired <= 1;
                            adder3_SrcA  <= ARS[i].Vj;
                            adder3_SrcB  <= ARS[i].Vk;    
                            adder3_tag   <= ARS[i].Tag;          
                          end
                    endcase
                           
                end
            end 
            
            //multiply 
            for (i = 0; i < 2; i++) begin
                if (!MRS[i].Fired & MRS[i].Qj == 0 & MRS[i].Qk == 0 & MRS[i].Busy) begin
                    case (i)
                        0: begin
                           multi1_start <= 1;
                           multi1_SrcA  <= MRS[i].Vj;
                           multi1_SrcB  <= MRS[i].Vk;   
                           multi1_tag   <= MRS[i].Tag;      
                           MRS[i].Fired <= 1;     
                           end
                        1: begin
                           multi2_start <= 1;
                           multi2_SrcA  <= MRS[i].Vj;
                           multi2_SrcB  <= MRS[i].Vk;   
                           multi2_tag   <= MRS[i].Tag;   
                           MRS[i].Fired <= 1;           
                           end
                    endcase
                end
            end

           
            // -------------------- Write result ------------------------    
            
            for (i = 0; i < 32; i ++ ) begin
                if (RegStat[i].Qi == cdb_tag && cdb_valid) begin
                    Reg_writeaddr   <= i;
                    Reg_writedata   <= cdb_data;
                    Reg_writevalid  <= 1;
                    RegStat[i].Qi   <= 0;                  
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
                    ARS[i].Fired <= 0;
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
                    MRS[i].Fired <= 0;
                end       
            end
            
        end
    end
    
    ///////////////////////////////////////////////Load or Store///////////////////////////////////////////////////////
    parameter LOAD1  = 4'b0110;
    parameter LOAD2  = 4'b0111;
    parameter STORE1 = 4'b1000;
    parameter STORE2 = 4'b1001;
    

    RS_t LRS[2];
    RS_t SRS[2];
    
    logic [1:0] Load_mask;
    logic [1:0] Store_mask;
    
    assign Load_mask = {~LRS[1].Busy,~LRS[0].Busy};
    assign Store_mask = {~SRS[1].Busy,~SRS[0].Busy};
    

    integer j;
    always_ff @(posedge clk or posedge reset) begin
         if (reset) begin
            for (j = 0; j < 2; j++) begin
                LRS[j].Busy <= 0;
                LRS[j].Vj   <= 0;
                LRS[j].Vk   <= 0;
                LRS[j].Qj   <= 0;
                LRS[j].Qk   <= 0;
                LRS[j].Addr <= 0;
                SRS[j].Busy <= 0;
                SRS[j].Vj   <= 0;
                SRS[j].Vk   <= 0;
                SRS[j].Qj   <= 0;
                SRS[j].Qk   <= 0;
                SRS[j].Addr <= 0;
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
        end
        // -------------------- Issue ------------------------
       
        else begin
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
                alloc = 3;
                casez(Load_mask)
                    2'b?1: alloc = 0; 
                    2'b10: alloc = 1;
                endcase

                if (alloc == 3) begin
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
                alloc = 3;
                casez(Store_mask)
                    2'b?1: alloc = 0; 
                    2'b10: alloc = 1;
                endcase
    
                if (alloc == 3) begin
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
            end
            
        // -------------------- Execute ------------------------    
            
            for (j = 0; j < 2; j ++)begin
                if (LRS[j].Qj == 0 & front_tag == LRS[j].Tag) begin
                    if (j == 0) begin
                        Load1_addr   <= LRS[j].Vj + LRS[j].Addr;  
                        Load1_valid  <= 1;  
                        Load1_tag    <= LRS[j].Tag;                      
                    end
                    else begin
                        Load2_addr   <= LRS[j].Vj + LRS[j].Addr;
                        Load2_valid  <= 1;
                        Load2_tag    <= LRS[j].Tag;  
                    end
                end
            end
            
            // both execute and write for store
            for (j = 0; j < 2; j++) begin
                if (SRS[j].Qj == 0 && SRS[j].Qk == 0 && front_tag == SRS[j].Tag) begin
                    if (j == 0) begin
                        Store1_addr  <= SRS[j].Vj + SRS[j].Addr; 
                        Store1_data  <= SRS[j].Vk;
                        Store1_valid <= 1; 
                        SRS[j].Busy  <= 0;
                    end
                    else begin
                        Store2_addr  <= SRS[j].Vj + SRS[j].Addr; 
                        Store2_data  <= SRS[j].Vk;
                        Store2_valid <= 1;  
                        SRS[j].Busy  <= 0;
                    end
               end
            end                  
        end
    end
    

    
endmodule