module Data_Memory (
    input wire clk,                    // Clock
    input wire [15:0] addr,            // Memory address
    input wire [15:0] write_data,      // Data to write
    input wire write_en,               // Write enable
    input wire read_en,                // Read enable
    output reg [15:0] read_data        // Data read from memory
);

    // Memory array: 64K x 16-bit
    reg [15:0] mem [0:65535];
   integer i;
    // Initialize memory (optional, for simulation)
    initial begin
        
        for (i = 0; i < 65536; i = i + 1) begin
            mem[i] = 16'h0000;
        end
        // Optional: Preload specific addresses for testing
        // mem[16'h1000] = 16'h1234;
        // mem[16'h2000] = 16'hABCD;
    end

    // Synchronous read and write
    always @(posedge clk) begin
        if (write_en) begin
            mem[addr] <= write_data;
        end
        if (read_en) begin
            read_data <= mem[addr];
        end else begin
            read_data <= 16'h0000; // Default output when not reading
        end
    end

endmodule