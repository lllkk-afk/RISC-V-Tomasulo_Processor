`timescale 1ns / 1ps

module instr_mem(
    input  logic [31:0] addr,
    output logic [31:0] readdata
    );
    
    logic [31:0] RAM[0:127];
    integer i;
    initial begin
        for (i = 0; i < 128; i = i + 1) begin
            RAM[i] = 32'h00000000;
        end

        $readmemh("riscvtest.mem", RAM);
    end
    assign readdata = RAM[addr[8:2]]; 
endmodule
