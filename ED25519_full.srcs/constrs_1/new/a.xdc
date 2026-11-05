# ==========================================
# CLOCK 100 MHz
# ==========================================
create_clock -name clk -period 10.000 \
    -waveform {0.000 5.000} [get_ports clk]

# ==========================================
# INPUT DELAY
# ==========================================
set_input_delay -clock [get_clocks clk] -max 2.000 \
    [get_ports {A[*] B[*] start rst}]

set_input_delay -clock [get_clocks clk] -min 0.500 \
    [get_ports {A[*] B[*] start rst}]

# ==========================================
# OUTPUT DELAY
# ==========================================
set_output_delay -clock [get_clocks clk] -max 2.000 \
    [get_ports {result[*] done}]

set_output_delay -clock [get_clocks clk] -min 0.500 \
    [get_ports {result[*] done}]