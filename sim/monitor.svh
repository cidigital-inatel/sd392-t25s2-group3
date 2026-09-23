`ifndef TB_MONITOR_SVH
`define TB_MONITOR_SVH
class monitor extends uvm_component;
    `uvm_component_utils(monitor)
    virtual bfm #(TB_DATA_WIDTH) vif;
    uvm_analysis_port #(sequence_item) observed_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent); observed_ap = new("observed_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual bfm #(TB_DATA_WIDTH))::get(this, "", "vif", vif))
            `uvm_fatal("MON/NOVIF", "Nenhuma interface virtual configurada para este monitor")
    endfunction

    task run_phase(uvm_phase phase);
        sequence_item tr;
        forever begin
            @(posedge vif.clk); #1step;
            if (!vif.reset_is_asserted()) begin
                tr = sequence_item::type_id::create("observed_tr");
                tr.observed_data = vif.data_out;
                observed_ap.write(tr);
            end
        end
    endtask
endclass
`endif
