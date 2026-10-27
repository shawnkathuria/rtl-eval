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
  reg [0:0] PI_flush_i;
  reg [0:0] PI_clk_i;
  reg [7:0] PI_data_i;
  reg [0:0] PI_push_i;
  reg [0:0] PI_rst_ni;
  reg [0:0] PI_pop_i;
  miter UUT (
    .flush_i(PI_flush_i),
    .clk_i(PI_clk_i),
    .data_i(PI_data_i),
    .push_i(PI_push_i),
    .rst_ni(PI_rst_ni),
    .pop_i(PI_pop_i)
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
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12521 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12531 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12541 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12551 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12561 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12571 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12581 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12582 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12583 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12593 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12603 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12613 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12623 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12633 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12643 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12653 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12663 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12673 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12683 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12693 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12703 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12713 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12723 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12724 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12725 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12726 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12727 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12728 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12729 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12730 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12731 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12732 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12733 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12734 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12735 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12736 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12737 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12738 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12739 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12740 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12741 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12742 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12743 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12744 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12745 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12746 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12747 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12748 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12749 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12750 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12751 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12752 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12753 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12754 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12755 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12756 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12757 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12758 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12759 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12760 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12761 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12762 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12763 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12764 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12765 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12766 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12767 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12768 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12769 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12770 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12771 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12772 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12773 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12774 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12775 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12776 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12777 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12778 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12779 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12780 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12781 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12782 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12783 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12784 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12785 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12786 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12787 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12788 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12789 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12790 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12791 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12792 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12793 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12794 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12795 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12796 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12797 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12798 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12799 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12800 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12801 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12802 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12803 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12804 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12805 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12806 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12807 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12808 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12809 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12810 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12811 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12812 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12813 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12814 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12815 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12816 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12817 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12818 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12819 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12820 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12821 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12822 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12823 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12824 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12825 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12826 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12827 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12828 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12829 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12830 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12831 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12832 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12833 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12834 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12835 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12836 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12837 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12838 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12839 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12840 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12841 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12842 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12843 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12844 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12845 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12846 = 1'b0;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12847 = 1'b1;
    UUT._witness_.anyinit_auto_ff_cc_337_slice_12848 = 1'b1;
    UUT.init = 1'b1;

    // state 0
    PI_flush_i = 1'b0;
    PI_clk_i = 1'b0;
    PI_data_i = 8'b00000000;
    PI_push_i = 1'b0;
    PI_rst_ni = 1'b0;
    PI_pop_i = 1'b0;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_flush_i <= 1'b0;
      PI_clk_i <= 1'b0;
      PI_data_i <= 8'b00000100;
      PI_push_i <= 1'b1;
      PI_rst_ni <= 1'b1;
      PI_pop_i <= 1'b0;
    end

    // state 2
    if (cycle == 1) begin
      PI_flush_i <= 1'b0;
      PI_clk_i <= 1'b0;
      PI_data_i <= 8'b00000000;
      PI_push_i <= 1'b0;
      PI_rst_ni <= 1'b1;
      PI_pop_i <= 1'b0;
    end

    genclock <= cycle < 2;
    cycle <= cycle + 1;
  end
endmodule
