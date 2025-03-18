`timescale 1ns / 1ps

module ReservationStation(
    // Common Signals
    input  logic        clk, reset,
    input  logic [4:0]  rs, rt, rd,

    // Memory Operations
    output logic [31:0] Load1_addr, Load2_addr, Store1_addr, Store2_addr,
    output logic        Load1_valid, Load2_valid, Store1_valid, Store2_valid,
    output logic [31:0] Store1_data, Store2_data,
    output logic [3:0]  Load1_tag, Load2_tag,

    // Register File Access
    input  logic [31:0] read_data1, read_data2, Lread_data1, Lread_data2,
    output logic [4:0]  read_addr1, read_addr2, Lread_addr1, Lread_addr2,
    output logic [4:0]  Reg_writeaddr,
    output logic [31:0] Reg_writedata,
    output logic        Reg_writevalid,

    // Arithmetic Execution
    input  logic        Add_en, Mul_en, isadd, ismultiply,
    output logic        adder1_start, adder2_start, adder3_start, 
                        multi1_start, multi2_start,
    output logic [31:0] adder1_SrcA, adder2_SrcA, adder3_SrcA, 
                        adder1_SrcB, adder2_SrcB, adder3_SrcB,  
                        multi1_SrcA, multi2_SrcA, multi1_SrcB, multi2_SrcB,
    output logic [3:0]  adder1_tag, adder2_tag, adder3_tag, 
                        multi1_tag, multi2_tag,
    output logic        A_stall,
    output logic        adder1_isadd, adder2_isadd, adder3_isadd,
                        multi1_ismultiply, multi2_ismultiply,

    // Load/Store Queue Control
    input  logic        Load_en, Store_en,
    input  logic [31:0] ext_imm,
    input  logic [3:0]  front_tag,
    output logic        push, pop,
    output logic [3:0]  push_tag,
    output logic        LS_stall,

    // Common Data Bus (CDB)
    input  logic        cdb_valid,
    input  logic [3:0]  cdb_tag,
    input  logic [31:0] cdb_data,

    // Immediate Instruction Indicator
    input  logic        imminstr,
    
    //Done
    output logic        done
);
    parameter ADD1  = 4'b0001;
    parameter MUL1  = 4'b0100;
    parameter LOAD1  = 4'b0110;
    parameter STORE1 = 4'b1000;
    
    typedef struct packed {
        logic [3:0]  Tag;
        logic        Fired,Busy;
        logic        isadd,ismultiply;
        logic [31:0] Vj,Vk;
        logic [2:0]  Qj,Qk;
        logic [31:0] Addr;
    } RS_t;
    
    typedef struct packed{
        logic [3:0]  Qi; //5+4 = 9 Qi = Tag
    } RegisterStat_t;
    
    RegisterStat_t RegStat[32]; 
  
    RS_t ARS[3];
    RS_t MRS[2];
    RS_t LRS[2];
    RS_t SRS[2];
    
    logic [1:0] A_alloc,M_alloc,L_alloc,S_alloc;
    
    always_comb begin
        casez({~ARS[2].Busy,~ARS[1].Busy,~ARS[0].Busy})
            3'b??1: A_alloc = 0;
            3'b?10: A_alloc = 1;
            3'b100: A_alloc = 2;
            default: A_alloc = 3;
        endcase
        
        casez({~MRS[1].Busy,~MRS[0].Busy})
            2'b?1: M_alloc = 0;
            2'b10: M_alloc = 1;
            default: M_alloc = 3;
        endcase
        
        casez({~LRS[1].Busy,~LRS[0].Busy})
            2'b?1: L_alloc = 0; 
            2'b10: L_alloc = 1;
            default: L_alloc = 3;
        endcase
        
        casez({~SRS[1].Busy,~SRS[0].Busy})
            2'b?1: S_alloc = 0; 
            2'b10: S_alloc = 1;
            default: S_alloc = 3;
        endcase
    end

        
    assign A_stall = (Add_en && (&{ARS[0].Busy,ARS[1].Busy, ARS[2].Busy})) || (Mul_en && (&{MRS[0].Busy, MRS[1].Busy}));
    assign LS_stall = (Load_en && (&{LRS[0].Busy,LRS[1].Busy})) || (Store_en && (&{SRS[0].Busy, SRS[1].Busy}));
    
    assign read_addr1 = rs;
    assign read_addr2 = rt; 
    assign Lread_addr1 = rs;
    assign Lread_addr2 = rt;
    
    logic wasbusy,empty;
    assign empty = ({~ARS[2].Busy,~ARS[1].Busy,~ARS[0].Busy }== 3'b111) & ({~MRS[1].Busy,~MRS[0].Busy} == 2'b11) & ({~LRS[1].Busy,~LRS[0].Busy} == 2'b11) & ({~SRS[1].Busy,~SRS[0].Busy} == 2'b11);;
    
    logic cdb_active;
    always_comb begin
        cdb_active = 0;
        for (int i = 0; i < 32; i++) begin
            if (RegStat[i].Qi == cdb_tag && cdb_valid)
                cdb_active = 1;
        end
    end
    
    logic valid;
    assign valid = !((rs == 0) & (rt == 0) & (rd == 0));
    logic done_reg;

    
    //Update RegStat
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int k = 0; k < 32; k++) begin
                RegStat[k] <= '{default: '0}; 
            end 
        end
        else begin
            if (cdb_active) begin
                for (int k = 0; k < 32; k ++ ) begin
                    if (RegStat[k].Qi == cdb_tag && cdb_valid) begin
                        RegStat[k].Qi   <= 0;                  
                    end
                end
            end
            if (Add_en & A_alloc != 3) begin
                RegStat[rd].Qi <= ARS[A_alloc].Tag;   
            end
            else if (Mul_en & M_alloc != 3) begin
                RegStat[rd].Qi <= MRS[M_alloc].Tag;
            end
            else if (Load_en & L_alloc != 3) begin
                RegStat[rd].Qi <= LRS[L_alloc].Tag;
            end
        end
    end
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 3; i++) begin
                ARS[i] <= '{Tag: ADD1 + i, default: '0}; 
            end
            for (int i = 0; i < 2; i++) begin
                MRS[i] <= '{Tag: MUL1 + i, default: '0};
                LRS[i] <= '{Tag: LOAD1 + i, default: '0}; 
                SRS[i] <= '{Tag: STORE1 + i, default: '0}; 
            end
            
            // Adder logic
            { adder1_start, adder2_start, adder3_start } <= 3'b000;
            { adder1_isadd, adder2_isadd, adder3_isadd } <= 3'b000;
            { adder1_tag, adder2_tag, adder3_tag }       <= '{default: '0};
            { adder1_SrcA, adder2_SrcA, adder3_SrcA }    <= '{default: '0};
            { adder1_SrcB, adder2_SrcB, adder3_SrcB }    <= '{default: '0};

            // Multiplier logic
            { multi1_start, multi2_start }               <= 2'b00;
            { multi1_ismultiply, multi2_ismultiply }     <= 2'b00;
            { multi1_tag, multi2_tag }                   <= '{default: '0};
            { multi1_SrcA, multi2_SrcA }                 <= '{default: '0};
            { multi1_SrcB, multi2_SrcB }                 <= '{default: '0};

            // Register write logic
            Reg_writevalid <= 0;
        
            // FIFO logic
            { push, pop, push_tag }                     <= 3'b000;
        
            // Load logic
            { Load1_addr, Load2_addr, Store1_addr, Store2_addr } <= '{default: '0};
            { Load1_tag, Load2_tag } <= '{default: '0};
        
            //Store logic
            { Store1_valid, Store2_valid, Load1_valid, Load2_valid } <= 4'b0000;
            { Store1_data, Store2_data } <= '{default: '0};
            
            wasbusy                     <= 0;
            done                        <= 0;
            done_reg                    <= 0;
            Reg_writeaddr               <= '0;
            Reg_writedata               <= '0;
        end 
        
        else begin
            //Arithmatic
            { adder1_start, adder2_start, adder3_start } <= 3'b000;
            { multi1_start, multi2_start }               <= 2'b00;
            Reg_writevalid                               <= 0;
            //Load and Store
            { Store1_valid, Store2_valid }               <= 2'b0000; 
            { push, pop}                                 <= 2'b000;
            // -------------------- Issue ------------------------
            if (!empty) begin
                wasbusy                                  <= 1;
            end
            
            done_reg                                       <= wasbusy & empty;
            if (done_reg) begin // done is a sticky signal
                done <= 1;
            end
            if (Add_en & valid) begin
                if (A_alloc != 3) begin
                    if (RegStat[rs].Qi != 0)
                        ARS[A_alloc].Qj <= RegStat[rs].Qi; 
                    else begin
                        ARS[A_alloc].Vj <= read_data1;
                        ARS[A_alloc].Qj <= 0;
                    end
                    if (imminstr) begin
                        ARS[A_alloc].Vk <= ext_imm;
                        ARS[A_alloc].Qk <= 0;    
                    end
                    else begin
                        if (RegStat[rt].Qi != 0) begin// if imminstr, this one should not be checked! if (RegStat[rt].Qi != 0)
                            ARS[A_alloc].Qk <= RegStat[rt].Qi;  
                        end 
                        else begin
                            ARS[A_alloc].Vk <= read_data2;
                            ARS[A_alloc].Qk <= 0;                   
                        end
                    end         
                    ARS[A_alloc].isadd <= isadd;
                    ARS[A_alloc].Busy <= 1;
                end
            end
            else if (Mul_en & valid) begin
                if (M_alloc != 3) begin
                    if (RegStat[rs].Qi != 0)
                        MRS[M_alloc].Qj <= RegStat[rs].Qi; 
                    else begin
                        MRS[M_alloc].Vj <= read_data1;
                        MRS[M_alloc].Qj <= 0;
                    end
                    if (RegStat[rt].Qi != 0)
                        MRS[M_alloc].Qk <= RegStat[rt].Qi;  
                    else begin
                        MRS[M_alloc].Vk <= read_data2;
                        MRS[M_alloc].Qk <= 0;
                    end   
                    MRS[M_alloc].Busy <= 1;
                   
                    MRS[M_alloc].ismultiply <= ismultiply;
                end
            end 
            
            if (Load_en & valid) begin
                if (L_alloc != 3) begin                 
                    if (RegStat[rs].Qi != 0)
                        LRS[L_alloc].Qj <= RegStat[rs].Qi; 
                    else begin
                        LRS[L_alloc].Vj <= Lread_data1; 
                        LRS[L_alloc].Qj <= 0;
                    end
                
                    LRS[L_alloc].Addr   <= ext_imm; 
                    LRS[L_alloc].Busy   <= 1;
                    
                    
                    push_tag           <= LRS[L_alloc].Tag;
                    push               <= 1;
                end   
            end
            else if (Store_en & valid) begin
                if (S_alloc != 3) begin
                    if (RegStat[rs].Qi != 0)
                        SRS[S_alloc].Qj <= RegStat[rs].Qi; 
                    else begin
                        SRS[S_alloc].Vj <= Lread_data1; 
                        SRS[S_alloc].Qj <= 0;
                    end
                    
                    if (RegStat[rt].Qi != 0)
                        SRS[S_alloc].Qk <= RegStat[rt].Qi; 
                    else begin
                        SRS[S_alloc].Vk <= Lread_data2; 
                        SRS[S_alloc].Qk <= 0;
                    end

                    SRS[S_alloc].Busy <= 1;
                    SRS[S_alloc].Addr <= ext_imm;
                    push_tag         <= SRS[S_alloc].Tag; 
                    push             <= 1;
                end
            end
            // -------------------- Execute ------------------------               
           //add 
            for (int i = 0; i < 3; i ++) begin
                if (!ARS[i].Fired & ARS[i].Qj == 0 & ARS[i].Qk == 0 & ARS[i].Busy) begin
                    case(i)
                        0:begin
                            adder1_start <= 1;
                            adder1_isadd <= ARS[i].isadd;
                            ARS[i].Fired <= 1;
                            adder1_SrcA  <= ARS[i].Vj;
                            adder1_SrcB  <= ARS[i].Vk;   
                            adder1_tag   <= ARS[i].Tag;         
                          end
                        1:begin
                            adder2_start <= 1;
                            adder2_isadd <= ARS[i].isadd;
                            ARS[i].Fired <= 1;
                            adder2_SrcA  <= ARS[i].Vj;
                            adder2_SrcB  <= ARS[i].Vk;    
                            adder2_tag   <= ARS[i].Tag;         
                          end
                        2:begin
                            adder3_start <= 1;
                            adder3_isadd <= ARS[i].isadd;
                            ARS[i].Fired <= 1;
                            adder3_SrcA  <= ARS[i].Vj;
                            adder3_SrcB  <= ARS[i].Vk;    
                            adder3_tag   <= ARS[i].Tag;          
                          end
                    endcase
                           
                end
            end 
            
            //multiply 
            for (int i = 0; i < 2; i++) begin
                if (!MRS[i].Fired & MRS[i].Qj == 0 & MRS[i].Qk == 0 & MRS[i].Busy) begin
                    case (i)
                        0: begin
                           multi1_start <= 1;
                           multi1_ismultiply <= MRS[i].ismultiply;
                           multi1_SrcA  <= MRS[i].Vj;
                           multi1_SrcB  <= MRS[i].Vk;   
                           multi1_tag   <= MRS[i].Tag;      
                           MRS[i].Fired <= 1;     
                           end
                        1: begin
                           multi2_start <= 1;
                           multi2_ismultiply <= MRS[i].ismultiply;
                           multi2_SrcA  <= MRS[i].Vj;
                           multi2_SrcB  <= MRS[i].Vk;   
                           multi2_tag   <= MRS[i].Tag;   
                           MRS[i].Fired <= 1;           
                           end
                    endcase
                end
            end

           for (int j = 0; j < 2; j ++)begin
                if (!LRS[j].Fired & LRS[j].Qj == 0 & front_tag == LRS[j].Tag & LRS[j].Busy) begin
                    if (j == 0) begin
                        Load1_addr   <= LRS[j].Vj + LRS[j].Addr;  
                        Load1_valid  <= 1;  
                        Load1_tag    <= LRS[j].Tag;
                        LRS[j].Fired <= 1;                  
                    end
                    else begin
                        Load2_addr   <= LRS[j].Vj + LRS[j].Addr;
                        Load2_valid  <= 1;
                        Load2_tag    <= LRS[j].Tag; 
                        LRS[j].Fired <= 1; 
                    end
                    pop <= 1;
                end        
            end

            for (int j = 0; j < 2; j++) begin
                if (SRS[j].Qj == 0 && front_tag == SRS[j].Tag & SRS[j].Busy) begin
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
                    pop  <= 1;    
               end
            end                  
            // -------------------- Write result ------------------------    
            
            for (int i = 0; i < 32; i ++ ) begin
                if (RegStat[i].Qi == cdb_tag && cdb_valid) begin
                    Reg_writeaddr   <= i;
                    Reg_writedata   <= cdb_data;
                    Reg_writevalid  <= 1;         
                end
            end
            
            for (int i = 0; i < 3; i ++ ) begin
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
               
            for (int i = 0; i < 2; i ++ ) begin
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
            
            for (int j = 0; j < 2; j ++ ) begin
                if (LRS[j].Qj == cdb_tag && cdb_valid) begin
                    LRS[j].Vj <= cdb_data;
                    LRS[j].Qj <= 0;
                end  
                if (LRS[j].Qk == cdb_tag && cdb_valid) begin
                    LRS[j].Vk <= cdb_data;
                    LRS[j].Qk <= 0;
                end         
                if (LRS[j].Tag == cdb_tag && cdb_valid) begin
                    LRS[j].Busy <= 0;
                    LRS[j].Fired <= 0;
                    if (j == 0) begin
                        Load1_valid  <= 0;  
                    end
                    else begin
                        Load2_valid  <= 0;  
                    end
                end
            end
                
            for (int j = 0; j < 2; j ++ ) begin
                if (SRS[j].Qj == cdb_tag && cdb_valid) begin
                    SRS[j].Vj <= cdb_data;
                    SRS[j].Qj <= 0;
                end  
                if (SRS[j].Qk == cdb_tag && cdb_valid) begin
                    SRS[j].Vk <= cdb_data;
                    SRS[j].Qk <= 0;
                end         
            end
        end
     end

endmodule