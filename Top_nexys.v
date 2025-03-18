`timescale 1ns / 1ps

module Top_Nexys(
    input clk,  			// fundamental clock 1MHz
    input btnU, 			// button BTNU for 4Hz speed
    input btnC, 			// button BTNC for pause
    output reg [15:0] led,  	// 16 LEDs to display upper or lower 16 bits of memory data
    output dp,  			// dot point of 7-segments, can be deleted if 7-segments are not implemented
    output [7:0]anode, 		// anodes of 7-segments, can be deleted if 7-segments are not implemented
    output reg [6:0]cathode  	// cathodes of 7-segments, can be deleted if 7-segments are not implemented
    );

wire div_clk;
reg  lower;
reg [4:0] reg_addr;
wire [31:0] reg_data;
wire done;
reg not_done;

reg reset_n = 0;
reg [3:0] reset_count = 4'b0000;  

reg reset;
always @(posedge clk) begin
    if (reset_count < 4'b1111) begin
        reset_count <= reset_count + 1;
        reset <= 1;  
    end else begin
        reset <= 0;  
    end
end

always @(posedge div_clk or posedge reset) begin
    led      <= 16'h0000;
    if (reset) begin
        led      <= 16'hFFFF;
        lower    <= 0;
        reg_addr <= 4'b0;
        not_done <= 1;
    end
    else if (done) begin
        if (not_done) begin
            not_done <= 0;
            led      <= 16'hFFFF;
        end
        else begin
            if (lower) begin
                led   <= reg_data[15:0];
                lower <= 0;     
            end
            else begin
                led <= reg_data[31:16];
                lower <= 1;
                reg_addr <= reg_addr + 1;
            end
        end
    end
end

always @(*) begin
    case(reg_addr)
        0: cathode = 7'b0000001; 
        1: cathode = 7'b1001111; 
        2: cathode = 7'b0010010; 
        3: cathode = 7'b0000110; 
        4: cathode = 7'b1001100;
        5: cathode = 7'b0100100; 
        6: cathode = 7'b0100000; 
        7: cathode = 7'b0001111; 
        8: cathode = 7'b0000000; 
        9: cathode = 7'b0000100;
        default: cathode = 7'b0000000; 
    endcase
end

assign anode = 8'b0;


clock_divider clk_div(
    .clk(clk),
    .reset(reset),
    .btnU(btnU),
    .btnC(btnC),
    .div_clk(div_clk)
);

Tomasulo_top tomasulo_proc(
    .clk(clk),
    .reset(reset), 
    .reg_addr(reg_addr),
    .reg_data(reg_data),
    .done(done)
);




endmodule