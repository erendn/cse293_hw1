
yosys -import

read_verilog synth/build/rtl.sv2v.v

prep
opt -full
stat

write_verilog -noexpr -noattr -simple-lhs synth/yosys_generic/build/synth.v
