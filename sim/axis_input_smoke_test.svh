/*
Este arquivo possui duas classes, sendo elas:
- axis_input_smoke_checker: uma classe que estende uvm_subscriber e é responsável por verificar os 
dados recebidos do agente AXI4-Stream de entrada. Ela mantém o controle do número de beats 
observados e dos erros encontrados durante a verificação.
- axis_input_smoke_test: uma classe que estende uvm_test e representa o teste de fumaça para o
agent de entrada AXI4-Stream.

*/



`ifndef TB_AXIS_INPUT_SMOKE_TEST_SVH
`define TB_AXIS_INPUT_SMOKE_TEST_SVH

class axis_input_smoke_checker extends uvm_subscriber #(axis_input_sequence_item);
    `uvm_component_utils(axis_input_smoke_checker)

    int unsigned beats_seen;
    int unsigned errors_seen;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void write(axis_input_sequence_item t);
        case (beats_seen)
            0: if (t.data !== 'h12345678 || t.last !== 1'b0)
                   errors_seen++;
            1: if (t.data !== 'hDEADBEEF || t.last !== 1'b0)
                   errors_seen++;
            2: if (t.data !== 'hCAFEBABE || t.last !== 1'b1)
                   errors_seen++;
            default: errors_seen++;
        endcase

        if (t.keep !== '1 || t.strb !== '1 || t.user !== '0)
            errors_seen++;
        beats_seen++;
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (beats_seen != 3 || errors_seen != 0)
            `uvm_error("AXIS_INPUT_SMOKE/CHECK",
                       $sformatf("Esperados 3 beats sem erros; observados %0d beat(s) e %0d erro(s)",
                                 beats_seen, errors_seen))
    endfunction
endclass

class axis_input_smoke_test extends uvm_test;
    `uvm_component_utils(axis_input_smoke_test)

    axis_input_agent agent_h;
    axis_input_smoke_checker checker_h;
    virtual axis_input_bfm #(
        .TDATA_WIDTH(TB_AXIS_INPUT_TDATA_WIDTH),
        .TUSER_WIDTH(TB_AXIS_INPUT_TUSER_WIDTH)
    ) vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axis_input_bfm #(
                .TDATA_WIDTH(TB_AXIS_INPUT_TDATA_WIDTH),
                .TUSER_WIDTH(TB_AXIS_INPUT_TUSER_WIDTH)
            ))::get(this, "", "axis_input_vif", vif))
            `uvm_fatal("AXIS_INPUT_SMOKE/NOVIF", "A interface AXI4-Stream de entrada nao foi configurada")

        uvm_config_db#(uvm_active_passive_enum)::set(
            this, "agent_h", "is_active", UVM_ACTIVE);
        uvm_config_db#(virtual axis_input_bfm #(
            .TDATA_WIDTH(TB_AXIS_INPUT_TDATA_WIDTH),
            .TUSER_WIDTH(TB_AXIS_INPUT_TUSER_WIDTH)
        ))::set(this, "agent_h", "vif", vif);

        agent_h = axis_input_agent::type_id::create("agent_h", this);
        checker_h = axis_input_smoke_checker::type_id::create("checker_h", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent_h.monitor_h.observed_ap.connect(checker_h.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        axis_input_smoke_sequence seq;

        phase.raise_objection(this, "Executando smoke test AXI4-Stream de entrada");
        vif.reset_assert(3);
        seq = axis_input_smoke_sequence::type_id::create("seq");
        seq.start(agent_h.sequencer_h);
        repeat (2) @(posedge vif.ACLK);
        phase.drop_objection(this, "Smoke test AXI4-Stream de entrada concluido");
    endtask
endclass

`endif
