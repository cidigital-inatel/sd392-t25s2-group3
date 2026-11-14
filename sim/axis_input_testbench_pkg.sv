// arquvo para reunir todos os arquivos do testbench em um único pacote, facilitando a importação e o gerenciamento das dependências do testbench.

package axis_input_testbench_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter int TB_AXIS_INPUT_TDATA_WIDTH = 32;
    parameter int TB_AXIS_INPUT_TKEEP_WIDTH = TB_AXIS_INPUT_TDATA_WIDTH / 8;
    parameter int TB_AXIS_INPUT_TUSER_WIDTH = 1;

    `include "axis_input_sequence_item.svh"
    `include "axis_input_sequencer.svh"
    `include "axis_input_driver.svh"
    `include "axis_input_monitor.svh"
    `include "axis_input_coverage.svh"
    `include "axis_input_scoreboard.svh"
    `include "axis_input_agent.svh"
    `include "axis_input_smoke_sequence.svh"
    `include "axis_input_smoke_test.svh"
endpackage
