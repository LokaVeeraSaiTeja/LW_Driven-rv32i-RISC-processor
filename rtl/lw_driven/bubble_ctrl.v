// ============================================
// LW-Driven Bubble Mitigation Control Unit
// (Kumar & Ray, IEEE TCAS-I, Jan 2026)
//
// Computes a load's data-memory address ONE STAGE EARLY, while the load is
// still in ID instead of EX. This lets the memory read begin during what
// would normally just be the load's EX cycle, so the data is ready a full
// cycle sooner -- exactly enough to remove the classic 1-cycle load-use
// stall, with no clock-period penalty.
//
// Case 1: the load's own rs1 is already resolvable with a plain register
//         read -- the common case, handled "for free".
// Case 2: the load's rs1 was written by the instruction 2 positions back,
//         currently sitting in EX/MEM (not yet written back) -- needs an
//         extra forward from EX/MEM into this early address generator.
// Case 3: the load's rs1 depends on the instruction immediately preceding
//         it (currently in EX, result not ready until the end of THIS
//         cycle) -- genuinely cannot be resolved combinationally in time.
//         Falls back to the conventional 1-cycle stall.
// ============================================
module bubble_ctrl (
    input  [6:0]  id_opcode,
    input  [4:0]  id_rs1,
    input  [31:0] id_read_data1,   // register file's rs1 read
    input  [31:0] id_imm,          // this instruction's immediate (combinational)

    input         ex_mem_reg_write,
    input  [4:0]  ex_mem_rd,
    input  [31:0] ex_mem_alu_result,

    input         id_ex_reg_write,
    input  [4:0]  id_ex_rd,

    output        early_valid,
    output        case3_stall,
    output [31:0] early_addr
);
    localparam OP_LOAD = 7'b0000011;

    wire is_load = (id_opcode == OP_LOAD);

    // Case 3: rs1 produced by the instruction immediately ahead (in EX) --
    // its result isn't ready combinationally until the end of this cycle.
    wire case3 = is_load && id_ex_reg_write && (id_ex_rd != 5'd0) && (id_ex_rd == id_rs1);

    // Case 2: rs1 produced by the instruction 2 positions back (in EX/MEM).
    wire case2_fwd = ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_rs1);

    wire [31:0] rs1_for_addr = case2_fwd ? ex_mem_alu_result : id_read_data1;

    assign case3_stall = case3;
    assign early_valid = is_load && !case3;
    assign early_addr  = rs1_for_addr + id_imm;
endmodule
