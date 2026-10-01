`ifndef TB_AXI_LITE_MONITOR_SVH
`define TB_AXI_LITE_MONITOR_SVH

class axi_lite_monitor extends uvm_component;
    `uvm_component_utils(axi_lite_monitor)

    virtual axi_lite_bfm #(
        .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
        .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
    ) vif;
    uvm_analysis_port #(axi_lite_sequence_item) observed_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        observed_ap = new("observed_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_bfm #(
                .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
                .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
            ))::get(this, "", "vif", vif))
            `uvm_fatal("AXI_LITE_MON/NOVIF", "Nenhuma interface virtual AXI4-Lite foi configurada")
    endfunction

    task run_phase(uvm_phase phase);
        logic [TB_AXI_LITE_ADDR_WIDTH-1:0] write_addresses[$];
        logic [TB_AXI_LITE_DATA_WIDTH-1:0] write_data[$];
        logic [TB_AXI_LITE_ADDR_WIDTH-1:0] read_addresses[$];
        axi_lite_sequence_item item;

        forever begin
            @(posedge vif.ACLK);

            if (vif.reset_is_asserted()) begin
                write_addresses.delete();
                write_data.delete();
                read_addresses.delete();
            end else begin
                if (vif.AWVALID && vif.AWREADY)
                    write_addresses.push_back(vif.AWADDR);

                if (vif.WVALID && vif.WREADY)
                    write_data.push_back(vif.WDATA);

                if (vif.BVALID && vif.BREADY) begin
                    if ((write_addresses.size() == 0) || (write_data.size() == 0)) begin
                        `uvm_error("AXI_LITE_MON/WRITE_RESPONSE", "Resposta de escrita sem endereco ou dado aceito")
                    end else begin
                        item = axi_lite_sequence_item::type_id::create("observed_write");
                        item.operation = AXI_LITE_WRITE;
                        item.address = write_addresses.pop_front();
                        item.write_data = write_data.pop_front();
                        item.response = vif.BRESP;
                        observed_ap.write(item);
                    end
                end

                if (vif.ARVALID && vif.ARREADY)
                    read_addresses.push_back(vif.ARADDR);

                if (vif.RVALID && vif.RREADY) begin
                    if (read_addresses.size() == 0) begin
                        `uvm_error("AXI_LITE_MON/READ_RESPONSE", "Resposta de leitura sem endereco aceito")
                    end else begin
                        item = axi_lite_sequence_item::type_id::create("observed_read");
                        item.operation = AXI_LITE_READ;
                        item.address = read_addresses.pop_front();
                        item.read_data = vif.RDATA;
                        item.response = vif.RRESP;
                        observed_ap.write(item);
                    end
                end
            end
        end
    endtask
endclass

`endif
