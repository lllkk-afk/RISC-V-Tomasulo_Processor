module Tomasulo_tb;

  // 信号定义
  logic clk;
  logic reset;
  logic [4:0] reg_addr;
  logic [31:0] reg_data;
  logic done;

  // 实例化顶层模块
  Tomasulo_top uut (
    .clk(clk),
    .reset(reset),
    .reg_addr(reg_addr),
    .reg_data(reg_data),
    .done(done)
  );

  // 时钟生成：周期10ns（50MHz）
  always #5 clk = ~clk;

  // 测试激励
  initial begin
    // 初始化信号
    clk = 0;
    reset = 0;
    #15
    reset = 1;
    reg_addr = 5'd0;
    
    // 保持复位一段时间
    #10;
    reset = 0;
    
    // 测试过程中，可以切换reg_addr来读取不同的寄存器数据
    // 这里仅做简单变化，实际情况视设计而定
    #50; reg_addr = 5'd3;
    #50; reg_addr = 5'd10;
    
    // 等待完成信号出现（done==1），你可以根据实际情况增加检查
    wait(done == 1);
    #50;
    
    $display("Test finished, reg_data = %h", reg_data);
    $finish;
  end

endmodule