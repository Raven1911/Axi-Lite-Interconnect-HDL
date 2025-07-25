`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/23/2025 10:42:06 PM
// Design Name: 
// Module Name: axi_interconnect_n_1_tb
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

module axi_interconnect_n_1_tb;
    // Parameters
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter TRANS_W_STRB_W = 4;
    parameter TRANS_WR_RESP_W = 2;
    parameter TRANS_PROT = 3;
    parameter QUANTUM_TIME = 50;
    parameter NUM_MASTERS = 16;
    parameter NUM_SLAVES = 16;
    parameter CLK_PERIOD = 10; // 10ns clock period (100 MHz)

    // Signals
    reg m_axi_aclk_i;
    reg m_axi_aresetn_i;
    
    // Master AW Channel
    reg  [ADDR_WIDTH*NUM_MASTERS-1:0] m_axi_awaddr_i;
    reg  [NUM_MASTERS-1:0]            m_axi_awvalid_i;
    wire [NUM_MASTERS-1:0]            m_axi_awready_o;
    reg  [NUM_MASTERS*TRANS_PROT-1:0] m_axi_awprot_i;
    
    // Master W Channel
    reg  [DATA_WIDTH*NUM_MASTERS-1:0]     m_axi_wdata_i;
    reg  [TRANS_W_STRB_W*NUM_MASTERS-1:0] m_axi_wstrb_i;
    reg  [NUM_MASTERS-1:0]                m_axi_wvalid_i;
    wire [NUM_MASTERS-1:0]                m_axi_wready_o;
    
    // Master B Channel
    wire [TRANS_WR_RESP_W*NUM_MASTERS-1:0] m_axi_bresp_o;
    wire [NUM_MASTERS-1:0]                 m_axi_bvalid_o;
    reg  [NUM_MASTERS-1:0]                 m_axi_bready_i;
    
    // Master AR Channel
    reg  [ADDR_WIDTH*NUM_MASTERS-1:0]     m_axi_araddr_i;
    reg  [NUM_MASTERS-1:0]                m_axi_arvalid_i;
    wire [NUM_MASTERS-1:0]                m_axi_arready_o;
    reg  [NUM_MASTERS*TRANS_PROT-1:0]     m_axi_arprot_i;
    
    // Master R Channel
    wire [DATA_WIDTH*NUM_MASTERS-1:0]      m_axi_rdata_o;
    wire [TRANS_WR_RESP_W*NUM_MASTERS-1:0] m_axi_rresp_o;
    wire [NUM_MASTERS-1:0]                 m_axi_rvalid_o;
    reg  [NUM_MASTERS-1:0]                 m_axi_rready_i;
    
    // Slave AW Channel
    wire [ADDR_WIDTH-1:0]     s_axi_awaddr_o;
    wire                      s_axi_awvalid_o;
    reg                       s_axi_awready_i;
    
    // Slave W Channel
    wire [DATA_WIDTH-1:0]     s_axi_wdata_o;
    wire [TRANS_W_STRB_W-1:0] s_axi_wstrb_o;
    wire                      s_axi_wvalid_o;
    reg                       s_axi_wready_i;
    
    // Slave B Channel
    reg  [TRANS_WR_RESP_W-1:0] s_axi_bresp_i;
    reg                        s_axi_bvalid_i;
    wire                       s_axi_bready_o;
    
    // Slave AR Channel
    wire [ADDR_WIDTH-1:0]     s_axi_araddr_o;
    wire                      s_axi_arvalid_o;
    reg                       s_axi_arready_i;
    wire [TRANS_PROT-1:0]     s_axi_arprot_o;
    
    // Slave R Channel
    reg  [DATA_WIDTH-1:0]     s_axi_rdata_i;
    reg  [TRANS_WR_RESP_W-1:0] s_axi_rresp_i;
    reg                        s_axi_rvalid_i;
    wire                       s_axi_rready_o;

    // Instantiate the DUT
    axi_interconnect_n_1 #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .TRANS_W_STRB_W(TRANS_W_STRB_W),
        .TRANS_WR_RESP_W(TRANS_WR_RESP_W),
        .TRANS_PROT(TRANS_PROT),
        .QUANTUM_TIME(QUANTUM_TIME),
        .NUM_MASTERS(NUM_MASTERS),
        .NUM_SLAVES(NUM_SLAVES)
    ) dut (
        .m_axi_aclk_i(m_axi_aclk_i),
        .m_axi_aresetn_i(m_axi_aresetn_i),
        .m_axi_awaddr_i(m_axi_awaddr_i),
        .m_axi_awvalid_i(m_axi_awvalid_i),
        .m_axi_awready_o(m_axi_awready_o),
        .m_axi_awprot_i(m_axi_awprot_i),
        .m_axi_wdata_i(m_axi_wdata_i),
        .m_axi_wstrb_i(m_axi_wstrb_i),
        .m_axi_wvalid_i(m_axi_wvalid_i),
        .m_axi_wready_o(m_axi_wready_o),
        .m_axi_bresp_o(m_axi_bresp_o),
        .m_axi_bvalid_o(m_axi_bvalid_o),
        .m_axi_bready_i(m_axi_bready_i),
        .m_axi_araddr_i(m_axi_araddr_i),
        .m_axi_arvalid_i(m_axi_arvalid_i),
        .m_axi_arready_o(m_axi_arready_o),
        .m_axi_arprot_i(m_axi_arprot_i),
        .m_axi_rdata_o(m_axi_rdata_o),
        .m_axi_rresp_o(m_axi_rresp_o),
        .m_axi_rvalid_o(m_axi_rvalid_o),
        .m_axi_rready_i(m_axi_rready_i),
        .s_axi_awaddr_o(s_axi_awaddr_o),
        .s_axi_awvalid_o(s_axi_awvalid_o),
        .s_axi_awready_i(s_axi_awready_i),
        .s_axi_awprot_o(s_axi_awprot_o),
        .s_axi_wdata_o(s_axi_wdata_o),
        .s_axi_wstrb_o(s_axi_wstrb_o),
        .s_axi_wvalid_o(s_axi_wvalid_o),
        .s_axi_wready_i(s_axi_wready_i),
        .s_axi_bresp_i(s_axi_bresp_i),
        .s_axi_bvalid_i(s_axi_bvalid_i),
        .s_axi_bready_o(s_axi_bready_o),
        .s_axi_araddr_o(s_axi_araddr_o),
        .s_axi_arvalid_o(s_axi_arvalid_o),
        .s_axi_arready_i(s_axi_arready_i),
        .s_axi_arprot_o(s_axi_arprot_o),
        .s_axi_rdata_i(s_axi_rdata_i),
        .s_axi_rresp_i(s_axi_rresp_i),
        .s_axi_rvalid_i(s_axi_rvalid_i),
        .s_axi_rready_o(s_axi_rready_o)
    );

    // Clock generation
    initial begin
        m_axi_aclk_i = 0;
        forever #(CLK_PERIOD/2) m_axi_aclk_i = ~m_axi_aclk_i;
    end

    // Reset task
    task reset_dut;
        begin
            m_axi_aresetn_i = 0;
            #20;
            m_axi_aresetn_i = 1;
        end
    endtask

    // Initialize inputs
    initial begin
        m_axi_awaddr_i = 0;
        m_axi_awvalid_i = 0;
        m_axi_awprot_i = 0;
        m_axi_wdata_i = 0;
        m_axi_wstrb_i = 0;
        m_axi_wvalid_i = 0;
        m_axi_bready_i = 0;
        m_axi_araddr_i = 0;
        m_axi_arvalid_i = 0;
        m_axi_arprot_i = 0;
        m_axi_rready_i = 0;
        s_axi_awready_i = 0;
        s_axi_wready_i = 0;
        s_axi_bresp_i = 0;
        s_axi_bvalid_i = 0;
        s_axi_arready_i = 0;
        s_axi_rdata_i = 0;
        s_axi_rresp_i = 0;
        s_axi_rvalid_i = 0;
    end

    // Task to simulate write transaction (AW, W, B)
    task write_transaction;
        input integer master_id;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        input [TRANS_W_STRB_W-1:0] strb;
        begin
            // AW Channel
            @(posedge m_axi_aclk_i);
            m_axi_awaddr_i[master_id*ADDR_WIDTH +: ADDR_WIDTH] = addr;
            m_axi_awprot_i[master_id*TRANS_PROT +: TRANS_PROT] = 3'b000;
            m_axi_awvalid_i[master_id] = 1;
            @(posedge m_axi_aclk_i); // Cycle 1: awvalid high
            @(posedge m_axi_aclk_i); // Cycle 2: awvalid high
            s_axi_awready_i = 1; // Cycle 3: awready high
            if (!s_axi_awvalid_o || s_axi_awaddr_o != addr) begin
                $display("Error: AW Channel mismatch! Expected addr: %h, Got: %h at time %0t", addr, s_axi_awaddr_o, $time);
                $finish;
            end
            if (!m_axi_awready_o[master_id]) begin
                $display("Error: m_axi_awready_o[%0d] not high in cycle 3 at time %0t", master_id, $time);
                $finish;
            end
            @(posedge m_axi_aclk_i);
            m_axi_awvalid_i[master_id] = 0; // awvalid low
            s_axi_awready_i = 0; // awready low

            // W Channel
            @(posedge m_axi_aclk_i);
            m_axi_wdata_i[master_id*DATA_WIDTH +: DATA_WIDTH] = data;
            m_axi_wstrb_i[master_id*TRANS_W_STRB_W +: TRANS_W_STRB_W] = strb;
            m_axi_wvalid_i[master_id] = 1;
            @(posedge m_axi_aclk_i); // Cycle 1: wvalid high
            @(posedge m_axi_aclk_i); // Cycle 2: wvalid high
            s_axi_wready_i = 1; // Cycle 3: wready high
            if (!s_axi_wvalid_o || s_axi_wdata_o != data || s_axi_wstrb_o != strb) begin
                $display("Error: W Channel mismatch! Expected data: %h, Got: %h at time %0t", data, s_axi_wdata_o, $time);
                $finish;
            end
            if (!m_axi_wready_o[master_id]) begin
                $display("Error: m_axi_wready_o[%0d] not high in cycle 3 at time %0t", master_id, $time);
                $finish;
            end
            @(posedge m_axi_aclk_i);
            m_axi_wvalid_i[master_id] = 0; // wvalid low
            s_axi_wready_i = 0; // wready low

            // B Channel
            @(posedge m_axi_aclk_i);
            m_axi_bready_i[master_id] = 1;
            @(posedge m_axi_aclk_i); // Cycle 1: bready high
            @(posedge m_axi_aclk_i); // Cycle 2: bready high
            s_axi_bresp_i = 2'b00; // OKAY response
            s_axi_bvalid_i = 1; // Cycle 3: bvalid high
            if (!s_axi_bready_o) begin
                $display("Error: s_axi_bready_o not high in cycle 3 at time %0t", $time);
                $finish;
            end
            if (!m_axi_bvalid_o[master_id]) begin
                $display("Error: m_axi_bvalid_o[%0d] not high in cycle 3 at time %0t", master_id, $time);
                $finish;
            end
            if (m_axi_bresp_o[master_id*TRANS_WR_RESP_W +: TRANS_WR_RESP_W] == 2'b00) begin
                $display("Write Transaction from Master %0d Successful! Addr: %h, Data: %h", master_id, addr, data);
            end else begin
                $display("Write Transaction from Master %0d Failed! Response: %b", master_id, m_axi_bresp_o[master_id*TRANS_WR_RESP_W +: TRANS_WR_RESP_W]);
            end
            @(posedge m_axi_aclk_i);
            m_axi_bready_i[master_id] = 0; // bready low
            s_axi_bvalid_i = 0; // bvalid low
        end
    endtask

    // Task to simulate read transaction (AR, R)
    task read_transaction;
        input integer master_id;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] expected_data;
        begin
            // AR Channel
            @(posedge m_axi_aclk_i);
            m_axi_araddr_i[master_id*ADDR_WIDTH +: ADDR_WIDTH] = addr;
            m_axi_arprot_i[master_id*TRANS_PROT +: TRANS_PROT] = 3'b000;
            m_axi_arvalid_i[master_id] = 1;
            @(posedge m_axi_aclk_i); // Cycle 1: arvalid high
            @(posedge m_axi_aclk_i); // Cycle 2: arvalid high
            s_axi_arready_i = 1; // Cycle 3: arready high
            if (!s_axi_arvalid_o || s_axi_araddr_o != addr) begin
                $display("Error: AR Channel mismatch! Expected addr: %h, Got: %h at time %0t", addr, s_axi_araddr_o, $time);
                $finish;
            end
            if (!m_axi_arready_o[master_id]) begin
                $display("Error: m_axi_arready_o[%0d] not high in cycle 3 at time %0t", master_id, $time);
                $finish;
            end
            @(posedge m_axi_aclk_i);
            m_axi_arvalid_i[master_id] = 0; // arvalid low
            s_axi_arready_i = 0; // arready low

            // R Channel
            @(posedge m_axi_aclk_i);
            m_axi_rready_i[master_id] = 1;
            @(posedge m_axi_aclk_i); // Cycle 1: rready high
            @(posedge m_axi_aclk_i); // Cycle 2: rready high
            s_axi_rdata_i = expected_data;
            s_axi_rresp_i = 2'b00; // OKAY response
            s_axi_rvalid_i = 1; // Cycle 3: rvalid high
            if (!s_axi_rready_o) begin
                $display("Error: s_axi_rready_o not high in cycle 3 at time %0t", $time);
                $finish;
            end
            if (!m_axi_rvalid_o[master_id]) begin
                $display("Error: m_axi_rvalid_o[%0d] not high in cycle 3 at time %0t", master_id, $time);
                $finish;
            end
            if (m_axi_rdata_o[master_id*DATA_WIDTH +: DATA_WIDTH] == expected_data && 
                m_axi_rresp_o[master_id*TRANS_WR_RESP_W +: TRANS_WR_RESP_W] == 2'b00) begin
                $display("Read Transaction from Master %0d Successful! Addr: %h, Data: %h", master_id, addr, m_axi_rdata_o[master_id*DATA_WIDTH +: DATA_WIDTH]);
            end else begin
                $display("Read Transaction from Master %0d Failed! Data: %h, Response: %b", 
                         master_id, m_axi_rdata_o[master_id*DATA_WIDTH +: DATA_WIDTH], 
                         m_axi_rresp_o[master_id*TRANS_WR_RESP_W +: TRANS_WR_RESP_W]);
            end
            @(posedge m_axi_aclk_i);
            m_axi_rready_i[master_id] = 0; // rready low
            s_axi_rvalid_i = 0; // rvalid low
        end
    endtask

    // Test scenario
    initial begin
        // Reset the DUT
        reset_dut();
        #20;

        // Test 1: Write transaction from Master 0
        $display("Starting Write Transaction Test for Master 0...");
        write_transaction(0, 32'h0000_1000, 32'hDEAD_BEEF, 4'b1111);
        #20;

        // Test 2: Read transaction from Master 1
        $display("Starting Read Transaction Test for Master 1...");
        read_transaction(1, 32'h0000_2000, 32'hCAFE_1234);
        #20;

        // Test 3: Concurrent write transactions from Master 0 and Master 2
        $display("Starting Concurrent Write Transaction Test for Master 0 and Master 2...");
        fork
            write_transaction(0, 32'h0000_3000, 32'h1234_5678, 4'b1111);
            write_transaction(2, 32'h0000_4000, 32'h8765_4321, 4'b1111);
        join
        #20;

        // Test 4: Concurrent read transactions from Master 1 and Master 3
        $display("Starting Concurrent Read Transaction Test for Master 1 and Master 3...");
        fork
            read_transaction(1, 32'h0000_5000, 32'hABCD_1234);
            read_transaction(3, 32'h0000_6000, 32'h5678_9ABC);
        join
        #20;

        // Test 5: Concurrent write transactions from 4 Masters (0, 2, 4, 6)
        $display("Starting Concurrent Write Transaction Test for Masters 0, 2, 4, 6...");
        fork
            write_transaction(0, 32'h0000_7000, 32'h1111_1111, 4'b1111);
            write_transaction(2, 32'h0000_8000, 32'h2222_2222, 4'b1111);
            write_transaction(4, 32'h0000_9000, 32'h3333_3333, 4'b1111);
            write_transaction(6, 32'h0000_A000, 32'h4444_4444, 4'b1111);
        join
        #20;

        // Test 6: Concurrent read transactions from 4 Masters (1, 3, 5, 7)
        $display("Starting Concurrent Read Transaction Test for Masters 1, 3, 5, 7...");
        fork
            read_transaction(1, 32'h0000_B000, 32'h5555_5555);
            read_transaction(3, 32'h0000_C000, 32'h6666_6666);
            read_transaction(5, 32'h0000_D000, 32'h7777_7777);
            read_transaction(7, 32'h0000_E000, 32'h8888_8888);
        join
        #20;

        // Test 7: Mixed concurrent write and read transactions from 4 Masters (0, 1, 2, 3)
        $display("Starting Mixed Concurrent Write and Read Transaction Test for Masters 0, 1, 2, 3...");
        fork
            write_transaction(0, 32'h0000_F000, 32'h9999_9999, 4'b1111);
            read_transaction(1, 32'h0001_0000, 32'hAAAA_AAAA);
            write_transaction(2, 32'h0001_1000, 32'hBBBB_BBBB, 4'b1111);
            read_transaction(3, 32'h0001_2000, 32'hCCCC_CCCC);
        join
        #20;

        $display("Simulation Completed!");
        $finish;
    end

endmodule