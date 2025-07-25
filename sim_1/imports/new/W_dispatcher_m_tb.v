`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/22/2025 01:37:07 PM
// Design Name: 
// Module Name: W_dispatcher_m_tb
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


module W_dispatcher_m_tb;

    // Parameters
    parameter DATA_WIDTH = 32;
    parameter TRANS_W_STRB_W = 4;
    parameter NUM_MASTERS = 16;
    parameter CLK_PERIOD = 10;

    // Signals
    reg [DATA_WIDTH*NUM_MASTERS-1:0] m_axi_wdata_i;
    reg [TRANS_W_STRB_W*NUM_MASTERS-1:0] m_axi_wstrb_i;
    reg [NUM_MASTERS-1:0] m_axi_wvalid_i;
    wire [NUM_MASTERS-1:0] m_axi_wready_o;
    wire [DATA_WIDTH-1:0] s_axi_wdata_o;
    wire [TRANS_W_STRB_W-1:0] s_axi_wstrb_o;
    wire s_axi_wvalid_o;
    reg s_axi_wready_i;
    reg [NUM_MASTERS-1:0] Master_ID_Selected_i;
    wire [NUM_MASTERS-1:0] Master_ID_Selected_o;

    reg clk;
    reg rst_n;

    // Variables for random testing and loops
    integer rand_master;
    reg [DATA_WIDTH-1:0] rand_data;
    reg [TRANS_W_STRB_W-1:0] rand_strb;
    reg rand_valid;
    integer loop_idx; // For loops in tasks and test cases

    // Instantiate the DUT
    W_dispatcher_m #(
        .DATA_WIDTH(DATA_WIDTH),
        .TRANS_W_STRB_W(TRANS_W_STRB_W),
        .NUM_MASTERS(NUM_MASTERS)
    ) dut (
        .m_axi_wdata_i(m_axi_wdata_i),
        .m_axi_wstrb_i(m_axi_wstrb_i),
        .m_axi_wvalid_i(m_axi_wvalid_i),
        .m_axi_wready_o(m_axi_wready_o),
        .s_axi_wdata_o(s_axi_wdata_o),
        .s_axi_wstrb_o(s_axi_wstrb_o),
        .s_axi_wvalid_o(s_axi_wvalid_o),
        .s_axi_wready_i(s_axi_wready_i),
        .Master_ID_Selected_i(Master_ID_Selected_i),
        .Master_ID_Selected_o(Master_ID_Selected_o)
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
            m_axi_wdata_i = 0;
            m_axi_wstrb_i = 0;
            m_axi_wvalid_i = 0;
            s_axi_wready_i = 0;
            Master_ID_Selected_i = 0;
            #(CLK_PERIOD*2);
            rst_n = 1;
            #(CLK_PERIOD);
        end
    endtask

    // Task to drive inputs for a specific master
    task drive_master;
        input [31:0] master_idx;
        input [DATA_WIDTH-1:0] data;
        input [TRANS_W_STRB_W-1:0] strb;
        input valid;
        begin
            Master_ID_Selected_i = (1 << master_idx); // One-hot encoding
            for (loop_idx = 0; loop_idx < NUM_MASTERS; loop_idx = loop_idx + 1) begin
                if (loop_idx == master_idx) begin
                    m_axi_wdata_i[loop_idx*DATA_WIDTH +: DATA_WIDTH] = data;
                    m_axi_wstrb_i[loop_idx*TRANS_W_STRB_W +: TRANS_W_STRB_W] = strb;
                    m_axi_wvalid_i[loop_idx] = valid;
                end else begin
                    m_axi_wdata_i[loop_idx*DATA_WIDTH +: DATA_WIDTH] = 0;
                    m_axi_wstrb_i[loop_idx*TRANS_W_STRB_W +: TRANS_W_STRB_W] = 0;
                    m_axi_wvalid_i[loop_idx] = 0;
                end
            end
            #(CLK_PERIOD); // Ensure signals are stable for one cycle
        end
    endtask

    // Task to check outputs
    task check_outputs;
        input [DATA_WIDTH-1:0] exp_data;
        input [TRANS_W_STRB_W-1:0] exp_strb;
        input exp_valid;
        begin
            #(CLK_PERIOD/4); // Small delay to capture stable outputs
            if (s_axi_wdata_o !== exp_data) begin
                $display("ERROR: s_axi_wdata_o = %h, expected = %h at time %t", s_axi_wdata_o, exp_data, $time);
            end else begin
                $display("PASS: s_axi_wdata_o = %h at time %t", s_axi_wdata_o, $time);
            end
            if (s_axi_wstrb_o !== exp_strb) begin
                $display("ERROR: s_axi_wstrb_o = %h, expected = %h at time %t", s_axi_wstrb_o, exp_strb, $time);
            end else begin
                $display("PASS: s_axi_wstrb_o = %h at time %t", s_axi_wstrb_o, $time);
            end
            if (s_axi_wvalid_o !== exp_valid) begin
                $display("ERROR: s_axi_wvalid_o = %b, expected = %b at time %t", s_axi_wvalid_o, exp_valid, $time);
            end else begin
                $display("PASS: s_axi_wvalid_o = %b at time %t", s_axi_wvalid_o, $time);
            end
        end
    endtask

    // Task to check m_axi_wready_o for one-hot master
    task check_wready;
        input [31:0] master_idx;
        begin
            if (m_axi_wready_o[master_idx] !== s_axi_wready_i) begin
                $display("ERROR: m_axi_wready_o[%0d] = %b, expected = %b at time %t", master_idx, m_axi_wready_o[master_idx], s_axi_wready_i, $time);
            end else begin
                $display("PASS: m_axi_wready_o[%0d] = %b at time %t", master_idx, m_axi_wready_o[master_idx], $time);
            end
            // Check that other masters have wready = 0
            for (loop_idx = 0; loop_idx < NUM_MASTERS; loop_idx = loop_idx + 1) begin
                if (loop_idx != master_idx && m_axi_wready_o[loop_idx] !== 0) begin
                    $display("ERROR: m_axi_wready_o[%0d] = %b, expected = 0 at time %t", loop_idx, m_axi_wready_o[loop_idx], $time);
                end
            end
        end
    endtask

    // Test stimulus
    initial begin
        // Initialize
        reset();

        // Test case 1: Single master active (master 0)
        $display("Test Case 1: Single master active (master 0)");
        s_axi_wready_i = 1;
        drive_master(0, 32'hDEADBEEF, 4'b1111, 1);
        check_outputs(32'hDEADBEEF, 4'b1111, 1);
        check_wready(0);

        // Test case 2: Different master active (master 5)
        $display("Test Case 2: Different master active (master 5)");
        drive_master(5, 32'hCAFEBABE, 4'b1010, 1);
        check_outputs(32'hCAFEBABE, 4'b1010, 1);
        check_wready(5);

        // Test case 3: No master selected
        $display("Test Case 3: No master selected");
        Master_ID_Selected_i = 0;
        m_axi_wdata_i = 0;
        m_axi_wstrb_i = 0;
        m_axi_wvalid_i = 0;
        #(CLK_PERIOD);
        check_outputs(0, 0, 0);
        if (|m_axi_wready_o !== 0) begin
            $display("ERROR: m_axi_wready_o = %b, expected all 0 at time %t", m_axi_wready_o, $time);
        end else begin
            $display("PASS: m_axi_wready_o all 0 at time %t", $time);
        end

        // Test case 4: Random master with random data
        $display("Test Case 4: Random master with random data");
        repeat (10) begin
            rand_master = $random % NUM_MASTERS;
            if (rand_master < 0) rand_master = rand_master + NUM_MASTERS; // Ensure non-negative
            rand_data = $random;
            rand_strb = $random;
            rand_valid = $random % 2;
            drive_master(rand_master, rand_data, rand_strb, rand_valid);
            check_outputs(rand_data, rand_strb, rand_valid);
            check_wready(rand_master);
        end

        // Test case 5: Toggle s_axi_wready_i
        $display("Test Case 5: Toggle s_axi_wready_i");
        s_axi_wready_i = 0;
        drive_master(3, 32'h12345678, 4'b1100, 1);
        check_outputs(32'h12345678, 4'b1100, 1);
        check_wready(3); // Should be 0 since s_axi_wready_i = 0
        s_axi_wready_i = 1;
        #(CLK_PERIOD);
        check_wready(3); // Should be 1 since s_axi_wready_i = 1

        // Test case 6: Master_ID_Selected pass-through
        $display("Test Case 6: Master_ID_Selected pass-through");
        Master_ID_Selected_i = 16'hA5A5; // Not one-hot, testing pass-through
        #(CLK_PERIOD);
        if (Master_ID_Selected_o !== 16'hA5A5) begin
            $display("ERROR: Master_ID_Selected_o = %h, expected = %h at time %t", Master_ID_Selected_o, 16'hA5A5, $time);
        end else begin
            $display("PASS: Master_ID_Selected_o = %h at time %t", Master_ID_Selected_o, $time);
        end

        // Test case 7: Cycle through all masters
        $display("Test Case 7: Cycle through all masters");
        for (loop_idx = 0; loop_idx < NUM_MASTERS; loop_idx = loop_idx + 1) begin
            drive_master(loop_idx, 32'h00000000 + loop_idx, 4'b1111, 1);
            check_outputs(32'h00000000 + loop_idx, 4'b1111, 1);
            check_wready(loop_idx);
        end

        // Test case 8: Invalid one-hot (multiple bits set)
        $display("Test Case 8: Invalid one-hot input (multiple bits set)");
        Master_ID_Selected_i = 16'b0000000000000011; // Two bits set (masters 0 and 1)
        m_axi_wdata_i[0*DATA_WIDTH +: DATA_WIDTH] = 32'hAAAA_AAAA;
        m_axi_wdata_i[1*DATA_WIDTH +: DATA_WIDTH] = 32'hBBBB_BBBB;
        m_axi_wstrb_i[0*TRANS_W_STRB_W +: TRANS_W_STRB_W] = 4'b1100;
        m_axi_wstrb_i[1*TRANS_W_STRB_W +: TRANS_W_STRB_W] = 4'b0011;
        m_axi_wvalid_i[0] = 1;
        m_axi_wvalid_i[1] = 1;
        #(CLK_PERIOD);
        // DUT's for loop selects highest index (master 1)
        check_outputs(32'hBBBB_BBBB, 4'b0011, 1);
        check_wready(1);

        // End simulation
        #(CLK_PERIOD*2);
        $display("Simulation completed successfully!");
        $finish;
    end

endmodule