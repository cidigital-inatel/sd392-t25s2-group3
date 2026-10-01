package testbench_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Configurações globais
    parameter int TB_DATA_WIDTH = 4;        // Tamanho do barramento de dados
    parameter int TB_NUM_TRANSACTIONS = 20; // Quantidade de sequence items a serem instanciados
    parameter int TB_AXI_LITE_ADDR_WIDTH = 32;
    parameter int TB_AXI_LITE_DATA_WIDTH = 32;

    `include "sequence_item_base.svh"
    `include "sequence_item.svh"
    `include "axi_lite_sequence_item.svh"
    `include "sequence_base.svh"
    `include "sequence_incremental.svh"
    `include "sequencer.svh"
    `include "axi_lite_sequencer.svh"
    `include "driver.svh"
    `include "axi_lite_driver.svh"
    `include "monitor.svh"
    `include "axi_lite_monitor.svh"
    `include "agent.svh"
    `include "axi_lite_agent.svh"
    `include "scoreboard.svh"
    `include "coverage.svh"
    `include "environment.svh"
    `include "environment_axi.svh"
    `include "test_base.svh"
    `include "test.svh"
    `include "axi_lite_smoke_sequence.svh"
    `include "axi_lite_smoke_test.svh"
endpackage
