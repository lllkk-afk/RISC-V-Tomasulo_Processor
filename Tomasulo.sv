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
    logic [3:0] adder1_tag_out, adder2_tag_out, adder3_tag_out;
    logic [3:0] adder_cdb_tag;
    logic adder1_result_valid, adder2_result_valid, adder3_result_valid;
    logic [31:0] adder1_result, adder2_result, adder3_result;
    logic A_stall,LS_stall;
    
    //multiplier
    logic multi1_start, multi2_start;
    logic [31:0] multi1_SrcA, multi2_SrcA;
    logic [31:0] multi1_SrcB, multi2_SrcB;
    logic [3:0] multi1_tag, multi2_tag;
    logic [3:0] multi1_tag_out, multi2_tag_out;
    logic multi1_result_valid, multi2_result_valid;
    logic [31:0] multi1_result_lower, multi2_result_lower;
    logic [31:0] multi1_result_higher, multi2_result_higher;
    
    //control logic
    logic Load_en,Store_en,Add_en,Multiply_en;

    //cdb
    logic cdb_valid;
    logic [3:0] cdb_tag;
    logic [31:0] cdb_data;
    logic [31:0] mem_data;
    logic        mem_valid;
    logic [3:0]  mem_tag;
    
    //fifo
    logic push,pop;
    logic [3:0] front_tag,RdTag;
    
    //Imm_ext
    logic [31:0] immext;
    
    //Address_unit
    logic [ 3:0] Load1_tag;
    logic [ 3:0] Load2_tag;
    logic [31:0] Load1_addr;
    logic [31:0] Load2_addr;
    logic        Load1_valid;
    logic        Load2_valid;    
    logic [31:0] Store1_addr;
    logic [31:0] Store2_addr;
    logic [31:0] Store1_data;
    logic [31:0] Store2_data;
    logic        Store1_valid;
    logic        Store2_valid;
    
    //Regfile
    logic        Reg_writevalid;
    logic [ 4:0] Reg_writeaddr;
    logic [31:0] Reg_writedata;
    logic [31:0] Aread_data1;
    logic [31:0] Aread_data2;
    logic [ 4:0] Aread_addr1;
    logic [ 4:0] Aread_addr2;
    logic        Aread_valid1;
    logic        Aread_valid2;
    logic [31:0] Lread_data1;
    logic [31:0] Lread_data2;
    logic [ 4:0] Lread_addr1;
    logic [ 4:0] Lread_addr2;
    logic        Lread_valid1;
    logic        Lread_valid2;

    
    CDB cdb(  
        .adder1_data(adder1_result),
        .adder2_data(adder2_result),
        .adder3_data(adder3_result),
        .adder1_tag(adder1_tag_out),
        .adder2_tag(adder2_tag_out),
        .adder3_tag(adder3_tag_out),
        .adder1_valid(adder1_result_valid),
        .adder2_valid(adder2_result_valid),
        .adder3_valid(adder3_result_valid),
        .multi1_data_lower(multi1_result_lower),
        .multi2_data_lower(multi2_result_lower),
        .multi1_data_higher(multi1_result_higher),
        .multi2_data_higher(multi2_result_higher),
        .multi1_tag(multi1_tag_out),
        .multi2_tag(multi2_tag_out),
        .multi1_valid(multi1_result_valid),
        .multi2_valid(multi2_result_valid),
        .mem_data(mem_data),
        .mem_tag(mem_tag),
        .mem_valid(mem_valid),
        .Data_out(cdb_data),
        .Tag_out(cdb_tag),
        .Data_valid(cdb_valid)
    );

    RS rs_inst (
        // Common
        .clk(clk),
        .reset(reset),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        
        //regfile
        .Reg_writeaddr(Reg_writeaddr),
        .Reg_writedata(Reg_writedata),
        .Reg_writevalid(Reg_writevalid),
        .Aread_data1(Aread_data1), 
        .Aread_data2(Aread_data2), 
        .Aread_addr1(Aread_addr1), 
        .Aread_addr2(Aread_addr2), 
        .Aread_valid1(Aread_valid1),
        .Aread_valid2(Aread_valid2),
        .Lread_data1(Lread_data1), 
        .Lread_data2(Lread_data2), 
        .Lread_addr1(Lread_addr1), 
        .Lread_addr2(Lread_addr2),
        .Lread_valid1(Lread_valid1),
        .Lread_valid2(Lread_valid2),
    
        // Arithmetic
        .Add_en(Add_en),
        .Mul_en(Multiply_en),
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
        .Load1_addr(Load1_addr),
        .Load1_addr(Load2_addr),
        .Load1_valid(Load1_valid),
        .Load2_valid(Load2_valid),
        .Load1_tag(Load1_tag),
        .Load2_tag(Load2_tag),
        .Store1_addr(Store1_addr),
        .Store2_addr(Store2_addr),
        .Store1_valid(Store1_valid),
        .Store2_valid(Store2_valid),
        .Store1_data(Store1_data),
        .Store2_data(Store2_data),
        .Load_en(Load_en),
        .Store_en(Store_en),
        .ext_imm(immext),
        .front_tag(front_tag),
        .push(push),
        .pop(pop),
        .RdTag(RdTag),
        .LS_stall(LS_stall),
        
        //cdb
        .cdb_valid(cdb_valid),
        .cdb_tag(cdb_tag),
        .cdb_data(cdb_data)
        
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
        .cdb_tag(cdb_tag),
        .cdb_valid(cdb_valid),
        .Tag_out(adder1_tag_out),
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
        .cdb_tag(cdb_tag),
        .cdb_valid(cdb_valid),
        .Tag_out(adder2_tag_out),
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
        .cdb_tag(cdb_tag),
        .cdb_valid(cdb_valid),
        .Tag_out(adder3_tag_out),
        .result_valid(adder3_result_valid),
        .Result(adder3_result)
    );
    
    Multiplier mul1 (
        .clk(clk),
        .reset(reset),
        .start(multi1_start),
        .SrcA(multi1_SrcA),
        .SrcB(multi1_SrcB),
        .Tag_in(multi1_tag),
        .cdb_tag(cdb_tag), 
        .cdb_valid(cdb_valid),
        .Tag_out(multi1_tag_out),
        .result_valid(multi1_result_valid),
        .Mul(multi1_result_lower),
        .Mulh(multi1_result_higher)
    );

    
    Multiplier mul2 (
        .clk(clk),
        .reset(reset),
        .start(multi2_start),
        .SrcA(multi2_SrcA),
        .SrcB(multi2_SrcB),
        .Tag_in(multi2_tag),
        .cdb_tag(cdb_tag), 
        .cdb_valid(cdb_valid),
        .Tag_out(multi2_tag_out),
        .result_valid(multi2_result_valid),
        .Mul(multi2_result_lower),
        .Mulh(multi2_result_higher)
    );
    
    Address_unit address_unit_inst (
        .clk(clk),
        .tag_in(),
        .load1_tag(Load1_tag),
        .load2_tag(Load2_tag),
        .load1_addr(Load1_addr),
        .load2_addr(Load2_addr),
        .store1_addr(Store1_addr),
        .store2_addr(Store2_addr),
        .store1_data(Store1_data),
        .store2_data(Store2_data),
        .load1_valid(Load1_valid),
        .load2_valid(Load2_valid),
        .store1_valid(Store1_valid),
        .store2_valid(Store2_valid),
        .cdb_valid(cdb_valid),
        .cdb_tag(cdb_tag),
        .tag_out(mem_tag),
        .readdata(mem_data),
        .readdata_valid(mem_valid)
    );

    Register_unit R_unit(
        .clk(clk),
        .Aread_data1(Aread_data1),
        .Aread_data2(Aread_data2),
        .Aread_addr1(Aread_addr1),
        .Aread_addr2(Aread_addr2),
        .Aread_valid1(Aread_valid1),
        .Aread_valid2(Aread_valid2),
        .Lread_data1(Lread_data1),
        .Lread_data2(Lread_data2),
        .Lread_addr1(Lread_addr1),
        .Lread_addr2(Lread_addr2),
        .Lread_valid1(Lread_valid1),
        .Lread_valid2(Lread_valid2),
        .Reg_writeaddr(Reg_writeaddr),
        .Reg_writedata(Reg_writedata),
        .Reg_writevalid(Reg_writevalid)
    );
    
    Controllogic conlogic(
        .Instr(instr),
        .ImmSrc(immsrc),
        .ALUControl(ALUControl),
        .Load_en(Load_en), 
        .Store_en(Store_en), 
        .Add_en(Add_en), 
        .Multiply_en(Multiply_en)
    );
    
    
    Imm_extend Imm_ext(
        .instr(instr[31:7]),
        .immsrc(immsrc),
        .immext(immext)
    );
    
endmodule
