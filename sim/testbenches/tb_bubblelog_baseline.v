`timescale 1ns/1ps
// ============================================================
// Bubble-detection console log -- BASELINE project ONLY (v2).
// SIMULATION-ONLY: replace riscv_tb.v with this. Not for synthesis.
//
// Logs every cycle the conventional hazard unit freezes the
// pipeline (pc_stall=1). In the baseline, a load-use stall fires
// when the instruction that NEEDS the load's data is in ID and the
// load itself is in EX -- so the PC shown is the waiting
// instruction (the "consumer"), and the load is the one just ahead.
// ============================================================
module riscv_tb;
    reg clk, reset;
    integer cycle_count;
    integer loads_seen, stall_cycles_total;
    reg     prev_stall;

    initial clk = 0;
    always #5 clk = ~clk;

    riscv_top dut (.clk(clk), .reset(reset));

    localparam OP_LOAD = 7'b0000011;

    initial begin
        cycle_count        = 0;
        loads_seen         = 0;
        stall_cycles_total = 0;
        prev_stall         = 0;

        reset = 1;
        repeat (3) @(posedge clk);
        reset = 0;

        $display("================================================================");
        $display(" BASELINE (conventional stall) -- live hazard detection log");
        $display("================================================================");
        $display("CYCLE | PC in ID | EVENT");
        $display("------+----------+-----------------------------------------------");

        // Run until the sentinel (address 0x80) is fetched.
        while (dut.pc_current !== 32'h80 && cycle_count < 2000) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            // count each load once (not again while it is held by a stall)
            if (dut.if_id_instruction[6:0] == OP_LOAD && !prev_stall)
                loads_seen = loads_seen + 1;

            if (dut.pc_stall) begin
                stall_cycles_total = stall_cycles_total + 1;
                $display("%5d  | 0x%02h     | LOAD-USE HAZARD -> BUBBLE INSERTED (1 cycle stall)",
                          cycle_count, dut.if_id_pc[7:0]);
            end
            prev_stall = dut.pc_stall;
        end

        // let the last instructions drain through WB before reading registers
        repeat (6) @(posedge clk);

        $display("------+----------+-----------------------------------------------");
        $display("");
        $display("SUMMARY: %0d loads executed | %0d bubbles (stall cycles) inserted",
                  loads_seen, stall_cycles_total);
        $display("");
        $display("TOTAL_CYCLES_TO_COMPLETE = %0d", cycle_count);
        $display("FINAL STATE: x28=%0d x29=%0d x30=%0d",
            dut.u_reg_file.regs[28], dut.u_reg_file.regs[29], dut.u_reg_file.regs[30]);
        $display("(must be identical to the LW-driven log -> same answer, different cycles)");
        $finish;
    end
endmodule
