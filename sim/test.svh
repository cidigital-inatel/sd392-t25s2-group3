`ifndef TB_TEST_SVH
`define TB_TEST_SVH
// Test de exemplo.
// Copie este arquivo para novos testes e selecione-o no testbench via script com +UVM_TESTNAME=<nome>.
class test extends test_base;
    `uvm_component_utils(test)

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    function void build_phase(uvm_phase phase);
        // Configurações seletivas de componentes do scoreboard e do coverage
        uvm_config_db#(bit)::set(this, "env_h.scoreboard_h", "scoreboard_enable", 1);
        uvm_config_db#(bit)::set(this, "env_h.scoreboard_h", "scoreboard_check_gray", 1);
        uvm_config_db#(bit)::set(this, "env_h.coverage_h", "coverage_enable", 1);
        uvm_config_db#(bit)::set(this, "env_h.coverage_h", "data_coverage_enable", 1);

        // Quantidade de agentes no environment
        uvm_config_db#(int unsigned)::set(this, "env_h", "number_of_agents", 1);

        // Modo do Agent (ativo ou passivo)
        uvm_config_db#(uvm_active_passive_enum)::set(this, "env_h.agent[0]", "is_active", UVM_ACTIVE);
        // Driver do agent: habilitar ou não seu protocolo de driving
        uvm_config_db#(bit)::set(this, "env_h.agent[0].driver_h", "protocol_drive_enable", 1);

        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        sequence_base seq;

        phase.raise_objection(this, "Rodando tráfego gray-code randomizado");
        vif.assert_reset();
        seq = base_sequence::type_id::create("random_sequence");
        seq.start(env_h.agents[0].sequencer_h);

        // Permitir que a última saída registrada seja observada antes de finalizar o teste
        repeat (2) @(posedge vif.clk);

        phase.drop_objection(this, "Tráfego randomizado concluído");
    endtask
endclass
`endif
