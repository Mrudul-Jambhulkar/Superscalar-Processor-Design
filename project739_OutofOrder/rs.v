module Reservation_Station (
    input wire clk,                    // Clock
    input wire rst,                    // Reset
    // Inputs from Dispatch Unit (for two instructions)
    input wire [15:0] pc_1, pc_2,      // Program counter
    input wire [3:0] opcode_1, opcode_2, // Opcode
    input wire [15:0] opr1_data_1, opr1_data_2, // Operand 1 data (from ARF or RRF)
    input wire [15:0] opr2_data_1, opr2_data_2, // Operand 2 data
    input wire [4:0] opr1_tag_1, opr1_tag_2,   // Operand 1 RRF tag (if not valid)
    input wire [4:0] opr2_tag_1, opr2_tag_2,   // Operand 2 RRF tag
    input wire opr1_valid_1, opr1_valid_2,     // Operand 1 validity
    input wire opr2_valid_1, opr2_valid_2,     // Operand 2 validity
    input wire [4:0] rrf_dest_1, rrf_dest_2,   // Destination RRF tag
    input wire valid_1, valid_2,               // Instruction valid
    input wire [1:0] cz_1, cz_2,               // Condition codes (e.g., for ADZ)
    input wire cmp_1, cmp_2,                   // Compare flag (e.g., for ADC)
    // Inputs from CDB (Common Data Bus, from EX/MEM/WB)
    input wire [4:0] cdb_tag_0, cdb_tag_1,     // RRF tag of result
    input wire [15:0] cdb_data_0, cdb_data_1,  // Result data
    input wire cdb_valid_0, cdb_valid_1,       // CDB entry valid
    // Outputs to ALU0
    output reg [15:0] pc_out_alu0,
    output reg [3:0] opcode_out_alu0,
    output reg [15:0] opr1_out_alu0,
    output reg [15:0] opr2_out_alu0,
    output reg [4:0] rrf_dest_out_alu0,
    output reg [1:0] cz_out_alu0,
    output reg cmp_out_alu0,
    output reg valid_out_alu0,
    // Outputs to ALU1
    output reg [15:0] pc_out_alu1,
    output reg [3:0] opcode_out_alu1,
    output reg [15:0] opr1_out_alu1,
    output reg [15:0] opr2_out_alu1,
    output reg [4:0] rrf_dest_out_alu1,
    output reg [1:0] cz_out_alu1,
    output reg cmp_out_alu1,
    output reg valid_out_alu1,
    // Outputs to LS0 (load/store unit)
    output reg [15:0] pc_out_ls0,
    output reg [3:0] opcode_out_ls0,
    output reg [15:0] opr1_out_ls0,
    output reg [15:0] opr2_out_ls0,
    output reg [4:0] rrf_dest_out_ls0,
    output reg [1:0] cz_out_ls0,
    output reg cmp_out_ls0,
    output reg valid_out_ls0,
    // Output to Dispatch Unit (for stall control)
    output reg rs_full                 // RS full, stall dispatch
);

    // RS storage: 32 entries
    reg [15:0] rs_pc [0:31];           // Program counter
    reg [3:0] rs_opcode [0:31];        // Opcode
    reg [15:0] rs_opr1_data [0:31];    // Operand 1 data
    reg [15:0] rs_opr2_data [0:31];    // Operand 2 data
    reg [4:0] rs_opr1_tag [0:31];      // Operand 1 RRF tag
    reg [4:0] rs_opr2_tag [0:31];      // Operand 2 RRF tag
    reg rs_opr1_valid [0:31];          // Operand 1 valid
    reg rs_opr2_valid [0:31];          // Operand 2 valid
    reg [4:0] rs_rrf_dest [0:31];      // Destination RRF tag
    reg rs_busy [0:31];                // Entry busy
    reg [1:0] rs_cz [0:31];            // Condition codes
    reg rs_cmp [0:31];                 // Compare flag

    // Internal signals
    reg [5:0] free_entry_1, free_entry_2; // Indices of free RS entries
    reg [5:0] alu0_entry, alu1_entry, ls0_entry; // Selected entries for issue
    reg alu0_ready, alu1_ready, ls0_ready; // Ready flags for issue
    integer i;

    // Find free entries for writing (combinational)
    always @(*) begin
        free_entry_1 = 32; // Default: no free entry
        free_entry_2 = 32;
        for (i = 0; i < 32; i = i + 1) begin
            if (!rs_busy[i] && free_entry_1 == 32) begin
                free_entry_1 = i;
            end else if (!rs_busy[i] && free_entry_2 == 32 && i != free_entry_1) begin
                free_entry_2 = i;
            end
        end
        // RS full signal
        rs_full = (free_entry_1 == 32); // Stall if no free entries
    end

    // Write new instructions from Dispatch Unit (sequential)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                rs_busy[i] <= 1'b0;
                rs_pc[i] <= 16'b0;
                rs_opcode[i] <= 4'b0;
                rs_opr1_data[i] <= 16'b0;
                rs_opr2_data[i] <= 16'b0;
                rs_opr1_tag[i] <= 5'b0;
                rs_opr2_tag[i] <= 5'b0;
                rs_opr1_valid[i] <= 1'b0;
                rs_opr2_valid[i] <= 1'b0;
                rs_rrf_dest[i] <= 5'b0;
                rs_cz[i] <= 2'b0;
                rs_cmp[i] <= 1'b0;
            end
        end else begin
            // Write instruction 1
            if (valid_1 && free_entry_1 != 32) begin
                rs_pc[free_entry_1] <= pc_1;
                rs_opcode[free_entry_1] <= opcode_1;
                rs_opr1_data[free_entry_1] <= opr1_data_1;
                rs_opr2_data[free_entry_1] <= opr2_data_1;
                rs_opr1_tag[free_entry_1] <= opr1_tag_1;
                rs_opr2_tag[free_entry_1] <= opr2_tag_1;
                rs_opr1_valid[free_entry_1] <= opr1_valid_1;
                rs_opr2_valid[free_entry_1] <= opr2_valid_1;
                rs_rrf_dest[free_entry_1] <= rrf_dest_1;
                rs_cz[free_entry_1] <= cz_1;
                rs_cmp[free_entry_1] <= cmp_1;
                rs_busy[free_entry_1] <= 1'b1;
            end
            // Write instruction 2
            if (valid_2 && free_entry_2 != 32 && free_entry_2 != free_entry_1) begin
                rs_pc[free_entry_2] <= pc_2;
                rs_opcode[free_entry_2] <= opcode_2;
                rs_opr1_data[free_entry_2] <= opr1_data_2;
                rs_opr2_data[free_entry_2] <= opr2_data_2;
                rs_opr1_tag[free_entry_2] <= opr1_tag_2;
                rs_opr2_tag[free_entry_2] <= opr2_tag_2;
                rs_opr1_valid[free_entry_2] <= opr1_valid_2;
                rs_opr2_valid[free_entry_2] <= opr2_valid_2;
                rs_rrf_dest[free_entry_2] <= rrf_dest_2;
                rs_cz[free_entry_2] <= cz_2;
                rs_cmp[free_entry_2] <= cmp_2;
                rs_busy[free_entry_2] <= 1'b1;
            end
        end
    end

    // Update operands from CDB (sequential)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Handled in write block
        end else begin
            for (i = 0; i < 32; i = i + 1) begin
                if (rs_busy[i]) begin
                    // Update operand 1 from CDB
                    if (!rs_opr1_valid[i] && cdb_valid_0 && cdb_tag_0 == rs_opr1_tag[i]) begin
                        rs_opr1_data[i] <= cdb_data_0;
                        rs_opr1_valid[i] <= 1'b1;
                    end else if (!rs_opr1_valid[i] && cdb_valid_1 && cdb_tag_1 == rs_opr1_tag[i]) begin
                        rs_opr1_data[i] <= cdb_data_1;
                        rs_opr1_valid[i] <= 1'b1;
                    end
                    // Update operand 2 from CDB
                    if (!rs_opr2_valid[i] && cdb_valid_0 && cdb_tag_0 == rs_opr2_tag[i]) begin
                        rs_opr2_data[i] <= cdb_data_0;
                        rs_opr2_valid[i] <= 1'b1;
                    end else if (!rs_opr2_valid[i] && cdb_valid_1 && cdb_tag_1 == rs_opr2_tag[i]) begin
                        rs_opr2_data[i] <= cdb_data_1;
                        rs_opr2_valid[i] <= 1'b1;
                    end
                end
            end
        end
    end

    // Issue logic (combinational)
    always @(*) begin
        // Defaults
        alu0_entry = 32;
        alu1_entry = 32;
        ls0_entry = 32;
        alu0_ready = 1'b0;
        alu1_ready = 1'b0;
        ls0_ready = 1'b0;

        // Find ready instructions
        for (i = 0; i < 32; i = i + 1) begin
            if (rs_busy[i] && rs_opr1_valid[i] && rs_opr2_valid[i]) begin
                // Load/store instructions (e.g., LW, SW)
                if (rs_opcode[i] == 4'b1000 || rs_opcode[i] == 4'b1001) begin
                    if (ls0_entry == 32) begin
                        ls0_entry = i;
                        ls0_ready = 1'b1;
                    end
                end
                // ALU instructions (ADA, NDU, ADC, ADZ, NDC)
                else if (rs_opcode[i] == 4'b0000 || rs_opcode[i] == 4'b0111 ||
                         rs_opcode[i] == 4'b1100 || rs_opcode[i] == 4'b0101 ||
                         rs_opcode[i] == 4'b1101) begin
                    if (alu0_entry == 32) begin
                        alu0_entry = i;
                        alu0_ready = 1'b1;
                    end else if (alu1_entry == 32 && i != alu0_entry) begin
                        alu1_entry = i;
                        alu1_ready = 1'b1;
                    end
                end
            end
        end

        // Output to ALU0
        if (alu0_ready) begin
            pc_out_alu0 = rs_pc[alu0_entry];
            opcode_out_alu0 = rs_opcode[alu0_entry];
            opr1_out_alu0 = rs_opr1_data[alu0_entry];
            opr2_out_alu0 = rs_opr2_data[alu0_entry];
            rrf_dest_out_alu0 = rs_rrf_dest[alu0_entry];
            cz_out_alu0 = rs_cz[alu0_entry];
            cmp_out_alu0 = rs_cmp[alu0_entry];
            valid_out_alu0 = 1'b1;
        end else begin
            pc_out_alu0 = 16'b0;
            opcode_out_alu0 = 4'b0;
            opr1_out_alu0 = 16'b0;
            opr2_out_alu0 = 16'b0;
            rrf_dest_out_alu0 = 5'b0;
            cz_out_alu0 = 2'b0;
            cmp_out_alu0 = 1'b0;
            valid_out_alu0 = 1'b0;
        end

        // Output to ALU1
        if (alu1_ready) begin
            pc_out_alu1 = rs_pc[alu1_entry];
            opcode_out_alu1 = rs_opcode[alu1_entry];
            opr1_out_alu1 = rs_opr1_data[alu1_entry];
            opr2_out_alu1 = rs_opr2_data[alu1_entry];
            rrf_dest_out_alu1 = rs_rrf_dest[alu1_entry];
            cz_out_alu1 = rs_cz[alu1_entry];
            cmp_out_alu1 = rs_cmp[alu1_entry];
            valid_out_alu1 = 1'b1;
        end else begin
            pc_out_alu1 = 16'b0;
            opcode_out_alu1 = 4'b0;
            opr1_out_alu1 = 16'b0;
            opr2_out_alu1 = 16'b0;
            rrf_dest_out_alu1 = 5'b0;
            cz_out_alu1 = 2'b0;
            cmp_out_alu1 = 1'b0;
            valid_out_alu1 = 1'b0;
        end

        // Output to LS0
        if (ls0_ready) begin
            pc_out_ls0 = rs_pc[ls0_entry];
            opcode_out_ls0 = rs_opcode[ls0_entry];
            opr1_out_ls0 = rs_opr1_data[ls0_entry];
            opr2_out_ls0 = rs_opr2_data[ls0_entry];
            rrf_dest_out_ls0 = rs_rrf_dest[ls0_entry];
            cz_out_ls0 = rs_cz[ls0_entry];
            cmp_out_ls0 = rs_cmp[ls0_entry];
            valid_out_ls0 = 1'b1;
        end else begin
            pc_out_ls0 = 16'b0;
            opcode_out_ls0 = 4'b0;
            opr1_out_ls0 = 16'b0;
            opr2_out_ls0 = 16'b0;
            rrf_dest_out_ls0 = 5'b0;
            cz_out_ls0 = 2'b0;
            cmp_out_ls0 = 1'b0;
            valid_out_ls0 = 1'b0;
        end
    end

    // Clear issued entries (sequential)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Handled in write block
        end else begin
            if (alu0_ready) begin
                rs_busy[alu0_entry] <= 1'b0;
            end
            if (alu1_ready && alu1_entry != alu0_entry) begin
                rs_busy[alu1_entry] <= 1'b0;
            end
            if (ls0_ready) begin
                rs_busy[ls0_entry] <= 1'b0;
            end
        end
    end

endmodule