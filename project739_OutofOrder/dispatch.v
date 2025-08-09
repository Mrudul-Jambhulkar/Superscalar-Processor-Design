module Dispatch_Unit (
    input wire clk,                    // Clock
    input wire rst,                    // Reset
    // Inputs from ID_STAGE
    input wire [3:0] opcode_1, opcode_2,              // Opcodes
    input wire [2:0] ra_1, rb_1, rc_1, ra_2, rb_2, rc_2, // Source/dest ARF registers
    input wire [15:0] imm_1, imm_2,                   // Immediate values
    input wire [15:0] pc_out_1_id, pc_out_2_id,       // PCs
    input wire alu_en_1, alu_en_2,                    // ALU enable
    input wire [2:0] alu_op_1, alu_op_2,              // ALU operation
    input wire mem_read_1, mem_read_2,                // Memory read enable
    input wire mem_write_1, mem_write_2,              // Memory write enable
    input wire reg_write_1, reg_write_2,              // Register write enable
    input wire [2:0] reg_dest_1, reg_dest_2,          // Destination ARF registers
    input wire branch_1, branch_2,                    // Branch control
    input wire jump_1, jump_2,                        // Jump control
    input wire [1:0] cz_1, cz_2,                      // Condition codes
    input wire cmp_1, cmp_2,                          // Compare flags
    input wire hazard_detected,                       // Hazard detected
    // Inputs from ARF
    input wire [7:0] arf_busy,                        // Busy bits for R0–R7
    input wire [4:0] arf_tag_0, arf_tag_1, arf_tag_2, arf_tag_3,
    input wire [4:0] arf_tag_4, arf_tag_5, arf_tag_6, arf_tag_7, // RRF tags
    input wire [15:0] arf_data_0, arf_data_1, arf_data_2, arf_data_3,
    input wire [15:0] arf_data_4, arf_data_5, arf_data_6, arf_data_7, // ARF data
    // Inputs from RRF
    input wire [31:0] rrf_busy_status,                // 0: free, 1: busy
    // Inputs from Reservation Station
    input wire rs_full,                               // No free entries
    input wire rs_has_one_slot,                       // Exactly one free entry
    // Outputs to Reservation Station
    output reg [3:0] rs_opcode_1, rs_opcode_2,        // Opcodes
    output reg [4:0] rs_tag_a_1, rs_tag_b_1, rs_tag_a_2, rs_tag_b_2, // Source RRF tags
    output reg [15:0] rs_data_a_1, rs_data_b_1, rs_data_a_2, rs_data_b_2, // Source data
    output reg rs_valid_a_1, rs_valid_b_1, rs_valid_a_2, rs_valid_b_2, // Operand validity
    output reg [15:0] rs_imm_1, rs_imm_2,             // Immediates
    output reg [15:0] rs_pc_1, rs_pc_2,               // PCs
    output reg rs_alu_en_1, rs_alu_en_2,              // ALU enable
    output reg [2:0] rs_alu_op_1, rs_alu_op_2,        // ALU operation
    output reg rs_mem_read_1, rs_mem_read_2,          // Memory read
    output reg rs_mem_write_1, rs_mem_write_2,        // Memory write
    output reg rs_reg_write_1, rs_reg_write_2,        // Register write
    output reg [4:0] rs_rrf_dest_1, rs_rrf_dest_2,    // Destination RRF tags
    output reg rs_branch_1, rs_branch_2,              // Branch control
    output reg rs_jump_1, rs_jump_2,                  // Jump control
    output reg [1:0] rs_cz_1, rs_cz_2,                // Condition codes
    output reg rs_cmp_1, rs_cmp_2,                    // Compare flags
    output reg rs_valid_1, rs_valid_2,                // Instruction validity
    // Outputs to ARF
    output reg [2:0] arf_tag_add_1, arf_tag_add_2,    // ARF registers to update
    output reg [4:0] arf_tag_out_1, arf_tag_out_2,    // New RRF tags
    output reg arf_busy_set_1, arf_busy_set_2,        // Set busy bits
    // Outputs to ROB
    output reg rob_valid_1, rob_valid_2,              // Instruction validity (new)
    output reg [15:0] rob_pc_1, rob_pc_2,             // PCs (new)
    output reg [3:0] rob_opcode_1, rob_opcode_2,      // Opcodes (new)
    output reg [2:0] rob_arf_dest_1, rob_arf_dest_2,  // ARF destinations
    output reg [4:0] rob_rrf_dest_1, rob_rrf_dest_2,  // RRF tags
    // Output to IF_stage
    output reg stall                                  // Stall fetch
);

    // Internal registers for RRF tag allocation
    reg [4:0] rrf_tag_1, rrf_tag_2;
    integer i;

    // ARF tag array for easier indexing
    wire [4:0] arf_tags [0:7];
    assign arf_tags[0] = arf_tag_0;
    assign arf_tags[1] = arf_tag_1;
    assign arf_tags[2] = arf_tag_2;
    assign arf_tags[3] = arf_tag_3;
    assign arf_tags[4] = arf_tag_4;
    assign arf_tags[5] = arf_tag_5;
    assign arf_tags[6] = arf_tag_6;
    assign arf_tags[7] = arf_tag_7;

    // ARF data array
    wire [15:0] arf_data [0:7];
    assign arf_data[0] = arf_data_0;
    assign arf_data[1] = arf_data_1;
    assign arf_data[2] = arf_data_2;
    assign arf_data[3] = arf_data_3;
    assign arf_data[4] = arf_data_4;
    assign arf_data[5] = arf_data_5;
    assign arf_data[6] = arf_data_6;
    assign arf_data[7] = arf_data_7;

    // Dispatch logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset outputs
            rs_opcode_1 <= 4'b0;
            rs_opcode_2 <= 4'b0;
            rs_tag_a_1 <= 5'b0;
            rs_tag_b_1 <= 5'b0;
            rs_tag_a_2 <= 5'b0;
            rs_tag_b_2 <= 5'b0;
            rs_data_a_1 <= 16'b0;
            rs_data_b_1 <= 16'b0;
            rs_data_a_2 <= 16'b0;
            rs_data_b_2 <= 16'b0;
            rs_valid_a_1 <= 1'b0;
            rs_valid_b_1 <= 1'b0;
            rs_valid_a_2 <= 1'b0;
            rs_valid_b_2 <= 1'b0;
            rs_imm_1 <= 16'b0;
            rs_imm_2 <= 16'b0;
            rs_pc_1 <= 16'b0;
            rs_pc_2 <= 16'b0;
            rs_alu_en_1 <= 1'b0;
            rs_alu_en_2 <= 1'b0;
            rs_alu_op_1 <= 3'b0;
            rs_alu_op_2 <= 3'b0;
            rs_mem_read_1 <= 1'b0;
            rs_mem_read_2 <= 1'b0;
            rs_mem_write_1 <= 1'b0;
            rs_mem_write_2 <= 1'b0;
            rs_reg_write_1 <= 1'b0;
            rs_reg_write_2 <= 1'b0;
            rs_rrf_dest_1 <= 5'b0;
            rs_rrf_dest_2 <= 5'b0;
            rs_branch_1 <= 1'b0;
            rs_branch_2 <= 1'b0;
            rs_jump_1 <= 1'b0;
            rs_jump_2 <= 1'b0;
            rs_cz_1 <= 2'b0;
            rs_cz_2 <= 2'b0;
            rs_cmp_1 <= 1'b0;
            rs_cmp_2 <= 1'b0;
            rs_valid_1 <= 1'b0;
            rs_valid_2 <= 1'b0;
            arf_tag_add_1 <= 3'b0;
            arf_tag_add_2 <= 3'b0;
            arf_tag_out_1 <= 5'b0;
            arf_tag_out_2 <= 5'b0;
            arf_busy_set_1 <= 1'b0;
            arf_busy_set_2 <= 1'b0;
            rob_valid_1 <= 1'b0;
            rob_valid_2 <= 1'b0;
            rob_pc_1 <= 16'b0;
            rob_pc_2 <= 16'b0;
            rob_opcode_1 <= 4'b0;
            rob_opcode_2 <= 4'b0;
            rob_arf_dest_1 <= 3'b0;
            rob_arf_dest_2 <= 3'b0;
            rob_rrf_dest_1 <= 5'b0;
            rob_rrf_dest_2 <= 5'b0;
            stall <= 1'b0;
        end else begin
            // Default outputs
            rs_valid_1 <= 1'b0;
            rs_valid_2 <= 1'b0;
            rob_valid_1 <= 1'b0;
            rob_valid_2 <= 1'b0;
            arf_busy_set_1 <= 1'b0;
            arf_busy_set_2 <= 1'b0;
            stall <= 1'b0;

            // Allocate RRF tags
            rrf_tag_1 <= 5'b0;
            rrf_tag_2 <= 5'b0;
            for (i = 0; i < 32; i = i + 1) begin
                if (!rrf_busy_status[i] && rrf_tag_1 == 5'b0) begin
                    rrf_tag_1 <= i;
                end else if (!rrf_busy_status[i] && rrf_tag_2 == 5'b0 && i != rrf_tag_1) begin
                    rrf_tag_2 <= i;
                end
            end

            // Dispatch instruction 1
            if (!hazard_detected && !rs_full && rrf_tag_1 != 5'b0) begin
                // RS outputs
                rs_opcode_1 <= opcode_1;
                rs_tag_a_1 <= arf_tags[ra_1];
                rs_tag_b_1 <= (opcode_1 == 4'b0100 || opcode_1 == 4'b0101) ? arf_tags[rb_1] : arf_tags[rc_1]; // LW/SW use Rb
                rs_data_a_1 <= arf_data[ra_1];
                rs_data_b_1 <= (opcode_1 == 4'b0100 || opcode_1 == 4'b0101) ? arf_data[rb_1] : arf_data[rc_1];
                rs_valid_a_1 <= !arf_busy[ra_1];
                rs_valid_b_1 <= !(opcode_1 == 4'b0100 || opcode_1 == 4'b0101) ? !arf_busy[rc_1] : !arf_busy[rb_1];
                rs_imm_1 <= imm_1;
                rs_pc_1 <= pc_out_1_id;
                rs_alu_en_1 <= alu_en_1;
                rs_alu_op_1 <= alu_op_1;
                rs_mem_read_1 <= mem_read_1;
                rs_mem_write_1 <= mem_write_1;
                rs_reg_write_1 <= reg_write_1;
                rs_rrf_dest_1 <= reg_write_1 ? rrf_tag_1 : 5'b0;
                rs_branch_1 <= branch_1;
                rs_jump_1 <= jump_1;
                rs_cz_1 <= cz_1;
                rs_cmp_1 <= cmp_1;
                rs_valid_1 <= 1'b1;
                // ARF outputs
                if (reg_write_1) begin
                    arf_tag_add_1 <= reg_dest_1;
                    arf_tag_out_1 <= rrf_tag_1;
                    arf_busy_set_1 <= 1'b1;
                end
                // ROB outputs
                rob_valid_1 <= 1'b1;
                rob_pc_1 <= pc_out_1_id;
                rob_opcode_1 <= opcode_1;
                rob_arf_dest_1 <= reg_dest_1;
                rob_rrf_dest_1 <= reg_write_1 ? rrf_tag_1 : 5'b0;
            end else begin
                stall <= 1'b1;
            end

            // Dispatch instruction 2
            if (!hazard_detected && !rs_full && !rs_has_one_slot && rrf_tag_2 != 5'b0) begin
                rs_opcode_2 <= opcode_2;
                rs_tag_a_2 <= arf_tags[ra_2];
                rs_tag_b_2 <= (opcode_2 == 4'b0100 || opcode_2 == 4'b0101) ? arf_tags[rb_2] : arf_tags[rc_2];
                rs_data_a_2 <= arf_data[ra_2];
                rs_data_b_2 <= (opcode_2 == 4'b0100 || opcode_2 == 4'b0101) ? arf_data[rb_2] : arf_data[rc_2];
                rs_valid_a_2 <= !arf_busy[ra_2];
                rs_valid_b_2 <= !(opcode_2 == 4'b0100 || opcode_2 == 4'b0101) ? !arf_busy[rc_2] : !arf_busy[rb_2];
                rs_imm_2 <= imm_2;
                rs_pc_2 <= pc_out_2_id;
                rs_alu_en_2 <= alu_en_2;
                rs_alu_op_2 <= alu_op_2;
                rs_mem_read_2 <= mem_read_2;
                rs_mem_write_2 <= mem_write_2;
                rs_reg_write_2 <= reg_write_2;
                rs_rrf_dest_2 <= reg_write_2 ? rrf_tag_2 : 5'b0;
                rs_branch_2 <= branch_2;
                rs_jump_2 <= jump_2;
                rs_cz_2 <= cz_2;
                rs_cmp_2 <= cmp_2;
                rs_valid_2 <= 1'b1;
                if (reg_write_2) begin
                    arf_tag_add_2 <= reg_dest_2;
                    arf_tag_out_2 <= rrf_tag_2;
                    arf_busy_set_2 <= 1'b1;
                end
                rob_valid_2 <= 1'b1;
                rob_pc_2 <= pc_out_2_id;
                rob_opcode_2 <= opcode_2;
                rob_arf_dest_2 <= reg_dest_2;
                rob_rrf_dest_2 <= reg_write_2 ? rrf_tag_2 : 5'b0;
            end else if (rs_has_one_slot || rs_full) begin
                stall <= 1'b1;
            end
        end
    end

endmodule