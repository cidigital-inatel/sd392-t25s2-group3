`ifndef TB_AXIS_OUTPUT_MONITOR_SVH
`define TB_AXIS_OUTPUT_MONITOR_SVH

class axis_output_monitor extends uvm_component;
    `uvm_component_utils(axis_output_monitor)

    virtual axis_output_bfm #(
        .TDATA_WIDTH(TB_AXIS_OUTPUT_TDATA_WIDTH)
    ) vif;
    uvm_analysis_port #(axis_output_sequence_item) observed_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        observed_ap = new("observed_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axis_output_bfm #(
                .TDATA_WIDTH(TB_AXIS_OUTPUT_TDATA_WIDTH)
            ))::get(this, "", "vif", vif))
            `uvm_fatal("AXIS_OUTPUT_MON/NOVIF", "Nenhuma interface virtual AXI4-Stream de saida foi configurada")
    endfunction

    task run_phase(uvm_phase phase);
        axis_output_sequence_item tr;
        forever begin
            @(posedge vif.ACLK);
            if (vif.reset_is_asserted())
                continue;

            if (vif.TVALID === 1'b1 && vif.TREADY === 1'b1) begin
                tr = axis_output_sequence_item::type_id::create("observed_beat");
                tr.data = vif.TDATA;
                tr.last = vif.TLAST;
                tr.ready = vif.TREADY;
                tr.cycles = 1;
                observed_ap.write(tr);
            end
        end
    endtask
endclass

`endif
