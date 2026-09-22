`ifndef TB_SEQUENCE_ITEM_BASE_SVH
`define TB_SEQUENCE_ITEM_BASE_SVH
// Sequence Item base (pai), contendo infraestrutura comum a qualquer sequence item
class sequence_item_base extends uvm_sequence_item;
    `uvm_object_utils(sequence_item_base)
    function new(string name = "sequence_item_base"); super.new(name); endfunction
endclass
`endif
