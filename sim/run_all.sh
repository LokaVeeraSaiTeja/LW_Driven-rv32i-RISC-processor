#!/usr/bin/env bash
# Runs every simulation in this repository with Icarus Verilog.
# Usage: ./sim/run_all.sh     (from the repository root)
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/sim/build"
rm -rf "$BUILD"; mkdir -p "$BUILD"

run () {  # $1 = core (baseline | lw_driven), $2 = program, $3 = testbench, $4 = label
    local dir="$BUILD/$4"; mkdir -p "$dir"
    cp "$ROOT/sim/programs/$2" "$dir/instructions.mem"
    local extra=""
    [ "$3" = "tb_fpga_top.v" ] && extra="$ROOT/fpga/fpga_top.v"
    ( cd "$dir" && iverilog -o sim "$ROOT"/rtl/"$1"/*.v $extra "$ROOT/sim/testbenches/$3" && vvp -n sim | grep -v "Not enough words" ) > "$dir/log.txt" 2>&1
    echo "==================== $4 ===================="
    cat "$dir/log.txt"
}

run baseline  instructions_10load.mem        tb_bubblelog_baseline.v bubblelog_baseline
run lw_driven instructions_10load.mem        tb_bubblelog_lwdriven.v bubblelog_lwdriven
run baseline  instructions_paper_table1.mem  tb_wave_baseline.v      paper_table1_baseline
run lw_driven instructions_paper_table1.mem  tb_wave_lwdriven.v      paper_table1_lwdriven
# FPGA wrapper as it is synthesized (program built into instr_mem.v)
for core in baseline lw_driven; do
    dir="$BUILD/fpga_top_$core"; mkdir -p "$dir"
    ( cd "$dir" && iverilog -DSYNTHESIS -o sim "$ROOT"/rtl/$core/*.v "$ROOT/fpga/fpga_top.v" "$ROOT/sim/testbenches/tb_fpga_top.v" && vvp -n sim ) > "$dir/log.txt" 2>&1
    echo "==================== fpga_top_$core ===================="; cat "$dir/log.txt"
done
