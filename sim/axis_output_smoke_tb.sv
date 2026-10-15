`timescale 1ns/1ps

module axis_output_smoke_tb;
    import uvm_pkg::*;
    import axis_output_testbench_pkg::*;
    `include "uvm_macros.svh"

    axis_output_bfm #(
        .TDATA_WIDTH(TB_AXIS_OUTPUT_TDATA_WIDTH)
    ) axis_output_bfm_i();

    // Produtor simples usado como modelo temporario do DUT, sem depender de RTL.
    logic [1:0] source_index;
    logic source_done;

    always @(posedge axis_output_bfm_i.ACLK or negedge axis_output_bfm_i.ARESETn) begin
        if (!axis_output_bfm_i.ARESETn) begin
            source_index <= '0;
            source_done <= 1'b0;
            axis_output_bfm_i.TDATA <= '0;
            axis_output_bfm_i.TVALID <= 1'b0;
            axis_output_bfm_i.TLAST <= 1'b0;
        end else if (!axis_output_bfm_i.TVALID && !source_done) begin
            case (source_index)
                0: axis_output_bfm_i.TDATA <= 'h12345678;
                1: axis_output_bfm_i.TDATA <= 'hDEADBEEF;
                default: axis_output_bfm_i.TDATA <= 'hCAFEBABE;
            endcase
            axis_output_bfm_i.TVALID <= 1'b1;
            axis_output_bfm_i.TLAST <= (source_index == 2);
        end else if (axis_output_bfm_i.TVALID && axis_output_bfm_i.TREADY) begin
            if (source_index == 2) begin
                axis_output_bfm_i.TVALID <= 1'b0;
                axis_output_bfm_i.TLAST <= 1'b0;
                source_done <= 1'b1;
            end else begin
                source_index <= source_index + 1'b1;
                case (source_index + 1'b1)
                    1: axis_output_bfm_i.TDATA <= 'hDEADBEEF;
                    default: axis_output_bfm_i.TDATA <= 'hCAFEBABE;
                endcase
                axis_output_bfm_i.TLAST <= (source_index == 1);
            end
        end
    end

    initial begin
        string selected_test;

        uvm_config_db#(virtual axis_output_bfm #(
            .TDATA_WIDTH(TB_AXIS_OUTPUT_TDATA_WIDTH)
        ))::set(null, "uvm_test_top", "axis_output_vif", axis_output_bfm_i);

        if (!$value$plusargs("UVM_TESTNAME=%s", selected_test))
            selected_test = "axis_output_smoke_test";

        run_test(selected_test);
    end
endmodule
