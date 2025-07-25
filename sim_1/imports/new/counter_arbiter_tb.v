`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/22/2025 09:38:32 AM
// Design Name: 
// Module Name: counter_arbiter_tb
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




module counter_arbiter_tb;

    // Parameters
    parameter NUM_MASTERS = 4;
    parameter CLK_PERIOD = 10; // Clock period in ns

    // Testbench signals
    reg tick_count_i;
    reg resetn_i;
    wire [$clog2(NUM_MASTERS)-1:0] number_o;

    // Instantiate the DUT (Device Under Test)
    counter_arbiter #(.NUM_MASTERS(NUM_MASTERS)) dut (
        .tick_count_i(tick_count_i),
        .resetn_i(resetn_i),
        .number_o(number_o)
    );

    // Clock generation
    initial begin
        tick_count_i = 0;
        forever #(CLK_PERIOD/2) tick_count_i = ~tick_count_i;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        resetn_i = 0;
        #20 resetn_i = 1; // Release reset after 2 clock cycles

        // Wait for some cycles to observe counter behavior
        #100 $display("Counter running...");
        #200 $finish; // End simulation after 20 clock cycles
    end


    endmodule