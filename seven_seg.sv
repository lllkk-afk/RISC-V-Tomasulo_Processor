`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/19/2025 01:46:57 AM
// Design Name: 
// Module Name: seven_seg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module seven_seg(
    input logic clk,
    input logic reset,
    input logic [4:0] reg_addr,
    output logic [7:0] anode,    
    output logic [6:0] cathode  
    );
    
    localparam int CLK_4HZ = 25_000_0 / 2; //25_000_0
    logic [20:0] counter;
    logic lastdigit;
    logic [3:0] digit_tens;
    logic [3:0] digit_ones;
    assign digit_tens = (reg_addr / 10) % 10;
    assign digit_ones = reg_addr % 10; 
    logic [3:0] current_number;
    
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            lastdigit   <= 0;
            counter <= '0;
        end 
        else begin
            if (counter == CLK_4HZ - 1) begin
              counter <= '0;
              if (lastdigit) 
                 lastdigit <= 0;
              else if (!lastdigit)
                 lastdigit <= 1;
              end 
              else begin
               counter <= counter + 1;
           end
        end 
    end
    
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            anode <= '1;
            current_number  <= '0;
        end
        else begin
            if (lastdigit) begin
                anode <= 8'b11111101;
                current_number <= digit_tens;
            end
            else begin
                anode <= 8'b11111110;
                current_number <= digit_ones;
            end
        end
    end
    
    always_comb begin
        case (current_number)
            4'd0:  cathode = 7'b1000000; 
            4'd1:  cathode = 7'b1111001; 
            4'd2:  cathode = 7'b0100100; 
            4'd3:  cathode = 7'b0110000; 
            4'd4:  cathode = 7'b0011001; 
            4'd5:  cathode = 7'b0010010; 
            4'd6:  cathode = 7'b0000010;
            4'd7:  cathode = 7'b1111000; 
            4'd8:  cathode = 7'b0000000; 
            4'd9:  cathode = 7'b0010000; 
            default: cathode = 7'b0000000;
    endcase
end
    
endmodule
