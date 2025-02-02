`timescale 1ns / 1ps

module Tomasulo(
    input logic clk, reset,
    input logic [31:0] instr  
    );
    
    typedef struct packed{
        logic [3:0]  Qi; //5+4 = 9 Qi = Tag
    } RegisterStat_t;
    
    logic [19:15] rs;
    logic [24:20] rt;
    logic [11:7]  rd;
    assign rs = instr[19:15];
    assign rt = instr[24:20];
    assign rd = instr[11:7];
    
    //adder
    logic adder1_start, adder2_start, adder3_start;
    logic [31:0] adder1_SrcA, adder2_SrcA, adder3_SrcA;
    logic [31:0] adder1_SrcB, adder2_SrcB, adder3_SrcB;
    logic [3:0] adder1_tag, adder2_tag, adder3_tag;
    logic [3:0] adder_cdb_tag;
    logic adder1_result_valid, adder2_result_valid, adder3_result_valid;
    logic [31:0] adder1_result, adder2_result, adder3_result;
    logic A_stall,LS_stall;
    
    //multiplier
    logic multi1_start, multi2_start;
    logic [31:0] multi1_SrcA, multi2_SrcA;
    logic [31:0] multi1_SrcB, multi2_SrcB;
    logic [3:0] multi1_tag, multi2_tag;


    //cdb
    logic cdb_valid;
    logic [3:0] cdb_tag;
    
    //fifo
    logic push,pop;
    logic [3:0] front_tag,RdTag;
    
    //Imm_ext
    logic [31:0] immext;
    
    CDB cdb(  
        .adder1_data(adder1_result),
        .adder2_data(adder2_result),
        .adder3_data(adder3_result),
        .adder1_tag(adder1_tag),
        .adder2_tag(adder2_tag),
        .adder3_tag(adder3_tag),
        .adder1_valid(adder1_result_valid),
        .adder2_valid(adder2_result_valid),
        .adder3_valid(adder3_result_valid),
        .multi1_data(),
        .multi2_data(),
        .multi1_tag(),
        .multi2_tag(),
        .multi1_valid(),
        .multi2_valid(),
        .mem_data(),
        .mem_tag(),
        .mem_valid(),
        .Data_out(),
        .Tag_out(adder_cdb_tag),
        .Data_valid(cdb_valid)
    );

    RS rs_inst (
        // Common
        .clk(clk),
        .reset(reset),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .read_data1(),
        .read_data2(),

        // Arithmetic
        .Add_en(),
        .Mul_en(),
        .adder1_start(adder1_start),
        .adder2_start(adder2_start),
        .adder3_start(adder3_start),
        .adder1_SrcA(adder1_SrcA),
        .adder2_SrcA(adder2_SrcA),
        .adder3_SrcA(adder3_SrcA),
        .adder1_SrcB(adder1_SrcB),
        .adder2_SrcB(adder2_SrcB),
        .adder3_SrcB(adder3_SrcB),
        .adder1_tag(adder1_tag),
        .adder2_tag(adder2_tag),
        .adder3_tag(adder3_tag),
        .multi1_start(multi1_start),
        .multi2_start(multi2_start),
        .multi1_SrcA(multi1_SrcA),
        .multi2_SrcA(multi2_SrcA),
        .multi1_SrcB(multi1_SrcB),
        .multi2_SrcB(multi2_SrcB),
        .multi1_tag(multi1_tag),
        .multi2_tag(multi2_tag),
        .A_stall(A_stall),

        // Load or Store
        .Load_en(),
        .Store_en(),
        .ext_imm(),
        .front_tag(front_tag),
        .push(push),
        .pop(pop),
        .RdTag(RdTag),
        .LoadAddress(),
        .LS_stall(LS_stall),
        
        //cdb
        .cdb_valid(cdb_valid),
        .cdb_tag(cdb_tag)
    );
    
    FIFO #(.FIFO_DEPTH(4), .TAG_WIDTH(4)) fifo (
        .clk(clk),
        .reset(reset),
        .push(push),
        .pop(pop),
        .push_tag(RdTag),
        .front_tag(front_tag)
    );
    
    Adder adder1(
        .clk(clk),
        .reset(reset),
        .start(adder1_start),
        .SrcA(adder1_SrcA),
        .SrcB(adder1_SrcB),
        .Tag_in(adder1_tag),
        .cdb_tag(adder_cdb_tag),
        .cdb_valid(cdb_valid),
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
        .cdb_tag(adder_cdb_tag),
        .cdb_valid(cdb_valid),
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
        .cdb_tag(adder_cdb_tag),
        .cdb_valid(cdb_valid),
        .result_valid(adder3_result_valid),
        .Result(adder3_result)
    );
    
    Multiplier mul1(
    
    
    );
    
    Multiplier mul2(
    
    
    );
    
    Address_unit addr_unit(
    
    );
    
    Controllogic conlogic(
    
    );
    
    data_mem dmem(
        .clk(clk),
        .we(),
        .addr(), 
        .writedata(),
        .readdata()
    );
    
    RegisterFile rf(
        .clk(clk),
        .RegWrite(),
        .readaddr1(),
        .readaddr2(),
        .writeaddr(),
        .writedata(),
        .readdata1(),
        .readdata2()
    );
    
    Imm_extend Imm_ext(
        .instr(instr[31:7]),
        .immsrc(immsrc),
        .immext(immext)
    );
    
endmodule
