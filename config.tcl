# ============================================================
# Vivado Simulator (xsim) script
# Description: This script allows configuration and control of
# the compilation, elaboration and simulation flows with the
# built-in Vivado simulator.
#
# Author: Elivander Judas Tadeu Pereira - Inatel
# Date: 2026-03-20
# Version: 1.0
#
# Version history:
# 1.0 Initial version aiming source code from UVM_PRIMER book.
#
# ============================================================


# ===================== UVM controls =========================
# Comment these 2 lines to allow changing parameter in runtime
set SCRIPT_TARGET   "all"
set GUI_MODE        "no-gui"

# Select one standalone AXI smoke test: axi_lite, axis_input or axis_output.
if {![info exists TESTBENCH_TARGET]} {
    set TESTBENCH_TARGET "axis_output"
}

if {$TESTBENCH_TARGET ni {axi_lite axis_input axis_output}} {
    error "TESTBENCH_TARGET must be axi_lite, axis_input or axis_output"
}

# UVM controls
switch $TESTBENCH_TARGET {
    axi_lite {
        set UVM_TEST "axi_lite_smoke_test"
    }
    axis_input {
        set UVM_TEST "axis_input_smoke_test"
    }
    axis_output {
        set UVM_TEST "axis_output_smoke_test"
    }
}
set UVM_VERBOSITY   "UVM_MEDIUM"
set UVM_ARGS        [list ]
set RND_SEED        1
set CODE_COVERAGE_ENABLE 0

# ================== Project definitions =====================
# Main directories
set ROOT_DIR        [pwd]

# Design (DUT) and Testbench (simulation) directories
set RTL_PATHS       "$ROOT_DIR/rtl"
set TB_PATHS        "$ROOT_DIR/sim"

# Design (DUT) file list (VHDL and Verilog/SV separated)
set XVHDL_RTL_FILES [list ]
set XVLOG_RTL_FILES [list ]

# Testbench (simulation) file list (VHDL and Verilog/SV separated)
set XVHDL_TB_FILES  [list ]
switch $TESTBENCH_TARGET {
    axi_lite {
        set RUN_DIR "$ROOT_DIR/work/axi_lite_smoke"
        set XVLOG_TB_FILES [list \
            "$TB_PATHS/axi_lite_bfm.sv" \
            "$TB_PATHS/axi_lite_testbench_pkg.sv" \
            "$TB_PATHS/axi_lite_smoke_tb.sv"]
        set TOP_NAME "axi_lite_smoke_tb"
    }
    axis_input {
        set RUN_DIR "$ROOT_DIR/work/axis_input_smoke"
        set XVLOG_TB_FILES [list \
            "$TB_PATHS/axis_input_bfm.sv" \
            "$TB_PATHS/axis_input_testbench_pkg.sv" \
            "$TB_PATHS/axis_input_smoke_tb.sv"]
        set TOP_NAME "axis_input_smoke_tb"
    }
    axis_output {
        set RUN_DIR "$ROOT_DIR/work/axis_output_smoke"
        set XVLOG_TB_FILES [list \
            "$TB_PATHS/axis_output_bfm.sv" \
            "$TB_PATHS/axis_output_testbench_pkg.sv" \
            "$TB_PATHS/axis_output_smoke_tb.sv"]
        set TOP_NAME "axis_output_smoke_tb"
    }
}
