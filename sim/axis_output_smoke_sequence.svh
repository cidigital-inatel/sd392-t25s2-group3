
/*
    Esta sequência UVM controla o TREADY do ambiente: aceita um beat, aplica backpressure por
    dois ciclos e volta a aceitar dados. Assim, o smoke test exercita um beat mantido pelo
    produtor enquanto TREADY está baixo.
*/

`ifndef TB_AXIS_OUTPUT_SMOKE_SEQUENCE_SVH
`define TB_AXIS_OUTPUT_SMOKE_SEQUENCE_SVH

class axis_output_smoke_sequence extends uvm_sequence #(axis_output_sequence_item);
    `uvm_object_utils(axis_output_smoke_sequence)

    function new(string name = "axis_output_smoke_sequence");
        super.new(name);
    endfunction

    task body();
        axis_output_sequence_item item;
        bit ready_pattern[3] = '{1'b1, 1'b0, 1'b1};
        int unsigned cycle_pattern[3] = '{1, 2, 3};

        foreach (ready_pattern[i]) begin
            item = axis_output_sequence_item::type_id::create(
                $sformatf("ready_%0d", i));
            start_item(item);
            item.ready = ready_pattern[i];
            item.cycles = cycle_pattern[i];
            finish_item(item);
        end
    endtask
endclass

`endif
