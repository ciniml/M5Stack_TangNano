set_option -out_dir [file normalize .]
set_option -device GW1N-1-QFN48-6
set_option -pn GW1N-LV1QN48C6/I5
set_option -prj_name M5Stack_TangNano
add_file -cst [file normalize src/M5Stack_TangNano.cst]
add_file -sdc [file normalize src/M5Stack_TangNano.sdc]
add_file -hdl [file normalize src/i2c_slave.v]
add_file -hdl [file normalize src/ws2812b.sv]
add_file -hdl [file normalize src/top.sv]

run_synthesis -opt [file normalize src/synthesize.cfg]
run_pnr -timing
