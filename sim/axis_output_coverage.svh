`ifndef TB_AXIS_OUTPUT_COVERAGE_SVH
`define TB_AXIS_OUTPUT_COVERAGE_SVH

class axis_output_coverage extends uvm_subscriber #(axis_output_sequence_item);
    `uvm_component_utils(axis_output_coverage)

    localparam int BYTES_PER_BEAT = TB_AXIS_OUTPUT_TDATA_WIDTH / 8;
    localparam int MLKEM768_SHARED_SECRET_BEATS =
        (32 + BYTES_PER_BEAT - 1) / BYTES_PER_BEAT;
    localparam int MLKEM768_CIPHERTEXT_BEATS =
        (1088 + BYTES_PER_BEAT - 1) / BYTES_PER_BEAT;

    bit coverage_enable = 1;
    int unsigned packet_beats;

    covergroup beat_cg with function sample(
        bit [1:0] data_class,
        bit last,
        int unsigned stall_cycles
    );
        option.per_instance = 1;

        cp_data_class: coverpoint data_class {
            bins all_zero = {2'd0};
            bins all_one = {2'd1};
            bins mixed = {2'd2};
        }

        cp_last: coverpoint last {
            bins continues = {1'b0};
            bins packet_end = {1'b1};
        }

        cp_backpressure: coverpoint stall_cycles {
            bins no_stall = {0};
            bins one_cycle = {1};
            bins multiple_cycles = {[2:32'hFFFF_FFFF]};
        }

        x_last_backpressure: cross cp_last, cp_backpressure;
    endgroup

    covergroup packet_cg with function sample(
        int unsigned beats,
        bit [1:0] object_class
    );
        option.per_instance = 1;

        cp_packet_length: coverpoint beats {
            bins one_beat = {1};
            bins short_packet = {[2:16]};
            bins medium_packet = {[17:64]};
            bins long_packet = {[65:32'hFFFF_FFFF]};
        }

        cp_mlkem_object: coverpoint object_class {
            bins other = {2'd0};
            bins shared_secret = {2'd1};
            bins ciphertext = {2'd2};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        beat_cg = new;
        packet_cg = new;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'(uvm_config_db#(bit)::get(this, "", "coverage_enable", coverage_enable));
        if ((TB_AXIS_OUTPUT_TDATA_WIDTH % 8) != 0)
            `uvm_fatal("COV/AXIS_OUTPUT_WIDTH", "TDATA precisa conter um numero inteiro de bytes")
    endfunction

    function void write(axis_output_sequence_item t);
        bit [1:0] data_class;
        bit [1:0] object_class;

        if (!coverage_enable)
            return;

        if (t.data == '0)
            data_class = 2'd0;
        else if (t.data == '1)
            data_class = 2'd1;
        else
            data_class = 2'd2;

        beat_cg.sample(data_class, t.last, t.stall_cycles);
        packet_beats++;

        if (t.last) begin
            object_class = 2'd0;
            if (packet_beats == MLKEM768_SHARED_SECRET_BEATS)
                object_class = 2'd1;
            else if (packet_beats == MLKEM768_CIPHERTEXT_BEATS)
                object_class = 2'd2;

            packet_cg.sample(packet_beats, object_class);
            packet_beats = 0;
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        if (coverage_enable) begin
            `uvm_info("COV/AXIS_OUTPUT",
                      $sformatf("Cobertura de beats AXI4-Stream de saida = %0.2f%%",
                                beat_cg.get_coverage()),
                      UVM_NONE)
            `uvm_info("COV/AXIS_OUTPUT",
                      $sformatf("Cobertura de pacotes AXI4-Stream de saida = %0.2f%%",
                                packet_cg.get_coverage()),
                      UVM_NONE)
            if (packet_beats != 0)
                `uvm_info("COV/AXIS_OUTPUT",
                          $sformatf("Pacote incompleto observado: %0d beat(s) sem TLAST",
                                    packet_beats),
                          UVM_NONE)
        end
    endfunction
endclass

`endif
