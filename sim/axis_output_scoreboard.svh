`ifndef TB_AXIS_OUTPUT_SCOREBOARD_SVH
`define TB_AXIS_OUTPUT_SCOREBOARD_SVH

class axis_output_scoreboard extends uvm_subscriber #(axis_output_sequence_item);
    `uvm_component_utils(axis_output_scoreboard)

    typedef struct packed {
        bit [TB_AXIS_OUTPUT_TDATA_WIDTH-1:0] data;
        bit last;
    } expected_beat_t;

    expected_beat_t expected_beats[$];
    int unsigned expected_count;
    int unsigned observed_count;
    int unsigned match_count;
    int unsigned error_count;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void add_expected_beat(
        input bit [TB_AXIS_OUTPUT_TDATA_WIDTH-1:0] data,
        input bit last
    );
        expected_beat_t beat;
        beat.data = data;
        beat.last = last;
        expected_beats.push_back(beat);
        expected_count++;
    endfunction

    function void write(axis_output_sequence_item t);
        expected_beat_t expected;
        observed_count++;

        if (expected_beats.size() == 0) begin
            error_count++;
            `uvm_error("AXIS_OUTPUT_SB/UNEXPECTED",
                       $sformatf("Beat inesperado: data=0x%0h last=%0b",
                                 t.data, t.last))
            return;
        end

        expected = expected_beats.pop_front();
        if ((t.data !== expected.data) ||
            (t.last !== expected.last)) begin
            error_count++;
            `uvm_error("AXIS_OUTPUT_SB/MISMATCH",
                       $sformatf("Beat %0d: esperado data=0x%0h last=%0b; observado data=0x%0h last=%0b",
                                 observed_count, expected.data, expected.last,
                                 t.data, t.last))
        end else begin
            match_count++;
            `uvm_info("AXIS_OUTPUT_SB/MATCH",
                      $sformatf("Beat %0d: data=0x%0h last=%0b",
                                observed_count, t.data, t.last),
                      UVM_HIGH)
        end
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (expected_beats.size() != 0) begin
            error_count += expected_beats.size();
            `uvm_error("AXIS_OUTPUT_SB/MISSING",
                       $sformatf("%0d beat(s) esperado(s) nao foram observados",
                                 expected_beats.size()))
            expected_beats.delete();
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("AXIS_OUTPUT_SB/REPORT",
                  $sformatf("expected=%0d observed=%0d matches=%0d errors=%0d",
                            expected_count, observed_count, match_count, error_count),
                  UVM_NONE)
    endfunction
endclass

`endif
