`ifndef TB_AXI_LITE_SMOKE_TEST_SVH
`define TB_AXI_LITE_SMOKE_TEST_SVH

class axi_lite_smoke_monitor extends uvm_subscriber #(axi_lite_sequence_item);
    `uvm_component_utils(axi_lite_smoke_monitor)

    int unsigned writes_seen;
    int unsigned reads_seen;
    int unsigned errors_seen;
    logic [TB_AXI_LITE_DATA_WIDTH-1:0] expected_read_data = 'hC0FFEE12;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void write(axi_lite_sequence_item item);
        if (item.response !== 2'b00)
            errors_seen++;

        case (item.operation)
            AXI_LITE_WRITE: writes_seen++;
            AXI_LITE_READ: begin
                reads_seen++;
                if (item.read_data !== expected_read_data) begin
                    errors_seen++;
                    `uvm_error("AXI_LITE_SMOKE/READ_DATA",
                               $sformatf("Esperado 0x%0h, observado 0x%0h",
                                         expected_read_data, item.read_data))
                end
            end
        endcase
    endfunction
endclass

class axi_lite_smoke_test extends uvm_test;
    `uvm_component_utils(axi_lite_smoke_test)

    environment_axi env_h;
    axi_lite_smoke_monitor monitor_checker;
    virtual axi_lite_bfm #(
        .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
        .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
    ) axi_lite_vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_bfm #(
                .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
                .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
            ))::get(this, "", "axi_lite_vif", axi_lite_vif))
            `uvm_fatal("AXI_LITE_SMOKE/NOVIF", "A interface AXI4-Lite nao foi configurada")

        uvm_config_db#(uvm_active_passive_enum)::set(
            this, "env_h.axi_lite_agent_h", "is_active", UVM_ACTIVE);
        uvm_config_db#(virtual axi_lite_bfm #(
            .ADDR_WIDTH(TB_AXI_LITE_ADDR_WIDTH),
            .DATA_WIDTH(TB_AXI_LITE_DATA_WIDTH)
        ))::set(this, "env_h", "axi_lite_vif", axi_lite_vif);

        env_h = environment_axi::type_id::create("env_h", this);
        monitor_checker = axi_lite_smoke_monitor::type_id::create("monitor_checker", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        env_h.axi_lite_agent_h.monitor_h.observed_ap.connect(monitor_checker.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        axi_lite_smoke_sequence seq;

        phase.raise_objection(this, "Executando smoke test AXI4-Lite");
        axi_lite_vif.reset_assert(3);
        seq = axi_lite_smoke_sequence::type_id::create("seq");
        seq.start(env_h.axi_lite_agent_h.sequencer_h);
        repeat (2) @(posedge axi_lite_vif.ACLK);
        phase.drop_objection(this, "Smoke test AXI4-Lite concluido");
    endtask

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (monitor_checker.writes_seen != 1 || monitor_checker.reads_seen != 1)
            `uvm_error("AXI_LITE_SMOKE/COUNT",
                       $sformatf("Esperadas 1 escrita e 1 leitura; observadas %0d e %0d",
                                 monitor_checker.writes_seen, monitor_checker.reads_seen))
        if (monitor_checker.errors_seen != 0)
            `uvm_error("AXI_LITE_SMOKE/ERRORS",
                       $sformatf("O monitor observou %0d erro(s)", monitor_checker.errors_seen))
    endfunction
endclass

`endif
