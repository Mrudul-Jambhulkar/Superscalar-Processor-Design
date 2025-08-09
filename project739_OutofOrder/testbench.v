`timescale 1ns / 1ps

module Top_Level_tb ();

// Testbench signals
reg clk;
reg rst;

// Instantiate the top-level module
Top_Level uut (
    .clk(clk),
    .rst(rst)
);

// Clock generation: 50ns period (20MHz)
initial begin
    clk = 0;
    forever #25 clk = ~clk;
end

// Reset and simulation control
initial begin
    // Initialize signals
    rst = 1;
    #100; // Hold reset for 100ns
    rst = 0;

    // Run simulation for 50 cycles (2500ns)
    #2500;
    $display("Simulation completed.");

    // Final state check
    $display("Final ARF State:");
    $display("R1 = %h (Expected: 0x0010)", uut.arf.arf_data_1);
    $display("R2 = %h (Expected: 0x0005)", uut.arf.arf_data_2);
    $display("R3 = %h (Expected: 0x000A)", uut.arf.arf_data_3);
    $display("R4 = %h (Expected: 0x0008)", uut.arf.arf_data_4);
    $display("R5 = %h (Expected: 0xFFFE)", uut.arf.arf_data_5);
    $display("R6 = %h (Expected: 0x0014)", uut.arf.arf_data_6);
    $display("R7 = %h (Expected: 0x1234)", uut.arf.arf_data_7);
    $display("Data Memory[0x0018] = %h (Expected: 0x0005)", uut.data_memory.mem[24]);

    $finish;
end

// Monitor key signals
initial begin
    $monitor("Time=%0t | PC=%h | ARF: R1=%h, R2=%h, R3=%h, R4=%h, R5=%h, R6=%h, R7=%h | ROB Commit: valid_0=%b, dest_0=%h, value_0=%h | Stall=%b",
             $time,
             uut.if_pc,
             uut.arf.arf_data_1,
             uut.arf.arf_data_2,
             uut.arf.arf_data_3,
             uut.arf.arf_data_4,
             uut.arf.arf_data_5,
             uut.arf.arf_data_6,
             uut.arf.arf_data_7,
             uut.rob.arf_valid_0,
             uut.rob.arf_dest_0,
             uut.rob.arf_value_0,
             uut.stall);
end

endmodule