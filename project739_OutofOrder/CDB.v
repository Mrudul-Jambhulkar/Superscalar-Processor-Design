module CDB (
    input wire clk,                    // Clock
    input wire rst,                    // Reset
    // Inputs from ALU0
    input wire [15:0] alu0_ex_aluc,    // ALU0 result
    input wire [4:0] alu0_rrf_dest,    // ALU0 RRF tag
    input wire alu0_valid,             // ALU0 result valid
    // Inputs from ALU1
    input wire [15:0] alu1_ex_aluc,    // ALU1 result
    input wire [4:0] alu1_rrf_dest,    // ALU1 RRF tag
    input wire alu1_valid,             // ALU1 result valid
    // Inputs from LS0
    input wire [15:0] ls0_ex_aluc,     // LS0 result (LW)
    input wire [4:0] ls0_rrf_dest,     // LS0 RRF tag
    input wire ls0_valid,              // LS0 result valid
    // Outputs to RS, RRF, ROB
    output reg [15:0] cdb_data_0,      // Result data (channel 0)
    output reg [4:0] cdb_tag_0,        // RRF tag (channel 0)
    output reg cdb_valid_0,            // Valid (channel 0)
    output reg [15:0] cdb_data_1,      // Result data (channel 1)
    output reg [4:0] cdb_tag_1,        // RRF tag (channel 1)
    output reg cdb_valid_1             // Valid (channel 1)
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cdb_data_0 <= 16'b0;
            cdb_tag_0 <= 5'b0;
            cdb_valid_0 <= 1'b0;
            cdb_data_1 <= 16'b0;
            cdb_tag_1 <= 5'b0;
            cdb_valid_1 <= 1'b0;
        end else begin
            // Default: no valid outputs
            cdb_data_0 <= 16'b0;
            cdb_tag_0 <= 5'b0;
            cdb_valid_0 <= 1'b0;
            cdb_data_1 <= 16'b0;
            cdb_tag_1 <= 5'b0;
            cdb_valid_1 <= 1'b0;

            // Arbitration: Select up to two results
            // Priority: ALU0 > ALU1 > LS0
            if (alu0_valid) begin
                // ALU0 takes channel 0
                cdb_data_0 <= alu0_ex_aluc;
                cdb_tag_0 <= alu0_rrf_dest;
                cdb_valid_0 <= 1'b1;
                if (alu1_valid) begin
                    // ALU1 takes channel 1
                    cdb_data_1 <= alu1_ex_aluc;
                    cdb_tag_1 <= alu1_rrf_dest;
                    cdb_valid_1 <= 1'b1;
                end else if (ls0_valid) begin
                    // LS0 takes channel 1 if ALU1 not valid
                    cdb_data_1 <= ls0_ex_aluc;
                    cdb_tag_1 <= ls0_rrf_dest;
                    cdb_valid_1 <= 1'b1;
                end
            end else if (alu1_valid) begin
                // ALU1 takes channel 0 if ALU0 not valid
                cdb_data_0 <= alu1_ex_aluc;
                cdb_tag_0 <= alu1_rrf_dest;
                cdb_valid_0 <= 1'b1;
                if (ls0_valid) begin
                    // LS0 takes channel 1
                    cdb_data_1 <= ls0_ex_aluc;
                    cdb_tag_1 <= ls0_rrf_dest;
                    cdb_valid_1 <= 1'b1;
                end
            end else if (ls0_valid) begin
                // LS0 takes channel 0 if no ALUs valid
                cdb_data_0 <= ls0_ex_aluc;
                cdb_tag_0 <= ls0_rrf_dest;
                cdb_valid_0 <= 1'b1;
            end
        end
    end

endmodule