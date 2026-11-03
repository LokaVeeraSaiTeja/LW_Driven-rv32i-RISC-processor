`timescale 1ns/1ps
// ============================================================
// Bubble-detection console log -- LW-DRIVEN project ONLY (v2).
// SIMULATION-ONLY: replace riscv_tb.v with this. Not for synthesis.
//
// Every time a load enters ID, prints which of the paper's three
// cases the Bubble Mitigation Control Unit detected and whether a
// bubble was still needed. A Case 3 load is held in ID for one
// extra cycle (the 1 remaining bubble); on its second cycle the
// dependency has moved to EX/MEM and it proceeds via the Case 2
// forward -- shown as a continuation line, not counted twice.
// ============================================================
module riscv_tb;
    reg clk, reset;
    integer cycle_count;
    integer loads_seen, case1_count, case2_count, case3_count, stall_cycles_total;
    reg     prev_stall;

    initial clk = 0;
    always #5 clk = ~clk;

    riscv_top dut (.clk(clk), .reset(reset));

    localparam OP_LOAD = 7'b0000011;

    initial begin
        cycle_count = 0; loads_seen = 0;
        case1_count = 0; case2_count = 0; case3_count = 0;
        stall_cycles_total = 0; prev_stall = 0;

        reset = 1;
        repeat (3) @(posedge clk);
        reset = 0;

        $display("================================================================");
        $display(" LW-DRIVEN BUBBLE MITIGATION -- live hazard-case detection log");
        $display("================================================================");
        $display("CYCLE | PC in ID | CASE DETECTED  | RESULT");
        $display("------+----------+----------------+-------------------------------");

        // Run until the sentinel (address 0x80) is fetched.
        while (dut.pc_current !== 32'h80 && cycle_count < 2000) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            if (dut.id_opcode == OP_LOAD) begin
                if (prev_stall) begin
                    // same load, released after its 1 Case-3 bubble
                    $display("%5d  | 0x%02h     |   (continued)  | released, address via EX/MEM forward",
                              cycle_count, dut.if_id_pc[7:0]);
                end else begin
                    loads_seen = loads_seen + 1;
                    if (dut.u_bubble_ctrl.case3) begin
                        case3_count = case3_count + 1;
                        $display("%5d  | 0x%02h     | Case 3         | BUBBLE INSERTED (1 cycle stall)",
                                  cycle_count, dut.if_id_pc[7:0]);
                    end else if (dut.u_bubble_ctrl.case2_fwd) begin
                        case2_count = case2_count + 1;
                        $display("%5d  | 0x%02h     | Case 2         | bubble MITIGATED (EX/MEM fwd to AG)",
                                  cycle_count, dut.if_id_pc[7:0]);
                    end else begin
                        case1_count = case1_count + 1;
                        $display("%5d  | 0x%02h     | Case 1         | bubble MITIGATED (early address)",
                                  cycle_count, dut.if_id_pc[7:0]);
                    end
                end
            end

            if (dut.pc_stall) stall_cycles_total = stall_cycles_total + 1;
            prev_stall = dut.pc_stall;
        end

        // let the last instructions drain through WB before reading registers
        repeat (6) @(posedge clk);

        $display("------+----------+----------------+-------------------------------");
        $display("");
        $display("SUMMARY: %0d loads executed | Case1=%0d Case2=%0d Case3=%0d",
                  loads_seen, case1_count, case2_count, case3_count);
        $display("  -> %0d of %0d load-use bubbles MITIGATED (Case 1 + Case 2)",
                  case1_count + case2_count, loads_seen);
        $display("  -> %0d bubbles (stall cycles) still inserted (Case 3, as the paper specifies)",
                  stall_cycles_total);
        $display("");
        $display("TOTAL_CYCLES_TO_COMPLETE = %0d", cycle_count);
        $display("FINAL STATE: x28=%0d x29=%0d x30=%0d",
            dut.u_reg_file.regs[28], dut.u_reg_file.regs[29], dut.u_reg_file.regs[30]);
        $display("(must be identical to the baseline log -> same answer, different cycles)");
        $finish;
    end
endmodule
