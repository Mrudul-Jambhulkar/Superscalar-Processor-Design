module IF_stage (
    input wire clk,
    input wire rst,
    input wire stall, // When high, stall the PC update
    input wire [15:0] branch_target, // Branch target address (word addressable)
    input wire branch_taken,        // High if a branch is taken
    output reg [15:0] pc,           // Current program counter
    output wire [15:0] inst1,        // First instruction
    output wire [15:0] inst2,         // Second instruction
	output wire [15:0] pc1,
	output wire [15:0] pc2
);

    // Internal wires for addresses
    wire [15:0] addr1,addr2 ;
    // Next PC logic
    wire [15:0] next_pc = branch_taken ? branch_target : pc + 16'd2;

    // Instruction memory instantiation
    Inst_Memory IM (
        .clk(clk),
        .addr_1(addr1),
        .addr_2(addr2),
        .IM_output_1(inst1),
        .IM_output_2(inst2)
    );

    // PC generation
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 16'd0;
        else if (!stall)
            pc <= next_pc;
    end

    assign addr1 = pc;
    assign addr2 = pc + 16'd1;
	assign pc1 = addr1 ;
	assign pc2 = addr2 ;

endmodule
