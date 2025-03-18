module clock_divider(
    input  logic clk,	
    input  logic reset,	
    input  logic btnU,		
    input  logic btnC,		
    output logic div_clk	
);

    localparam int CLK_4HZ = 100_000_000 / 2;  //100_000_000
    logic [26:0] counter;

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            counter  <= '0;
            div_clk  <= 1'b0;
        end
        else begin
            if (btnC) begin
                div_clk <= 1'b0;
                counter <= '0;
            end
            else begin
                if (counter == CLK_4HZ - 1) begin
                    counter <= '0;
                    div_clk <= ~div_clk;
                end 
                else begin
                    counter <= counter + 1;
                end
            end
        end
    end

endmodule
