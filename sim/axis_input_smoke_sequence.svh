/*
    O teste é uma sequência UVM de teste rápido: ela cria e envia três beats de dados fixos pelo 
    sequencer, configurando `TLAST` em `1` apenas no último beat e mantendo `TKEEP`/`TSTRB` válidos
     e `TUSER` zerado. O driver recebe cada item e o transmite pelo BFM, permitindo conferir se o
      agent de entrada transfere os beats corretamente.
*/


`ifndef TB_AXIS_INPUT_SMOKE_SEQUENCE_SVH
`define TB_AXIS_INPUT_SMOKE_SEQUENCE_SVH

class axis_input_smoke_sequence extends uvm_sequence #(axis_input_sequence_item);
    `uvm_object_utils(axis_input_smoke_sequence)

    function new(string name = "axis_input_smoke_sequence");
        super.new(name);
    endfunction

    task body();
        axis_input_sequence_item item;
        logic [TB_AXIS_INPUT_TDATA_WIDTH-1:0] test_data[3] = '{
            'h12345678, 'hDEADBEEF, 'hCAFEBABE
        };

        foreach (test_data[i]) begin
            item = axis_input_sequence_item::type_id::create($sformatf("beat_%0d", i));
            start_item(item);
            item.data = test_data[i];
            item.last = (i == ($size(test_data) - 1));
            item.keep = '1;
            item.strb = '1;
            item.user = '0;
            finish_item(item);
        end
    endtask
endclass

`endif
