`ifndef TB_AXIS_INPUT_DRIVER_SVH
`define TB_AXIS_INPUT_DRIVER_SVH

class axis_input_driver extends uvm_driver #(axis_input_sequence_item);
    `uvm_component_utils(axis_input_driver)

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
            `uvm_fatal("AXIS_INPUT_DRV/NOVIF", "Nenhuma interface virtual AXI4-Stream de entrada foi configurada")
    endfunction

    task run_phase(uvm_phase phase);
        axis_input_sequence_item req;
        forever begin
            seq_item_port.get_next_item(req);
            vif.send_beat(req.data, req.last, req.user, req.keep, req.strb);

            // Saída de informações detalhadas sobre o beat enviado, incluindo TDATA, TLAST, TKEEP, TSTRB e TUSER
            // para ajudar em uma depuração mais eficaz e compreensão do fluxo de dados.
            `uvm_info("AXIS_INPUT_DRV/DRIVE",
                      $sformatf("Beat enviado: TDATA=0x%0h TLAST=%0b TKEEP=0x%0h TSTRB=0x%0h TUSER=0x%0h",
                                req.data, req.last, req.keep, req.strb, req.user),
                      UVM_HIGH)
            seq_item_port.item_done();
        end
    endtask
endclass

`endif
