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
  reg [0:0] PI_clk_i;
  reg [0:0] PI_pop_i;
  reg [0:0] PI_flush_i;
  reg [0:0] PI_push_i;
  miter UUT (
    .rst_ni(PI_rst_ni),
    .data_i(PI_data_i),
    .clk_i(PI_clk_i),
    .pop_i(PI_pop_i),
    .flush_i(PI_flush_i),
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
    UUT._witness_.anyinit_flatten_ref_uut__procdff_166_gate = 64'b1111011111011001110000100100001010101110101111110011110000000000;
    UUT._witness_.anyinit_flatten_ref_uut__procdff_166_gold = 64'b0000001011010010111100111110011111111111111111110001110100000000;
    UUT._witness_.anyinit_flatten_ref_uut__procdff_171_gate = 3'b000;
    UUT._witness_.anyinit_flatten_ref_uut__procdff_171_gold = 3'b000;
    UUT._witness_.anyinit_flatten_ref_uut__procdff_176_gate = 3'b100;
    UUT._witness_.anyinit_flatten_ref_uut__procdff_176_gold = 3'b111;
    UUT._witness_.anyinit_flatten_ref_uut__procdff_181_gate = 4'b0111;
    UUT._witness_.anyinit_flatten_ref_uut__procdff_181_gold = 4'b0111;
    UUT.init = 1'b1;

    // state 0
    PI_rst_ni = 1'b0;
    PI_data_i = 8'b01001010;
    PI_clk_i = 1'b0;
    PI_pop_i = 1'b1;
    PI_flush_i = 1'b1;
    PI_push_i = 1'b1;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_rst_ni <= 1'b1;
      PI_data_i <= 8'b00100000;
      PI_clk_i <= 1'b0;
      PI_pop_i <= 1'b0;
      PI_flush_i <= 1'b1;
      PI_push_i <= 1'b1;
    end

    // state 2
    if (cycle == 1) begin
      PI_rst_ni <= 1'b1;
      PI_data_i <= 8'b00100000;
      PI_clk_i <= 1'b0;
      PI_pop_i <= 1'b1;
      PI_flush_i <= 1'b0;
      PI_push_i <= 1'b1;
    end

    genclock <= cycle < 2;
    cycle <= cycle + 1;
  end
endmodule
