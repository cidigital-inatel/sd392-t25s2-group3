`ifndef TB_TEST_BASE_SVH
`define TB_TEST_BASE_SVH
// Classe Test pai: tests do projeto a herdam e sobrescrevem apenas estímulos e configurações
class test_base extends uvm_test;
    `uvm_component_utils(test_base)
    environment env_h;
    virtual bfm #(TB_DATA_WIDTH) vif;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual bfm #(TB_DATA_WIDTH))::get(this, "", "vif_0", vif))
            `uvm_fatal("TEST/NOVIF", "O Testbench não configurou a vif_0")

        // Republique no escopo do environment; interfaces virtuais vif_N adicionais seguem esse padrão
        uvm_config_db#(virtual bfm #(TB_DATA_WIDTH))::set(this, "env_h", "vif_0", vif);
        env_h = environment::type_id::create("env_h", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        `uvm_info("TEST/EOE", "Topologia UVM:", UVM_LOW)
        uvm_top.print_topology();
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("TEST/CONNECT", "Conexões a nível de Test concluídas", UVM_HIGH)
    endfunction

    function void start_of_simulation_phase(uvm_phase phase);
        `uvm_info("TEST/START", "Iniciando simulação UVM", UVM_LOW)
    endfunction

    function void extract_phase(uvm_phase phase);
        `uvm_info("TEST/EXTRACT", "Extraindo resultados de fim de teste", UVM_LOW)
    endfunction

    function void check_phase(uvm_phase phase);
        if (env_h.scoreboard_h.mismatch_count != 0)
            `uvm_error("TEST/CHECK", "O Scoreboard reportou divergências")
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("TEST/REPORT", "Teste concluído; inspecione relatórios do scoreboard e do coverage", UVM_NONE)
    endfunction

    function void final_phase(uvm_phase phase);
        `uvm_info("TEST/FINAL", "Fase final do UVM alcançada", UVM_LOW)
    endfunction
endclass
`endif
