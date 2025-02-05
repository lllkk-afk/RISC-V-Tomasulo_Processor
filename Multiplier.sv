`timescale 1ns / 1ps

module Multiplier(
    input  logic        clk,reset,
    input  logic        start,
    input  logic [31:0] SrcA,
    input  logic [31:0] SrcB,
    input  logic [ 3:0] Tag_in,
    input  logic [ 3:0] cdb_tag, // for clearing valid 
    input  logic        cdb_valid,
    output logic [ 3:0] Tag_out,
    output logic        result_valid,
    output logic [31:0] Mul,
    output logic [31:0] Mulh
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
            state            <= IDLE;
            result_valid     <= 0;
            Mul              <= 0;
            Mulh             <= 0;
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
                        result_valid <= 0;
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
                        result_valid <= 1;
                        state <= IDLE;
                        Tag_out <= Tag_in;
                    end
                end
            endcase
            
            if (result_valid && cdb_valid && (cdb_tag == Tag_in)) begin
                result_valid <= 0;
            end
        end 
    end
    
endmodule
