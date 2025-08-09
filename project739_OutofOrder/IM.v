module Inst_Memory (
    input wire clk,
    input wire [15:0] addr_1, // Address for first instruction
    input wire [15:0] addr_2, // Address for second instruction
    output reg [15:0] IM_output_1, // First 16-bit instruction
    output reg [15:0] IM_output_2  // Second 16-bit instruction
);

    // Memory array: 256 entries of 16-bit instructions (512 bytes)
    reg [15:0] instructions [0:255];
    integer i = 0 ;
    // Initialize memory with sample IITB-RISC-23 instructions
    initial begin
        // Example instructions (based on ISA encoding)
           instructions[0] = 16'b0001_100_010_011_000; // ADD R4, R2, R3
    // [15:12]=0001 (ADD), [11:9]=100 (R4), [8:6]=010 (R2), [5:3]=011 (R3), [2:0]=000 (unused)
    // Operation: R4 = R2 + R3 = 0x0005 + 0x0003 = 0x0008
    // Tests: ALU0/ALU1 arithmetic, register renaming, ROB commit

    instructions[1] = 16'b0010_101_010_011_000; // NAND R5, R2, R3
    // [15:12]=0010 (NAND), [11:9]=101 (R5), [8:6]=010 (R2), [5:3]=011 (R3), [2:0]=000 (unused)
    // Operation: R5 = ~(R2 & R3) = ~(0x0005 & 0x0003) = ~(0x0001) = 0xFFFE
    // Tests: ALU0/ALU1 logical operation, CDB broadcast

    instructions[2] = 16'b0000_110_001_000100; // ADI R6, R1, 4
    // [15:12]=0000 (ADI), [11:9]=110 (R6), [8:6]=001 (R1), [5:0]=000100 (imm=4)
    // Operation: R6 = R1 + 4 = 0x0010 + 4 = 0x0014
    // Tests: Immediate arithmetic, ALU pipeline

    instructions[3] = 16'b0100_111_110_000000; // LW R7, 0(R6)
    // [15:12]=0100 (LW), [11:9]=111 (R7), [8:6]=110 (R6), [5:0]=000000 (imm=0)
    // Operation: R7 = M[R6 + 0] = M[0x0014] = 0x1234
    // Tests: LS0 load, data memory access, ROB commit

    instructions[4] = 16'b0101_010_001_001000; // SW R2, 8(R1)
    // [15:12]=0101 (SW), [11:9]=010 (R2), [8:6]=001 (R1), [5:0]=001000 (imm=8)
    // Operation: M[R1 + 8] = R2 = M[0x0018] = 0x0005
    // Tests: LS0 store, data memory write

    instructions[5] = 16'b0011_011_000001010; // LLI R3, 10
    // [15:12]=0011 (LLI), [11:9]=011 (R3), [8:0]=000001010 (imm=10)
    // Operation: R3 = 10 = 0x000A
    // Tests: Immediate load, ARF update
        // Fill remaining with NOPs (e.g., ADI R0, R0, 0)
        for ( i = 6; i < 256; i = i + 1) begin
            instructions[i] = 16'b0000_000_000_000000;
        end
    end

    // Synchronous read: output two instructions on clk edge
    always @(posedge clk) begin
        // Assume addr_1 and addr_2 are word-aligned (divided by 2 to index 16-bit entries)
        IM_output_1 <= instructions[addr_1[9:1]]; // addr_1/2 (9-bit index)
        IM_output_2 <= instructions[addr_2[9:1]]; // addr_2/2 (9-bit index)
    end

endmodule