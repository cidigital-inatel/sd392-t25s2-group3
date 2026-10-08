`ifndef TB_AXIS_INPUT_SEQUENCER_SVH
`define TB_AXIS_INPUT_SEQUENCER_SVH

class axis_input_sequencer extends uvm_sequencer #(axis_input_sequence_item);
    `uvm_component_utils(axis_input_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

`endif
