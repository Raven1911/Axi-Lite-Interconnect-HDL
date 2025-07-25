`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/22/2025 11:18:49 PM
// Design Name: 
// Module Name: DLock_timer_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module DLock_timer_tb;

    // Parameters
    parameter QUANTUM_TIME = 3;
    parameter CLK_PERIOD = 10;

    // Signals
    reg         clk_i;
    reg         start_i;
    reg         reset_n_i;
    wire        tick_timer;

    // Instantiate DUT
    DLock_timer #(
        .QUANTUM_TIME(QUANTUM_TIME)
    ) dut (
        .clk_i(clk_i),
        .start_i(start_i),
        .resetn_i(reset_n_i),
        .tick_timer(tick_timer)
    );

    // Clock generation
    initial begin
        clk_i = 0;
        forever #(CLK_PERIOD/2) clk_i = ~clk_i;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        start_i = 0;
        reset_n_i = 0;

        // Test case 1: Reset behavior
        #20;
        reset_n_i = 1;
        #20;
        if (tick_timer == 0)
            $display("Test 1 Passed: After reset, tick_timer = %b", tick_timer);
        else
            $display("Test 1 Failed: Expected tick_timer = 0, got %b", tick_timer);

        // Test case 2: Start timer and count to QUANTUM_TIME
        start_i = 1;
        #((QUANTUM_TIME-1)*CLK_PERIOD); // Wait for 15 cycles
        if (tick_timer == 0)
            $display("Test 2a Passed: Before QUANTUM_TIME, tick_timer = %b", tick_timer);
        else
            $display("Test 2a Failed: Expected tick_timer = 0, got %b", tick_timer);
        #CLK_PERIOD; // 16th cycle
        if (tick_timer == 1)
            $display("Test 2b Passed: At QUANTUM_TIME, tick_timer = %b", tick_timer);
        else
            $display("Test 2b Failed: Expected tick_timer = 1, got %b", tick_timer);
        #CLK_PERIOD; // Next cycle, tick should go low
        if (tick_timer == 0)
            $display("Test 2c Passed: After QUANTUM_TIME, tick_timer = %b", tick_timer);
        else
            $display("Test 2c Failed: Expected tick_timer = 0, got %b", tick_timer);

        // Test case 3: Stop timer in middle of counting
        start_i = 1;
        #(5*CLK_PERIOD); // Count for 5 cycles
        start_i = 0;
        #((QUANTUM_TIME)*CLK_PERIOD); // Wait longer than QUANTUM_TIME
        if (tick_timer == 0)
            $display("Test 3 Passed: Timer stopped, tick_timer = %b", tick_timer);
        else
            $display("Test 3 Failed: Expected tick_timer = 0, got %b", tick_timer);

        // Test case 4: Reset during counting
        start_i = 1;
        #(8*CLK_PERIOD); // Count for 8 cycles
        reset_n_i = 0;
        #20;
        reset_n_i = 1;
        #20;
        if (tick_timer == 0)
            $display("Test 4 Passed: After reset during counting, tick_timer = %b", tick_timer);
        else
            $display("Test 4 Failed: Expected tick_timer = 0, got %b", tick_timer);

        // Test case 5: Continuous counting for multiple QUANTUM_TIME periods
        start_i = 1;
        #((2*QUANTUM_TIME)*CLK_PERIOD); // Wait for 2 QUANTUM_TIME periods
        if (tick_timer == 1)
            $display("Test 5 Passed: Second QUANTUM_TIME, tick_timer = %b", tick_timer);
        else
            $display("Test 5 Failed: Expected tick_timer = 1, got %b", tick_timer);

        // Finish simulation
        #100;
        $display("Simulation completed!");
        $finish;
    end

endmodule
