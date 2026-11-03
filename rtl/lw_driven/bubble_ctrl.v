
// LW-Driven Bubble Mitigation Control Unit

module bubble_ctrl (
    input  [6:0]  id_opcode,
    input  [4:0]  id_rs1,
    input  [31:0] id_read_data1,   // register file's rs1 read
    input  [31:0] id_imm,          

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

    // Case 3: rs1 produced by the instruction immediately ahead (in EX) 
   
    wire case3 = is_load && id_ex_reg_write && (id_ex_rd != 5'd0) && (id_ex_rd == id_rs1);

    // Case 2: rs1 produced by the instruction 2 positions back (in EX/MEM)
    wire case2_fwd = ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_rs1);

    wire [31:0] rs1_for_addr = case2_fwd ? ex_mem_alu_result : id_read_data1;

    assign case3_stall = case3;
    assign early_valid = is_load && !case3;
    assign early_addr  = rs1_for_addr + id_imm;
endmodule
