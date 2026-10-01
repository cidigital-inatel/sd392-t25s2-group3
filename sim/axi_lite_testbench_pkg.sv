package axi_lite_testbench_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter int TB_AXI_LITE_ADDR_WIDTH = 32;
    parameter int TB_AXI_LITE_DATA_WIDTH = 32;

    `include "axi_lite_sequence_item.svh"
    `include "axi_lite_sequencer.svh"
    `include "axi_lite_driver.svh"
    `include "axi_lite_monitor.svh"
    `include "axi_lite_agent.svh"
    `include "environment_axi.svh"
    `include "axi_lite_smoke_sequence.svh"
    `include "axi_lite_smoke_test.svh"
endpackage
