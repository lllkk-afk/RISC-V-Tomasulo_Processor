`timescale 1ns / 1ps

module Address_unit(
    input  logic        clk,
    input  logic [3:0]  tag_in,
    input  logic [3:0]  load1_tag,
    input  logic [3:0]  load2_tag,
    // don't need tag for store
    input  logic [31:0] load1_addr, 
    input  logic [31:0] load2_addr,
    input  logic [31:0] store1_addr,
    input  logic [31:0] store2_addr,
    input  logic [31:0] store1_data,
    input  logic [31:0] store2_data,
    input  logic        load1_valid,
    input  logic        load2_valid,
    input  logic        store1_valid,
    input  logic        store2_valid,
    //cdb
    input  logic        cdb_valid,
    input  logic [3:0]  cdb_tag,
    output logic [3:0]  tag_out,
    output logic [31:0] readdata,
    output logic        readdata_valid
    );
    
    logic write_enable;
    logic [31:0] data;
    logic [31:0] writedata;
    logic [31:0] addr; //both read and write
    
    //arbitrator
    always_comb begin
        readdata = 0;
        write_enable = 0;
        
        if (load1_valid) begin
            addr = load1_addr;
            readdata = data;
            write_enable = 0;
            tag_out = load1_tag;
        end
        else if (load2_valid) begin
            addr = load2_addr;
            readdata = data;
            write_enable = 0;
            tag_out = load2_tag;
        end
        else if (store1_valid) begin
            addr = store1_addr;
            writedata = store1_data;
            write_enable = 1;
        end
        else  if (store2_valid) begin
            addr = store2_addr;
            writedata = store2_data;
            write_enable = 1;
        end
    end
    
    always_ff @(posedge clk) begin
       
        if (load1_valid | load2_valid) begin
            readdata_valid <= 1;
        end

        if (readdata_valid && cdb_valid && (cdb_tag == tag_out)) begin
            readdata_valid <= 0;  
        end
    end

            
    data_mem dm(
        .clk(clk),
        .we(write_enable),
        .addr(addr), 
        .writedata(writedata),
        .readdata(data)
    );
        
 endmodule