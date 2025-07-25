`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/22/2025 09:38:58 AM
// Design Name: 
// Module Name: mux_ID_arbiter_tb
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




module mux_ID_arbiter_tb;

    // Parameters
    parameter NUM_MASTERS = 4;
    parameter SIM_DELAY = 10; // Delay between test cases in ns

    // Testbench signals
    reg [NUM_MASTERS*NUM_MASTERS-1:0] Master_ID_Selected_i;
    reg [$clog2(NUM_MASTERS)-1:0] number_select_i;
    wire [NUM_MASTERS-1:0] Master_ID_Selected_o;

    // Instantiate the DUT (Device Under Test)
    mux_ID_arbiter #(.NUM_MASTERS(NUM_MASTERS)) dut (
        .Master_ID_Selected_i(Master_ID_Selected_i),
        .number_select_i(number_select_i),
        .Master_ID_Selected_o(Master_ID_Selected_o)
    );

    // Test stimulus
    initial begin
        // Initialize inputs
        Master_ID_Selected_i = 16'hDCBA;
        number_select_i = 0;

        // Populate Master_ID_Selected_i with test data
        // Example: Assign unique patterns to each NUM_MASTERS-bit segment
        // for (integer i = 0; i < NUM_MASTERS; i = i + 1) begin
        //     Master_ID_Selected_i[(i * NUM_MASTERS) +: NUM_MASTERS] = {NUM_MASTERS{1'b1}} ^ (i << (NUM_MASTERS - 1)); // Unique pattern per segment
        // end

        // Test case 1: Select index 0
        #SIM_DELAY number_select_i = 0;
        #SIM_DELAY $display("Time = %0t ns, Select = %d, Master_ID_Selected_o = %b", $time, number_select_i, Master_ID_Selected_o);

        // Test case 2: Select index 5
        #SIM_DELAY number_select_i = 1;
        #SIM_DELAY $display("Time = %0t ns, Select = %d, Master_ID_Selected_o = %b", $time, number_select_i, Master_ID_Selected_o);

        // Test case 3: Select index 15 (max value)
        #SIM_DELAY number_select_i = 2;
        #SIM_DELAY $display("Time = %0t ns, Select = %d, Master_ID_Selected_o = %b", $time, number_select_i, Master_ID_Selected_o);

        // Test case 3: Select index 15 (max value)
        #SIM_DELAY number_select_i = 3;
        #SIM_DELAY $display("Time = %0t ns, Select = %d, Master_ID_Selected_o = %b", $time, number_select_i, Master_ID_Selected_o);

        // Test case 4: Select an out-of-range value (to observe behavior)
        #SIM_DELAY number_select_i = 16; // Should wrap or select last segment
        #SIM_DELAY $display("Time = %0t ns, Select = %d, Master_ID_Selected_o = %b", $time, number_select_i, Master_ID_Selected_o);

        // End simulation
        #SIM_DELAY $finish;
    end

    // Continuous monitoring
    initial begin
        $monitor("Time = %0t ns, Select = %d, Master_ID_Selected_o = %b", $time, number_select_i, Master_ID_Selected_o);
    end

endmodule