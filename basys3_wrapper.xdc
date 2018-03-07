## Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Switches
set_property PACKAGE_PIN V17 [get_ports {sel[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sel[0]}]
set_property PACKAGE_PIN V16 [get_ports {sel[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sel[1]}]
set_property PACKAGE_PIN W16 [get_ports {sel[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sel[2]}]
set_property PACKAGE_PIN W17 [get_ports {sel[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sel[3]}]

## LEDs
set_property PACKAGE_PIN U16 [get_ports {counts[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {counts[0]}]
set_property PACKAGE_PIN E19 [get_ports {counts[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {counts[1]}]
set_property PACKAGE_PIN U19 [get_ports {counts[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {counts[2]}]
set_property PACKAGE_PIN V19 [get_ports {counts[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {counts[3]}]
set_property PACKAGE_PIN W18 [get_ports {counts[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {counts[4]}]
set_property PACKAGE_PIN U15 [get_ports {counts[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {counts[5]}]
set_property PACKAGE_PIN U14 [get_ports {counts[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {counts[6]}]
set_property PACKAGE_PIN V14 [get_ports {counts[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {counts[7]}]

## Buttons
set_property PACKAGE_PIN U18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property PACKAGE_PIN W19 [get_ports data]						
set_property IOSTANDARD LVCMOS33 [get_ports data]
