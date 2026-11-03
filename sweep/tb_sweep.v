`timescale 1ns/1ps
module riscv_tb;
    reg clk, reset;
    integer cycle_count;
    integer sentinel;
    initial clk = 0;
    always #5 clk = ~clk;
    riscv_top dut (.clk(clk), .reset(reset));
    initial begin
        if (!$value$plusargs("SENTINEL=%d", sentinel)) sentinel = 0;
        cycle_count = 0;
        reset = 1;
        repeat (3) @(posedge clk);
        reset = 0;
        while (dut.pc_current !== sentinel && cycle_count < 20000) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end
        repeat (10) @(posedge clk);
        $display("RESULT cycles=%0d x29=%0d x30=%0d", cycle_count,
            dut.u_reg_file.regs[29], dut.u_reg_file.regs[30]);
        $finish;
    end
endmodule
