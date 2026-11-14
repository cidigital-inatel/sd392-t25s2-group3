`ifndef TB_ENVIRONMENT_AXI_SVH
`define TB_ENVIRONMENT_AXI_SVH

class environment_axi extends uvm_env;
    `uvm_component_utils(environment_axi)

    axi_lite_agent axi_lite_agent_h;
    axi_lite_scoreboard scoreboard_h;
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
            `uvm_fatal("ENV_AXI/NOVIF", "A interface virtual AXI4-Lite nao foi configurada")

        axi_lite_agent_h = axi_lite_agent::type_id::create("axi_lite_agent_h", this);
        scoreboard_h = axi_lite_scoreboard::type_id::create("scoreboard_h", this);
        uvm_config_db#(virtual axi_lite_bfm #(
            .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
            .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
        ))::set(this, "axi_lite_agent_h", "vif", axi_lite_vif);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        axi_lite_agent_h.monitor_h.observed_ap.connect(scoreboard_h.actual_export);
        if (axi_lite_agent_h.get_is_active() == UVM_ACTIVE)
            axi_lite_agent_h.driver_h.expected_ap.connect(scoreboard_h.expected_export);
    endfunction
endclass

`endif
