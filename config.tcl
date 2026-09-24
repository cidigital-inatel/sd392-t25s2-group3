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

# UVM controls
set UVM_TEST        "test"
set UVM_VERBOSITY   "UVM_MEDIUM"
set UVM_ARGS        [list ]
set RND_SEED        1

# ================== Project definitions =====================
# Main directories
set ROOT_DIR        [pwd]
set RUN_DIR         "$ROOT_DIR/work/sim"

# Design (DUT) and Testbench (simulation) directories
set RTL_PATHS       "$ROOT_DIR/rtl"
set TB_PATHS        "$ROOT_DIR/sim"

# Design (DUT) file list (VHDL and Verilog/SV separated)
set XVHDL_RTL_FILES [list ]
set XVLOG_RTL_FILES [list "$RTL_PATHS/gray_encoder_sync.sv" ]

# Testbench (simulation) file list (VHDL and Verilog/SV separated)
set XVHDL_TB_FILES  [list ]
set XVLOG_TB_FILES  [list "$TB_PATHS/bfm.sv" \
                          "$TB_PATHS/testbench_pkg.sv" \
                          "$TB_PATHS/testbench.sv" ]

# Name of the top level simulation module
set TOP_NAME        "gray_encoder_sync_tb"
