`ifndef TB_AXI_LITE_SCOREBOARD_SVH
`define TB_AXI_LITE_SCOREBOARD_SVH

`uvm_analysis_imp_decl(_axi_lite_expected)
`uvm_analysis_imp_decl(_axi_lite_actual)

class axi_lite_scoreboard extends uvm_component;
    `uvm_component_utils(axi_lite_scoreboard)

    uvm_analysis_imp_axi_lite_expected #(axi_lite_sequence_item, axi_lite_scoreboard) expected_export;
    uvm_analysis_imp_axi_lite_actual #(axi_lite_sequence_item, axi_lite_scoreboard) actual_export;

    axi_lite_sequence_item expected_q[$];
    int unsigned expected_count;
    int unsigned observed_count;
    int unsigned match_count;
    int unsigned error_count;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        expected_export = new("expected_export", this);
        actual_export = new("actual_export", this);
    endfunction

    function void write_axi_lite_expected(axi_lite_sequence_item t);
        axi_lite_sequence_item copy;
        if (!$cast(copy, t.clone()))
            `uvm_fatal("AXI_LITE_SB/CLONE", "Falha ao copiar transacao esperada")
        expected_q.push_back(copy);
        expected_count++;
    endfunction

    function void write_axi_lite_actual(axi_lite_sequence_item t);
        axi_lite_sequence_item expected;
        bit fields_match;
        observed_count++;

        if (expected_q.size() == 0) begin
            error_count++;
            `uvm_error("AXI_LITE_SB/UNEXPECTED",
                       $sformatf("Transacao inesperada: op=%s addr=0x%0h",
                                 t.operation.name(), t.address))
            return;
        end

        expected = expected_q.pop_front();
        fields_match = (t.operation === expected.operation) &&
                       (t.address === expected.address) &&
                       (t.response === expected.response);

        if (t.operation == AXI_LITE_WRITE)
            fields_match &= (t.write_data === expected.write_data);
        else
            fields_match &= (t.read_data === expected.expected_read_data);

        if (!fields_match) begin
            error_count++;
            if (t.operation == AXI_LITE_READ) begin
                `uvm_error("AXI_LITE_SB/MISMATCH",
                           $sformatf("Leitura addr=0x%0h: esperado data=0x%0h resp=%0b; observado data=0x%0h resp=%0b",
                                     expected.address, expected.expected_read_data, expected.response,
                                     t.read_data, t.response))
            end else begin
                `uvm_error("AXI_LITE_SB/MISMATCH",
                           $sformatf("Escrita esperada addr=0x%0h data=0x%0h resp=%0b; observada addr=0x%0h data=0x%0h resp=%0b",
                                     expected.address, expected.write_data, expected.response,
                                     t.address, t.write_data, t.response))
            end
        end else begin
            match_count++;
            `uvm_info("AXI_LITE_SB/MATCH",
                      $sformatf("Transacao %0d conferida: op=%s addr=0x%0h",
                                observed_count, t.operation.name(), t.address),
                      UVM_HIGH)
        end
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (expected_q.size() != 0) begin
            error_count += expected_q.size();
            `uvm_error("AXI_LITE_SB/MISSING",
                       $sformatf("%0d transacao(oes) esperada(s) nao observada(s)",
                                 expected_q.size()))
            expected_q.delete();
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("AXI_LITE_SB/REPORT",
                  $sformatf("expected=%0d observed=%0d matches=%0d errors=%0d",
                            expected_count, observed_count, match_count, error_count),
                  UVM_NONE)
    endfunction
endclass

`endif
