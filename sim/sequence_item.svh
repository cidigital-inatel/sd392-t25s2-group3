`ifndef TB_SEQUENCE_ITEM_SVH
`define TB_SEQUENCE_ITEM_SVH
// Sequence Items específicos do projeto. Adicione campos de protocolo (fields) e constraints nas classes filhas conforme necessário
class sequence_item extends sequence_item_base;
    rand bit [TB_DATA_WIDTH-1:0] data;
    bit [TB_DATA_WIDTH-1:0] observed_data;

    `uvm_object_utils_begin(sequence_item)
        `uvm_field_int(data, UVM_DEFAULT)
        `uvm_field_int(observed_data, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "sequence_item"); super.new(name); endfunction
endclass
`endif
