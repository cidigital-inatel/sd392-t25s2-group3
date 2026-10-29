`ifndef TB_AXIS_OUTPUT_AGENT_SVH
`define TB_AXIS_OUTPUT_AGENT_SVH

class axis_output_agent extends uvm_agent;
    `uvm_component_utils(axis_output_agent)

    axis_output_sequencer sequencer_h;
    axis_output_driver driver_h;
    axis_output_monitor monitor_h;
    axis_output_coverage coverage_h;
    virtual axis_output_bfm #(
        .TDATA_WIDTH(TB_AXIS_OUTPUT_TDATA_WIDTH)
    ) vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axis_output_bfm #(
                .TDATA_WIDTH(TB_AXIS_OUTPUT_TDATA_WIDTH)
            ))::get(this, "", "vif", vif))
            `uvm_fatal("AXIS_OUTPUT_AGENT/NOVIF", "Nenhuma interface virtual AXI4-Stream de saida foi configurada")

        monitor_h = axis_output_monitor::type_id::create("monitor_h", this);
        coverage_h = axis_output_coverage::type_id::create("coverage_h", this);
        uvm_config_db#(virtual axis_output_bfm #(
            .TDATA_WIDTH(TB_AXIS_OUTPUT_TDATA_WIDTH)
        ))::set(this, "monitor_h", "vif", vif);

        if (get_is_active() == UVM_ACTIVE) begin
            sequencer_h = axis_output_sequencer::type_id::create("sequencer_h", this);
            driver_h = axis_output_driver::type_id::create("driver_h", this);
            uvm_config_db#(virtual axis_output_bfm #(
                .TDATA_WIDTH(TB_AXIS_OUTPUT_TDATA_WIDTH)
            ))::set(this, "driver_h", "vif", vif);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        monitor_h.observed_ap.connect(coverage_h.analysis_export);
        if (get_is_active() == UVM_ACTIVE)
            driver_h.seq_item_port.connect(sequencer_h.seq_item_export);
    endfunction
endclass

`endif
