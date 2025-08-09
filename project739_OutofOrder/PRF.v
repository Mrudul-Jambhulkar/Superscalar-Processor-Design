module ARF (
    input wire clk,                    // Clock
    input wire rst,                    // Reset
    // Outputs to Dispatch Unit
    output reg [15:0] arf_data_0, arf_data_1, arf_data_2, arf_data_3,
                      arf_data_4, arf_data_5, arf_data_6, arf_data_7, // Data for R0–R7
    output reg [4:0] arf_tag_0, arf_tag_1, arf_tag_2, arf_tag_3,
                     arf_tag_4, arf_tag_5, arf_tag_6, arf_tag_7,     // Tags for R0–R7
    output reg [7:0] arf_busy,         // Busy bits for R0–R7
    // Update ports from Dispatch Unit
    input wire [2:0] tag_add_1,        // ARF address to update (instr_1 dest)
    input wire [4:0] tag_out_1,        // New RRF tag for instr_1
    input wire busy_set_1,             // Set busy bit for instr_1
    input wire [2:0] tag_add_2,        // ARF address for instr_2
    input wire [4:0] tag_out_2,        // New RRF tag for instr_2
    input wire busy_set_2,             // Set busy bit for instr_2
    // Write-back from WB/ROB
    input wire [2:0] wb_arf_addr,      // ARF address to write
    input wire [15:0] wb_data,         // Committed data
    input wire wb_valid,               // Write valid
    input wire wb_busy_clear           // Clear busy bit
);

    // ARF storage
    reg [15:0] registers [0:7];        // 8 registers, 16-bit each
    reg [4:0] tags [0:7];              // 5-bit RRF tags
    reg [7:0] busy_reg;                // Busy bits

    // Output logic (combinational)
    always @(*) begin
        arf_data_0 = registers[0];
        arf_data_1 = registers[1];
        arf_data_2 = registers[2];
        arf_data_3 = registers[3];
        arf_data_4 = registers[4];
        arf_data_5 = registers[5];
        arf_data_6 = registers[6];
        arf_data_7 = registers[7];
        arf_tag_0 = tags[0];
        arf_tag_1 = tags[1];
        arf_tag_2 = tags[2];
        arf_tag_3 = tags[3];
        arf_tag_4 = tags[4];
        arf_tag_5 = tags[5];
        arf_tag_6 = tags[6];
        arf_tag_7 = tags[7];
        arf_busy = busy_reg;
    end

    // Write and update logic
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                registers[i] <= 16'b0;
                tags[i] <= 5'b0;
                busy_reg[i] <= 1'b0;
            end
        end else begin
            // Dispatch updates (set tags and busy bits)
            if (busy_set_1 && tag_add_1 != 3'd0) begin
                tags[tag_add_1] <= tag_out_1;
                busy_reg[tag_add_1] <= 1'b1;
            end
            if (busy_set_2 && tag_add_2 != 3'd0 && tag_add_2 != tag_add_1) begin
                tags[tag_add_2] <= tag_out_2;
                busy_reg[tag_add_2] <= 1'b1;
            end
            // Write-back (commit from ROB/WB)
            if (wb_valid && wb_arf_addr != 3'd0) begin
                registers[wb_arf_addr] <= wb_data;
                if (wb_busy_clear) begin
                    busy_reg[wb_arf_addr] <= 1'b0;
                end
            end
        end
    end

endmodule

module RRF (
    input wire clk,                    // Clock
    input wire rst,                    // Reset
    // Write ports from EX/MEM (speculative results)
    input wire [4:0] wb_rrf_tag,       // RRF tag to write
    input wire [15:0] wb_data,         // Result data
    input wire wb_valid,               // Write valid
    // Busy status updates from Dispatch Unit
    input wire [4:0] alloc_tag_1,      // RRF tag to allocate (instr_1)
    input wire alloc_valid_1,          // Allocation valid
    input wire [4:0] alloc_tag_2,      // RRF tag to allocate (instr_2)
    input wire alloc_valid_2,          // Allocation valid
    // Busy status updates from ROB
    input wire [4:0] free_tag,         // RRF tag to free
    input wire free_valid,             // Free valid
    // Output to Dispatch Unit
    output reg [31:0] busy_status      // 0: free, 1: busy
);

    // RRF storage
    reg [15:0] registers [0:31];       // 32 entries, 16-bit each
    reg [31:0] busy_reg;               // Busy status

    // Write and busy status logic
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 16'b0;
                busy_reg[i] <= 1'b0;
            end
        end else begin
            // Write speculative result
            if (wb_valid && wb_rrf_tag != 5'b0) begin
                registers[wb_rrf_tag] <= wb_data;
            end
            // Allocate tags (set busy)
            if (alloc_valid_1 && alloc_tag_1 != 5'b0) begin
                busy_reg[alloc_tag_1] <= 1'b1;
            end
            if (alloc_valid_2 && alloc_tag_2 != 5'b0 && alloc_tag_2 != alloc_tag_1) begin
                busy_reg[alloc_tag_2] <= 1'b1;
            end
            // Free tags (clear busy)
            if (free_valid && free_tag != 5'b0) begin
                busy_reg[free_tag] <= 1'b0;
            end
        end
    end

    // Output busy status
    always @(*) begin
        busy_status = busy_reg;
    end

endmodule