module ID_STAGE (
    input wire clk,
    input wire rst,
    input wire [15:0] instr_1,      // First instruction from IF_STAGE
    input wire [15:0] instr_2,      // Second instruction from IF_STAGE
    input wire [15:0] pc_out_1,     // PC of first instruction
    input wire [15:0] pc_out_2,     // PC of second instruction
    input wire carry_flag,           // Carry flag (C)
    input wire zero_flag,            // Zero flag (Z)
    output reg [3:0] opcode_1,      // Opcode for first instruction
    output reg [3:0] opcode_2,      // Opcode for second instruction
    output reg [2:0] ra_1,          // RA index for first instruction
    output reg [2:0] rb_1,          // RB index for first instruction
    output reg [2:0] rc_1,          // RC index for first instruction
    output reg [2:0] ra_2,          // RA index for second instruction
    output reg [2:0] rb_2,          // RB index for second instruction
    output reg [2:0] rc_2,          // RC index for second instruction
    output reg [15:0] imm_1,        // Sign-extended immediate for first instruction
    output reg [15:0] imm_2,        // Sign-extended immediate for second instruction
    output reg [15:0] pc_out_1_id,  // PC of first instruction to RR stage
    output reg [15:0] pc_out_2_id,  // PC of second instruction to RR stage
    output reg alu_en_1,            // ALU enable for first instruction
    output reg alu_en_2,            // ALU enable for second instruction
    output reg [2:0] alu_op_1,      // ALU operation for first instruction
    output reg [2:0] alu_op_2,      // ALU operation for second instruction
    output reg mem_read_1,          // Memory read for first instruction
    output reg mem_read_2,          // Memory read for second instruction
    output reg mem_write_1,         // Memory write for first instruction
    output reg mem_write_2,         // Memory write for second instruction
    output reg reg_write_1,         // Register write-back for first instruction
    output reg reg_write_2,         // Register write-back for second instruction
    output reg [2:0] reg_dest_1,    // Destination register for first instruction
    output reg [2:0] reg_dest_2,    // Destination register for second instruction
    output reg branch_1,            // Branch signal for first instruction
    output reg branch_2,            // Branch signal for second instruction
    output reg jump_1,              // Jump signal for first instruction
    output reg jump_2,              // Jump signal for second instruction
    output reg [1:0] cz_1,          // Condition code for first instruction (e.g., for ADZ, ADC)
    output reg [1:0] cz_2,          // Condition code for second instruction
    output reg cmp_1,               // Compare flag for first instruction (flag update)
    output reg cmp_2,               // Compare flag for second instruction
    output reg hazard_detected      // Hazard between instr_1 and instr_2
);

    // Constants
    localparam NOP = 16'h0000; // ADI R0, R0, 0
    localparam ALU_ADD = 3'b000; // Add
    localparam ALU_ADDC = 3'b001; // Add with carry
    localparam ALU_ADD_COMP = 3'b010; // Add complement
    localparam ALU_ADDC_COMP = 3'b011; // Add complement with carry
    localparam ALU_NAND = 3'b100; // NAND
    localparam ALU_NAND_COMP = 3'b101; // NAND complement

    // Decode logic for each instruction
    always @(posedge clk) begin
        if (rst) begin
            opcode_1 <= 4'b0;
            opcode_2 <= 4'b0;
            ra_1 <= 3'b0;
            rb_1 <= 3'b0;
            rc_1 <= 3'b0;
            ra_2 <= 3'b0;
            rb_2 <= 3'b0;
            rc_2 <= 3'b0;
            imm_1 <= 16'b0;
            imm_2 <= 16'b0;
            pc_out_1_id <= 16'b0;
            pc_out_2_id <= 16'b0;
            alu_en_1 <= 1'b0;
            alu_en_2 <= 1'b0;
            alu_op_1 <= 3'b0;
            alu_op_2 <= 3'b0;
            mem_read_1 <= 1'b0;
            mem_read_2 <= 1'b0;
            mem_write_1 <= 1'b0;
            mem_write_2 <= 1'b0;
            reg_write_1 <= 1'b0;
            reg_write_2 <= 1'b0;
            reg_dest_1 <= 3'b0;
            reg_dest_2 <= 3'b0;
            branch_1 <= 1'b0;
            branch_2 <= 1'b0;
            jump_1 <= 1'b0;
            jump_2 <= 1'b0;
            cz_1 <= 2'b0;       // Reset condition code
            cz_2 <= 2'b0;
            cmp_1 <= 1'b0;      // Reset compare flag
            cmp_2 <= 1'b0;
            hazard_detected <= 1'b0;
        end else begin
            // Pass PCs
            pc_out_1_id <= pc_out_1;
            pc_out_2_id <= pc_out_2;

            // Decode Instruction 1
            opcode_1 <= instr_1[15:12];
            ra_1 <= instr_1[11:9];
            rb_1 <= instr_1[8:6];
            case (instr_1[15:12])
                // R-type: ADA, ADC, ADZ, AWC, ACA, ACC, ACZ, ACW, NDU, NDC, NDZ, NCU, NCC, NCZ
                4'b0001, 4'b0010: begin
                    rc_1 <= instr_1[5:3];
                    imm_1 <= 16'b0;
                    alu_en_1 <= 1'b1;
                    mem_read_1 <= 1'b0;
                    mem_write_1 <= 1'b0;
                    reg_write_1 <= (instr_1 == NOP) ? 1'b0 : 1'b1;
                    reg_dest_1 <= instr_1[5:3]; // RC
                    branch_1 <= 1'b0;
                    jump_1 <= 1'b0;
                    cz_1 <= instr_1[2:1];   // Condition code (CZ)
                    cmp_1 <= instr_1[0];    // Compare flag (C)
                    // Predicated execution
                    case ({instr_1[15:12], instr_1[2:0]})
                        // ADA, ACA
                        {4'b0001, 3'b000}, {4'b0001, 3'b100}: alu_op_1 <= ALU_ADD;
                        // ADC, ACC
                        {4'b0001, 3'b010}, {4'b0001, 3'b110}: alu_op_1 <= carry_flag ? ALU_ADD : ALU_ADD; // No-op if C=0
                        // ADZ, ACZ
                        {4'b0001, 3'b001}, {4'b0001, 3'b101}: alu_op_1 <= zero_flag ? ALU_ADD : ALU_ADD; // No-op if Z=0
                        // AWC, ACW
                        {4'b0001, 3'b011}, {4'b0001, 3'b111}: alu_op_1 <= ALU_ADDC;
                        // NDU, NCU
                        {4'b0010, 3'b000}, {4'b0010, 3'b100}: alu_op_1 <= ALU_NAND;
                        // NDC, NCC
                        {4'b0010, 3'b010}, {4'b0010, 3'b110}: alu_op_1 <= carry_flag ? ALU_NAND : ALU_NAND; // No-op if C=0
                        // NDZ, NCZ
                        {4'b0010, 3'b001}, {4'b0010, 3'b101}: alu_op_1 <= zero_flag ? ALU_NAND : ALU_NAND; // No-op if Z=0
                        default: alu_op_1 <= ALU_ADD;
                    endcase
                    // Disable reg_write for predicated instructions if condition fails
                    if ((instr_1[2:0] == 3'b010 && !carry_flag) || (instr_1[2:0] == 3'b001 && !zero_flag))
                        reg_write_1 <= 1'b0;
                end
                // I-type: ADI, LW, SW, BEQ, BLT, BLE
                4'b0000, 4'b0100, 4'b0101, 4'b1000, 4'b1001: begin
                    rc_1 <= 3'b0;
                    imm_1 <= {{10{instr_1[5]}}, instr_1[5:0]}; // Sign-extend 6-bit immediate
                    alu_en_1 <= (instr_1[15:12] == 4'b0000); // Only for ADI
                    alu_op_1 <= ALU_ADD;
                    mem_read_1 <= (instr_1[15:12] == 4'b0100); // LW
                    mem_write_1 <= (instr_1[15:12] == 4'b0101); // SW
                    reg_write_1 <= (instr_1[15:12] == 4'b0000 || instr_1[15:12] == 4'b0100); // ADI, LW
                    reg_dest_1 <= (instr_1[15:12] == 4'b0000) ? instr_1[8:6] : instr_1[11:9]; // RB for ADI, RA for LW
                    branch_1 <= (instr_1[15:12] == 4'b1000 || instr_1[15:12] == 4'b1001); // BEQ, BLT, BLE
                    jump_1 <= 1'b0;
                    cz_1 <= 2'b00;      // No condition code for I-type
                    cmp_1 <= 1'b0;      // No flag update
                end
                // J-type: LLI, LM, SM, JAL, JLR, JRI
                4'b0011, 4'b0110, 4'b0111, 4'b1100, 4'b1101, 4'b1111: begin
                    rc_1 <= 3'b0;
                    imm_1 <= (instr_1[15:12] == 4'b0011 || instr_1[15:12] == 4'b0110 || instr_1[15:12] == 4'b0111) ?
                             {7'b0, instr_1[8:0]} : {{7{instr_1[8]}}, instr_1[8:0]}; // Unsigned for LLI/LM/SM, signed for JAL/JRI
                    alu_en_1 <= 1'b0;
                    mem_read_1 <= (instr_1[15:12] == 4'b0110); // LM
                    mem_write_1 <= (instr_1[15:12] == 4'b0111); // SM
                    reg_write_1 <= (instr_1[15:12] == 4'b0011 || instr_1[15:12] == 4'b0110 || instr_1[15:12] == 4'b1100); // LLI, LM, JAL
                    reg_dest_1 <= instr_1[11:9]; // RA
                    branch_1 <= (instr_1[15:12] == 4'b1101); // JLR
                    jump_1 <= (instr_1[15:12] == 4'b1100 || instr_1[15:12] == 4'b1111); // JAL, JRI
                    cz_1 <= 2'b00;      // No condition code for J-type
                    cmp_1 <= 1'b0;      // No flag update
                end
                default: begin
                    rc_1 <= 3'b0;
                    imm_1 <= 16'b0;
                    alu_en_1 <= 1'b0;
                    mem_read_1 <= 1'b0;
                    mem_write_1 <= 1'b0;
                    reg_write_1 <= 1'b0;
                    reg_dest_1 <= 3'b0;
                    branch_1 <= 1'b0;
                    jump_1 <= 1'b0;
                    cz_1 <= 2'b00;      // Default: no condition
                    cmp_1 <= 1'b0;      // Default: no flag update
                end
            endcase

            // Decode Instruction 2
            opcode_2 <= instr_2[15:12];
            ra_2 <= instr_2[11:9];
            rb_2 <= instr_2[8:6];
            case (instr_2[15:12])
                // R-type
                4'b0001, 4'b0010: begin
                    rc_2 <= instr_2[5:3];
                    imm_2 <= 16'b0;
                    alu_en_2 <= 1'b1;
                    mem_read_2 <= 1'b0;
                    mem_write_2 <= 1'b0;
                    reg_write_2 <= (instr_2 == NOP) ? 1'b0 : 1'b1;
                    reg_dest_2 <= instr_2[5:3]; // RC
                    branch_2 <= 1'b0;
                    jump_2 <= 1'b0;
                    cz_2 <= instr_2[2:1];   // Condition code (CZ)
                    cmp_2 <= instr_2[0];    // Compare flag (C)
                    case ({instr_2[15:12], instr_2[2:0]})
                        {4'b0001, 3'b000}, {4'b0001, 3'b100}: alu_op_2 <= ALU_ADD;
                        {4'b0001, 3'b010}, {4'b0001, 3'b110}: alu_op_2 <= carry_flag ? ALU_ADD : ALU_ADD;
                        {4'b0001, 3'b001}, {4'b0001, 3'b101}: alu_op_2 <= zero_flag ? ALU_ADD : ALU_ADD;
                        {4'b0001, 3'b011}, {4'b0001, 3'b111}: alu_op_2 <= ALU_ADDC;
                        {4'b0010, 3'b000}, {4'b0010, 3'b100}: alu_op_2 <= ALU_NAND;
                        {4'b0010, 3'b010}, {4'b0010, 3'b110}: alu_op_2 <= carry_flag ? ALU_NAND : ALU_NAND;
                        {4'b0010, 3'b001}, {4'b0010, 3'b101}: alu_op_2 <= zero_flag ? ALU_NAND : ALU_NAND;
                        default: alu_op_2 <= ALU_ADD;
                    endcase
                    if ((instr_2[2:0] == 3'b010 && !carry_flag) || (instr_2[2:0] == 3'b001 && !zero_flag))
                        reg_write_2 <= 1'b0;
                end
                // I-type
                4'b0000, 4'b0100, 4'b0101, 4'b1000, 4'b1001: begin
                    rc_2 <= 3'b0;
                    imm_2 <= {{10{instr_2[5]}}, instr_2[5:0]};
                    alu_en_2 <= (instr_2[15:12] == 4'b0000);
                    alu_op_2 <= ALU_ADD;
                    mem_read_2 <= (instr_2[15:12] == 4'b0100);
                    mem_write_2 <= (instr_2[15:12] == 4'b0101);
                    reg_write_2 <= (instr_2[15:12] == 4'b0000 || instr_2[15:12] == 4'b0100);
                    reg_dest_2 <= (instr_2[15:12] == 4'b0000) ? instr_2[8:6] : instr_2[11:9];
                    branch_2 <= (instr_2[15:12] == 4'b1000 || instr_2[15:12] == 4'b1001);
                    jump_2 <= 1'b0;
                    cz_2 <= 2'b00;      // No condition code for I-type
                    cmp_2 <= 1'b0;      // No flag update
                end
                // J-type
                4'b0011, 4'b0110, 4'b0111, 4'b1100, 4'b1101, 4'b1111: begin
                    rc_2 <= 3'b0;
                    imm_2 <= (instr_2[15:12] == 4'b0011 || instr_2[15:12] == 4'b0110 || instr_2[15:12] == 4'b0111) ?
                             {7'b0, instr_2[8:0]} : {{7{instr_2[8]}}, instr_2[8:0]};
                    alu_en_2 <= 1'b0;
                    mem_read_2 <= (instr_2[15:12] == 4'b0110);
                    mem_write_2 <= (instr_2[15:12] == 4'b0111);
                    reg_write_2 <= (instr_2[15:12] == 4'b0011 || instr_2[15:12] == 4'b0110 || instr_2[15:12] == 4'b1100);
                    reg_dest_2 <= instr_2[11:9];
                    branch_2 <= (instr_2[15:12] == 4'b1101);
                    jump_2 <= (instr_2[15:12] == 4'b1100 || instr_2[15:12] == 4'b1111);
                    cz_2 <= 2'b00;      // No condition code for J-type
                    cmp_2 <= 1'b0;      // No flag update
                end
                default: begin
                    rc_2 <= 3'b0;
                    imm_2 <= 16'b0;
                    alu_en_2 <= 1'b0;
                    mem_read_2 <= 1'b0;
                    mem_write_2 <= 1'b0;
                    reg_write_2 <= 1'b0;
                    reg_dest_2 <= 3'b0;
                    branch_2 <= 1'b0;
                    jump_2 <= 1'b0;
                    cz_2 <= 2'b00;      // Default: no condition
                    cmp_2 <= 1'b0;      // Default: no flag update
                end
            endcase

            // Hazard detection (basic: check if instr_1 writes to a register that instr_2 reads)
            hazard_detected <= 1'b0;
            if (reg_write_1 && (reg_dest_1 != 3'b0)) begin
                if (reg_dest_1 == ra_2 || reg_dest_1 == rb_2 || (opcode_2[3:2] == 2'b00 && reg_dest_1 == rc_2))
                    hazard_detected <= 1'b1;
            end
        end
    end

endmodule