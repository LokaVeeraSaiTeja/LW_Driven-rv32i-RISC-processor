`timescale 1ns/1ps
// ============================================================
// Paper-style waveform testbench -- LW-DRIVEN project ONLY.
// SIMULATION-ONLY: replace riscv_tb.v with this. Not for synthesis.
// Runs the paper's Table I program and exposes paper-style signals:
//   CLOCK, RESET, ENABLE, OUTPUT, PC, BUBBLE_DETECTED, BUBBLE_FIX,
//   BUBBLE_INSERTED
// ============================================================
module riscv_tb;
    reg CLOCK, RESET;
    integer cycle, bubbles, fixes, last_wb_cycle;

    initial CLOCK = 0;
    always #5 CLOCK = ~CLOCK;

    riscv_top dut (.clk(CLOCK), .reset(RESET));

    // ---------- paper-style waveform signals (add these to the wave window) ----------
    wire [31:0] PC              = dut.pc_current;
    wire        ENABLE          = dut.wb_reg_write && (dut.wb_rd != 5'd0);   // register write-back
    wire [31:0] OUTPUT          = dut.wb_write_data;                         // value written back
    wire [4:0]  OUTPUT_REG      = dut.wb_rd;
    // same detection condition as the baseline hazard unit
    wire        BUBBLE_DETECTED = dut.id_ex_mem_read && (dut.id_ex_rd != 5'd0) &&
                                  ((dut.id_ex_rd == dut.if_id_instruction[19:15]) ||
                                   (dut.id_ex_rd == dut.if_id_instruction[24:20]));
    wire        BUBBLE_INSERTED = dut.pc_stall;                              // only Case 3 stalls
    // hazard detected but NO stall needed: data was fetched early by the AG
    wire        BUBBLE_FIX      = BUBBLE_DETECTED && !BUBBLE_INSERTED;

    initial begin
        cycle = 0; bubbles = 0; fixes = 0; last_wb_cycle = 0;
        RESET = 1;
        repeat (3) @(posedge CLOCK);
        RESET = 0;

        $display("================================================================");
        $display(" LW-DRIVEN -- paper Table I program (bubble mitigation)");
        $display("================================================================");
        $display("CYCLE | PC   | WRITE-BACK      | HAZARD");
        $display("------+------+-----------------+---------------------------------");

        repeat (16) begin
            @(negedge CLOCK);           // sample mid-cycle, after signals settle
            cycle = cycle + 1;
            if (BUBBLE_INSERTED) bubbles = bubbles + 1;
            if (BUBBLE_FIX)      fixes   = fixes + 1;
            if (ENABLE) last_wb_cycle = cycle;
            if (ENABLE)
                $display("%5d | 0x%02h | x%0d = %-10d | %0s", cycle, PC[7:0], OUTPUT_REG, OUTPUT,
                    BUBBLE_INSERTED ? "BUBBLE INSERTED (Case 3)" : BUBBLE_FIX ? "LOAD-USE HAZARD -> BUBBLE FIXED, no stall" : "");
            else
                $display("%5d | 0x%02h | -               | %0s", cycle, PC[7:0],
                    BUBBLE_INSERTED ? "BUBBLE INSERTED (Case 3)" : BUBBLE_FIX ? "LOAD-USE HAZARD -> BUBBLE FIXED, no stall" : "");
        end

        $display("------+------+-----------------+---------------------------------");
        $display("SUMMARY: %0d hazard(s) fixed without a bubble | %0d bubble(s) inserted",
                  fixes, bubbles);
        $display("         last result written back in cycle %0d", last_wb_cycle);
        $display("FINAL x3 = %0d (expected 24), x6 = %0d (expected 2)",
                  dut.u_reg_file.regs[3], dut.u_reg_file.regs[6]);
        $finish;
    end
endmodule
