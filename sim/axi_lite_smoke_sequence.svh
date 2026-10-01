`ifndef TB_AXI_LITE_SMOKE_SEQUENCE_SVH
`define TB_AXI_LITE_SMOKE_SEQUENCE_SVH

class axi_lite_smoke_sequence extends uvm_sequence #(axi_lite_sequence_item);
    `uvm_object_utils(axi_lite_smoke_sequence)

    localparam logic [TB_AXI_LITE_ADDR_WIDTH-1:0] TEST_ADDRESS = 'h4;
    localparam logic [TB_AXI_LITE_DATA_WIDTH-1:0] TEST_DATA = 'hC0FFEE12;

    function new(string name = "axi_lite_smoke_sequence");
        super.new(name);
    endfunction

    task body();
        axi_lite_sequence_item item;

        item = axi_lite_sequence_item::type_id::create("write_item");
        start_item(item);
        item.operation = AXI_LITE_WRITE;
        item.address = TEST_ADDRESS;
        item.write_data = TEST_DATA;
        finish_item(item);

        item = axi_lite_sequence_item::type_id::create("read_item");
        start_item(item);
        item.operation = AXI_LITE_READ;
        item.address = TEST_ADDRESS;
        finish_item(item);
    endtask
endclass

`endif
