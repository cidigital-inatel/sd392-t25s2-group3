package testbench_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Configurações globais
    parameter int TB_DATA_WIDTH = 4;        // Tamanho do barramento de dados
    parameter int TB_NUM_TRANSACTIONS = 20; // Quantidade de sequence items a serem instanciados
    parameter int TB_AXI_LITE_ADDR_WIDTH = 32;
    parameter int TB_AXI_LITE_DATA_WIDTH = 32;

    `include "modelo/sequence_item_base.svh"
    `include "modelo/sequence_item.svh"
    `include "axi_lite_sequence_item.svh"
    `include "modelo/sequence_base.svh"
    `include "modelo/sequence_incremental.svh"
    `include "modelo/sequencer.svh"
    `include "axi_lite_sequencer.svh"
    `include "modelo/driver.svh"
    `include "axi_lite_driver.svh"
    `include "modelo/monitor.svh"
    `include "axi_lite_monitor.svh"
    `include "axi_lite_coverage.svh"
    `include "modelo/agent.svh"
    `include "axi_lite_agent.svh"
    `include "modelo/scoreboard.svh"
    `include "axi_lite_scoreboard.svh"
    `include "modelo/coverage.svh"
    `include "modelo/environment.svh"
    `include "environment_axi.svh"
    `include "modelo/test_base.svh"
    `include "modelo/test.svh"
    `include "axi_lite_smoke_sequence.svh"
    `include "axi_lite_smoke_test.svh"
endpackage
