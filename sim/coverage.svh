`ifndef TB_COVERAGE_SVH
`define TB_COVERAGE_SVH
// Manter coverpoints independentes para que intenções específicas de cobertura possam ser habilitadas/desabilitadas por configuração
class coverage extends uvm_subscriber #(sequence_item);
    `uvm_component_utils(coverage)
    bit coverage_enable = 1;
    bit data_coverage_enable = 1;

    covergroup data_cg with function sample(bit [TB_DATA_WIDTH-1:0] value);
        option.per_instance = 1;
        cp_gray: coverpoint value;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent); data_cg = new;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'(uvm_config_db#(bit)::get(this, "", "coverage_enable", coverage_enable));
        void'(uvm_config_db#(bit)::get(this, "", "data_coverage_enable", data_coverage_enable));
    endfunction

    function void write(sequence_item t);
        if (coverage_enable && data_coverage_enable) data_cg.sample(t.observed_data);
    endfunction

    function void report_phase(uvm_phase phase);
        if (coverage_enable) `uvm_info("COV/REPORT", $sformatf("Cobertura de códigos gray = %0.2f%%", data_cg.get_coverage()), UVM_NONE)
    endfunction
endclass
`endif
