package testbench_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Configurações globais
    parameter int TB_DATA_WIDTH = 4;        // Tamanho do barramento de dados
    parameter int TB_NUM_TRANSACTIONS = 20; // Quantidade de sequence items a serem instanciados

    //`include "base_sequence_item.svh"
    `include "sequence_item.svh"
    //`include "base_sequence.svh"
    `include "sequence.svh"
    `include "sequencer.svh"
    `include "driver.svh"
    `include "monitor.svh"
    `include "agent.svh"
    `include "scoreboard.svh"
    `include "coverage.svh"
    `include "environment.svh"
    // `include "base_test.svh"
    `include "test.svh"
endpackage
