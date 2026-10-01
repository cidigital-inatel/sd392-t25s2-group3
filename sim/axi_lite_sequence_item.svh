`ifndef TB_AXI_LITE_SEQUENCE_ITEM_SVH
`define TB_AXI_LITE_SEQUENCE_ITEM_SVH

// Transação de leitura ou escrita para a interface AXI4-Lite.
typedef enum bit {
    AXI_LITE_READ,
    AXI_LITE_WRITE
} axi_lite_operation_e;

class axi_lite_sequence_item extends uvm_sequence_item;
    rand axi_lite_operation_e operation;
    rand logic [TB_AXI_LITE_ADDR_WIDTH-1:0] address;
    rand logic [TB_AXI_LITE_DATA_WIDTH-1:0] write_data;
    logic [TB_AXI_LITE_DATA_WIDTH-1:0] expected_read_data;
    logic [TB_AXI_LITE_DATA_WIDTH-1:0] read_data;
    logic [1:0] response;

    `uvm_object_utils_begin(axi_lite_sequence_item)
        `uvm_field_enum(axi_lite_operation_e, operation, UVM_DEFAULT)
        `uvm_field_int(address, UVM_DEFAULT)
        `uvm_field_int(write_data, UVM_DEFAULT)
        `uvm_field_int(expected_read_data, UVM_DEFAULT)
        `uvm_field_int(read_data, UVM_DEFAULT)
        `uvm_field_int(response, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "axi_lite_sequence_item");
        super.new(name);
        operation = AXI_LITE_WRITE;
    endfunction
endclass

`endif
