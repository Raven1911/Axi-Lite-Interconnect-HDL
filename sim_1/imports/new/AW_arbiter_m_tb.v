`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/22/2025 09:33:46 AM
// Design Name: 
// Module Name: AW_arbiter_m_tb
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



module AW_arbiter_m_tb;
    // Parameters
    parameter ADDR_WIDTH = 32;
    parameter NUM_MASTERS = 16;
    parameter CLK_PERIOD = 10; // 10ns clock period

    // Inputs
    reg                        m_axi_aresetn_i;
    reg [ADDR_WIDTH*NUM_MASTERS-1:0] m_axi_awaddr_i;
    reg [NUM_MASTERS-1:0]    m_axi_awvalid_i;
    reg                      s_axi_awready_i;

    // Outputs
    wire [NUM_MASTERS-1:0]   m_axi_awready_o;
    wire [ADDR_WIDTH-1:0]    s_axi_awaddr_o;
    wire                     s_axi_awvalid_o;
    wire [NUM_MASTERS-1:0]   Master_ID_Selected_o;

    // Instantiate the AW_arbiter_m
    AW_arbiter_m #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_MASTERS(NUM_MASTERS)
    ) dut (
        .m_axi_aresetn_i(m_axi_aresetn_i),
        .m_axi_awaddr_i(m_axi_awaddr_i),
        .m_axi_awvalid_i(m_axi_awvalid_i),
        .m_axi_awready_o(m_axi_awready_o),
        .s_axi_awaddr_o(s_axi_awaddr_o),
        .s_axi_awvalid_o(s_axi_awvalid_o),
        .s_axi_awready_i(s_axi_awready_i),
        .Master_ID_Selected_o(Master_ID_Selected_o)
    );

    // Clock generation for s_axi_awready_i (simulating slave response)
    initial begin
        s_axi_awready_i = 0;
        forever #(CLK_PERIOD/2) s_axi_awready_i = ~s_axi_awready_i;
    end

    // Test stimulus
    initial begin
        // Initialize inputs
        m_axi_aresetn_i = 0;
        m_axi_awaddr_i = 0;
        m_axi_awvalid_i = 0;

        // Reset the system
        #20;
        m_axi_aresetn_i = 1;
        $display("Time=%0t: After reset, Master_ID_Selected_o=%b, s_axi_awaddr_o=%h, s_axi_awvalid_o=%b, m_axi_awready_o=%b", 
                 $time, Master_ID_Selected_o, s_axi_awaddr_o, s_axi_awvalid_o, m_axi_awready_o);

        // Test case 1: Single master request (Master 0)
        #20;
        m_axi_awaddr_i = {15*{32'h0}, 32'hDEADBEEF}; // Master 0 address
        m_axi_awvalid_i = 16'b0000000000000001; // Master 0 requests
        #CLK_PERIOD;
        $display("Time=%0t: Master 0 requests, Master_ID_Selected_o=%b, s_axi_awaddr_o=%h, s_axi_awvalid_o=%b, m_axi_awready_o=%b", 
                 $time, Master_ID_Selected_o, s_axi_awaddr_o, s_axi_awvalid_o, m_axi_awready_o);

        // Test case 2: Single master request (Master 5)
        #CLK_PERIOD;
        m_axi_awaddr_i = {10*{32'h0}, 32'hCAFEBABE, 5*{32'h0}}; // Master 5 address
        m_axi_awvalid_i = 16'b0000000000100000; // Master 5 requests
        #CLK_PERIOD;
        $display("Time=%0t: Master 5 requests, Master_ID_Selected_o=%b, s_axi_awaddr_o=%h, s_axi_awvalid_o=%b, m_axi_awready_o=%b", 
                 $time, Master_ID_Selected_o, s_axi_awaddr_o, s_axi_awvalid_o, m_axi_awready_o);

        // Test case 3: Multiple master requests (Masters 0, 3, 7, 10)
        #CLK_PERIOD;
        m_axi_awaddr_i = {5*{32'h0}, 32'h12345678, 2*{32'h0}, 32'hABCDEF12, 3*{32'h0}, 32'h55555555, 32'h0, 32'hDEADBEEF, 32'h0}; // Masters 0, 3, 7, 10 addresses
        m_axi_awvalid_i = 16'b0000010010001001; // Masters 0, 3, 7, 10 request
        #CLK_PERIOD;
        $display("Time=%0t: Masters 0,3,7,10 request, Master_ID_Selected_o=%b, s_axi_awaddr_o=%h, s_axi_awvalid_o=%b, m_axi_awready_o=%b", 
                 $time, Master_ID_Selected_o, s_axi_awaddr_o, s_axi_awvalid_o, m_axi_awready_o);

        // Test case 4: No requests
        #CLK_PERIOD;
        m_axi_awaddr_i = 0;
        m_axi_awvalid_i = 16'b0000000000000000; // No masters request
        #CLK_PERIOD;
        $display("Time=%0t: No requests, Master_ID_Selected_o=%b, s_axi_awaddr_o=%h, s_axi_awvalid_o=%b, m_axi_awready_o=%b", 
                 $time, Master_ID_Selected_o, s_axi_awaddr_o, s_axi_awvalid_o, m_axi_awready_o);

        // Test case 5: Sequential requests with round-robin (Master 8)
        #CLK_PERIOD;
        m_axi_awaddr_i = {7*{32'h0}, 32'hFEEDBEEF, 8*{32'h0}}; // Master 8 address
        m_axi_awvalid_i = 16'b0000000100000000; // Master 8 requests
        #CLK_PERIOD;
        $display("Time=%0t: Master 8 requests, Master_ID_Selected_o=%b, s_axi_awaddr_o=%h, s_axi_awvalid_o=%b, m_axi_awready_o=%b", 
                 $time, Master_ID_Selected_o, s_axi_awaddr_o, s_axi_awvalid_o, m_axi_awready_o);

        // Test case 6: Multiple cycles with mixed requests
        #CLK_PERIOD;
        m_axi_awaddr_i = {16{32'h11111111}}; // All masters with same address for simplicity
        m_axi_awvalid_i = 16'b1010101010101010; // Alternating masters (0, 2, 4, 6, 8, 10, 12, 14)
        repeat(8) begin
            #CLK_PERIOD;
            $display("Time=%0t: Alternating masters, Master_ID_Selected_o=%b, s_axi_awaddr_o=%h, s_axi_awvalid_o=%b, m_axi_awready_o=%b", 
                     $time, Master_ID_Selected_o, s_axi_awaddr_o, s_axi_awvalid_o, m_axi_awready_o);
        end

        // Test case 7: Check round-robin progression with all masters requesting
        #CLK_PERIOD;
        m_axi_awaddr_i = {32'h11111111, 32'h22222222, 32'h33333333, 32'h44444444, 
                          32'h55555555, 32'h66666666, 32'h77777777, 32'h88888888, 
                          32'h99999999, 32'hAAAAAAAA, 32'hBBBBBBBB, 32'hCCCCCCCC, 
                          32'hDDDDDDDD, 32'hEEEEEEEE, 32'hFFFFFFFF, 32'h00000000}; // Unique addresses for each master
        m_axi_awvalid_i = 16'b1111111111111111; // All masters request
        repeat(16) begin
            #CLK_PERIOD;
            $display("Time=%0t: All masters request, Master_ID_Selected_o=%b, s_axi_awaddr_o=%h, s_axi_awvalid_o=%b, m_axi_awready_o=%b", 
                     $time, Master_ID_Selected_o, s_axi_awaddr_o, s_axi_awvalid_o, m_axi_awready_o);
        end

        // End simulation
        #20;
        $display("Simulation completed.");
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t: m_axi_aresetn_i=%b, s_axi_awready_i=%b, m_axi_awvalid_i=%b, Master_ID_Selected_o=%b, s_axi_awaddr_o=%h, s_axi_awvalid_o=%b, m_axi_awready_o=%b", 
                 $time, m_axi_aresetn_i, s_axi_awready_i, m_axi_awvalid_i, Master_ID_Selected_o, s_axi_awaddr_o, s_axi_awvalid_o, m_axi_awready_o);
    end

endmodule

