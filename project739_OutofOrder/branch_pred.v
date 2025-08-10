module branch_predictor (
    input wire clk,                  // Clock signal
    input wire rst_n,                // Active-low reset
    input wire [31:0] pc,            // Program Counter
    input wire branch_valid,         // Valid branch signal
    input wire branch_taken,         // Actual branch outcome
    output reg prediction            // Predicted branch outcome
);

    // Parameters
    parameter BHR_SIZE = 4;          // Branch History Register size
    parameter PHT_SIZE = 16;         // Pattern History Table size (2^4)
    parameter COUNTER_MAX = 3;       // 2-bit saturating counter max value
    parameter PHT_ADDR_WIDTH = $clog2(PHT_SIZE); // Address width for PHT

    // Internal registers
    reg [BHR_SIZE-1:0] bhr;          // Branch History Register
    reg [1:0] pht [0:PHT_SIZE-1];    // Pattern History Table (2-bit counters)
    wire [PHT_ADDR_WIDTH-1:0] pht_index; // PHT index

    // Calculate PHT index (XOR of lower PC bits and BHR)
    assign pht_index = (pc[PHT_ADDR_WIDTH-1:0] ^ bhr);

    // Prediction logic
    always @(*) begin
        prediction = (pht[pht_index] >= 2); // Predict taken if counter >= 2
    end

    // Update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset BHR and initialize PHT to weakly taken (2)
            bhr <= 0;
            for (integer i = 0; i < PHT_SIZE; i = i + 1) begin
                pht[i] <= 2;
            end
        end
        else if (branch_valid) begin
            // Update PHT based on actual branch outcome
            if (branch_taken) begin
                if (pht[pht_index] < COUNTER_MAX)
                    pht[pht_index] <= pht[pht_index] + 1;
            end
            else begin
                if (pht[pht_index] > 0)
                    pht[pht_index] <= pht[pht_index] - 1;
            end
            // Update BHR (shift left, add new outcome)
            bhr <= {bhr[BHR_SIZE-2:0], branch_taken};
        end
    end

endmodule
