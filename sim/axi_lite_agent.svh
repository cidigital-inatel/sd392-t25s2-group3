`ifndef TB_AXI_LITE_AGENT_SVH
`define TB_AXI_LITE_AGENT_SVH

class axi_lite_agent extends uvm_agent;
    `uvm_component_utils(axi_lite_agent)

    axi_lite_sequencer sequencer_h;
    axi_lite_driver driver_h;
    axi_lite_monitor monitor_h;
    virtual axi_lite_bfm #(
        .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
        .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
    ) vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_bfm #(
                .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
                .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
            ))::get(this, "", "vif", vif))
            `uvm_fatal("AXI_LITE_AGENT/NOVIF", "Nenhuma interface virtual AXI4-Lite foi configurada")

        monitor_h = axi_lite_monitor::type_id::create("monitor_h", this);
        uvm_config_db#(virtual axi_lite_bfm #(
            .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
            .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
        ))::set(this, "monitor_h", "vif", vif);

        if (get_is_active() == UVM_ACTIVE) begin
            sequencer_h = axi_lite_sequencer::type_id::create("sequencer_h", this);
            driver_h = axi_lite_driver::type_id::create("driver_h", this);
            uvm_config_db#(virtual axi_lite_bfm #(
                .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
                .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
            ))::set(this, "driver_h", "vif", vif);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE)
            driver_h.seq_item_port.connect(sequencer_h.seq_item_export);
    endfunction
endclass

`endif
