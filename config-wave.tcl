# ===================== WAVE =================================
# Log everything to waveform:
log_wave -recursive *

# Light option, define which signals to log into waveform (change name of TESTBENCH TOP accordingly):
# log_wave /gray_encoder_sync_tb/*

# --------------------- bfm --------------------------------
#=== Divider for visual separation or group for packaging signals:
add_wave_divider "bfm_div" -color #0000FF
add_wave_group "bfm"

#=== Add all signals (*) or list them one by one (change name of TESTBENCH TOP and SIGNALS accordingly):
#add_wave {{/gray_encoder_sync_tb/bfm/*}}
add_wave /gray_encoder_sync_tb/bfm/clk -at_wave "bfm"
add_wave /gray_encoder_sync_tb/bfm/rst -at_wave "bfm"
add_wave /gray_encoder_sync_tb/bfm/data_in -at_wave "bfm"
add_wave /gray_encoder_sync_tb/bfm/data_out -at_wave "bfm"

# ===================== RUN ==================================
run all

# ===================== COVERAGE =============================
# exec xcrg -dir . -db_name func_cov_DB -report_dir ../../report/functional_coverage -report_format html

# ===================== DEBUG ================================
puts "Simulation finished at time [current_time]"
