module ALU_Pipe (
    input wire clk,                    // Clock
    input wire rst,                    // Reset
    // Inputs from Reservation Station
    input wire [15:0] pc_in,           // Program counter
    input wire [3:0] opcode_in,        // Opcode (0001: ADD, 0010: NAND)
    input wire [15:0] opr1_in,         // Operand 1
    input wire [15:0] opr2_in,         // Operand 2
    input wire [4:0] rrf_dest_in,      // Destination RRF tag
    input wire [1:0] cz_in,            // Condition code (00: ADA, 01: ADZ, 10: ADC)
    input wire cmp_in,                 // Compare flag (1: update flags)
    input wire valid_in,               // Instruction valid
    // Outputs to CDB and next stage
    output reg [15:0] pc_out,          // Passthrough PC
    output reg [3:0] opcode_out,       // Passthrough opcode
    output reg [4:0] rrf_dest_out,     // Passthrough RRF tag
    output reg [15:0] ex_aluc,         // ALU result
    output reg carry_flag,             // Carry flag
    output reg zero_flag,              // Zero flag
    output reg [15:0] ex_pc_next,      // Next PC
    output reg valid_out               // Output validity
);

    // Internal registers for pipeline
    reg [15:0] reg_pc;
    reg [3:0] reg_opcode;
    reg [15:0] reg_opr1;
    reg [15:0] reg_opr2;
    reg [4:0] reg_rrf_dest;
    reg [1:0] reg_cz;
    reg reg_cmp;
    reg reg_valid;

    // Internal signals for computation
    reg [16:0] add_result; // 17-bit to capture carry
    reg [15:0] nand_result;
    reg execute;           // Whether to execute based on cz
    reg [15:0] alu_result; // Final ALU result
    reg update_flags;      // Whether to update flags

    // Register inputs (pipeline stage)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_pc <= 16'b0;
            reg_opcode <= 4'b0;
            reg_opr1 <= 16'b0;
            reg_opr2 <= 16'b0;
            reg_rrf_dest <= 5'b0;
            reg_cz <= 2'b0;
            reg_cmp <= 1'b0;
            reg_valid <= 1'b0;
            carry_flag <= 1'b0;
            zero_flag <= 1'b0;
        end else begin
            reg_pc <= pc_in;
            reg_opcode <= opcode_in;
            reg_opr1 <= opr1_in;
            reg_opr2 <= opr2_in;
            reg_rrf_dest <= rrf_dest_in;
            reg_cz <= cz_in;
            reg_cmp <= cmp_in;
            reg_valid <= valid_in;
        end
    end

    // Combinational logic for ALU computation
    always @(*) begin
        // Default values
        execute = 1'b0;
        alu_result = 16'b0;
        add_result = 17'b0;
        nand_result = 16'b0;
        update_flags = 1'b0;

        if (reg_valid) begin
            case (reg_opcode)
                4'b0001: begin // ADD (ADA, ADZ, ADC)
                    // Determine if instruction should execute based on cz
                    case (reg_cz)
                        2'b00: execute = 1'b1; // ADA: unconditional
                        2'b01: execute = zero_flag; // ADZ: execute if zero flag
                        2'b10: execute = carry_flag; // ADC: execute if carry flag
                        default: execute = 1'b0;
                    endcase
                    if (execute) begin
                        add_result = {1'b0, reg_opr1} + {1'b0, reg_opr2};
                        alu_result = add_result[15:0];
                        update_flags = reg_cmp;
                    end
                end
                4'b0010: begin // NAND (NDU, NDC)
                    execute = 1'b1; // Unconditional
                    nand_result = ~(reg_opr1 & reg_opr2);
                    alu_result = nand_result;
                    update_flags = reg_cmp;
                end
                default: begin
                    execute = 1'b0;
                    alu_result = 16'b0;
                    update_flags = 1'b0;
                end
            endcase
        end
    end

    // Register outputs and update flags
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 16'b0;
            opcode_out <= 4'b0;
            rrf_dest_out <= 5'b0;
            ex_aluc <= 16'b0;
            ex_pc_next <= 16'b0;
            valid_out <= 1'b0;
            carry_flag <= 1'b0;
            zero_flag <= 1'b0;
        end else begin
            pc_out <= reg_pc;
            opcode_out <= reg_opcode;
            rrf_dest_out <= reg_rrf_dest;
            valid_out <= reg_valid && execute;
            ex_aluc <= alu_result;
            ex_pc_next <= reg_pc + 16'd1; // Increment PC by 1 for ALU instructions

            // Update flags if instruction executed and cmp_in = 1
            if (reg_valid && execute && update_flags) begin
                zero_flag <= (alu_result == 16'b0);
                if (reg_opcode == 4'b0001) begin
                    carry_flag <= add_result[16];
                end
            end
        end
    end

endmodule