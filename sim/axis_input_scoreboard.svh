`ifndef TB_AXIS_INPUT_SCOREBOARD_SVH
`define TB_AXIS_INPUT_SCOREBOARD_SVH

`uvm_analysis_imp_decl(_axis_input_expected)
`uvm_analysis_imp_decl(_axis_input_actual)

class axis_input_scoreboard extends uvm_component;
    `uvm_component_utils(axis_input_scoreboard)

    uvm_analysis_imp_axis_input_expected #(axis_input_sequence_item, axis_input_scoreboard) expected_export;
    uvm_analysis_imp_axis_input_actual #(axis_input_sequence_item, axis_input_scoreboard) actual_export;

    axis_input_sequence_item expected_q[$];
    int unsigned expected_count;
    int unsigned observed_count;
    int unsigned match_count;
    int unsigned error_count;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        expected_export = new("expected_export", this);
        actual_export = new("actual_export", this);
    endfunction

    function void write_axis_input_expected(axis_input_sequence_item t);
        axis_input_sequence_item copy;
        if (!$cast(copy, t.clone()))
            `uvm_fatal("AXIS_INPUT_SB/CLONE", "Falha ao copiar beat esperado")
        expected_q.push_back(copy);
        expected_count++;
    endfunction

    function void write_axis_input_actual(axis_input_sequence_item t);
        axis_input_sequence_item expected;
        bit fields_match;
        observed_count++;

        if (expected_q.size() == 0) begin
            error_count++;
            `uvm_error("AXIS_INPUT_SB/UNEXPECTED",
                       $sformatf("Beat inesperado: data=0x%0h last=%0b",
                                 t.data, t.last))
            return;
        end

        expected = expected_q.pop_front();
        fields_match = (t.data === expected.data) &&
                       (t.last === expected.last) &&
                       (t.keep === expected.keep) &&
                       (t.strb === expected.strb) &&
                       (t.user === expected.user);

        if (!fields_match) begin
            error_count++;
            `uvm_error("AXIS_INPUT_SB/MISMATCH",
                       $sformatf("Beat %0d: esperado data=0x%0h last=%0b keep=0x%0h strb=0x%0h user=0x%0h; observado data=0x%0h last=%0b keep=0x%0h strb=0x%0h user=0x%0h",
                                 observed_count, expected.data, expected.last,
                                 expected.keep, expected.strb, expected.user,
                                 t.data, t.last, t.keep, t.strb, t.user))
        end else begin
            match_count++;
            `uvm_info("AXIS_INPUT_SB/MATCH",
                      $sformatf("Beat %0d conferido: data=0x%0h last=%0b",
                                observed_count, t.data, t.last),
                      UVM_HIGH)
        end
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (expected_q.size() != 0) begin
            error_count += expected_q.size();
            `uvm_error("AXIS_INPUT_SB/MISSING",
                       $sformatf("%0d beat(s) esperado(s) nao observado(s)", expected_q.size()))
            expected_q.delete();
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("AXIS_INPUT_SB/REPORT",
                  $sformatf("expected=%0d observed=%0d matches=%0d errors=%0d",
                            expected_count, observed_count, match_count, error_count),
                  UVM_NONE)
    endfunction
endclass

`endif
