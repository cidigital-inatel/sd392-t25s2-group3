`ifndef TB_AXIS_INPUT_AGENT_SVH
`define TB_AXIS_INPUT_AGENT_SVH

class axis_input_agent extends uvm_agent;
    `uvm_component_utils(axis_input_agent)

    axis_input_sequencer sequencer_h;
    axis_input_driver driver_h;
    axis_input_monitor monitor_h;
    virtual axis_input_bfm #(
        .TDATA_WIDTH(TB_AXIS_INPUT_TDATA_WIDTH),
        .TUSER_WIDTH(TB_AXIS_INPUT_TUSER_WIDTH)
    ) vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axis_input_bfm #(
                .TDATA_WIDTH(TB_AXIS_INPUT_TDATA_WIDTH),
                .TUSER_WIDTH(TB_AXIS_INPUT_TUSER_WIDTH)
            ))::get(this, "", "vif", vif))
            `uvm_fatal("AXIS_INPUT_AGENT/NOVIF", "Nenhuma interface virtual AXI4-Stream de entrada foi configurada")

        monitor_h = axis_input_monitor::type_id::create("monitor_h", this);
        uvm_config_db#(virtual axis_input_bfm #(
            .TDATA_WIDTH(TB_AXIS_INPUT_TDATA_WIDTH),
            .TUSER_WIDTH(TB_AXIS_INPUT_TUSER_WIDTH)
        ))::set(this, "monitor_h", "vif", vif);

        if (get_is_active() == UVM_ACTIVE) begin
            sequencer_h = axis_input_sequencer::type_id::create("sequencer_h", this);
            driver_h = axis_input_driver::type_id::create("driver_h", this);
            uvm_config_db#(virtual axis_input_bfm #(
                .TDATA_WIDTH(TB_AXIS_INPUT_TDATA_WIDTH),
                .TUSER_WIDTH(TB_AXIS_INPUT_TUSER_WIDTH)
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
