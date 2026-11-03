// ============================================
// Instruction Memory — Read-only ROM
// 256 words x 32-bit = 1KB program space
//
// SIMULATION: loads instructions.mem with $readmemh (as before), so all
//             testbenches and programs keep working unchanged.
// SYNTHESIS : Vivado defines SYNTHESIS automatically. $readmemh with a
//             relative path is not found from the synthesis run folder
//             (gives an EMPTY ROM on the board), so the 10-load test
//             program is built in directly here instead.
// ============================================
module instr_mem (
    input  [31:0] addr,        // PC value comes in here
    output [31:0] instruction  // 32-bit instruction goes out
);

    reg [31:0] mem [0:255];    // 256 instruction slots

`ifdef SYNTHESIS
    // 10-load hazard test program (same as instructions.mem, 33 words)
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000013;   // NOP padding
        mem[ 0] = 32'h06f00093;
        mem[ 1] = 32'h00000113;
        mem[ 2] = 32'h00112023;
        mem[ 3] = 32'h0de00193;
        mem[ 4] = 32'h00400213;
        mem[ 5] = 32'h00322023;
        mem[ 6] = 32'h00000e13;
        mem[ 7] = 32'h000e2e83;
        mem[ 8] = 32'h001e8f13;
        mem[ 9] = 32'h000e2e83;
        mem[10] = 32'h001e8f13;
        mem[11] = 32'h000e2e83;
        mem[12] = 32'h001e8f13;
        mem[13] = 32'h000e2e83;
        mem[14] = 32'h001e8f13;
        mem[15] = 32'h000e2e83;
        mem[16] = 32'h001e8f13;
        mem[17] = 32'h000e2e83;
        mem[18] = 32'h001e8f13;
        mem[19] = 32'h000e2e83;
        mem[20] = 32'h001e8f13;
        mem[21] = 32'h00400e13;
        mem[22] = 32'h00500693;
        mem[23] = 32'h000e2e83;
        mem[24] = 32'h001e8f13;
        mem[25] = 32'h00400e13;
        mem[26] = 32'h00500693;
        mem[27] = 32'h000e2e83;
        mem[28] = 32'h001e8f13;
        mem[29] = 32'h00000e13;
        mem[30] = 32'h000e2e83;
        mem[31] = 32'h001e8f13;
        mem[32] = 32'h00000fef;
    end
`else
    // Load program from file at simulation start
    initial begin
        $readmemh("instructions.mem", mem);
    end
`endif

    // Read is combinational — address divided by 4 = word index
    assign instruction = mem[addr[9:2]];  // addr[9:2] = addr/4

endmodule
