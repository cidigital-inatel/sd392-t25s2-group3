`ifndef TB_AXI_LITE_SMOKE_TEST_SVH
`define TB_AXI_LITE_SMOKE_TEST_SVH

class axi_lite_smoke_test extends uvm_test;
    `uvm_component_utils(axi_lite_smoke_test)
    environment_axi env_h;
    virtual axi_lite_bfm #(
        .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
        .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
    ) axi_lite_vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_bfm #(
                .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
                .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
            ))::get(this, "", "axi_lite_vif", axi_lite_vif))
            `uvm_fatal("AXI_LITE_SMOKE/NOVIF", "A interface AXI4-Lite nao foi configurada")

        uvm_config_db#(uvm_active_passive_enum)::set(
            this, "env_h.axi_lite_agent_h", "is_active", UVM_ACTIVE);
        uvm_config_db#(virtual axi_lite_bfm #(
            .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
            .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
        ))::set(this, "env_h", "axi_lite_vif", axi_lite_vif);

        env_h = environment_axi::type_id::create("env_h", this);
    endfunction

    task run_phase(uvm_phase phase);
        axi_lite_smoke_sequence seq;

        phase.raise_objection(this, "Executando smoke test AXI4-Lite");
        axi_lite_vif.reset_assert(3);
        seq = axi_lite_smoke_sequence::type_id::create("seq");
        seq.start(env_h.axi_lite_agent_h.sequencer_h);
        repeat (2) @(posedge axi_lite_vif.ACLK);
        phase.drop_objection(this, "Smoke test AXI4-Lite concluido");
    endtask
endclass

`endif
