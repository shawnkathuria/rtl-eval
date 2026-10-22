`ifndef VERILATOR
module testbench;
  reg [4095:0] vcdfile;
  reg clock;
`else
module testbench(input clock, output reg genclock);
  initial genclock = 1;
`endif
  reg genclock = 1;
  reg [31:0] cycle = 0;
  reg [7:0] PI_data_i;
  reg [0:0] PI_pop_i;
  reg [0:0] PI_clk_i;
  reg [0:0] PI_rst_ni;
  reg [0:0] PI_push_i;
  miter UUT (
    .data_i(PI_data_i),
    .pop_i(PI_pop_i),
    .clk_i(PI_clk_i),
    .rst_ni(PI_rst_ni),
    .push_i(PI_push_i)
  );
`ifndef VERILATOR
  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end
    #5 clock = 0;
    while (genclock) begin
      #5 clock = 0;
      #5 clock = 1;
    end
  end
`endif
  initial begin
`ifndef VERILATOR
    #1;
`endif
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$$flatten/ref_uut .\$0/mem_q[63:0]_gate#sampled$294  = 64'b0000000000000000000000000000000000000000000000000000000000000000;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$$flatten/ref_uut .\$0/mem_q[63:0]_gold#sampled$312  = 64'b0000000000000000000000000000000000000000000000000000000000000000;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/init#sampled$436  = 1'b1;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/ref_uut .\mem_q_gate#sampled$292  = 64'b0000000000000000000000000000000000000000000000000000000000000000;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/ref_uut .\mem_q_gold#sampled$310  = 64'b0000000000000000000000000000000000000000000000000000000000000000;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/ref_uut .\read_pointer_n_gate#sampled$330  = 3'b000;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/ref_uut .\read_pointer_n_gold#sampled$348  = 3'b000;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/ref_uut .\read_pointer_q_gate#sampled$328  = 3'b000;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/ref_uut .\read_pointer_q_gold#sampled$346  = 3'b000;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/ref_uut .\status_cnt_n_gate#sampled$402  = 4'b0000;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/ref_uut .\status_cnt_n_gold#sampled$420  = 4'b0000;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/ref_uut .\status_cnt_q_gate#sampled$400  = 4'b0000;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/ref_uut .\status_cnt_q_gold#sampled$418  = 4'b0000;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/ref_uut .\write_pointer_n_gate#sampled$366  = 3'b000;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/ref_uut .\write_pointer_n_gold#sampled$384  = 3'b000;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/ref_uut .\write_pointer_q_gate#sampled$364  = 3'b000;
    // UUT.$auto$clk2fflogic.\cc:101:sample_data$/ref_uut .\write_pointer_q_gold#sampled$382  = 3'b000;
    // UUT.$auto$clk2fflogic.\cc:75:sample_control$$auto$rtlil .\cc:3201:Not$393#sampled$394  = 1'b0;
    // UUT.$auto$clk2fflogic.\cc:87:sample_control_edge$/clk_i#sampled$440  = 1'b1;

    // state 0
    PI_data_i = 8'b00000000;
    PI_pop_i = 1'b0;
    PI_clk_i = 1'b0;
    PI_rst_ni = 1'b0;
    PI_push_i = 1'b0;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_data_i <= 8'b01000000;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b1;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 2
    if (cycle == 1) begin
      PI_data_i <= 8'b00101001;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b0;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 3
    if (cycle == 2) begin
      PI_data_i <= 8'b00010000;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b1;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 4
    if (cycle == 3) begin
      PI_data_i <= 8'b00000000;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b0;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 5
    if (cycle == 4) begin
      PI_data_i <= 8'b01010000;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b1;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 6
    if (cycle == 5) begin
      PI_data_i <= 8'b00000000;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b0;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 7
    if (cycle == 6) begin
      PI_data_i <= 8'b10000111;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b1;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 8
    if (cycle == 7) begin
      PI_data_i <= 8'b00000000;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b0;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 9
    if (cycle == 8) begin
      PI_data_i <= 8'b00000100;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b1;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b0;
    end

    // state 10
    if (cycle == 9) begin
      PI_data_i <= 8'b00011010;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b0;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 11
    if (cycle == 10) begin
      PI_data_i <= 8'b00000000;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b1;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 12
    if (cycle == 11) begin
      PI_data_i <= 8'b00000000;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b0;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 13
    if (cycle == 12) begin
      PI_data_i <= 8'b00000010;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b1;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b0;
    end

    // state 14
    if (cycle == 13) begin
      PI_data_i <= 8'b11101101;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b0;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 15
    if (cycle == 14) begin
      PI_data_i <= 8'b00000000;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b1;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b0;
    end

    // state 16
    if (cycle == 15) begin
      PI_data_i <= 8'b00000000;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b0;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 17
    if (cycle == 16) begin
      PI_data_i <= 8'b00000000;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b1;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 18
    if (cycle == 17) begin
      PI_data_i <= 8'b00000000;
      PI_pop_i <= 1'b1;
      PI_clk_i <= 1'b0;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b0;
    end

    // state 19
    if (cycle == 18) begin
      PI_data_i <= 8'b01001000;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b1;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b0;
    end

    // state 20
    if (cycle == 19) begin
      PI_data_i <= 8'b00000000;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b0;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 21
    if (cycle == 20) begin
      PI_data_i <= 8'b00000000;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b1;
      PI_rst_ni <= 1'b1;
      PI_push_i <= 1'b0;
    end

    genclock <= cycle < 21;
    cycle <= cycle + 1;
  end
endmodule
