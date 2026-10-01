`timescale 1ns/1ps
module axi_lite_smoke_tb;
    import uvm_pkg::*;
    import axi_lite_testbench_pkg::*;
    `include "uvm_macros.svh"

    axi_lite_bfm #(
        .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
        .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH),
        .CLK_FREQ_MHZ(100)
    ) axi_lite_bfm_i();

    logic aw_pending;
    logic w_pending;
    logic [TB_AXI_LITE_ADDR_WIDTH-1:0] aw_address_latched;
    logic [TB_AXI_LITE_DATA_WIDTH-1:0] w_data_latched;
    logic [TB_AXI_LITE_DATA_WIDTH-1:0] registers [0:15];

    wire aw_handshake = axi_lite_bfm_i.AWVALID && axi_lite_bfm_i.AWREADY;
    wire w_handshake = axi_lite_bfm_i.WVALID && axi_lite_bfm_i.WREADY;

    // Modelo simples de subordinate AXI-Lite para o teste de integracao.
    assign axi_lite_bfm_i.AWREADY = !aw_pending && !axi_lite_bfm_i.BVALID;
    assign axi_lite_bfm_i.WREADY = !w_pending && !axi_lite_bfm_i.BVALID;
    assign axi_lite_bfm_i.ARREADY = !axi_lite_bfm_i.RVALID;

    always @(posedge axi_lite_bfm_i.ACLK or negedge axi_lite_bfm_i.ARESETn) begin
        if (!axi_lite_bfm_i.ARESETn) begin
            aw_pending <= 1'b0;
            w_pending <= 1'b0;
            aw_address_latched <= '0;
            w_data_latched <= '0;
            axi_lite_bfm_i.BRESP <= 2'b00;
            axi_lite_bfm_i.BVALID <= 1'b0;
            axi_lite_bfm_i.RDATA <= '0;
            axi_lite_bfm_i.RRESP <= 2'b00;
            axi_lite_bfm_i.RVALID <= 1'b0;
            foreach (registers[i]) registers[i] <= '0;
        end else begin
            if (axi_lite_bfm_i.BVALID && axi_lite_bfm_i.BREADY)
                axi_lite_bfm_i.BVALID <= 1'b0;

            if (aw_handshake) begin
                aw_address_latched <= axi_lite_bfm_i.AWADDR;
                aw_pending <= 1'b1;
            end

            if (w_handshake) begin
                w_data_latched <= axi_lite_bfm_i.WDATA;
                w_pending <= 1'b1;
            end

            if ((aw_pending || aw_handshake) && (w_pending || w_handshake)) begin
                registers[(aw_pending ? aw_address_latched : axi_lite_bfm_i.AWADDR) >> 2] <=
                    w_pending ? w_data_latched : axi_lite_bfm_i.WDATA;
                aw_pending <= 1'b0;
                w_pending <= 1'b0;
                axi_lite_bfm_i.BRESP <= 2'b00;
                axi_lite_bfm_i.BVALID <= 1'b1;
            end

            if (axi_lite_bfm_i.ARVALID && axi_lite_bfm_i.ARREADY) begin
                axi_lite_bfm_i.RDATA <= registers[axi_lite_bfm_i.ARADDR >> 2];
                axi_lite_bfm_i.RRESP <= 2'b00;
                axi_lite_bfm_i.RVALID <= 1'b1;
            end else if (axi_lite_bfm_i.RVALID && axi_lite_bfm_i.RREADY) begin
                axi_lite_bfm_i.RVALID <= 1'b0;
            end
        end
    end

    // Instância DUT
    initial begin
        string selected_test;

        // CONFIGURAÇÕES DO AMBIENTE UVM
        uvm_config_db#(virtual axi_lite_bfm #(
            .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
            .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
        ))::set(null, "uvm_test_top", "axi_lite_vif", axi_lite_bfm_i);

        // Se não houver um +UVM_TESTNAME=<test_selecionado> via script, escolher o teste abaixo
        if (!$value$plusargs("UVM_TESTNAME=%s", selected_test))
            selected_test = "axi_lite_smoke_test";

        run_test(selected_test);
    end
endmodule
