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
  reg [0:0] PI_rst_ni;
  reg [7:0] PI_data_i;
  reg [0:0] PI_push_i;
  reg [0:0] PI_flush_i;
  reg [0:0] PI_pop_i;
  reg [0:0] PI_clk_i;
  miter UUT (
    .rst_ni(PI_rst_ni),
    .data_i(PI_data_i),
    .push_i(PI_push_i),
    .flush_i(PI_flush_i),
    .pop_i(PI_pop_i),
    .clk_i(PI_clk_i)
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
    UUT._witness_.anyinit_flatten_ref_uut__procdff_166_gate = 64'b0110000000000001100010101000001010101010111011110011110100010000;
    UUT._witness_.anyinit_flatten_ref_uut__procdff_166_gold = 64'b0010001111101101001100110000001110111111111111110011010100000000;
    UUT._witness_.anyinit_flatten_ref_uut__procdff_171_gate = 3'b000;
    UUT._witness_.anyinit_flatten_ref_uut__procdff_171_gold = 3'b000;
    UUT._witness_.anyinit_flatten_ref_uut__procdff_176_gate = 3'b100;
    UUT._witness_.anyinit_flatten_ref_uut__procdff_176_gold = 3'b111;
    UUT._witness_.anyinit_flatten_ref_uut__procdff_181_gate = 4'b1110;
    UUT._witness_.anyinit_flatten_ref_uut__procdff_181_gold = 4'b0111;
    UUT.init = 1'b1;

    // state 0
    PI_rst_ni = 1'b0;
    PI_data_i = 8'b01001010;
    PI_push_i = 1'b1;
    PI_flush_i = 1'b1;
    PI_pop_i = 1'b1;
    PI_clk_i = 1'b0;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_rst_ni <= 1'b1;
      PI_data_i <= 8'b00100000;
      PI_push_i <= 1'b0;
      PI_flush_i <= 1'b1;
      PI_pop_i <= 1'b0;
      PI_clk_i <= 1'b0;
    end

    // state 2
    if (cycle == 1) begin
      PI_rst_ni <= 1'b1;
      PI_data_i <= 8'b00100000;
      PI_push_i <= 1'b1;
      PI_flush_i <= 1'b0;
      PI_pop_i <= 1'b1;
      PI_clk_i <= 1'b0;
    end

    genclock <= cycle < 2;
    cycle <= cycle + 1;
  end
endmodule
