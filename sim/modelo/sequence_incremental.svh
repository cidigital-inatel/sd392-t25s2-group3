`ifndef TB_SEQUENCE_INCREMENTAL_SVH
`define TB_SEQUENCE_INCREMENTAL_SVH
// Sequence especializada (incremental), para testes de fumaça direcionados
class sequence_incremental extends sequence_base;
    `uvm_object_utils(sequence_incremental)

    function new(string name = "sequence_incremental"); super.new(name); endfunction

    virtual task body();
        sequence_item req;
        for (int unsigned i = 0; i < TB_NUM_TRANSACTIONS; i++) begin
            req = sequence_item::type_id::create($sformatf("req_%0d", i));
            start_item(req);
            if (!req.randomize() with { data == i[TB_DATA_WIDTH-1:0]; })
                `uvm_fatal("SEQ/RAND", "Falha na geração randômica direcionada (incremental) de itens")
            finish_item(req);
        end
    endtask
endclass
`endif
