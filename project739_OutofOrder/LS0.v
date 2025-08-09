module LS0_Pipe (
    input wire clk,                    // Clock
    input wire rst,                    // Reset
    // Inputs from Reservation Station
    input wire [15:0] pc_in,           // Program counter
    input wire [3:0] opcode_in,        // Opcode (0100: LW, 0101: SW)
    input wire [15:0] opr1_in,         // Base register (Rb for LW, data for SW)
    input wire [15:0] opr2_in,         // Immediate offset
    input wire [4:0] rrf_dest_in,      // Destination RRF tag (for LW)
    input wire [1:0] cz_in,            // Condition code
    input wire cmp_in,                 // Compare flag
    input wire valid_in,               // Instruction valid
    input wire [15:0] mem_read_data,   // Data read from memory
    // Outputs to CDB and memory
    output reg [15:0] pc_out,          // Passthrough PC
    output reg [3:0] opcode_out,       // Passthrough opcode
    output reg [4:0] rrf_dest_out,     // Passthrough RRF tag
    output reg [15:0] ex_aluc,         // Load result (for LW)
    output reg carry_flag,             // Carry flag
    output reg zero_flag,              // Zero flag
    output reg [15:0] ex_pc_next,      // Next PC
    output reg [15:0] mem_addr,        // Memory address
    output reg [15:0] mem_write_data,  // Data to write (for SW)
    output reg mem_write_en,           // Memory write enable
    output reg mem_read_en,            // Memory read enable
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
    reg [15:0] address;        // Computed memory address
    reg [15:0] load_result;    // Result for LW
    reg execute;               // Whether to execute based on cz
    reg update_flags;          // Whether to update flags

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

    // Combinational logic for address computation and memory control
    always @(*) begin
        // Default values
        execute = 1'b0;
        address = 16'b0;
        load_result = 16'b0;
        mem_write_en = 1'b0;
        mem_read_en = 1'b0;
        mem_write_data = 16'b0;
        update_flags = 1'b0;

        if (reg_valid) begin
            case (reg_opcode)
                4'b0100: begin // LW
                    // Determine if instruction should execute based on cz
                    case (reg_cz)
                        2'b00: execute = 1'b1; // Unconditional
                        2'b01: execute = zero_flag; // Conditional on zero flag
                        2'b10: execute = carry_flag; // Conditional on carry flag
                        default: execute = 1'b0;
                    endcase
                    if (execute) begin
                        address = reg_opr1 + reg_opr2; // Base + offset
                        load_result = mem_read_data;   // Data from memory
                        mem_read_en = 1'b1;
                        update_flags = reg_cmp;
                    end
                end
                4'b0101: begin // SW
                    case (reg_cz)
                        2'b00: execute = 1'b1; // Unconditional
                        2'b01: execute = zero_flag;
                        2'b10: execute = carry_flag;
                        default: execute = 1'b0;
                    endcase
                    if (execute) begin
                        address = reg_opr2;          // Immediate offset as address
                        mem_write_data = reg_opr1;   // Data to write
                        mem_write_en = 1'b1;
                        update_flags = reg_cmp;
                    end
                end
                default: begin
                    execute = 1'b0;
                    address = 16'b0;
                    load_result = 16'b0;
                    mem_write_en = 1'b0;
                    mem_read_en = 1'b0;
                    mem_write_data = 16'b0;
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
            mem_addr <= 16'b0;
            mem_write_data <= 16'b0;
            mem_write_en <= 1'b0;
            mem_read_en <= 1'b0;
            valid_out <= 1'b0;
            carry_flag <= 1'b0;
            zero_flag <= 1'b0;
        end else begin
            pc_out <= reg_pc;
            opcode_out <= reg_opcode;
            rrf_dest_out <= reg_rrf_dest;
            valid_out <= reg_valid && execute;
            ex_aluc <= load_result; // Only for LW
            ex_pc_next <= reg_pc + 16'd1; // Increment PC by 1
            mem_addr <= address;
            mem_write_data <= mem_write_data; // Already set combinationaly
            mem_write_en <= mem_write_en;
            mem_read_en <= mem_read_en;

            // Update flags if instruction executed and cmp_in = 1
            if (reg_valid && execute && update_flags) begin
                zero_flag <= (load_result == 16'b0); // Only for LW
                // carry_flag unchanged for load/store
            end
        end
    end

endmodule