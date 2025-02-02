`timescale 1ns / 1ps

module Multiplier(
    input  logic clk,reset,
    input  logic [31:0] SrcA,
    input  logic [31:0] SrcB,
    input  logic start,
    output logic [31:0] Mul,
    output logic [31:0] Mulh,
    output logic busy
    );
    

    typedef enum logic { IDLE, CALC} state_t;
    state_t state;
    
    logic q0;
    logic [31:0] Q; //Lower half
    logic [31:0] A; //Upper half
    logic [31:0] M; //multiplicand
    logic [5:0]  n; //no of bit
    logic [31:0] A_new;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            busy  <= 0;
            Mul   <= 0;
            Mulh  <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        M    <= SrcA;
                        Q    <= SrcB;
                        A    <= 0;
                        A_new<= 0;
                        q0   <= 0;
                        n    <= 6'd32;   
                        busy <= 1;
                        state <= CALC;
                    end
                end

                CALC: begin
                    if (n > 0) begin
                        case ({Q[0], q0})
                            2'b00,2'b11: A_new = A;
                            2'b01:       A_new = A + M;
                            2'b10:       A_new = A - M;
                        endcase

                        {A,Q,q0} <= {A_new[31],A_new,Q};
                        n        <= n - 1;
                    end
                    else begin
                        Mul  <= Q;
                        Mulh <= A;
                        busy <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end 
    end
    
endmodule
