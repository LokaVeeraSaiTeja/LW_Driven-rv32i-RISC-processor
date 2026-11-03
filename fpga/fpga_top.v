// ============================================================
// fpga_top.v  (v2: x30 now latched AFTER the pipeline drains)
// Hardware demo wrapper for the EDGE Artix-7 board (XC7A35T-FTG256).
// Instantiates riscv_top, runs the 10-load test program, and shows
// on the 16 LEDs:
//   sw0 = 0 : cycles taken to finish  (baseline 41, LW-driven 34)
//   sw0 = 1 : final value of x30      (must be 112 on BOTH designs)
//   led[15] : DONE -- lights once the result is ready
// Set THIS module as the synthesis top (not riscv_top).
// ============================================================
module fpga_top (
    input  wire        clk,       // board clock, PACKAGE_PIN N11
    input  wire        btn_rst,   // center push button, active-high
    input  wire        sw0,       // switch 0, display select
    output wire [15:0] led
);

    // 33 instructions -> sentinel instruction at byte address 0x80
    localparam [31:0] SENTINEL_PC = 32'h0000_0080;

    wire        reset = btn_rst;  // hold button = reset, release = run
    wire [31:0] pc_current;
    wire [31:0] x30_val;

    riscv_top dut (
        .clk     (clk),
        .reset   (reset),
        .dbg_pc  (pc_current),
        .dbg_x30 (x30_val)
    );

    reg        reached;      // sentinel fetched -> stop counting cycles
    reg        done;         // pipeline drained -> result latched
    reg [3:0]  drain;
    reg [31:0] cycle_count;
    reg [31:0] final_x30;

    always @(posedge clk) begin
        if (reset) begin
            reached     <= 1'b0;
            done        <= 1'b0;
            drain       <= 4'd0;
            cycle_count <= 32'd0;
            final_x30   <= 32'd0;
        end else if (!reached) begin
            if (pc_current == SENTINEL_PC)
                reached <= 1'b1;            // freeze the cycle count
            else
                cycle_count <= cycle_count + 32'd1;
        end else if (!done) begin
            // wait for the last instructions to reach write-back
            drain <= drain + 4'd1;
            if (drain == 4'd6) begin
                final_x30 <= x30_val;
                done      <= 1'b1;
            end
        end
    end

    assign led[15]   = done;
    assign led[14:0] = sw0 ? final_x30[14:0] : cycle_count[14:0];

endmodule
