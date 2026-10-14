/*
    a tranferencia acontece na borda de subida do clock quando TREADY=1 e TVALID=1. O DUT (Manager) 
    produz TDATA, TVALID e TLAST, enquanto o ambiente de teste controla TREADY.
*/

`ifndef TB_AXIS_OUTPUT_DRIVER_SVH
`define TB_AXIS_OUTPUT_DRIVER_SVH

class axis_output_driver extends uvm_driver #(axis_output_sequence_item);
    `uvm_component_utils(axis_output_driver)

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
            `uvm_fatal("AXIS_OUTPUT_DRV/NOVIF", "Nenhuma interface virtual AXI4-Stream de saida foi configurada")
    endfunction

    // Controla TREADY pelo número de ciclos de cada item, aplicando backpressure ao DUT.
    task run_phase(uvm_phase phase);
        axis_output_sequence_item req;
        vif.TREADY = 1'b0;
        forever begin
            seq_item_port.get_next_item(req);
            repeat (req.cycles) begin
                vif.set_ready(req.ready);
                @(posedge vif.ACLK);
            end
            `uvm_info("AXIS_OUTPUT_DRV/READY",
                      $sformatf("TREADY mantido em %0b por %0d ciclo(s)",
                                req.ready, req.cycles),
                      UVM_HIGH)
            seq_item_port.item_done();
        end
    endtask
endclass

`endif
