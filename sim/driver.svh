`ifndef TB_DRIVER_SVH
`define TB_DRIVER_SVH
class driver extends uvm_driver #(sequence_item);
    `uvm_component_utils(driver)
    virtual bfm #(TB_DATA_WIDTH) vif;
    uvm_analysis_port #(sequence_item) expected_ap;
    bit protocol_drive_enable = 1;

    function new(string name, uvm_component parent);
        super.new(name, parent); expected_ap = new("expected_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual bfm #(TB_DATA_WIDTH))::get(this, "", "vif", vif))
            `uvm_fatal("DRV/NOVIF", "Nenhuma interface virtual configurada para este driver")
        void'(uvm_config_db#(bit)::get(this, "", "protocol_drive_enable", protocol_drive_enable));
    endfunction

    task run_phase(uvm_phase phase);
        sequence_item req;
        forever begin
            seq_item_port.get_next_item(req);
            if (protocol_drive_enable) begin
                vif.drive_word(req.data);
                expected_ap.write(req);
            end
            `uvm_info("DRV/DRIVE", $sformatf("Dado alimentado=0x%0h", req.data), UVM_HIGH)
            seq_item_port.item_done();
        end
    endtask
endclass
`endif
