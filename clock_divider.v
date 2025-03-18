module clock_divider(
	input clk,	
	input reset,	
	input btnU,		
	input btnC,		
	output reg div_clk);	

parameter clk_4hz = 25_000_000 / 2;
reg [24:0] counter;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        counter <= 0;
        div_clk <= 0;
    end
    else begin
        if (btnU) begin
            if (counter == clk_4hz - 1) begin
                counter <= 0;
                div_clk <= ~div_clk;
            end else begin
                counter <= counter + 1;
            end
        end
        else if (btnC) begin
            div_clk <= 0;
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
            div_clk <= ~div_clk;
        end
    end    
end
	
endmodule