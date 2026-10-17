// Formal miter: golden FIFO (mutsel=0) vs mutant (mutsel=`mutidx), driven
// with identical, unconstrained inputs. Any cycle where an output differs is
// a counterexample, and that counterexample IS the input sequence that would
// have exposed the bug. This is the ground truth the testbench is scored
// against: a mutant with no counterexample up to the BMC depth is treated
// as equivalent (NOCHANGE) and excluded from the score.

module miter (
    input        clk,
    input        rst,
    input        wr_en,
    input  [7:0] wr_data,
    input        rd_en
);
    wire       ref_full,  uut_full;
    wire       ref_empty, uut_empty;
    wire [3:0] ref_count, uut_count;
    wire [7:0] ref_rd_data, uut_rd_data;

    fifo ref (
        .mutsel  (8'd 0),
        .clk     (clk), .rst (rst),
        .wr_en   (wr_en), .wr_data (wr_data), .full (ref_full),
        .rd_en   (rd_en), .rd_data (ref_rd_data), .empty (ref_empty),
        .count   (ref_count)
    );

    fifo uut (
        .mutsel  (8'd `mutidx),
        .clk     (clk), .rst (rst),
        .wr_en   (wr_en), .wr_data (wr_data), .full (uut_full),
        .rd_en   (rd_en), .rd_data (uut_rd_data), .empty (uut_empty),
        .count   (uut_count)
    );

    // Hold reset for the first cycle so both sides start from a known state,
    // then never reset again (otherwise the solver can hide bugs behind resets).
    reg init = 1;
    always @(posedge clk) init <= 0;
    always @* begin
        if (init) assume (rst);
        else      assume (!rst);
    end

    always @* begin
        if (!init) begin
            assert (ref_full  == uut_full);
            assert (ref_empty == uut_empty);
            assert (ref_count == uut_count);
            // rd_data is only meaningful when there is something to read
            if (!ref_empty) assert (ref_rd_data == uut_rd_data);
        end
    end
endmodule
