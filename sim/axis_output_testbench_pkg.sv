// Pacote do testbench AXI4-Stream de saida.

package axis_output_testbench_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter int TB_AXIS_OUTPUT_TDATA_WIDTH = 32;

    `include "axis_output_sequence_item.svh"
    `include "axis_output_sequencer.svh"
    `include "axis_output_driver.svh"
    `include "axis_output_monitor.svh"
    `include "axis_output_coverage.svh"
    `include "axis_output_scoreboard.svh"
    `include "axis_output_agent.svh"
    `include "axis_output_smoke_sequence.svh"
    `include "axis_output_smoke_test.svh"
endpackage
