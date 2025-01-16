
rtl/config_pkg.sv

-DNO_ICE40_DEFAULT_ASSIGNMENTS
${YOSYS_DATDIR}/ice40/cells_sim.v

synth/icestorm_icebreaker/build/synth.v

-I${UART_DIR}/rtl
${UART_DIR}/rtl/uart_rx.v
${UART_DIR}/rtl/uart_tx.v

rtl/config_pkg.sv

rtl/alu.sv
