create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]
set_input_delay -clock clk -max 2.000 \
    [get_ports {A[*] B[*]}]

set_input_delay -clock clk -min 0.500 \
    [get_ports {A[*] B[*]}]