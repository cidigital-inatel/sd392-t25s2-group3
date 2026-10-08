/*
    Representa uma transferência (um beat) do AXI4-Stream de entrada. Ela não representa a mensagem
     ML-KEM inteira: uma mensagem com vários beats será formada por vários desses itens enviados em
    sequência.

    - data: contém o valor de TDATA; sua largura vem do parâmetro TB_AXIS_INPUT_TDATA_WIDTH.
    - last: corresponde a TLAST. Quando está em 1, indica que aquele beat encerra o pacote.
    - keep e strb: correspondem a TKEEP e TSTRB; cada bit indica se o byte correspondente do beat é 
    válido ou relevante. A largura é TB_AXIS_INPUT_TKEEP_WIDTH.
    - user: corresponde a TUSER. O sinal está disponível, mas seu significado funcional ainda depende 
    da especificação da interface.

*/

`ifndef TB_AXIS_INPUT_SEQUENCE_ITEM_SVH
`define TB_AXIS_INPUT_SEQUENCE_ITEM_SVH

class axis_input_sequence_item extends uvm_sequence_item;
    rand bit [TB_AXIS_INPUT_TDATA_WIDTH-1:0] data;
    rand bit last;
    rand bit [TB_AXIS_INPUT_TKEEP_WIDTH-1:0] keep;
    rand bit [TB_AXIS_INPUT_TKEEP_WIDTH-1:0] strb;
    rand bit [TB_AXIS_INPUT_TUSER_WIDTH-1:0] user;

    constraint strb_is_subset_of_keep {
        (strb & ~keep) == '0;
    }

    `uvm_object_utils_begin(axis_input_sequence_item)
        `uvm_field_int(data, UVM_DEFAULT)
        `uvm_field_int(last, UVM_DEFAULT)
        `uvm_field_int(keep, UVM_DEFAULT)
        `uvm_field_int(strb, UVM_DEFAULT)
        `uvm_field_int(user, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "axis_input_sequence_item");
        super.new(name);
        data = '0;
        last = 1'b0;
        keep = '1;
        strb = '1;
        user = '0;
    endfunction
endclass

`endif
