// ============================================
// Hazard Detection Unit (LW-driven bubble-free version)
//
// With the bubble-mitigation unit in place, the classic load-use hazard
// (Case 1/2) is resolved without a stall -- the load's data lands in EX/MEM
// on time and the existing forwarding unit picks it up normally. The only
// hazard that still genuinely needs a stall is Case 3 (bubble_ctrl.v),
// exactly as the paper describes. Control hazards (branch taken) are
// unchanged from the original design.
// ============================================
module hazard_unit (
    input       case3_stall,    // from bubble_ctrl.v
    input       branch_taken,

    output reg  pc_stall,
    output reg  if_id_stall,
    output reg  id_ex_flush,
    output reg  if_id_flush
);
    always @(*) begin
        pc_stall    = 0;
        if_id_stall = 0;
        id_ex_flush = 0;
        if_id_flush = 0;

        if (case3_stall) begin
            pc_stall    = 1;
            if_id_stall = 1;
            id_ex_flush = 1;
        end

        if (branch_taken && !case3_stall) begin
            if_id_flush = 1;
            id_ex_flush = 1;
        end
    end
endmodule
