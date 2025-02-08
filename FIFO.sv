`timescale 1ns / 1ps

module FIFO #(
    parameter FIFO_DEPTH = 4, 
    parameter TAG_WIDTH = 4    
)(
    input logic clk, reset,
    input logic push, 
    input logic pop,  
    input logic [TAG_WIDTH-1:0] push_tag,  
    output logic [TAG_WIDTH-1:0] front_tag 
);

    logic [TAG_WIDTH-1:0] fifo_mem [FIFO_DEPTH-1:0];
    logic [$clog2(FIFO_DEPTH)-1:0] head, tail;

    assign front_tag = fifo_mem[head]; 

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            head <= 0;
            tail <= 0;
        end
        else begin
            if (push) begin
                fifo_mem[tail] <= push_tag;
                tail <= (tail + 1);
            end

            if (pop) begin
                head <= (head + 1);
            end
        end
    end

endmodule
