`ifndef TB_ENVIRONMENT_SVH
`define TB_ENVIRONMENT_SVH
class environment extends uvm_env;
    `uvm_component_utils(environment)
    agent agents[];
    scoreboard scoreboard_h;
    coverage coverage_h;
    int unsigned number_of_agents = 1;
    int interface_selection = 0;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    function void build_phase(uvm_phase phase);
        string vif_key;
        virtual bfm #(TB_DATA_WIDTH) selected_vif;
        super.build_phase(phase);

        void'(uvm_config_db#(int unsigned)::get(this, "", "number_of_agents", number_of_agents));
        void'(uvm_config_db#(int)::get(this, "", "interface_selection", interface_selection));

        if (number_of_agents == 0) `uvm_fatal("ENV/AGENTS", "number_of_agents precisa ser não-nulo")

        scoreboard_h = scoreboard::type_id::create("scoreboard_h", this);
        coverage_h = coverage::type_id::create("coverage_h", this);
        agents = new[number_of_agents];

        for (int i = 0; i < number_of_agents; i++) begin
            agents[i] = agent::type_id::create($sformatf("agent[%0d]", i), this);
            vif_key = $sformatf("vif_%0d", interface_selection + i);

            if (!uvm_config_db#(virtual bfm #(TB_DATA_WIDTH))::get(this, "", vif_key, selected_vif))
                `uvm_fatal("ENV/NOVIF", $sformatf("Nenhuma interface configurada sobre a chave '%s'", vif_key))

            uvm_config_db#(virtual bfm #(TB_DATA_WIDTH))::set(this, $sformatf("agent[%0d]*", i), "vif", selected_vif);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        foreach (agents[i]) begin
            agents[i].monitor_h.observed_ap.connect(scoreboard_h.actual_export);
            agents[i].monitor_h.observed_ap.connect(coverage_h.analysis_export);
            if (agents[i].get_is_active() == UVM_ACTIVE)
                agents[i].driver_h.expected_ap.connect(scoreboard_h.expected_export);
        end
    endfunction
endclass
`endif
