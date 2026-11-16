`ifndef TB_SCOREBOARD_SVH
`define TB_SCOREBOARD_SVH
`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)
// Setores do scoreboard pode ser seletivamente ativados através de flags de configuração
class scoreboard extends uvm_component;
    `uvm_component_utils(scoreboard)
    uvm_analysis_imp_expected #(sequence_item, scoreboard) expected_export;
    uvm_analysis_imp_actual #(sequence_item, scoreboard) actual_export;

    bit scoreboard_enable = 1;
    bit check_gray_enable = 1;
    int unsigned match_count, mismatch_count;
    sequence_item expected_q[$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        expected_export = new("expected_export", this);
        actual_export = new("actual_export", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Obter flags de configuração do scoreboard
        void'(uvm_config_db#(bit)::get(this, "", "scoreboard_enable", scoreboard_enable));
        void'(uvm_config_db#(bit)::get(this, "", "scoreboard_check_gray", check_gray_enable));
    endfunction

    function void write_expected(sequence_item tr);
        sequence_item copy;
        if (scoreboard_enable) begin
            $cast(copy, tr.clone());
            expected_q.push_back(copy);
        end
    endfunction

    function void write_actual(sequence_item tr);
      sequence_item expected;
      bit [TB_DATA_WIDTH-1:0] expected_gray;

      if (!scoreboard_enable) return;
      if (expected_q.size() == 0) begin
          // Ciclos ociosos (ok para diversos protocolos). Apenas compare quando o estímulo estiver pendente
          return;
      end

      expected = expected_q.pop_front();
      expected_gray = expected.data ^ (expected.data >> 1);
      if (!check_gray_enable || tr.observed_data == expected_gray) begin
          match_count++;
          `uvm_info("SB/MATCH", $sformatf("input=0x%0h gray=0x%0h", expected.data, tr.observed_data), UVM_MEDIUM)
      end else begin
          mismatch_count++;
          `uvm_error("SB/MISMATCH", $sformatf("input=0x%0h esperado=0x%0h observado=0x%0h", expected.data, expected_gray, tr.observed_data))
      end
    endfunction

    function void check_phase(uvm_phase phase);
        if (scoreboard_enable && expected_q.size() != 0)
            `uvm_error("SB/PENDING", $sformatf("%0d transações esperadas não foram observadas", expected_q.size()))
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB/REPORT", $sformatf("matches=%0d mismatches=%0d", match_count, mismatch_count), UVM_NONE)
    endfunction
endclass
`endif
