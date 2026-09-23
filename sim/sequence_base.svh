`ifndef TB_SEQUENCE_BASE_SVH
`define TB_SEQUENCE_BASE_SVH
// Sequence base, providenciando infraestrutura comum e comportamento RANDÔMICO padrão
class sequence_base extends uvm_sequence #(sequence_item);
    `uvm_object_utils(sequence_base)

    function new(string name = "sequence_base"); super.new(name); endfunction

    virtual task body();
        sequence_item req;
        repeat (TB_NUM_TRANSACTIONS) begin
            req = sequence_item::type_id::create("random_req");
            start_item(req);
            if (!req.randomize()) `uvm_fatal("SEQ/RAND", "Falha na geração randômica de itens")
            finish_item(req);
        end
    endtask
endclass
`endif
