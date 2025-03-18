module Tomasulo_tb;

  // �źŶ���
  logic clk;
  logic reset;
  logic [4:0] reg_addr;
  logic [31:0] reg_data;
  logic done;

  // ʵ��������ģ��
  Tomasulo_top uut (
    .clk(clk),
    .reset(reset),
    .reg_addr(reg_addr),
    .reg_data(reg_data),
    .done(done)
  );

  // ʱ�����ɣ�����10ns��50MHz��
  always #5 clk = ~clk;

  // ���Լ���
  initial begin
    // ��ʼ���ź�
    clk = 0;
    reset = 0;
    #15
    reset = 1;
    reg_addr = 5'd0;
    
    // ���ָ�λһ��ʱ��
    #10;
    reset = 0;
    
    // ���Թ����У������л�reg_addr����ȡ��ͬ�ļĴ�������
    // ��������򵥱仯��ʵ���������ƶ���
    #50; reg_addr = 5'd3;
    #50; reg_addr = 5'd10;
    
    // �ȴ�����źų��֣�done==1��������Ը���ʵ��������Ӽ��
    wait(done == 1);
    #50;
    
    $display("Test finished, reg_data = %h", reg_data);
    $finish;
  end

endmodule