module IF_ID_Pipe (
    input wire clk, rst,
    input wire stall,
    input wire [15:0] inst1_in, inst2_in,
    input wire [15:0] pc1_in, pc2_in,
    output reg [15:0] inst1_out, inst2_out,
    output reg [15:0] pc1_out, pc2_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            inst1_out <= 16'b0;
            inst2_out <= 16'b0;
            pc1_out <= 16'b0;
            pc2_out <= 16'b0;
        end else if (!stall) begin
            inst1_out <= inst1_in;
            inst2_out <= inst2_in;
            pc1_out <= pc1_in;
            pc2_out <= pc2_in;
        end
    end
endmodule

module ID_Dispatch_Pipe (
    input wire clk, rst,
    input wire [3:0] opcode_1_in, opcode_2_in,
    input wire [2:0] ra_1_in, rb_1_in, rc_1_in, ra_2_in, rb_2_in, rc_2_in,
    input wire [15:0] imm_1_in, imm_2_in,
    input wire [15:0] pc_out_1_id_in, pc_out_2_id_in,
    input wire alu_en_1_in, alu_en_2_in,
    input wire [2:0] alu_op_1_in, alu_op_2_in,
    input wire mem_read_1_in, mem_read_2_in,
    input wire mem_write_1_in, mem_write_2_in,
    input wire reg_write_1_in, reg_write_2_in,
    input wire [2:0] reg_dest_1_in, reg_dest_2_in,
    input wire branch_1_in, branch_2_in,
    input wire jump_1_in, jump_2_in,
    input wire [1:0] cz_1_in, cz_2_in,
    input wire cmp_1_in, cmp_2_in,
    input wire hazard_detected_in,
    output reg [3:0] opcode_1_out, opcode_2_out,
    output reg [2:0] ra_1_out, rb_1_out, rc_1_out, ra_2_out, rb_2_out, rc_2_out,
    output reg [15:0] imm_1_out, imm_2_out,
    output reg [15:0] pc_out_1_id_out, pc_out_2_id_out,
    output reg alu_en_1_out, alu_en_2_out,
    output reg [2:0] alu_op_1_out, alu_op_2_out,
    output reg mem_read_1_out, mem_read_2_out,
    output reg mem_write_1_out, mem_write_2_out,
    output reg reg_write_1_out, reg_write_2_out,
    output reg [2:0] reg_dest_1_out, reg_dest_2_out,
    output reg branch_1_out, branch_2_out,
    output reg jump_1_out, jump_2_out,
    output reg [1:0] cz_1_out, cz_2_out,
    output reg cmp_1_out, cmp_2_out,
    output reg hazard_detected_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            opcode_1_out <= 4'b0;
            opcode_2_out <= 4'b0;
            ra_1_out <= 3'b0;
            rb_1_out <= 3'b0;
            rc_1_out <= 3'b0;
            ra_2_out <= 3'b0;
            rb_2_out <= 3'b0;
            rc_2_out <= 3'b0;
            imm_1_out <= 16'b0;
            imm_2_out <= 16'b0;
            pc_out_1_id_out <= 16'b0;
            pc_out_2_id_out <= 16'b0;
            alu_en_1_out <= 1'b0;
            alu_en_2_out <= 1'b0;
            alu_op_1_out <= 3'b0;
            alu_op_2_out <= 3'b0;
            mem_read_1_out <= 1'b0;
            mem_read_2_out <= 1'b0;
            mem_write_1_out <= 1'b0;
            mem_write_2_out <= 1'b0;
            reg_write_1_out <= 1'b0;
            reg_write_2_out <= 1'b0;
            reg_dest_1_out <= 3'b0;
            reg_dest_2_out <= 3'b0;
            branch_1_out <= 1'b0;
            branch_2_out <= 1'b0;
            jump_1_out <= 1'b0;
            jump_2_out <= 1'b0;
            cz_1_out <= 2'b0;
            cz_2_out <= 2'b0;
            cmp_1_out <= 1'b0;
            cmp_2_out <= 1'b0;
            hazard_detected_out <= 1'b0;
        end else begin
            opcode_1_out <= opcode_1_in;
            opcode_2_out <= opcode_2_in;
            ra_1_out <= ra_1_in;
            rb_1_out <= rb_1_in;
            rc_1_out <= rc_1_in;
            ra_2_out <= ra_2_in;
            rb_2_out <= rb_2_in;
            rc_2_out <= rc_2_in;
            imm_1_out <= imm_1_in;
            imm_2_out <= imm_2_in;
            pc_out_1_id_out <= pc_out_1_id_in;
            pc_out_2_id_out <= pc_out_2_id_in;
            alu_en_1_out <= alu_en_1_in;
            alu_en_2_out <= alu_en_2_in;
            alu_op_1_out <= alu_op_1_in;
            alu_op_2_out <= alu_op_2_in;
            mem_read_1_out <= mem_read_1_in;
            mem_read_2_out <= mem_read_2_in;
            mem_write_1_out <= mem_write_1_in;
            mem_write_2_out <= mem_write_2_in;
            reg_write_1_out <= reg_write_1_in;
            reg_write_2_out <= reg_write_2_in;
            reg_dest_1_out <= reg_dest_1_in;
            reg_dest_2_out <= reg_dest_2_in;
            branch_1_out <= branch_1_in;
            branch_2_out <= branch_2_in;
            jump_1_out <= jump_1_in;
            jump_2_out <= jump_2_in;
            cz_1_out <= cz_1_in;
            cz_2_out <= cz_2_in;
            cmp_1_out <= cmp_1_in;
            cmp_2_out <= cmp_2_in;
            hazard_detected_out <= hazard_detected_in;
        end
    end
endmodule

module RS_EX_Pipe (
    input wire clk, rst,
    input wire [15:0] pc_in,
    input wire [3:0] opcode_in,
    input wire [15:0] opr1_in,
    input wire [15:0] opr2_in,
    input wire [4:0] rrf_dest_in,
    input wire [1:0] cz_in,
    input wire cmp_in,
    input wire valid_in,
    output reg [15:0] pc_out,
    output reg [3:0] opcode_out,
    output reg [15:0] opr1_out,
    output reg [15:0] opr2_out,
    output reg [4:0] rrf_dest_out,
    output reg [1:0] cz_out,
    output reg cmp_out,
    output reg valid_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 16'b0;
            opcode_out <= 4'b0;
            opr1_out <= 16'b0;
            opr2_out <= 16'b0;
            rrf_dest_out <= 5'b0;
            cz_out <= 2'b0;
            cmp_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            pc_out <= pc_in;
            opcode_out <= opcode_in;
            opr1_out <= opr1_in;
            opr2_out <= opr2_in;
            rrf_dest_out <= rrf_dest_in;
            cz_out <= cz_in;
            cmp_out <= cmp_in;
            valid_out <= valid_in;
        end
    end
endmodule

module EX_MEM_Pipe (
    input wire clk, rst,
    input wire [15:0] mem_addr_in,
    input wire [15:0] mem_write_data_in,
    input wire mem_write_en_in,
    input wire mem_read_en_in,
    output reg [15:0] mem_addr_out,
    output reg [15:0] mem_write_data_out,
    output reg mem_write_en_out,
    output reg mem_read_en_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_addr_out <= 16'b0;
            mem_write_data_out <= 16'b0;
            mem_write_en_out <= 1'b0;
            mem_read_en_out <= 1'b0;
        end else begin
            mem_addr_out <= mem_addr_in;
            mem_write_data_out <= mem_write_data_in;
            mem_write_en_out <= mem_write_en_in;
            mem_read_en_out <= mem_read_en_in;
        end
    end
endmodule

module MEM_WB_Pipe (
    input wire clk, rst,
    input wire [15:0] read_data_in,
    output reg [15:0] read_data_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_data_out <= 16'b0;
        end else begin
            read_data_out <= read_data_in;
        end
    end
endmodule

module EX_CDB_Pipe (
    input wire clk, rst,
    input wire [15:0] ex_aluc_in,
    input wire [4:0] rrf_dest_in,
    input wire valid_in,
    output reg [15:0] ex_aluc_out,
    output reg [4:0] rrf_dest_out,
    output reg valid_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ex_aluc_out <= 16'b0;
            rrf_dest_out <= 5'b0;
            valid_out <= 1'b0;
        end else begin
            ex_aluc_out <= ex_aluc_in;
            rrf_dest_out <= rrf_dest_in;
            valid_out <= valid_in;
        end
    end
endmodule

module CDB_WB_Pipe (
    input wire clk, rst,
    input wire [15:0] cdb_data_0_in, cdb_data_1_in,
    input wire [4:0] cdb_tag_0_in, cdb_tag_1_in,
    input wire cdb_valid_0_in, cdb_valid_1_in,
    output reg [15:0] cdb_data_0_out, cdb_data_1_out,
    output reg [4:0] cdb_tag_0_out, cdb_tag_1_out,
    output reg cdb_valid_0_out, cdb_valid_1_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cdb_data_0_out <= 16'b0;
            cdb_data_1_out <= 16'b0;
            cdb_tag_0_out <= 5'b0;
            cdb_tag_1_out <= 5'b0;
            cdb_valid_0_out <= 1'b0;
            cdb_valid_1_out <= 1'b0;
        end else begin
            cdb_data_0_out <= cdb_data_0_in;
            cdb_data_1_out <= cdb_data_1_in;
            cdb_tag_0_out <= cdb_tag_0_in;
            cdb_tag_1_out <= cdb_tag_1_in;
            cdb_valid_0_out <= cdb_valid_0_in;
            cdb_valid_1_out <= cdb_valid_1_in;
        end
    end
endmodule

