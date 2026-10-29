`ifndef TB_AXIS_OUTPUT_SEQUENCE_ITEM_SVH
`define TB_AXIS_OUTPUT_SEQUENCE_ITEM_SVH

class axis_output_sequence_item extends uvm_sequence_item;
    rand bit ready;
    rand int unsigned cycles;
    bit [TB_AXIS_OUTPUT_TDATA_WIDTH-1:0] data;
    bit last;
    int unsigned stall_cycles;

    constraint cycles_positive {
        cycles > 0;
    }

    `uvm_object_utils_begin(axis_output_sequence_item)
        `uvm_field_int(ready, UVM_DEFAULT)
        `uvm_field_int(cycles, UVM_DEFAULT)
        `uvm_field_int(data, UVM_DEFAULT)
        `uvm_field_int(last, UVM_DEFAULT)
        `uvm_field_int(stall_cycles, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "axis_output_sequence_item");
        super.new(name);
        ready = 1'b1;
        cycles = 1;
        data = '0;
        last = 1'b0;
        stall_cycles = 0;
    endfunction
endclass

`endif
