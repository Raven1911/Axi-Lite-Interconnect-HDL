`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/22/2025 07:41:11 PM
// Design Name: 
// Module Name: AR_arbiter_m_tb
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


module AR_arbiter_m_tb;

    // Parameters
    parameter ADDR_WIDTH = 32;
    parameter TRANS_PROT = 3;
    parameter NUM_MASTERS = 16;
    parameter CLK_PERIOD = 10;

    // Signals
    reg                                         m_axi_aresetn_i;
    reg  [ADDR_WIDTH*NUM_MASTERS-1:0]           m_axi_araddr_i;
    reg  [NUM_MASTERS-1:0]                      m_axi_arvalid_i;
    wire [NUM_MASTERS-1:0]                      m_axi_arready_o;
    reg  [NUM_MASTERS*TRANS_PROT-1:0]           m_axi_arprot_i;
    wire [ADDR_WIDTH-1:0]                       s_axi_araddr_o;
    wire                                        s_axi_arvalid_o;
    reg                                         s_axi_arready_i;
    wire [TRANS_PROT-1:0]                       s_axi_arprot_o;
    wire [NUM_MASTERS-1:0]                      Master_ID_Selected_o;

    // Clock
    reg clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Instantiate DUT
    AR_arbiter_m #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .TRANS_PROT(TRANS_PROT),
        .NUM_MASTERS(NUM_MASTERS)
    ) dut (
        .m_axi_aresetn_i(m_axi_aresetn_i),
        .m_axi_araddr_i(m_axi_araddr_i),
        .m_axi_arvalid_i(m_axi_arvalid_i),
        .m_axi_arready_o(m_axi_arready_o),
        .m_axi_arprot_i(m_axi_arprot_i),
        .s_axi_araddr_o(s_axi_araddr_o),
        .s_axi_arvalid_o(s_axi_arvalid_o),
        .s_axi_arready_i(s_axi_arready_i),
        .s_axi_arprot_o(s_axi_arprot_o),
        .Master_ID_Selected_o(Master_ID_Selected_o)
    );

    // Test stimulus
    initial begin
        // Initialize signals
        m_axi_aresetn_i = 0;
        m_axi_araddr_i = 0;
        m_axi_arvalid_i = 0;
        m_axi_arprot_i = 0;
        s_axi_arready_i = 0;

        // Reset
        #20;
        m_axi_aresetn_i = 1;
        #20;

        // Test case 1: Single master (Master 0) request
        m_axi_araddr_i[31:0] = 32'h0000_1000;
        m_axi_arprot_i[2:0] = 3'b001;
        m_axi_arvalid_i = 16'h0001;
        #10; // Cycle 1: s_axi_arvalid high
        #10; // Cycle 2: s_axi_arvalid still high
        s_axi_arready_i = 1; // Cycle 3: both high
        #10;
        s_axi_arready_i = 0; // End of cycle 3: both low
        m_axi_arvalid_i = 0;
        if (Master_ID_Selected_o == 16'h0001 && s_axi_araddr_o == 32'h0000_1000 && s_axi_arprot_o == 3'b001 && s_axi_arvalid_o == 1 && m_axi_arready_o == 16'h0001)
            $display("Test 1 Passed: Master 0 selected, addr=%h, prot=%b, valid=%b", s_axi_araddr_o, s_axi_arprot_o, s_axi_arvalid_o);
        else
            $display("Test 1 Failed: Expected Master_ID=0001, addr=00001000, prot=001, valid=1, got Master_ID=%b, addr=%h, prot=%b, valid=%b",
                     Master_ID_Selected_o, s_axi_araddr_o, s_axi_arprot_o, s_axi_arvalid_o);
        #10; // Wait for next transaction

        // Test case 2: Multiple masters (0, 5, 10) requesting, check round-robin
        m_axi_arvalid_i = 16'h0421; // Masters 0, 5, 10
        m_axi_araddr_i[31:0] = 32'h0000_2000; // Master 0
        m_axi_araddr_i[191:160] = 32'h0000_3000; // Master 5
        m_axi_araddr_i[351:320] = 32'h0000_4000; // Master 10
        m_axi_arprot_i[2:0] = 3'b010; // Master 0
        m_axi_arprot_i[17:15] = 3'b011; // Master 5
        m_axi_arprot_i[32:30] = 3'b100; // Master 10
        #10; // Cycle 1: s_axi_arvalid high
        #10; // Cycle 2: s_axi_arvalid still high
        s_axi_arready_i = 1; // Cycle 3: both high
        #10;
        s_axi_arready_i = 0; // End of cycle 3: both low
        if (Master_ID_Selected_o == 16'h0001 && s_axi_araddr_o == 32'h0000_2000 && s_axi_arprot_o == 3'b010)
            $display("Test 2 Passed: Master 0 selected first, addr=%h, prot=%b", s_axi_araddr_o, s_axi_arprot_o);
        else
            $display("Test 2 Failed: Expected Master_ID=0001, addr=00002000, prot=010, got Master_ID=%b, addr=%h, prot=%b",
                     Master_ID_Selected_o, s_axi_araddr_o, s_axi_arprot_o);
        #10; // Wait for next transaction

        // Test case 3: Continue with same requests, check next master (Master 5)
        m_axi_arvalid_i = 16'h0421;
        #10; // Cycle 1: s_axi_arvalid high
        #10; // Cycle 2: s_axi_arvalid still high
        s_axi_arready_i = 1; // Cycle 3: both high
        #10;
        s_axi_arready_i = 0; // End of cycle 3: both low
        if (Master_ID_Selected_o == 16'h0020 && s_axi_araddr_o == 32'h0000_3000 && s_axi_arprot_o == 3'b011)
            $display("Test 3 Passed: Master 5 selected next, addr=%h, prot=%b", s_axi_araddr_o, s_axi_arprot_o);
        else
            $display("Test 3 Failed: Expected Master_ID=0020, addr=00003000, prot=011, got Master_ID=%b, addr=%h, prot=%b",
                     Master_ID_Selected_o, s_axi_araddr_o, s_axi_arprot_o);
        #10; // Wait for next transaction

        // Test case 4: Continue, check Master 10
        m_axi_arvalid_i = 16'h0421;
        #10; // Cycle 1: s_axi_arvalid high
        #10; // Cycle 2: s_axi_arvalid still high
        s_axi_arready_i = 1; // Cycle 3: both high
        #10;
        s_axi_arready_i = 0; // End of cycle 3: both low
        if (Master_ID_Selected_o == 16'h0400 && s_axi_araddr_o == 32'h0000_4000 && s_axi_arprot_o == 3'b100)
            $display("Test 4 Passed: Master 10 selected next, addr=%h, prot=%b", s_axi_araddr_o, s_axi_arprot_o);
        else
            $display("Test 4 Failed: Expected Master_ID=0400, addr=00004000, prot=100, got Master_ID=%b, addr=%h, prot=%b",
                     Master_ID_Selected_o, s_axi_araddr_o, s_axi_arprot_o);
        #10; // Wait for next transaction

        // Test case 5: No valid requests
        m_axi_arvalid_i = 0;
        #10; // Cycle 1
        #10; // Cycle 2
        s_axi_arready_i = 1; // Cycle 3: s_axi_arready_i high, but no valid
        #10;
        s_axi_arready_i = 0; // End of cycle 3
        if (s_axi_arvalid_o == 0 && Master_ID_Selected_o == 0)
            $display("Test 5 Passed: No valid requests, s_axi_arvalid_o=%b, Master_ID=%b", s_axi_arvalid_o, Master_ID_Selected_o);
        else
            $display("Test 5 Failed: Expected s_axi_arvalid_o=0, Master_ID=0, got s_axi_arvalid_o=%b, Master_ID=%b",
                     s_axi_arvalid_o, Master_ID_Selected_o);
        #10; // Wait for next transaction

        // Test case 6: Reset during operation
        m_axi_arvalid_i = 16'h8000; // Master 15
        m_axi_araddr_i[511:480] = 32'h0000_5000;
        m_axi_arprot_i[47:45] = 3'b101;
        #10; // Cycle 1: s_axi_arvalid high
        m_axi_aresetn_i = 0; // Reset in middle of transaction
        #20;
        m_axi_aresetn_i = 1;
        #10; // Cycle 1: s_axi_arvalid high
        #10; // Cycle 2: s_axi_arvalid still high
        s_axi_arready_i = 1; // Cycle 3: both high
        #10;
        s_axi_arready_i = 0; // End of cycle 3: both low
        if (Master_ID_Selected_o == 16'h8000 && s_axi_araddr_o == 32'h0000_5000 && s_axi_arprot_o == 3'b101)
            $display("Test 6 Passed: Master 15 selected after reset, addr=%h, prot=%b", s_axi_araddr_o, s_axi_arprot_o);
        else
            $display("Test 6 Failed: Expected Master_ID=8000, addr=00005000, prot=101, got Master_ID=%b, addr=%h, prot=%b",
                     Master_ID_Selected_o, s_axi_araddr_o, s_axi_arprot_o);
        #10; // Wait for next transaction

        // Finish simulation
        #100;
        $display("Simulation completed!");
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t Master_ID=%b s_axi_araddr_o=%h s_axi_arvalid_o=%b s_axi_arprot_o=%b m_axi_arready_o=%b",
                 $time, Master_ID_Selected_o, s_axi_araddr_o, s_axi_arvalid_o, s_axi_arprot_o, m_axi_arready_o);
    end

endmodule