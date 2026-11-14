`ifndef TB_AXIS_INPUT_SMOKE_TEST_SVH
`define TB_AXIS_INPUT_SMOKE_TEST_SVH

class axis_input_smoke_test extends uvm_test;
    `uvm_component_utils(axis_input_smoke_test)

    axis_input_agent agent_h;
    axis_input_scoreboard scoreboard_h;
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
        scoreboard_h = axis_input_scoreboard::type_id::create("scoreboard_h", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent_h.monitor_h.observed_ap.connect(scoreboard_h.actual_export);
        agent_h.driver_h.expected_ap.connect(scoreboard_h.expected_export);
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
