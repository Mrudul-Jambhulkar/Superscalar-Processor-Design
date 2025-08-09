module Top_Level (
    input wire clk,
    input wire rst
);
    // IF Stage Wires
    wire [15:0] if_pc, if_inst1, if_inst2, if_pc1, if_pc2;
    wire [15:0] im_addr_1, im_addr_2, im_output_1, im_output_2;
    wire stall, branch_taken;
    wire [15:0] branch_target;

    // IF ? ID Pipeline Wires
    wire [15:0] if_id_inst1, if_id_inst2, if_id_pc1, if_id_pc2;

    // ID Stage Wires
    wire [3:0] id_opcode_1, id_opcode_2;
    wire [2:0] id_ra_1, id_rb_1, id_rc_1, id_ra_2, id_rb_2, id_rc_2;
    wire [15:0] id_imm_1, id_imm_2;
    wire [15:0] id_pc_out_1_id, id_pc_out_2_id;
    wire id_alu_en_1, id_alu_en_2;
    wire [2:0] id_alu_op_1, id_alu_op_2;
    wire id_mem_read_1, id_mem_read_2, id_mem_write_1, id_mem_write_2;
    wire id_reg_write_1, id_reg_write_2;
    wire [2:0] id_reg_dest_1, id_reg_dest_2;
    wire id_branch_1, id_branch_2, id_jump_1, id_jump_2;
    wire [1:0] id_cz_1, id_cz_2;
    wire id_cmp_1, id_cmp_2;
    wire id_hazard_detected;

    // ID ? Dispatch Pipeline Wires
    wire [3:0] id_disp_opcode_1, id_disp_opcode_2;
    wire [2:0] id_disp_ra_1, id_disp_rb_1, id_disp_rc_1, id_disp_ra_2, id_disp_rb_2, id_disp_rc_2;
    wire [15:0] id_disp_imm_1, id_disp_imm_2;
    wire [15:0] id_disp_pc_out_1_id, id_disp_pc_out_2_id;
    wire id_disp_alu_en_1, id_disp_alu_en_2;
    wire [2:0] id_disp_alu_op_1, id_disp_alu_op_2;
    wire id_disp_mem_read_1, id_disp_mem_read_2, id_disp_mem_write_1, id_disp_mem_write_2;
    wire id_disp_reg_write_1, id_disp_reg_write_2;
    wire [2:0] id_disp_reg_dest_1, id_disp_reg_dest_2;
    wire id_disp_branch_1, id_disp_branch_2, id_disp_jump_1, id_disp_jump_2;
    wire [1:0] id_disp_cz_1, id_disp_cz_2;
    wire id_disp_cmp_1, id_disp_cmp_2;
    wire id_disp_hazard_detected;

    // Dispatch Stage Wires
    wire [3:0] disp_rs_opcode_1, disp_rs_opcode_2;
    wire [4:0] disp_rs_tag_a_1, disp_rs_tag_b_1, disp_rs_tag_a_2, disp_rs_tag_b_2;
    wire [15:0] disp_rs_data_a_1, disp_rs_data_b_1, disp_rs_data_a_2, disp_rs_data_b_2;
    wire disp_rs_valid_a_1, disp_rs_valid_b_1, disp_rs_valid_a_2, disp_rs_valid_b_2;
    wire [15:0] disp_rs_imm_1, disp_rs_imm_2;
    wire [15:0] disp_rs_pc_1, disp_rs_pc_2;
    wire disp_rs_alu_en_1, disp_rs_alu_en_2;
    wire [2:0] disp_rs_alu_op_1, disp_rs_alu_op_2;
    wire disp_rs_mem_read_1, disp_rs_mem_read_2, disp_rs_mem_write_1, disp_rs_mem_write_2;
    wire disp_rs_reg_write_1, disp_rs_reg_write_2;
    wire [4:0] disp_rs_rrf_dest_1, disp_rs_rrf_dest_2;
    wire disp_rs_branch_1, disp_rs_branch_2, disp_rs_jump_1, disp_rs_jump_2;
    wire [1:0] disp_rs_cz_1, disp_rs_cz_2;
    wire disp_rs_cmp_1, disp_rs_cmp_2;
    wire disp_rs_valid_1, disp_rs_valid_2;
    wire [2:0] disp_arf_tag_add_1, disp_arf_tag_add_2;
    wire [4:0] disp_arf_tag_out_1, disp_arf_tag_out_2;
    wire disp_arf_busy_set_1, disp_arf_busy_set_2;
    wire disp_rob_valid_1, disp_rob_valid_2;
    wire [15:0] disp_rob_pc_1, disp_rob_pc_2;
    wire [3:0] disp_rob_opcode_1, disp_rob_opcode_2;
    wire [2:0] disp_rob_arf_dest_1, disp_rob_arf_dest_2;
    wire [4:0] disp_rob_rrf_dest_1, disp_rob_rrf_dest_2;

    // ARF Wires
    wire [15:0] arf_data_0, arf_data_1, arf_data_2, arf_data_3, arf_data_4, arf_data_5, arf_data_6, arf_data_7;
    wire [4:0] arf_tag_0, arf_tag_1, arf_tag_2, arf_tag_3, arf_tag_4, arf_tag_5, arf_tag_6, arf_tag_7;
    wire [7:0] arf_busy;

    // RRF Wires
    wire [31:0] rrf_busy_status;
    wire [4:0] rrf_alloc_tag_1, rrf_alloc_tag_2;
    wire rrf_alloc_valid_1, rrf_alloc_valid_2;
    wire [4:0] rrf_free_tag;
    wire rrf_free_valid;

    // RS Wires
    wire rs_full, rs_has_one_slot;
    wire [15:0] rs_alu0_pc, rs_alu1_pc, rs_ls0_pc;
    wire [3:0] rs_alu0_opcode, rs_alu1_opcode, rs_ls0_opcode;
    wire [15:0] rs_alu0_opr1, rs_alu1_opr1, rs_ls0_opr1;
    wire [15:0] rs_alu0_opr2, rs_alu1_opr2, rs_ls0_opr2;
    wire [4:0] rs_alu0_rrf_dest, rs_alu1_rrf_dest, rs_ls0_rrf_dest;
    wire [1:0] rs_alu0_cz, rs_alu1_cz, rs_ls0_cz;
    wire rs_alu0_cmp, rs_alu1_cmp, rs_ls0_cmp;
    wire rs_alu0_valid, rs_alu1_valid, rs_ls0_valid;

    // RS ? EX Pipeline Wires
    wire [15:0] rs_ex_alu0_pc, rs_ex_alu1_pc, rs_ex_ls0_pc;
    wire [3:0] rs_ex_alu0_opcode, rs_ex_alu1_opcode, rs_ex_ls0_opcode;
    wire [15:0] rs_ex_alu0_opr1, rs_ex_alu1_opr1, rs_ex_ls0_opr1;
    wire [15:0] rs_ex_alu0_opr2, rs_ex_alu1_opr2, rs_ex_ls0_opr2;
    wire [4:0] rs_ex_alu0_rrf_dest, rs_ex_alu1_rrf_dest, rs_ex_ls0_rrf_dest;
    wire [1:0] rs_ex_alu0_cz, rs_ex_alu1_cz, rs_ex_ls0_cz;
    wire rs_ex_alu0_cmp, rs_ex_alu1_cmp, rs_ex_ls0_cmp;
    wire rs_ex_alu0_valid, rs_ex_alu1_valid, rs_ex_ls0_valid;

    // EX Stage Wires (ALU0, ALU1, LS0)
    wire [15:0] alu0_ex_aluc, alu1_ex_aluc, ls0_ex_aluc;
    wire [4:0] alu0_rrf_dest, alu1_rrf_dest, ls0_rrf_dest;
    wire alu0_valid, alu1_valid, ls0_valid;
    wire [15:0] alu0_pc_out, alu1_pc_out, ls0_pc_out;
    wire [3:0] alu0_opcode_out, alu1_opcode_out, ls0_opcode_out;
    wire alu0_carry_flag, alu1_carry_flag, ls0_carry_flag;
    wire alu0_zero_flag, alu1_zero_flag, ls0_zero_flag;
    wire [15:0] alu0_ex_pc_next, alu1_ex_pc_next, ls0_ex_pc_next;

    // LS0 Memory Wires
    wire [15:0] ls0_mem_addr, ls0_mem_write_data;
    wire ls0_mem_write_en, ls0_mem_read_en;

    // EX ? MEM Pipeline Wires
    wire [15:0] ex_mem_addr, ex_mem_write_data;
    wire ex_mem_write_en, ex_mem_read_en;

    // Data Memory Wires
    wire [15:0] mem_read_data;

    // MEM ? WB Pipeline Wires
    wire [15:0] mem_wb_read_data;

    // EX ? CDB Pipeline Wires
    wire [15:0] cdb_alu0_ex_aluc, cdb_alu1_ex_aluc, cdb_ls0_ex_aluc;
    wire [4:0] cdb_alu0_rrf_dest, cdb_alu1_rrf_dest, cdb_ls0_rrf_dest;
    wire cdb_alu0_valid, cdb_alu1_valid, cdb_ls0_valid;

    // CDB Wires
    wire [15:0] cdb_data_0, cdb_data_1;
    wire [4:0] cdb_tag_0, cdb_tag_1;
    wire cdb_valid_0, cdb_valid_1;

    // CDB ? WB Pipeline Wires
    wire [15:0] cdb_wb_data_0, cdb_wb_data_1;
    wire [4:0] cdb_wb_tag_0, cdb_wb_tag_1;
    wire cdb_wb_valid_0, cdb_wb_valid_1;

    // ROB Wires
    wire [15:0] rob_arf_value_0, rob_arf_value_1;
    wire [2:0] rob_arf_dest_0, rob_arf_dest_1;
    wire rob_arf_valid_0, rob_arf_valid_1;
    wire [15:0] rob_dest_pc_out;
    wire rob_dest_pc_valid;

    // ARF Writeback Wires
    wire [2:0] wb_arf_addr;
    wire [15:0] wb_data;
    wire wb_valid, wb_busy_clear;

    // Flag Wires (from ALU0 to ID_STAGE)
    wire carry_flag, zero_flag;

    // IF Stage
    IF_stage if_stage (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .branch_target(rob_dest_pc_out),
        .branch_taken(rob_dest_pc_valid),
        .pc(if_pc),
        .inst1(if_inst1),
        .inst2(if_inst2),
        .pc1(if_pc1),
        .pc2(if_pc2)
    );

    Inst_Memory inst_memory (
        .clk(clk),
        .addr_1(if_pc1),
        .addr_2(if_pc2),
        .IM_output_1(im_output_1),
        .IM_output_2(im_output_2)
    );

    // IF ? ID Pipeline
    IF_ID_Pipe if_id_pipe (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .inst1_in(im_output_1),
        .inst2_in(im_output_2),
        .pc1_in(if_pc1),
        .pc2_in(if_pc2),
        .inst1_out(if_id_inst1),
        .inst2_out(if_id_inst2),
        .pc1_out(if_id_pc1),
        .pc2_out(if_id_pc2)
    );

    // ID Stage
    ID_STAGE id_stage (
        .clk(clk),
        .rst(rst),
        .instr_1(if_id_inst1),
        .instr_2(if_id_inst2),
        .pc_out_1(if_id_pc1),
        .pc_out_2(if_id_pc2),
        .carry_flag(carry_flag),
        .zero_flag(zero_flag),
        .opcode_1(id_opcode_1),
        .opcode_2(id_opcode_2),
        .ra_1(id_ra_1),
        .rb_1(id_rb_1),
        .rc_1(id_rc_1),
        .ra_2(id_ra_2),
        .rb_2(id_rb_2),
        .rc_2(id_rc_2),
        .imm_1(id_imm_1),
        .imm_2(id_imm_2),
        .pc_out_1_id(id_pc_out_1_id),
        .pc_out_2_id(id_pc_out_2_id),
        .alu_en_1(id_alu_en_1),
        .alu_en_2(id_alu_en_2),
        .alu_op_1(id_alu_op_1),
        .alu_op_2(id_alu_op_2),
        .mem_read_1(id_mem_read_1),
        .mem_read_2(id_mem_read_2),
        .mem_write_1(id_mem_write_1),
        .mem_write_2(id_mem_write_2),
        .reg_write_1(id_reg_write_1),
        .reg_write_2(id_reg_write_2),
        .reg_dest_1(id_reg_dest_1),
        .reg_dest_2(id_reg_dest_2),
        .branch_1(id_branch_1),
        .branch_2(id_branch_2),
        .jump_1(id_jump_1),
        .jump_2(id_jump_2),
        .cz_1(id_cz_1),
        .cz_2(id_cz_2),
        .cmp_1(id_cmp_1),
        .cmp_2(id_cmp_2),
        .hazard_detected(id_hazard_detected)
    );

    // ID ? Dispatch Pipeline
    ID_Dispatch_Pipe id_dispatch_pipe (
        .clk(clk),
        .rst(rst),
        .opcode_1_in(id_opcode_1),
        .opcode_2_in(id_opcode_2),
        .ra_1_in(id_ra_1),
        .rb_1_in(id_rb_1),
        .rc_1_in(id_rc_1),
        .ra_2_in(id_ra_2),
        .rb_2_in(id_rb_2),
        .rc_2_in(id_rc_2),
        .imm_1_in(id_imm_1),
        .imm_2_in(id_imm_2),
        .pc_out_1_id_in(id_pc_out_1_id),
        .pc_out_2_id_in(id_pc_out_2_id),
        .alu_en_1_in(id_alu_en_1),
        .alu_en_2_in(id_alu_en_2),
        .alu_op_1_in(id_alu_op_1),
        .alu_op_2_in(id_alu_op_2),
        .mem_read_1_in(id_mem_read_1),
        .mem_read_2_in(id_mem_read_2),
        .mem_write_1_in(id_mem_write_1),
        .mem_write_2_in(id_mem_write_2),
        .reg_write_1_in(id_reg_write_1),
        .reg_write_2_in(id_reg_write_2),
        .reg_dest_1_in(id_reg_dest_1),
        .reg_dest_2_in(id_reg_dest_2),
        .branch_1_in(id_branch_1),
        .branch_2_in(id_branch_2),
        .jump_1_in(id_jump_1),
        .jump_2_in(id_jump_2),
        .cz_1_in(id_cz_1),
        .cz_2_in(id_cz_2),
        .cmp_1_in(id_cmp_1),
        .cmp_2_in(id_cmp_2),
        .hazard_detected_in(id_hazard_detected),
        .opcode_1_out(id_disp_opcode_1),
        .opcode_2_out(id_disp_opcode_2),
        .ra_1_out(id_disp_ra_1),
        .rb_1_out(id_disp_rb_1),
        .rc_1_out(id_disp_rc_1),
        .ra_2_out(id_disp_ra_2),
        .rb_2_out(id_disp_rb_2),
        .rc_2_out(id_disp_rc_2),
        .imm_1_out(id_disp_imm_1),
        .imm_2_out(id_disp_imm_2),
        .pc_out_1_id_out(id_disp_pc_out_1_id),
        .pc_out_2_id_out(id_disp_pc_out_2_id),
        .alu_en_1_out(id_disp_alu_en_1),
        .alu_en_2_out(id_disp_alu_en_2),
        .alu_op_1_out(id_disp_alu_op_1),
        .alu_op_2_out(id_disp_alu_op_2),
        .mem_read_1_out(id_disp_mem_read_1),
        .mem_read_2_out(id_disp_mem_read_2),
        .mem_write_1_out(id_disp_mem_write_1),
        .mem_write_2_out(id_disp_mem_write_2),
        .reg_write_1_out(id_disp_reg_write_1),
        .reg_write_2_out(id_disp_reg_write_2),
        .reg_dest_1_out(id_disp_reg_dest_1),
        .reg_dest_2_out(id_disp_reg_dest_2),
        .branch_1_out(id_disp_branch_1),
        .branch_2_out(id_disp_branch_2),
        .jump_1_out(id_disp_jump_1),
        .jump_2_out(id_disp_jump_2),
        .cz_1_out(id_disp_cz_1),
        .cz_2_out(id_disp_cz_2),
        .cmp_1_out(id_disp_cmp_1),
        .cmp_2_out(id_disp_cmp_2),
        .hazard_detected_out(id_disp_hazard_detected)
    );

    // Dispatch Stage
    Dispatch_Unit dispatch_unit (
        .clk(clk),
        .rst(rst),
        .opcode_1(id_disp_opcode_1),
        .opcode_2(id_disp_opcode_2),
        .ra_1(id_disp_ra_1),
        .rb_1(id_disp_rb_1),
        .rc_1(id_disp_rc_1),
        .ra_2(id_disp_ra_2),
        .rb_2(id_disp_rb_2),
        .rc_2(id_disp_rc_2),
        .imm_1(id_disp_imm_1),
        .imm_2(id_disp_imm_2),
        .pc_out_1_id(id_disp_pc_out_1_id),
        .pc_out_2_id(id_disp_pc_out_2_id),
        .alu_en_1(id_disp_alu_en_1),
        .alu_en_2(id_disp_alu_en_2),
        .alu_op_1(id_disp_alu_op_1),
        .alu_op_2(id_disp_alu_op_2),
        .mem_read_1(id_disp_mem_read_1),
        .mem_read_2(id_disp_mem_read_2),
        .mem_write_1(id_disp_mem_write_1),
        .mem_write_2(id_disp_mem_write_2),
        .reg_write_1(id_disp_reg_write_1),
        .reg_write_2(id_disp_reg_write_2),
        .reg_dest_1(id_disp_reg_dest_1),
        .reg_dest_2(id_disp_reg_dest_2),
        .branch_1(id_disp_branch_1),
        .branch_2(id_disp_branch_2),
        .jump_1(id_disp_jump_1),
        .jump_2(id_disp_jump_2),
        .cz_1(id_disp_cz_1),
        .cz_2(id_disp_cz_2),
        .cmp_1(id_disp_cmp_1),
        .cmp_2(id_disp_cmp_2),
        .hazard_detected(id_disp_hazard_detected),
        .arf_busy(arf_busy),
        .arf_tag_0(arf_tag_0),
        .arf_tag_1(arf_tag_1),
        .arf_tag_2(arf_tag_2),
        .arf_tag_3(arf_tag_3),
        .arf_tag_4(arf_tag_4),
        .arf_tag_5(arf_tag_5),
        .arf_tag_6(arf_tag_6),
        .arf_tag_7(arf_tag_7),
        .arf_data_0(arf_data_0),
        .arf_data_1(arf_data_1),
        .arf_data_2(arf_data_2),
        .arf_data_3(arf_data_3),
        .arf_data_4(arf_data_4),
        .arf_data_5(arf_data_5),
        .arf_data_6(arf_data_6),
        .arf_data_7(arf_data_7),
        .rrf_busy_status(rrf_busy_status),
        .rs_full(rs_full),
        .rs_has_one_slot(rs_has_one_slot),
        .rs_opcode_1(disp_rs_opcode_1),
        .rs_opcode_2(disp_rs_opcode_2),
        .rs_tag_a_1(disp_rs_tag_a_1),
        .rs_tag_b_1(disp_rs_tag_b_1),
        .rs_tag_a_2(disp_rs_tag_a_2),
        .rs_tag_b_2(disp_rs_tag_b_2),
        .rs_data_a_1(disp_rs_data_a_1),
        .rs_data_b_1(disp_rs_data_b_1),
        .rs_data_a_2(disp_rs_data_a_2),
        .rs_data_b_2(disp_rs_data_b_2),
        .rs_valid_a_1(disp_rs_valid_a_1),
        .rs_valid_b_1(disp_rs_valid_b_1),
        .rs_valid_a_2(disp_rs_valid_a_2),
        .rs_valid_b_2(disp_rs_valid_b_2),
        .rs_imm_1(disp_rs_imm_1),
        .rs_imm_2(disp_rs_imm_2),
        .rs_pc_1(disp_rs_pc_1),
        .rs_pc_2(disp_rs_pc_2),
        .rs_alu_en_1(disp_rs_alu_en_1),
        .rs_alu_en_2(disp_rs_alu_en_2),
        .rs_alu_op_1(disp_rs_alu_op_1),
        .rs_alu_op_2(disp_rs_alu_op_2),
        .rs_mem_read_1(disp_rs_mem_read_1),
        .rs_mem_read_2(disp_rs_mem_read_2),
        .rs_mem_write_1(disp_rs_mem_write_1),
        .rs_mem_write_2(disp_rs_mem_write_2),
        .rs_reg_write_1(disp_rs_reg_write_1),
        .rs_reg_write_2(disp_rs_reg_write_2),
        .rs_rrf_dest_1(disp_rs_rrf_dest_1),
        .rs_rrf_dest_2(disp_rs_rrf_dest_2),
        .rs_branch_1(disp_rs_branch_1),
        .rs_branch_2(disp_rs_branch_2),
        .rs_jump_1(disp_rs_jump_1),
        .rs_jump_2(disp_rs_jump_2),
        .rs_cz_1(disp_rs_cz_1),
        .rs_cz_2(disp_rs_cz_2),
        .rs_cmp_1(disp_rs_cmp_1),
        .rs_cmp_2(disp_rs_cmp_2),
        .rs_valid_1(disp_rs_valid_1),
        .rs_valid_2(disp_rs_valid_2),
        .arf_tag_add_1(disp_arf_tag_add_1),
        .arf_tag_add_2(disp_arf_tag_add_2),
        .arf_tag_out_1(disp_arf_tag_out_1),
        .arf_tag_out_2(disp_arf_tag_out_2),
        .arf_busy_set_1(disp_arf_busy_set_1),
        .arf_busy_set_2(disp_arf_busy_set_2),
        .rob_valid_1(disp_rob_valid_1),
        .rob_valid_2(disp_rob_valid_2),
        .rob_pc_1(disp_rob_pc_1),
        .rob_pc_2(disp_rob_pc_2),
        .rob_opcode_1(disp_rob_opcode_1),
        .rob_opcode_2(disp_rob_opcode_2),
        .rob_arf_dest_1(disp_rob_arf_dest_1),
        .rob_arf_dest_2(disp_rob_arf_dest_2),
        .rob_rrf_dest_1(disp_rob_rrf_dest_1),
        .rob_rrf_dest_2(disp_rob_rrf_dest_2),
        .stall(stall)
    );

    // ARF
    ARF arf (
        .clk(clk),
        .rst(rst),
        .arf_data_0(arf_data_0),
        .arf_data_1(arf_data_1),
        .arf_data_2(arf_data_2),
        .arf_data_3(arf_data_3),
        .arf_data_4(arf_data_4),
        .arf_data_5(arf_data_5),
        .arf_data_6(arf_data_6),
        .arf_data_7(arf_data_7),
        .arf_tag_0(arf_tag_0),
        .arf_tag_1(arf_tag_1),
        .arf_tag_2(arf_tag_2),
        .arf_tag_3(arf_tag_3),
        .arf_tag_4(arf_tag_4),
        .arf_tag_5(arf_tag_5),
        .arf_tag_6(arf_tag_6),
        .arf_tag_7(arf_tag_7),
        .arf_busy(arf_busy),
        .tag_add_1(disp_arf_tag_add_1),
        .tag_out_1(disp_arf_tag_out_1),
        .busy_set_1(disp_arf_busy_set_1),
        .tag_add_2(disp_arf_tag_add_2),
        .tag_out_2(disp_arf_tag_out_2),
        .busy_set_2(disp_arf_busy_set_2),
        .wb_arf_addr(rob_arf_dest_0), // Simplified: use ROB commit 0
        .wb_data(rob_arf_value_0),
        .wb_valid(rob_arf_valid_0),
        .wb_busy_clear(rob_arf_valid_0)
    );

    // RRF
    RRF rrf (
        .clk(clk),
        .rst(rst),
        .wb_rrf_tag(cdb_wb_tag_0), // Simplified: use CDB channel 0
        .wb_data(cdb_wb_data_0),
        .wb_valid(cdb_wb_valid_0),
        .alloc_tag_1(disp_rob_rrf_dest_1),
        .alloc_valid_1(disp_rob_valid_1 && disp_rs_reg_write_1),
        .alloc_tag_2(disp_rob_rrf_dest_2),
        .alloc_valid_2(disp_rob_valid_2 && disp_rs_reg_write_2),
        .free_tag(rob_arf_dest_0), // Simplified
        .free_valid(rob_arf_valid_0),
        .busy_status(rrf_busy_status)
    );

    // Reservation Station
    Reservation_Station rs (
        .clk(clk),
        .rst(rst),
        .pc_1(disp_rs_pc_1),
        .pc_2(disp_rs_pc_2),
        .opcode_1(disp_rs_opcode_1),
        .opcode_2(disp_rs_opcode_2),
        .opr1_data_1(disp_rs_data_a_1),
        .opr1_data_2(disp_rs_data_a_2),
        .opr2_data_1(disp_rs_data_b_1),
        .opr2_data_2(disp_rs_data_b_2),
        .opr1_tag_1(disp_rs_tag_a_1),
        .opr1_tag_2(disp_rs_tag_a_2),
        .opr2_tag_1(disp_rs_tag_b_1),
        .opr2_tag_2(disp_rs_tag_b_2),
        .opr1_valid_1(disp_rs_valid_a_1),
        .opr1_valid_2(disp_rs_valid_a_2),
        .opr2_valid_1(disp_rs_valid_b_1),
        .opr2_valid_2(disp_rs_valid_b_2),
        .rrf_dest_1(disp_rs_rrf_dest_1),
        .rrf_dest_2(disp_rs_rrf_dest_2),
        .valid_1(disp_rs_valid_1),
        .valid_2(disp_rs_valid_2),
        .cz_1(disp_rs_cz_1),
        .cz_2(disp_rs_cz_2),
        .cmp_1(disp_rs_cmp_1),
        .cmp_2(disp_rs_cmp_2),
        .cdb_tag_0(cdb_wb_tag_0),
        .cdb_tag_1(cdb_wb_tag_1),
        .cdb_data_0(cdb_wb_data_0),
        .cdb_data_1(cdb_wb_data_1),
        .cdb_valid_0(cdb_wb_valid_0),
        .cdb_valid_1(cdb_wb_valid_1),
        .pc_out_alu0(rs_alu0_pc),
        .opcode_out_alu0(rs_alu0_opcode),
        .opr1_out_alu0(rs_alu0_opr1),
        .opr2_out_alu0(rs_alu0_opr2),
        .rrf_dest_out_alu0(rs_alu0_rrf_dest),
        .cz_out_alu0(rs_alu0_cz),
        .cmp_out_alu0(rs_alu0_cmp),
        .valid_out_alu0(rs_alu0_valid),
        .pc_out_alu1(rs_alu1_pc),
        .opcode_out_alu1(rs_alu1_opcode),
        .opr1_out_alu1(rs_alu1_opr1),
        .opr2_out_alu1(rs_alu1_opr2),
        .rrf_dest_out_alu1(rs_alu1_rrf_dest),
        .cz_out_alu1(rs_alu1_cz),
        .cmp_out_alu1(rs_alu1_cmp),
        .valid_out_alu1(rs_alu1_valid),
        .pc_out_ls0(rs_ls0_pc),
        .opcode_out_ls0(rs_ls0_opcode),
        .opr1_out_ls0(rs_ls0_opr1),
        .opr2_out_ls0(rs_ls0_opr2),
        .rrf_dest_out_ls0(rs_ls0_rrf_dest),
        .cz_out_ls0(rs_ls0_cz),
        .cmp_out_ls0(rs_ls0_cmp),
        .valid_out_ls0(rs_ls0_valid),
        .rs_full(rs_full)
    );

    // RS ? EX Pipelines
    RS_EX_Pipe rs_ex_alu0 (
        .clk(clk),
        .rst(rst),
        .pc_in(rs_alu0_pc),
        .opcode_in(rs_alu0_opcode),
        .opr1_in(rs_alu0_opr1),
        .opr2_in(rs_alu0_opr2),
        .rrf_dest_in(rs_alu0_rrf_dest),
        .cz_in(rs_alu0_cz),
        .cmp_in(rs_alu0_cmp),
        .valid_in(rs_alu0_valid),
        .pc_out(rs_ex_alu0_pc),
        .opcode_out(rs_ex_alu0_opcode),
        .opr1_out(rs_ex_alu0_opr1),
        .opr2_out(rs_ex_alu0_opr2),
        .rrf_dest_out(rs_ex_alu0_rrf_dest),
        .cz_out(rs_ex_alu0_cz),
        .cmp_out(rs_ex_alu0_cmp),
        .valid_out(rs_ex_alu0_valid)
    );

    RS_EX_Pipe rs_ex_alu1 (
        .clk(clk),
        .rst(rst),
        .pc_in(rs_alu1_pc),
        .opcode_in(rs_alu1_opcode),
        .opr1_in(rs_alu1_opr1),
        .opr2_in(rs_alu1_opr2),
        .rrf_dest_in(rs_alu1_rrf_dest),
        .cz_in(rs_alu1_cz),
        .cmp_in(rs_alu1_cmp),
        .valid_in(rs_alu1_valid),
        .pc_out(rs_ex_alu1_pc),
        .opcode_out(rs_ex_alu1_opcode),
        .opr1_out(rs_ex_alu1_opr1),
        .opr2_out(rs_ex_alu1_opr2),
        .rrf_dest_out(rs_ex_alu1_rrf_dest),
        .cz_out(rs_ex_alu1_cz),
        .cmp_out(rs_ex_alu1_cmp),
        .valid_out(rs_ex_alu1_valid)
    );

    RS_EX_Pipe rs_ex_ls0 (
        .clk(clk),
        .rst(rst),
        .pc_in(rs_ls0_pc),
        .opcode_in(rs_ls0_opcode),
        .opr1_in(rs_ls0_opr1),
        .opr2_in(rs_ls0_opr2),
        .rrf_dest_in(rs_ls0_rrf_dest),
        .cz_in(rs_ls0_cz),
        .cmp_in(rs_ls0_cmp),
        .valid_in(rs_ls0_valid),
        .pc_out(rs_ex_ls0_pc),
        .opcode_out(rs_ex_ls0_opcode),
        .opr1_out(rs_ex_ls0_opr1),
        .opr2_out(rs_ex_ls0_opr2),
        .rrf_dest_out(rs_ex_ls0_rrf_dest),
        .cz_out(rs_ex_ls0_cz),
        .cmp_out(rs_ex_ls0_cmp),
        .valid_out(rs_ex_ls0_valid)
    );

    // EX Stage: ALU0
    ALU_Pipe alu0 (
        .clk(clk),
        .rst(rst),
        .pc_in(rs_ex_alu0_pc),
        .opcode_in(rs_ex_alu0_opcode),
        .opr1_in(rs_ex_alu0_opr1),
        .opr2_in(rs_ex_alu0_opr2),
        .rrf_dest_in(rs_ex_alu0_rrf_dest),
        .cz_in(rs_ex_alu0_cz),
        .cmp_in(rs_ex_alu0_cmp),
        .valid_in(rs_ex_alu0_valid),
        .pc_out(alu0_pc_out),
        .opcode_out(alu0_opcode_out),
        .rrf_dest_out(alu0_rrf_dest),
        .ex_aluc(alu0_ex_aluc),
        .carry_flag(alu0_carry_flag),
        .zero_flag(alu0_zero_flag),
        .ex_pc_next(alu0_ex_pc_next),
        .valid_out(alu0_valid)
    );

    // EX Stage: ALU1
    ALU_Pipe alu1 (
        .clk(clk),
        .rst(rst),
        .pc_in(rs_ex_alu1_pc),
        .opcode_in(rs_ex_alu1_opcode),
        .opr1_in(rs_ex_alu1_opr1),
        .opr2_in(rs_ex_alu1_opr2),
        .rrf_dest_in(rs_ex_alu1_rrf_dest),
        .cz_in(rs_ex_alu1_cz),
        .cmp_in(rs_ex_alu1_cmp),
        .valid_in(rs_ex_alu1_valid),
        .pc_out(alu1_pc_out),
        .opcode_out(alu1_opcode_out),
        .rrf_dest_out(alu1_rrf_dest),
        .ex_aluc(alu1_ex_aluc),
        .carry_flag(alu1_carry_flag),
        .zero_flag(alu1_zero_flag),
        .ex_pc_next(alu1_ex_pc_next),
        .valid_out(alu1_valid)
    );

    // EX Stage: LS0
    LS0_Pipe ls0 (
        .clk(clk),
        .rst(rst),
        .pc_in(rs_ex_ls0_pc),
        .opcode_in(rs_ex_ls0_opcode),
        .opr1_in(rs_ex_ls0_opr1),
        .opr2_in(rs_ex_ls0_opr2),
        .rrf_dest_in(rs_ex_ls0_rrf_dest),
        .cz_in(rs_ex_ls0_cz),
        .cmp_in(rs_ex_ls0_cmp),
        .valid_in(rs_ex_ls0_valid),
        .mem_read_data(mem_wb_read_data),
        .pc_out(ls0_pc_out),
        .opcode_out(ls0_opcode_out),
        .rrf_dest_out(ls0_rrf_dest),
        .ex_aluc(ls0_ex_aluc),
        .carry_flag(ls0_carry_flag),
        .zero_flag(ls0_zero_flag),
        .ex_pc_next(ls0_ex_pc_next),
        .mem_addr(ls0_mem_addr),
        .mem_write_data(ls0_mem_write_data),
        .mem_write_en(ls0_mem_write_en),
        .mem_read_en(ls0_mem_read_en),
        .valid_out(ls0_valid)
    );

    // EX ? MEM Pipeline
    EX_MEM_Pipe ex_mem_pipe (
        .clk(clk),
        .rst(rst),
        .mem_addr_in(ls0_mem_addr),
        .mem_write_data_in(ls0_mem_write_data),
        .mem_write_en_in(ls0_mem_write_en),
        .mem_read_en_in(ls0_mem_read_en),
        .mem_addr_out(ex_mem_addr),
        .mem_write_data_out(ex_mem_write_data),
        .mem_write_en_out(ex_mem_write_en),
        .mem_read_en_out(ex_mem_read_en)
    );

    // MEM Stage
    Data_Memory data_memory (
        .clk(clk),
        .addr(ex_mem_addr),
        .write_data(ex_mem_write_data),
        .write_en(ex_mem_write_en),
        .read_en(ex_mem_read_en),
        .read_data(mem_read_data)
    );

    // MEM ? WB Pipeline
    MEM_WB_Pipe mem_wb_pipe (
        .clk(clk),
        .rst(rst),
        .read_data_in(mem_read_data),
        .read_data_out(mem_wb_read_data)
    );

    // EX ? CDB Pipelines
    EX_CDB_Pipe ex_cdb_alu0 (
        .clk(clk),
        .rst(rst),
        .ex_aluc_in(alu0_ex_aluc),
        .rrf_dest_in(alu0_rrf_dest),
        .valid_in(alu0_valid),
        .ex_aluc_out(cdb_alu0_ex_aluc),
        .rrf_dest_out(cdb_alu0_rrf_dest),
        .valid_out(cdb_alu0_valid)
    );

    EX_CDB_Pipe ex_cdb_alu1 (
        .clk(clk),
        .rst(rst),
        .ex_aluc_in(alu1_ex_aluc),
        .rrf_dest_in(alu1_rrf_dest),
        .valid_in(alu1_valid),
        .ex_aluc_out(cdb_alu1_ex_aluc),
        .rrf_dest_out(cdb_alu1_rrf_dest),
        .valid_out(cdb_alu1_valid)
    );

    EX_CDB_Pipe ex_cdb_ls0 (
        .clk(clk),
        .rst(rst),
        .ex_aluc_in(ls0_ex_aluc),
        .rrf_dest_in(ls0_rrf_dest),
        .valid_in(ls0_valid),
        .ex_aluc_out(cdb_ls0_ex_aluc),
        .rrf_dest_out(cdb_ls0_rrf_dest),
        .valid_out(cdb_ls0_valid)
    );

    // CDB
    CDB cdb (
        .clk(clk),
        .rst(rst),
        .alu0_ex_aluc(cdb_alu0_ex_aluc),
        .alu0_rrf_dest(cdb_alu0_rrf_dest),
        .alu0_valid(cdb_alu0_valid),
        .alu1_ex_aluc(cdb_alu1_ex_aluc),
        .alu1_rrf_dest(cdb_alu1_rrf_dest),
        .alu1_valid(cdb_alu1_valid),
        .ls0_ex_aluc(cdb_ls0_ex_aluc),
        .ls0_rrf_dest(cdb_ls0_rrf_dest),
        .ls0_valid(cdb_ls0_valid),
        .cdb_data_0(cdb_data_0),
        .cdb_tag_0(cdb_tag_0),
        .cdb_valid_0(cdb_valid_0),
        .cdb_data_1(cdb_data_1),
        .cdb_tag_1(cdb_tag_1),
        .cdb_valid_1(cdb_valid_1)
    );

    // CDB ? WB Pipeline
    CDB_WB_Pipe cdb_wb_pipe (
        .clk(clk),
        .rst(rst),
        .cdb_data_0_in(cdb_data_0),
        .cdb_data_1_in(cdb_data_1),
        .cdb_tag_0_in(cdb_tag_0),
        .cdb_tag_1_in(cdb_tag_1),
        .cdb_valid_0_in(cdb_valid_0),
        .cdb_valid_1_in(cdb_valid_1),
        .cdb_data_0_out(cdb_wb_data_0),
        .cdb_data_1_out(cdb_wb_data_1),
        .cdb_tag_0_out(cdb_wb_tag_0),
        .cdb_tag_1_out(cdb_wb_tag_1),
        .cdb_valid_0_out(cdb_wb_valid_0),
        .cdb_valid_1_out(cdb_wb_valid_1)
    );

    // ROB
    ROB rob (
        .clk(clk),
        .rst(rst),
        .iss_valid_0(disp_rob_valid_1),
        .pc_iss_0(disp_rob_pc_1),
        .opcode_iss_0(disp_rob_opcode_1),
        .arf_dest_iss_0(disp_rob_arf_dest_1),
        .rrf_dest_iss_0(disp_rob_rrf_dest_1),
        .iss_valid_1(disp_rob_valid_2),
        .pc_iss_1(disp_rob_pc_2),
        .opcode_iss_1(disp_rob_opcode_2),
        .arf_dest_iss_1(disp_rob_arf_dest_2),
        .rrf_dest_iss_1(disp_rob_rrf_dest_2),
        .cdb_data_0(cdb_wb_data_0),
        .cdb_tag_0(cdb_wb_tag_0),
        .cdb_valid_0(cdb_wb_valid_0),
        .cdb_data_1(cdb_wb_data_1),
        .cdb_tag_1(cdb_wb_tag_1),
        .cdb_valid_1(cdb_wb_valid_1),
        .arf_value_0(rob_arf_value_0),
        .arf_dest_0(rob_arf_dest_0),
        .arf_valid_0(rob_arf_valid_0),
        .arf_value_1(rob_arf_value_1),
        .arf_dest_1(rob_arf_dest_1),
        .arf_valid_1(rob_arf_valid_1),
        .dest_pc_out(rob_dest_pc_out),
        .dest_pc_valid(rob_dest_pc_valid)
    );

    // Flag Assignment (use ALU0 flags for ID_STAGE)
    assign carry_flag = alu0_carry_flag;
    assign zero_flag = alu0_zero_flag;

endmodule