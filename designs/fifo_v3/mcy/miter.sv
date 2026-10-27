// Formal miter for fifo_v3: golden (mutsel=0) vs mutant (mutsel=`mutidx),
// identical unconstrained inputs; any output difference is a counterexample.
// See designs/fifo/mcy/miter.sv for the full explanation.

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

    fifo_v3 ref (
        .mutsel (8'd 0),
        .clk_i (clk_i), .rst_ni (rst_ni), .flush_i (flush_i), .testmode_i (1'b0),
        .full_o (ref_full), .empty_o (ref_empty), .usage_o (ref_usage),
        .data_i (data_i), .push_i (push_i), .data_o (ref_data), .pop_i (pop_i)
    );

    fifo_v3 uut (
        .mutsel (8'd `mutidx),
        .clk_i (clk_i), .rst_ni (rst_ni), .flush_i (flush_i), .testmode_i (1'b0),
        .full_o (uut_full), .empty_o (uut_empty), .usage_o (uut_usage),
        .data_i (data_i), .push_i (push_i), .data_o (uut_data), .pop_i (pop_i)
    );

    // Active-low async reset: assert it in the first cycle only.
    reg init = 1;
    always @(posedge clk_i) init <= 0;
    always @* begin
        if (init) assume (!rst_ni);
        else      assume (rst_ni);
    end

    always @* begin
        if (!init) begin
            assert (ref_full  == uut_full);
            assert (ref_empty == uut_empty);
            assert (ref_usage == uut_usage);
            if (!ref_empty) assert (ref_data == uut_data);
        end
    end
endmodule
