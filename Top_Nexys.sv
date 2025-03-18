`timescale 1ns / 1ps

module Top_Nexys(
    input  logic         clk,        // fundamental clock 1MHz
    input  logic         reset,
    input  logic         btnU,       // button BTNU for 4Hz speed
    input  logic         btnC,       // button BTNC for pause
    output logic [15:0]  led,        // 16 LEDs to display upper or lower 16 bits of memory data
    output logic         dp,         // dot point of 7-segments
    output logic [7:0]   anode,      // anodes of 7-segments
    output logic [6:0]   cathode     // cathodes of 7-segments£¬
);
  logic         div_clk;
  logic [4:0]   reg_addr;
  logic [31:0]  reg_data;
  logic         done;
  logic         reset_tomasulo;
  logic         reset_flag;
  assign led =  reg_data[15:0];

  always_ff @(posedge div_clk or negedge reset) begin
      if (!reset)
          reg_addr <= 5'b00000;
      else if (done)
          reg_addr <= reg_addr + 1;
  end

  always_ff @(posedge clk or negedge reset) begin
      if (!reset) begin
          reset_tomasulo <= 0;
          reset_flag     <= 0;
      end
      else if (!reset_flag) begin
          reset_tomasulo <= 1;
          reset_flag     <= 1;
      end 
      else begin
          reset_tomasulo <= 0;
      end
  end

  assign dp    = 1;

  clock_divider clk_div (
      .clk(clk),
      .reset(reset),
      .btnU(btnU),
      .btnC(btnC),
      .div_clk(div_clk)
  );
  
  Tomasulo_top tomasulo_top(
      .clk(clk),
      .reset(reset_tomasulo),
      .reg_addr(reg_addr),
      .reg_data(reg_data),
      .done(done)
    );
  
  seven_seg seven_seg(
    .clk(clk),
    .reset(reset),
    .reg_addr(reg_addr),
    .anode(anode),    
    .cathode(cathode)  
    );

endmodule