// para rodar o teste no vivado, use o seguinte comando no terminal do Vivado:
// navegue até a pasta do projeto e execute:
// source axis_input_smoke_tb.sv

`timescale 1ns/1ps

module axis_input_smoke_tb;
    import uvm_pkg::*;
    import axis_input_testbench_pkg::*;

    `include "uvm_macros.svh"

    axis_input_bfm #(
        .TDATA_WIDTH(TB_AXIS_INPUT_TDATA_WIDTH),
        .TUSER_WIDTH(TB_AXIS_INPUT_TUSER_WIDTH)
    ) axis_input_bfm_i();

    assign axis_input_bfm_i.TREADY = 1'b1;

    initial begin
        string selected_test;

        uvm_config_db#(virtual axis_input_bfm #(
            .TDATA_WIDTH(TB_AXIS_INPUT_TDATA_WIDTH),
            .TUSER_WIDTH(TB_AXIS_INPUT_TUSER_WIDTH)
        ))::set(null, "uvm_test_top", "axis_input_vif", axis_input_bfm_i);

        if (!$value$plusargs("UVM_TESTNAME=%s", selected_test))
            selected_test = "axis_input_smoke_test";

        run_test(selected_test);
    end
endmodule
