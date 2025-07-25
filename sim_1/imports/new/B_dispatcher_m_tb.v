`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/22/2025 02:39:36 PM
// Design Name: 
// Module Name: B_dispatcher_m_tb
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



module B_dispatcher_m_tb;

    // Parameters
    parameter TRANS_WR_RESP_W = 2;
    parameter NUM_MASTERS = 16;
    parameter CLK_PERIOD = 10;

    // Signals
    wire [TRANS_WR_RESP_W*NUM_MASTERS-1:0] m_axi_bresp_o;
    wire [NUM_MASTERS-1:0] m_axi_bvalid_o;
    reg [NUM_MASTERS-1:0] m_axi_bready_i;
    reg [TRANS_WR_RESP_W-1:0] s_axi_bresp_i;
    reg s_axi_bvalid_i;
    wire s_axi_bready_o;
    reg [NUM_MASTERS-1:0] Master_ID_Selected_i;

    reg clk;
    reg rst_n;

    // Variables for random testing and loops
    integer rand_master;
    reg [TRANS_WR_RESP_W-1:0] rand_resp;
    reg rand_valid;
    integer loop_idx;

    // Instantiate the DUT
    B_dispatcher_m #(
        .TRANS_WR_RESP_W(TRANS_WR_RESP_W),
        .NUM_MASTERS(NUM_MASTERS)
    ) dut (
        .m_axi_bresp_o(m_axi_bresp_o),
        .m_axi_bvalid_o(m_axi_bvalid_o),
        .m_axi_bready_i(m_axi_bready_i),
        .s_axi_bresp_i(s_axi_bresp_i),
        .s_axi_bvalid_i(s_axi_bvalid_i),
        .s_axi_bready_o(s_axi_bready_o),
        .Master_ID_Selected_i(Master_ID_Selected_i)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Reset task
    task reset;
        begin
            rst_n = 0;
            m_axi_bready_i = 0;
            s_axi_bresp_i = 0;
            s_axi_bvalid_i = 0;
            Master_ID_Selected_i = 0;
            #(CLK_PERIOD*2);
            rst_n = 1;
            #(CLK_PERIOD);
        end
    endtask

    // Task to drive inputs for a specific master
    task drive_inputs;
        input [31:0] master_idx;
        input [TRANS_WR_RESP_W-1:0] bresp;
        input bvalid;
        input bready;
        begin
            Master_ID_Selected_i = (1 << master_idx); // One-hot encoding
            s_axi_bresp_i = bresp;
            s_axi_bvalid_i = bvalid;
            for (loop_idx = 0; loop_idx < NUM_MASTERS; loop_idx = loop_idx + 1) begin
                m_axi_bready_i[loop_idx] = (loop_idx == master_idx) ? bready : 0;
            end
            #(CLK_PERIOD); // Ensure signals are stable for one cycle
        end
    endtask

    // Task to check outputs
    task check_outputs;
        input [31:0] master_idx;
        input [TRANS_WR_RESP_W-1:0] exp_bresp;
        input exp_bvalid;
        begin
            #(CLK_PERIOD/4); // Small delay to capture stable outputs
            if (m_axi_bresp_o[master_idx*TRANS_WR_RESP_W +: TRANS_WR_RESP_W] !== exp_bresp) begin
                $display("ERROR: m_axi_bresp_o[%0d] = %h, expected = %h at time %t", master_idx, m_axi_bresp_o[master_idx*TRANS_WR_RESP_W +: TRANS_WR_RESP_W], exp_bresp, $time);
            end else begin
                $display("PASS: m_axi_bresp_o[%0d] = %h at time %t", master_idx, m_axi_bresp_o[master_idx*TRANS_WR_RESP_W +: TRANS_WR_RESP_W], $time);
            end
            if (m_axi_bvalid_o[master_idx] !== exp_bvalid) begin
                $display("ERROR: m_axi_bvalid_o[%0d] = %b, expected = %b at time %t", master_idx, m_axi_bvalid_o[master_idx], exp_bvalid, $time);
            end else begin
                $display("PASS: m_axi_bvalid_o[%0d] = %b at time %t", master_idx, m_axi_bvalid_o[master_idx], $time);
            end
            // Check other masters' outputs are zero
            for (loop_idx = 0; loop_idx < NUM_MASTERS; loop_idx = loop_idx + 1) begin
                if (loop_idx != master_idx) begin
                    if (m_axi_bresp_o[loop_idx*TRANS_WR_RESP_W +: TRANS_WR_RESP_W] !== 0) begin
                        $display("ERROR: m_axi_bresp_o[%0d] = %h, expected = 0 at time %t", loop_idx, m_axi_bresp_o[loop_idx*TRANS_WR_RESP_W +: TRANS_WR_RESP_W], $time);
                    end
                    if (m_axi_bvalid_o[loop_idx] !== 0) begin
                        $display("ERROR: m_axi_bvalid_o[%0d] = %b, expected = 0 at time %t", loop_idx, m_axi_bvalid_o[loop_idx], $time);
                    end
                end
            end
        end
    endtask

    // Task to check s_axi_bready_o
    task check_bready;
        input [31:0] master_idx;
        input exp_bready;
        begin
            if (s_axi_bready_o !== exp_bready) begin
                $display("ERROR: s_axi_bready_o = %b, expected = %b at time %t", s_axi_bready_o, exp_bready, $time);
            end else begin
                $display("PASS: s_axi_bready_o = %b at time %t", s_axi_bready_o, $time);
            end
        end
    endtask

    // Test stimulus
    initial begin
        // Initialize
        reset();

        // Test case 1: Single master active (master 0)
        $display("Test Case 1: Single master active (master 0)");
        drive_inputs(0, 2'b00, 1, 1); // OKAY response
        check_outputs(0, 2'b00, 1);
        check_bready(0, 1);

        // Test case 2: Different master active (master 5)
        $display("Test Case 2: Different master active (master 5)");
        drive_inputs(5, 2'b10, 1, 1); // SLVERR response
        check_outputs(5, 2'b10, 1);
        check_bready(5, 1);

        // Test case 3: No master selected
        $display("Test Case 3: No master selected");
        Master_ID_Selected_i = 0;
        s_axi_bresp_i = 2'b00;
        s_axi_bvalid_i = 0;
        m_axi_bready_i = 0;
        #(CLK_PERIOD);
        for (loop_idx = 0; loop_idx < NUM_MASTERS; loop_idx = loop_idx + 1) begin
            if (m_axi_bresp_o[loop_idx*TRANS_WR_RESP_W +: TRANS_WR_RESP_W] !== 0) begin
                $display("ERROR: m_axi_bresp_o[%0d] = %h, expected = 0 at time %t", loop_idx, m_axi_bresp_o[loop_idx*TRANS_WR_RESP_W +: TRANS_WR_RESP_W], $time);
            end
            if (m_axi_bvalid_o[loop_idx] !== 0) begin
                $display("ERROR: m_axi_bvalid_o[%0d] = %b, expected = 0 at time %t", loop_idx, m_axi_bvalid_o[loop_idx], $time);
            end
        end
        check_bready(0, 0);

        // Test case 4: Random master with random data
        $display("Test Case 4: Random master with random data");
        repeat (10) begin
            rand_master = $random % NUM_MASTERS;
            if (rand_master < 0) rand_master = rand_master + NUM_MASTERS; // Ensure non-negative
            rand_resp = $random % 4; // Valid AXI responses: 00, 01, 10, 11
            rand_valid = $random % 2;
            rand_valid = $random % 2;
            drive_inputs(rand_master, rand_resp, rand_valid, rand_valid);
            check_outputs(rand_master, rand_resp, rand_valid);
            check_bready(rand_master, rand_valid);
        end

        // Test case 5: Toggle m_axi_bready_i
        $display("Test Case 5: Toggle m_axi_bready_i");
        drive_inputs(3, 2'b01, 1, 0); // EXOKAY response, bready = 0
        check_outputs(3, 2'b01, 1);
        check_bready(3, 0);
        drive_inputs(3, 2'b01, 1, 1); // Same, but bready = 1
        check_outputs(3, 2'b01, 1);
        check_bready(3, 1);

        // Test case 6: Cycle through all masters
        $display("Test Case 6: Cycle through all masters");
        for (loop_idx = 0; loop_idx < NUM_MASTERS; loop_idx = loop_idx + 1) begin
            drive_inputs(loop_idx, 2'b00, 1, 1);
            check_outputs(loop_idx, 2'b00, 1);
            check_bready(loop_idx, 1);
        end

        // Test case 7: Invalid one-hot (multiple bits set)
        $display("Test Case 7: Invalid one-hot input (multiple bits set)");
        Master_ID_Selected_i = 16'b0000000000000011; // Masters 0 and 1
        s_axi_bresp_i = 2'b10;
        s_axi_bvalid_i = 1;
        m_axi_bready_i[0] = 0;
        m_axi_bready_i[1] = 1;
        #(CLK_PERIOD);
        check_outputs(1, 2'b10, 1); // DUT picks master 1 (highest index)
        check_bready(1, 1);

        // End simulation
        #(CLK_PERIOD*2);
        $display("Simulation completed successfully!");
        $finish;
    end

endmodule