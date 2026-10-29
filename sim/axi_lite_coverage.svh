`ifndef TB_AXI_LITE_COVERAGE_SVH
`define TB_AXI_LITE_COVERAGE_SVH

class axi_lite_coverage extends uvm_subscriber #(axi_lite_sequence_item);
    `uvm_component_utils(axi_lite_coverage)

    bit coverage_enable = 1;

    covergroup transaction_cg with function sample(
        axi_lite_operation_e operation,
        bit [1:0] address_lsb,
        bit [1:0] response
    );
        option.per_instance = 1;

        cp_operation: coverpoint operation {
            bins read = {AXI_LITE_READ};
            bins write = {AXI_LITE_WRITE};
        }

        cp_address_alignment: coverpoint address_lsb {
            bins word_aligned = {2'b00};
            bins byte_offset = {[2'b01:2'b11]};
        }

        cp_response: coverpoint response {
            bins okay = {2'b00};
            bins exokay = {2'b01};
            bins slverr = {2'b10};
            bins decerr = {2'b11};
        }

        x_operation_response: cross cp_operation, cp_response;
        x_operation_alignment: cross cp_operation, cp_address_alignment;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        transaction_cg = new;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'(uvm_config_db#(bit)::get(this, "", "coverage_enable", coverage_enable));
    endfunction

    function void write(axi_lite_sequence_item t);
        if (coverage_enable)
            transaction_cg.sample(t.operation, t.address[1:0], t.response);
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        if (coverage_enable)
            `uvm_info("COV/AXI_LITE",
                      $sformatf("Cobertura de transacoes AXI4-Lite = %0.2f%%",
                                transaction_cg.get_coverage()),
                      UVM_NONE)
    endfunction
endclass

`endif
