`timescale 1ns/1ps
module ml_kem_tb;
    import uvm_pkg::*;
    import testbench_pkg::*;
    `include "uvm_macros.svh"

    // Instância BFM...
    // TB_DATA_WIDTH = tamanho do barramento de dados
    bfm #(.DATA_WIDTH(TB_DATA_WIDTH), .CLK_FREQ_MHZ(100)) bfm_i();

    // Instância DUT
    gray_encoder_sync #(.DATA_WIDTH(TB_DATA_WIDTH)) dut_i (
        .clk      (bfm_i.clk),
        .reset_n  (bfm_i.reset_n),
        .data_in  (bfm_i.data_in),
        .data_out (bfm_i.data_out)
    );

    initial begin
        string selected_test;

        // CONFIGURAÇÕES DO AMBIENTE UVM
        // 1. Interface virtual para o bfm instanciado
        uvm_config_db#(virtual bfm #(TB_DATA_WIDTH))::set(null, "uvm_test_top", "vif_0", bfm_i);

        // Se não houver um +UVM_TESTNAME=<test_selecionado> via script, escolher o teste abaixo
        if (!$value$plusargs("UVM_TESTNAME=%s", selected_test))
            selected_test = "test";

        run_test(selected_test);
    end
endmodule
