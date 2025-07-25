`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/22/2025 07:35:40 PM
// Design Name: 
// Module Name: R_dispatcher_m_tb
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

module R_dispatcher_m_tb;

    // Parameters
    parameter DATA_WIDTH = 32;
    parameter TRANS_WR_RESP_W = 2;
    parameter NUM_MASTERS = 16;
    parameter CLK_PERIOD = 10;

    // Signals
    reg  [DATA_WIDTH-1:0]                       s_axi_rdata_i;
    reg  [TRANS_WR_RESP_W-1:0]                  s_axi_rresp_i;
    reg                                         s_axi_rvalid_i;
    wire                                        s_axi_rready_o;
    wire [DATA_WIDTH*NUM_MASTERS-1:0]           m_axi_rdata_o;
    wire [TRANS_WR_RESP_W*NUM_MASTERS-1:0]      m_axi_rresp_o;
    wire [NUM_MASTERS-1:0]                      m_axi_rvalid_o;
    reg  [NUM_MASTERS-1:0]                      m_axi_rready_i;
    reg  [NUM_MASTERS-1:0]                      Master_ID_Selected_i;

    // Clock and reset
    reg clk = 0;
    reg rst_n = 0;

    // Instantiate the DUT
    R_dispatcher_m #(
        .DATA_WIDTH(DATA_WIDTH),
        .TRANS_WR_RESP_W(TRANS_WR_RESP_W),
        .NUM_MASTERS(NUM_MASTERS)
    ) dut (
        .m_axi_rdata_o(m_axi_rdata_o),
        .m_axi_rresp_o(m_axi_rresp_o),
        .m_axi_rvalid_o(m_axi_rvalid_o),
        .m_axi_rready_i(m_axi_rready_i),
        .s_axi_rdata_i(s_axi_rdata_i),
        .s_axi_rresp_i(s_axi_rresp_i),
        .s_axi_rvalid_i(s_axi_rvalid_i),
        .s_axi_rready_o(s_axi_rready_o),
        .Master_ID_Selected_i(Master_ID_Selected_i)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Test stimulus
    initial begin
        // Initialize signals
        s_axi_rdata_i = 0;
        s_axi_rresp_i = 0;
        s_axi_rvalid_i = 0;
        m_axi_rready_i = 0;
        Master_ID_Selected_i = 0;
        
        // Reset
        rst_n = 0;
        #20;
        rst_n = 1;
        #20;

        // Test case 1: No master selected
        s_axi_rdata_i = 32'hDEADBEEF;
        s_axi_rresp_i = 2'b00;
        s_axi_rvalid_i = 1;
        #20;
        if (m_axi_rvalid_o == 0)
            $display("Test 1 Passed: No master selected, m_axi_rvalid_o = %b", m_axi_rvalid_o);
        else
            $display("Test 1 Failed: Expected m_axi_rvalid_o = 0, got %b", m_axi_rvalid_o);

        // Test case 2: Select Master 0
        Master_ID_Selected_i = 16'h0001; // One-hot for Master 0
        m_axi_rready_i = 16'h0001;
        s_axi_rdata_i = 32'h12345678;
        s_axi_rresp_i = 2'b01;
        s_axi_rvalid_i = 1;
        #20;
        if (m_axi_rdata_o[31:0] == 32'h12345678 && m_axi_rresp_o[1:0] == 2'b01 && m_axi_rvalid_o[0] == 1)
            $display("Test 2 Passed: Master 0 selected, data = %h, resp = %b, valid = %b", 
                     m_axi_rdata_o[31:0], m_axi_rresp_o[1:0], m_axi_rvalid_o[0]);
        else
            $display("Test 2 Failed: Expected data = %h, resp = %b, valid = %b, got data = %h, resp = %b, valid = %b",
                     32'h12345678, 2'b01, 1, m_axi_rdata_o[31:0], m_axi_rresp_o[1:0], m_axi_rvalid_o[0]);

        // Test case 3: Select Master 5
        Master_ID_Selected_i = 16'h0020; // One-hot for Master 5
        m_axi_rready_i = 16'h0020;
        s_axi_rdata_i = 32'hA5A5A5A5;
        s_axi_rresp_i = 2'b10;
        s_axi_rvalid_i = 1;
        #20;
        if (m_axi_rdata_o[191:160] == 32'hA5A5A5A5 && m_axi_rresp_o[11:10] == 2'b10 && m_axi_rvalid_o[5] == 1)
            $display("Test 3 Passed: Master 5 selected, data = %h, resp = %b, valid = %b", 
                     m_axi_rdata_o[191:160], m_axi_rresp_o[11:10], m_axi_rvalid_o[5]);
        else
            $display("Test 3 Failed: Expected data = %h, resp = %b, valid = %b, got data = %h, resp = %b, valid = %b",
                     32'hA5A5A5A5, 2'b10, 1, m_axi_rdata_o[191:160], m_axi_rresp_o[11:10], m_axi_rvalid_o[5]);

        // Test case 4: Select Master 15
        Master_ID_Selected_i = 16'h8000; // One-hot for Master 15
        m_axi_rready_i = 16'h8000;
        s_axi_rdata_i = 32'hFFFFFFFF;
        s_axi_rresp_i = 2'b11;
        s_axi_rvalid_i = 1;
        #20;
        if (m_axi_rdata_o[511:480] == 32'hFFFFFFFF && m_axi_rresp_o[31:30] == 2'b11 && m_axi_rvalid_o[15] == 1)
            $display("Test 4 Passed: Master 15 selected, data = %h, resp = %b, valid = %b", 
                     m_axi_rdata_o[511:480], m_axi_rresp_o[31:30], m_axi_rvalid_o[15]);
        else
            $display("Test 4 Failed: Expected data = %h, resp = %b, valid = %b, got data = %h, resp = %b, valid = %b",
                     32'hFFFFFFFF, 2'b11, 1, m_axi_rdata_o[511:480], m_axi_rresp_o[31:30], m_axi_rvalid_o[15]);

        // Test case 5: No valid data
        Master_ID_Selected_i = 16'h0001;
        m_axi_rready_i = 16'h0001;
        s_axi_rvalid_i = 0;
        #20;
        if (m_axi_rvalid_o[0] == 0)
            $display("Test 5 Passed: No valid data, m_axi_rvalid_o[0] = %b", m_axi_rvalid_o[0]);
        else
            $display("Test 5 Failed: Expected m_axi_rvalid_o[0] = 0, got %b", m_axi_rvalid_o[0]);

        // Finish simulation
        #100;
        $display("Simulation completed!");
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t Master_ID=%b s_axi_rready_o=%b m_axi_rvalid_o=%b", 
                 $time, Master_ID_Selected_i, s_axi_rready_o, m_axi_rvalid_o);
    end

endmodule
