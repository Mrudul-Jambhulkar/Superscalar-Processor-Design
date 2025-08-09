module ROB (
    input wire clk,                    // Clock
    input wire rst,                    // Reset
    // Inputs from Dispatch (Issue Stage)
    input wire iss_valid_0,            // Issue valid for instruction 0
    input wire [15:0] pc_iss_0,        // PC
    input wire [3:0] opcode_iss_0,     // Opcode
    input wire [2:0] arf_dest_iss_0,   // ARF destination
    input wire [4:0] rrf_dest_iss_0,   // RRF tag
    input wire iss_valid_1,            // Issue valid for instruction 1
    input wire [15:0] pc_iss_1,
    input wire [3:0] opcode_iss_1,
    input wire [2:0] arf_dest_iss_1,
    input wire [4:0] rrf_dest_iss_1,
    // Inputs from CDB
    input wire [15:0] cdb_data_0,      // Result data
    input wire [4:0] cdb_tag_0,        // RRF tag
    input wire cdb_valid_0,            // Valid
    input wire [15:0] cdb_data_1,
    input wire [4:0] cdb_tag_1,
    input wire cdb_valid_1,
    // Outputs to ARF
    output reg [15:0] arf_value_0,     // Value to ARF
    output reg [2:0] arf_dest_0,       // ARF register
    output reg arf_valid_0,            // Commit valid
    output reg [15:0] arf_value_1,
    output reg [2:0] arf_dest_1,
    output reg arf_valid_1,
    // Output to PC update (for branches)
    output reg [15:0] dest_pc_out,     // Destination PC
    output reg dest_pc_valid           // Valid PC update
);

    // ROB entry: 54 bits
    // 53:38: dest_pc (16)
    // 37: Carry flag (1)
    // 36: Zero flag (1)
    // 35:32: Opcode (4)
    // 31:16: PC (16)
    // 15:0: Value (16)
    // 8:4: RRF tag (5)
    // 3:1: ARF dest (3)
    // 2: Busy (1)
    // 1: Execute (1)
    // 0: Issue (1)
    reg [53:0] rob [0:31];
    integer i;

    // Head and tail pointers
    reg [4:0] head; // Points to next entry to commit
    reg [4:0] tail; // Points to next free entry

    // Initialize ROB
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            rob[i] = 54'b0;
        end
        head = 5'b0;
        tail = 5'b0;
    end

    // Main process: Write, Update, Commit
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                rob[i] <= 54'b0;
            end
            head <= 5'b0;
            tail <= 5'b0;
            arf_value_0 <= 16'b0;
            arf_dest_0 <= 3'b0;
            arf_valid_0 <= 1'b0;
            arf_value_1 <= 16'b0;
            arf_dest_1 <= 3'b0;
            arf_valid_1 <= 1'b0;
            dest_pc_out <= 16'b0;
            dest_pc_valid <= 1'b0;
        end else begin
            // Default outputs
            arf_value_0 <= 16'b0;
            arf_dest_0 <= 3'b0;
            arf_valid_0 <= 1'b0;
            arf_value_1 <= 16'b0;
            arf_dest_1 <= 3'b0;
            arf_valid_1 <= 1'b0;
            dest_pc_out <= 16'b0;
            dest_pc_valid <= 1'b0;

            // 1. Write dispatched instructions
            if (iss_valid_0 && tail != head - 1) begin
                rob[tail] <= {16'b0, 1'b0, 1'b0, opcode_iss_0, pc_iss_0, 16'b0, rrf_dest_iss_0, arf_dest_iss_0, 1'b1, 1'b0, 1'b0};
                tail <= (tail == 31) ? 0 : tail + 1;
            end
            if (iss_valid_1 && tail != head - 1 && (!iss_valid_0 || tail + 1 != head - 1)) begin
                rob[tail + iss_valid_0] <= {16'b0, 1'b0, 1'b0, opcode_iss_1, pc_iss_1, 16'b0, rrf_dest_iss_1, arf_dest_iss_1, 1'b1, 1'b0, 1'b0};
                tail <= (tail + iss_valid_0 == 31) ? 0 : tail + iss_valid_0 + 1;
            end

            // 2. Update from CDB
            for (i = 0; i < 32; i = i + 1) begin
                if (rob[i][2]) begin // Busy
                    if (!rob[i][1] && cdb_valid_0 && cdb_tag_0 == rob[i][8:4]) begin
                        rob[i][15:0] <= cdb_data_0; // Value
                        rob[i][1] <= 1'b1; // Execute
                        rob[i][53:38] <= rob[i][31:16] + 16'd1; // Dest PC (PC + 1)
                        // Flags (optional, only for ALU)
                        if (rob[i][35:32] == 4'b0001 || rob[i][35:32] == 4'b0010) begin
                            rob[i][37] <= (cdb_data_0[15] && rob[i][35:32] == 4'b0001); // Carry for ADD
                            rob[i][36] <= (cdb_data_0 == 16'b0); // Zero
                        end
                    end else if (!rob[i][1] && cdb_valid_1 && cdb_tag_1 == rob[i][8:4]) begin
                        rob[i][15:0] <= cdb_data_1;
                        rob[i][1] <= 1'b1;
                        rob[i][53:38] <= rob[i][31:16] + 16'd1;
                        if (rob[i][35:32] == 4'b0001 || rob[i][35:32] == 4'b0010) begin
                            rob[i][37] <= (cdb_data_1[15] && rob[i][35:32] == 4'b0001);
                            rob[i][36] <= (cdb_data_1 == 16'b0);
                        end
                    end
                end
            end

            // 3. Commit up to two instructions
            if (rob[head][2] && rob[head][1]) begin // Busy and Executed
                rob[head][0] <= 1'b1; // Issue
                if (rob[head][35:32] != 4'b0101) begin // Not SW
                    arf_value_0 <= rob[head][15:0];
                    arf_dest_0 <= rob[head][3:1];
                    arf_valid_0 <= 1'b1;
                end
                if (rob[head][35:32] == 4'b0110) begin // Branch (assuming opcode 0110)
                    dest_pc_out <= rob[head][53:38];
                    dest_pc_valid <= 1'b1;
                end
                rob[head][2] <= 1'b0; // Clear busy
                head <= (head == 31) ? 0 : head + 1;
            end
            if (rob[head + 1][2] && rob[head + 1][1] && head + 1 != tail) begin
                rob[head + 1][0] <= 1'b1;
                if (rob[head + 1][35:32] != 4'b0101) begin
                    arf_value_1 <= rob[head + 1][15:0];
                    arf_dest_1 <= rob[head + 1][3:1];
                    arf_valid_1 <= 1'b1;
                end
                if (rob[head + 1][35:32] == 4'b0110) begin
                    dest_pc_out <= rob[head + 1][53:38];
                    dest_pc_valid <= 1'b1;
                end
                rob[head + 1][2] <= 1'b0;
                head <= (head == 30) ? 0 : head + 2;
            end
        end
    end

endmodule