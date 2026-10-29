`ifndef TB_AXIS_INPUT_MONITOR_SVH
`define TB_AXIS_INPUT_MONITOR_SVH

class axis_input_monitor extends uvm_component;
    `uvm_component_utils(axis_input_monitor)

    virtual axis_input_bfm #(
        .TDATA_WIDTH(TB_AXIS_INPUT_TDATA_WIDTH),
        .TUSER_WIDTH(TB_AXIS_INPUT_TUSER_WIDTH)
    ) vif;
    uvm_analysis_port #(axis_input_sequence_item) observed_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        observed_ap = new("observed_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axis_input_bfm #(
                .TDATA_WIDTH(TB_AXIS_INPUT_TDATA_WIDTH),
                .TUSER_WIDTH(TB_AXIS_INPUT_TUSER_WIDTH)
            ))::get(this, "", "vif", vif))
            `uvm_fatal("AXIS_INPUT_MON/NOVIF", "Nenhuma interface virtual AXI4-Stream de entrada foi configurada")
    endfunction

    task run_phase(uvm_phase phase);
        axis_input_sequence_item tr;
        int unsigned pending_stall_cycles = 0;

        forever begin
            @(posedge vif.ACLK);
            if (vif.reset_is_asserted()) begin
                pending_stall_cycles = 0;
                continue;
            end

            if (vif.TVALID === 1'b1 && vif.TREADY === 1'b1) begin
                tr = axis_input_sequence_item::type_id::create("observed_beat");
                tr.data = vif.TDATA;
                tr.last = vif.TLAST;
                tr.keep = vif.TKEEP;
                tr.strb = vif.TSTRB;
                tr.user = vif.TUSER;
                tr.stall_cycles = pending_stall_cycles;
                observed_ap.write(tr);
                pending_stall_cycles = 0;
            end else if (vif.TVALID === 1'b1 && vif.TREADY === 1'b0) begin
                pending_stall_cycles++;
            end
        end
    endtask
endclass

`endif
