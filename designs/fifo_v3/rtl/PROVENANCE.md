# fifo_v3.sv provenance

Source: https://github.com/pulp-platform/common_cells, file `src/fifo_v3.sv`,
revision `b7297b0` (2024-10-03), the last revision before the module started
depending on `assertions.svh` (#233) and before the `cc_` rename (#290).
License: Solderpad Hardware License v0.51 (Apache-2.0 based); header retained.
This FIFO is the one used throughout the PULP platform, including CVA6.

`fifo_v3.orig.sv` is the unmodified upstream file.
`fifo_v3.sv` applies `yosys-compat.patch`: the SystemVerilog `parameter type dtype`
is replaced by a plain `logic [DATA_WIDTH-1:0]` because Yosys's SV frontend does
not support type parameters. Behavior is unchanged for the default `dtype`.

Both tools are run with `-DSYNTHESIS`, which disables the two protocol
assertions at the bottom of the file (push-when-full / pop-when-empty). Those
are *environment* assumptions, not properties of the design; the design itself
ignores a push when full and a pop when empty, and the bench and miter rely on
that behavior rather than avoiding it.

Instance under test: DATA_WIDTH=8, DEPTH=8, FALL_THROUGH=0.
