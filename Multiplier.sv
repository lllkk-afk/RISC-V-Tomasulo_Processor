`timescale 1ns / 1ps

module Multiplier(
    input  logic        clk,reset,
    input  logic        start,
    input  logic [31:0] SrcA,
    input  logic [31:0] SrcB,
    input  logic [ 3:0] Tag_in,
    input  logic [ 3:0] cdb_tag, // for clearing valid 
    input  logic        cdb_valid,
    input  logic        ismultiply,  //new
    output logic [ 3:0] Tag_out,
    output logic        result_valid,
    output logic [31:0] Mul,
    output logic [31:0] Mulh,
    output logic [31:0] Quotient,    //new
    output logic [31:0] Remainder,  //new
    output logic        mulvalid,   //multiply is valid
    output logic        divvalid    //division is valid
    );
    

    typedef enum logic [1:0] { IDLE, MUL, DIV} state_t;
    state_t state;
    
    logic q0;
    logic [31:0] Q; //Lower half or quotient
    logic [31:0] A; //Upper half or remainder
    logic [31:0] M; //multiplicand or divisor
    logic [5:0]  n; //no of bit
    logic [31:0] A_new;
    logic SrcA_sign; // 0 means positive
    logic SrcB_sign; 
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state            <= IDLE;
            result_valid     <= 0;
            M                <= 0;
            Q                <= 0;
            A                <= 0;
            SrcA_sign        <= 0;
            SrcB_sign        <= 0;
            q0               <= 0;
            n                <= 6'd0;   
            result_valid     <= 0;
            mulvalid         <= 0;
            divvalid         <= 0;
            Quotient         <= '0;  
            Remainder        <= '0; 
            Tag_out          <= '0;
            Mul              <= '0;
            Mulh             <= '0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (start & ismultiply) begin
                        M    <= SrcA;
                        Q    <= SrcB;
                        A    <= 0;
                        A_new<= 0;
                        q0   <= 0;
                        n    <= 6'd32;   
                        result_valid  <= 0;
                        state <= MUL; 
                        mulvalid <= 0;
                        divvalid <= 0;
                    end
                    else if (start & !ismultiply) begin
                        Q    <= SrcA[31]? -SrcA:SrcA;
                        M    <= SrcB[31]? -SrcB:SrcB;
                        A    <= 0;
                        n    <= 6'd32;   
                        result_valid <= 0;
                        SrcA_sign <= SrcA[31];
                        SrcB_sign <= SrcB[31];
                        state <= DIV;
                        mulvalid <= 0;
                        divvalid <= 0;
                    end
                end

                DIV: begin
                    if (n > 0) begin
                        if (A[31]) begin
                            {A, Q} = {A, Q} << 1;  
                            A = A + M;                       
                        end
                        else begin
                           {A, Q} = {A, Q} << 1;  
                            A = A - M;
                        end
                        Q[0] = A[31] ? 0 : 1;   
                        n <= n - 1;
                    end
                    else begin
                        if (A[31]) begin
                            A  = A + M;
                        end
                        if (SrcA_sign ^ SrcB_sign) begin // Different signs
                            Quotient <= -Q;  // Negate the quotient
                            Remainder <= -A; // Negate the remainder (for consistent sign)
                        end
                        else begin
                            Quotient   <= Q;
                            Remainder  <= A;  
                        end
                        result_valid <= 1;
                        divvalid <= 1;
                        state <= IDLE;
                        Tag_out <= Tag_in;     
                        end                
                    end 
                MUL: begin
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
                        mulvalid <= 1;
                        state <= IDLE;
                        Tag_out <= Tag_in;
                    end
                end
                endcase     
            
            if (result_valid && cdb_valid && (cdb_tag == Tag_in)) begin
                result_valid <= 0;
                divvalid <= 0;
                mulvalid <= 0;
            end
        end 
    end
    
    /*
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
    */
endmodule
