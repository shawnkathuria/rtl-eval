// Synchronous FIFO, golden reference.
//
// This is the design under mutation. It is deliberately small and plain so a
// reader can convince themselves it is correct in a few minutes; the thing
// being evaluated is the TESTBENCH, not this block.
//
// Interface (all synchronous to clk, active-high reset):
//   wr_en / wr_data : push when wr_en && !full
//   rd_en / rd_data : pop  when rd_en && !empty; rd_data shows the head word
//                     combinationally (first-word-fall-through)
//   full / empty    : status flags
//   count           : number of words currently stored, 0..DEPTH
//
// Pointer scheme: DEPTH is a power of two; pointers carry one extra MSB so
// that full and empty are distinguishable without a separate flag register.

`default_nettype none

module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 8,          // must be a power of two
    parameter AW    = $clog2(DEPTH)
) (
    input  wire             clk,
    input  wire             rst,

    input  wire             wr_en,
    input  wire [WIDTH-1:0] wr_data,
    output wire             full,

    input  wire             rd_en,
    output wire [WIDTH-1:0] rd_data,
    output wire             empty,

    output wire [AW:0]      count
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [AW:0]      wr_ptr;
    reg [AW:0]      rd_ptr;

    wire do_write = wr_en && !full;
    wire do_read  = rd_en && !empty;

    assign empty   = (wr_ptr == rd_ptr);
    assign full    = (wr_ptr[AW] != rd_ptr[AW]) &&
                     (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]);
    assign count   = wr_ptr - rd_ptr;
    assign rd_data = mem[rd_ptr[AW-1:0]];

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= {(AW+1){1'b0}};
            rd_ptr <= {(AW+1){1'b0}};
        end else begin
            if (do_write) begin
                mem[wr_ptr[AW-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end
            if (do_read) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

endmodule

`default_nettype wire
