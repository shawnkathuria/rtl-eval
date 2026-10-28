// Miter for hand-written mutants: fifo_gold vs fifo_mut (both elaborated at 8x8 by
// run.sh), identical free inputs incl. flush_i. Same reset and data_o rule as
// mcy/miter.sv.
//   task "all"  : every output compared. FAIL = a real bug (counterexample).
//   task "core" : only empty_o and data_o compared. PASS = the bug is provably
//                 invisible except on full_o/usage_o (a port-only bug).

module miter (
    input        clk_i,
    input        rst_ni,
    input        push_i,
    input  [7:0] data_i,
    input        pop_i,
    input        flush_i
);
    wire       ref_full,  uut_full;
    wire       ref_empty, uut_empty;
    wire [2:0] ref_usage, uut_usage;
    wire [7:0] ref_data,  uut_data;

    fifo_gold ref (
        .clk_i (clk_i), .rst_ni (rst_ni), .flush_i (flush_i), .testmode_i (1'b0),
        .full_o (ref_full), .empty_o (ref_empty), .usage_o (ref_usage),
        .data_i (data_i), .push_i (push_i), .data_o (ref_data), .pop_i (pop_i)
    );

    fifo_mut uut (
        .clk_i (clk_i), .rst_ni (rst_ni), .flush_i (flush_i), .testmode_i (1'b0),
        .full_o (uut_full), .empty_o (uut_empty), .usage_o (uut_usage),
        .data_i (data_i), .push_i (push_i), .data_o (uut_data), .pop_i (pop_i)
    );

    reg init = 1;
    always @(posedge clk_i) init <= 0;
    always @* begin
        if (init) assume (!rst_ni);
        else      assume (rst_ni);
    end

    always @* begin
        if (!init) begin
`ifndef CORE_ONLY
            assert (ref_full  == uut_full);
            assert (ref_usage == uut_usage);
`endif
            assert (ref_empty == uut_empty);
            if (!ref_empty) assert (ref_data == uut_data);
        end
    end
endmodule
