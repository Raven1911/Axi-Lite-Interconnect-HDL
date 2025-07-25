`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/22/2025 09:30:01 AM
// Design Name: 
// Module Name: arbiter_tb
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



module arbiter_tb;
    // Parameters
    parameter NUM_MASTERS = 16;
    parameter CLK_PERIOD = 10; // 10ns clock period

    // Inputs
    reg                        resetn_i;
    reg                        enb_grant_i;
    reg [NUM_MASTERS-1:0]      requite_grant_i;

    // Outputs
    wire [NUM_MASTERS-1:0]     grant_permission_o;

    // Instantiate the arbiter

    arbiter#(
        .NUM_MASTERS(NUM_MASTERS)     // Number of masters
    ) dut  (  
        .resetn_i(resetn_i),
        .enb_grant_i(enb_grant_i),
        .requite_grant_i(requite_grant_i),

        .grant_permission_o(grant_permission_o) // id one hot

    );

    // Clock generation for enb_grant_i
    initial begin
        enb_grant_i = 0;
        forever #(CLK_PERIOD/2) enb_grant_i = ~enb_grant_i;
    end

    // Test stimulus
    initial begin
        // Initialize inputs
        resetn_i = 0;
        requite_grant_i = 0;

        // Reset the system
        #20;
        resetn_i = 1;
        $display("Time=%0t: After reset, grant_permission_o=%b", $time, grant_permission_o);

        // Test case 1: Single master request
        #20;
        requite_grant_i = 16'b0000000000000001; // Master 0 requests
        #CLK_PERIOD;
        $display("Time=%0t: Master 0 requests, grant_permission_o=%b, number_signal=%d", 
                 $time, grant_permission_o, dut.counter_arbiter_unit.number_o);

        // Test case 2: Another single master request
        #CLK_PERIOD;
        requite_grant_i = 16'b0000000000000100; // Master 2 requests
        #CLK_PERIOD;
        $display("Time=%0t: Master 2 requests, grant_permission_o=%b, number_signal=%d", 
                 $time, grant_permission_o, dut.counter_arbiter_unit.number_o);

        // Test case 3: Multiple master requests (Masters 0, 3, 5)
        #CLK_PERIOD;
        requite_grant_i = 16'b0000000000101001; // Masters 0, 3, 5 request
        #CLK_PERIOD;
        $display("Time=%0t: Masters 0,3,5 request, grant_permission_o=%b, number_signal=%d", 
                 $time, grant_permission_o, dut.counter_arbiter_unit.number_o);

        // Test case 4: All masters request
        #CLK_PERIOD;
        requite_grant_i = 16'b1111111111111111; // All masters request
        #CLK_PERIOD;
        $display("Time=%0t: All masters request, grant_permission_o=%b, number_signal=%d", 
                 $time, grant_permission_o, dut.counter_arbiter_unit.number_o);

        // Test case 5: No requests
        #CLK_PERIOD;
        requite_grant_i = 16'b0000000000000000; // No masters request
        #CLK_PERIOD;
        $display("Time=%0t: No requests, grant_permission_o=%b, number_signal=%d", 
                 $time, grant_permission_o, dut.counter_arbiter_unit.number_o);

        // Test case 6: Sequential requests with round-robin
        #CLK_PERIOD;
        requite_grant_i = 16'b0000000000000010; // Master 1 requests
        #CLK_PERIOD;
        $display("Time=%0t: Master 1 requests, grant_permission_o=%b, number_signal=%d", 
                 $time, grant_permission_o, dut.counter_arbiter_unit.number_o);

        // Test case 7: Multiple cycles with mixed requests
        #CLK_PERIOD;
        requite_grant_i = 16'b1010101010101010; // Alternating masters
        repeat(4) begin
            #CLK_PERIOD;
            $display("Time=%0t: Alternating masters, grant_permission_o=%b, number_signal=%d", 
                     $time, grant_permission_o, dut.counter_arbiter_unit.number_o);
        end

        // End simulation
        #20;
        $display("Simulation completed.");
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t: resetn_i=%b, enb_grant_i=%b, requite_grant_i=%b, grant_permission_o=%b", 
                 $time, resetn_i, enb_grant_i, requite_grant_i, grant_permission_o);
    end

endmodule