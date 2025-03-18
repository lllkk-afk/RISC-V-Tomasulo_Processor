`timescale 1ns / 1ps

module Tomasulo(
    input logic clk, reset,
    input logic [31:0] instr,
    input logic [4:0] reg_addr,//for Board display,
    output logic [31:0] reg_data,
    output logic A_stall,LS_stall,
    output logic done 
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
    logic adder1_isadd,adder2_isadd,adder3_isadd;
    
    //mem
    logic [31:0] mem_read_data1,mem_read_data2;
    logic        mem_read_valid1,mem_read_valid2;
    logic [3:0]  mem_tag;
    
    //multiplier
    logic multi1_start, multi2_start;
    logic mulvalid1,divvalid1,mulvalid2,divvalid2;
    logic [31:0] multi1_SrcA, multi2_SrcA;
    logic [31:0] multi1_SrcB, multi2_SrcB;
    logic [3:0] multi1_tag, multi2_tag;
    logic [3:0] multi1_tag_out, multi2_tag_out;
    logic multi1_result_valid, multi2_result_valid;
    logic [31:0] multi1_result_lower, multi2_result_lower;
    logic [31:0] multi1_result_higher, multi2_result_higher;
    logic [31:0] Quotient1,Quotient2;
    logic [31:0] Remainder1,Remainder2;
    logic multi1_ismultiply,multi2_ismultiply;
    
    //control logic
    logic Load_en,Store_en,Add_en,Multiply_en;
    logic imminstr;
    logic ismultiply;
    logic isadd;

    //cdb
    logic cdb_valid;
    logic [3:0] cdb_tag;
    logic [31:0] cdb_data;
    logic [31:0] mem_data;
    logic        mem_valid;
    
    //fifo
    logic push,pop;
    logic [3:0] front_tag,push_tag;
    
    //Imm_ext
    logic [31:0] immext;
    logic [1:0]  immsrc;
    
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
    logic [31:0] read_data1,read_data2,Lread_data1,Lread_data2;
    logic [ 4:0] read_addr1,read_addr2,Lread_addr1,Lread_addr2;

    
    CDB cdb( 
        .clk(clk),
        .reset(reset),
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
        .mulvalid1(mulvalid1),
        .divvalid1(divvalid1),
        .mulvalid2(mulvalid2),
        .divvalid2(divvalid2),
        .mem_data1(mem_read_data1),
        .mem_data2(mem_read_data2),
        .mem_tag(mem_tag),
        .mem_valid1(mem_read_valid1),
        .mem_valid2(mem_read_valid2),
        .Quotient1(Quotient1),
        .Quotient2(Quotient2),
        .Remainder1(Remainder1),
        .Remainder2(Remainder2),
        .Data_out(cdb_data),
        .Tag_out(cdb_tag),
        .Data_valid(cdb_valid)
    );
    
    ReservationStation RS (
        // Common
        .clk(clk),
        .reset(reset),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        
        //mem
        .Load1_addr(Load1_addr),
        .Load2_addr(Load2_addr),
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
        
        //regfile
        .Reg_writeaddr(Reg_writeaddr),
        .Reg_writedata(Reg_writedata),
        .Reg_writevalid(Reg_writevalid),
        .read_data1(read_data1), 
        .read_data2(read_data2), 
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .Lread_data1(Lread_data1), 
        .Lread_data2(Lread_data2), 
        .Lread_addr1(Lread_addr1),
        .Lread_addr2(Lread_addr2),
        
        // Arithmetic
        .Add_en(Add_en),
        .Mul_en(Multiply_en),
        .isadd(isadd),
        .ismultiply(ismultiply),
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
        .adder1_isadd(adder1_isadd),
        .adder2_isadd(adder2_isadd),
        .adder3_isadd(adder3_isadd),
        .multi1_ismultiply(multi1_ismultiply),
        .multi2_ismultiply(multi2_ismultiply),
        
       
        // Load or Store
        .Load_en(Load_en),
        .Store_en(Store_en),
        .ext_imm(immext),
        .front_tag(front_tag),
        .push(push),
        .pop(pop),
        .push_tag(push_tag),
        .LS_stall(LS_stall),
        
        //cdb
        .cdb_valid(cdb_valid),
        .cdb_tag(cdb_tag),
        .cdb_data(cdb_data),
        
        //immediate
        .imminstr(imminstr),
        
        .done(done)
    );
    
    FIFO #(.FIFO_DEPTH(4), .TAG_WIDTH(4)) fifo (
        .clk(clk),
        .reset(reset),
        .push(push),
        .pop(pop),
        .push_tag(push_tag),
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
        .isadd(adder1_isadd),
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
        .isadd(adder2_isadd),
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
        .isadd(adder3_isadd),
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
        .ismultiply(multi1_ismultiply),
        .Tag_out(multi1_tag_out),
        .result_valid(multi1_result_valid),
        .Mul(multi1_result_lower),
        .Mulh(multi1_result_higher),
        .Quotient(Quotient1),
        .Remainder(Remainder1),
        .mulvalid(mulvalid1),
        .divvalid(divvalid1)
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
        .ismultiply(multi2_ismultiply),
        .Tag_out(multi2_tag_out),
        .result_valid(multi2_result_valid),
        .Mul(multi2_result_lower),
        .Mulh(multi2_result_higher),
        .Quotient(Quotient2),
        .Remainder(Remainder2),
        .mulvalid(mulvalid2),
        .divvalid(divvalid2)
    );
    
        
    Address_unit address_unit_inst (
        .clk(clk),
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
        .mem_read_data1(mem_read_data1),
        .mem_read_data2(mem_read_data2),
        .mem_read_valid1(mem_read_valid1),
        .mem_read_valid2(mem_read_valid2)
    );

    
    RegisterFile rf(
        .clk(clk),
        .RegWrite(Reg_writevalid),
        .readaddr1(read_addr1),
        .readaddr2(read_addr2),
        .Lreadaddr1(Lread_addr1),
        .Lreadaddr2(Lread_addr2),
        .writeaddr(Reg_writeaddr),
        .writedata(Reg_writedata),
        .readdata1(read_data1),
        .readdata2(read_data2),
        .Lreaddata1(Lread_data1),
        .Lreaddata2(Lread_data2),
        .reg_addr(reg_addr),
        .reg_data(reg_data)
    );
    
    Controllogic conlogic(
        .Instr(instr),
        .ImmSrc(immsrc),
        .Imminstr(imminstr),
        .Load_en(Load_en), 
        .Store_en(Store_en), 
        .Add_en(Add_en), 
        .Multiply_en(Multiply_en),
        .ismultiply(ismultiply),
        .isadd(isadd)
    );
    
    
    Imm_extend Imm_ext(
        .instr(instr[31:7]),
        .immsrc(immsrc),
        .immext(immext)
    );
    
endmodule
