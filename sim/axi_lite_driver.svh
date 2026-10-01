`ifndef TB_AXI_LITE_DRIVER_SVH
`define TB_AXI_LITE_DRIVER_SVH

class axi_lite_driver extends uvm_driver #(axi_lite_sequence_item);
    `uvm_component_utils(axi_lite_driver)

    virtual axi_lite_bfm #(
        .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
        .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
    ) vif;
    uvm_analysis_port #(axi_lite_sequence_item) expected_ap;
    bit protocol_drive_enable = 1'b1;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        expected_ap = new("expected_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_bfm #(
                .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
                .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
            ))::get(this, "", "vif", vif))
            `uvm_fatal("AXI_LITE_DRV/NOVIF", "Nenhuma interface virtual AXI4-Lite foi configurada")

        void'(uvm_config_db#(bit)::get(this, "", "protocol_drive_enable", protocol_drive_enable));
    endfunction

    task run_phase(uvm_phase phase);
        axi_lite_sequence_item req;
        forever begin
            seq_item_port.get_next_item(req);
            if (protocol_drive_enable) begin
                case (req.operation)
                    AXI_LITE_WRITE: begin
                        vif.write_reg(req.address, req.write_data, req.response);
                        `uvm_info("AXI_LITE_DRV/WRITE",
                                  $sformatf("Escrita: endereco=0x%0h dado=0x%0h resposta=%0b",
                                            req.address, req.write_data, req.response),
                                  UVM_HIGH)
                    end
                    AXI_LITE_READ: begin
                        vif.read_reg(req.address, req.read_data, req.response);
                        `uvm_info("AXI_LITE_DRV/READ",
                                  $sformatf("Leitura: endereco=0x%0h dado=0x%0h resposta=%0b",
                                            req.address, req.read_data, req.response),
                                  UVM_HIGH)
                    end
                endcase
                expected_ap.write(req);
            end
            seq_item_port.item_done();
        end
    endtask
endclass

`endif
