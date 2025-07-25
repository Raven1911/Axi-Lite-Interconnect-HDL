`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/25/2025 10:37:09 PM
// Design Name: 
// Module Name: axi_lite_slave_interface_tb
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
module axi_lite_slave_interface_tb;

    // Parameters
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter TRANS_W_STRB_W = 4;
    parameter TRANS_WR_RESP_W = 2;
    parameter TRANS_PROT = 3;
    parameter CYCLE_CLOCK = 3;
    parameter CLK_PERIOD = 10;

    // Testbench signals
    reg                             clk_i;
    reg                             resetn_i;
    reg  [ADDR_WIDTH-1:0]           i_axi_awaddr;
    reg                             i_axi_awvalid;
    wire                            o_axi_awready;
    reg  [TRANS_PROT-1:0]           i_axi_awprot;
    reg  [DATA_WIDTH-1:0]           i_axi_wdata;
    reg  [TRANS_W_STRB_W-1:0]       i_axi_wstrb;
    reg                             i_axi_wvalid;
    wire                            o_axi_wready;
    wire [TRANS_WR_RESP_W-1:0]      o_axi_bresp;
    wire                            o_axi_bvalid;
    reg                             i_axi_bready;
    reg  [ADDR_WIDTH-1:0]           i_axi_araddr;
    reg                             i_axi_arvalid;
    wire                            o_axi_arready;
    reg  [TRANS_PROT-1:0]           i_axi_arprot;
    wire [DATA_WIDTH-1:0]           o_axi_rdata;
    wire                            o_axi_rvalid;
    wire [TRANS_WR_RESP_W-1:0]      o_axi_rresp;
    reg                             i_axi_rready;
    wire [ADDR_WIDTH-1:0]           o_addr_w;
    wire [TRANS_PROT-1:0]           o_awprot_w;
    wire [3:0]                      o_wen;
    wire [DATA_WIDTH-1:0]           o_data_w;
    wire                            o_write_data_w;
    reg  [TRANS_WR_RESP_W-1:0]      o_bresp_w;
    wire [ADDR_WIDTH-1:0]           o_addr_r;
    wire [TRANS_PROT-1:0]           o_arprot_r;
    reg  [DATA_WIDTH-1:0]           i_data_r;
    reg  [TRANS_WR_RESP_W-1:0]      o_rresp_r;
    wire                            o_read_data_r;

    // Instantiate the AXI-Lite slave interface
    axi_lite_slave_interface #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .TRANS_W_STRB_W(TRANS_W_STRB_W),
        .TRANS_WR_RESP_W(TRANS_WR_RESP_W),
        .TRANS_PROT(TRANS_PROT),
        .CYCLE_CLOCK(CYCLE_CLOCK)
    ) duut (
        .clk_i(clk_i),
        .resetn_i(resetn_i),
        .i_axi_awaddr(i_axi_awaddr),
        .i_axi_awvalid(i_axi_awvalid),
        .o_axi_awready(o_axi_awready),
        .i_axi_awprot(i_axi_awprot),
        .i_axi_wdata(i_axi_wdata),
        .i_axi_wstrb(i_axi_wstrb),
        .i_axi_wvalid(i_axi_wvalid),
        .o_axi_wready(o_axi_wready),
        .o_axi_bresp(o_axi_bresp),
        .o_axi_bvalid(o_axi_bvalid),
        .i_axi_bready(i_axi_bready),
        .i_axi_araddr(i_axi_araddr),
        .i_axi_arvalid(i_axi_arvalid),
        .o_axi_arready(o_axi_arready),
        .i_axi_arprot(i_axi_arprot),
        .o_axi_rdata(o_axi_rdata),
        .o_axi_rvalid(o_axi_rvalid),
        .o_axi_rresp(o_axi_rresp),
        .i_axi_rready(i_axi_rready),
        .o_addr_w(o_addr_w),
        .o_awprot_w(o_awprot_w),
        .o_wen(o_wen),
        .o_data_w(o_data_w),
        .o_write_data_w(o_write_data_w),
        .o_bresp_w(o_bresp_w),
        .o_addr_r(o_addr_r),
        .o_arprot_r(o_arprot_r),
        .i_data_r(i_data_r),
        .o_rresp_r(o_rresp_r),
        .o_read_data_r(o_read_data_r)
    );

    // Clock generation
    initial begin
        clk_i = 0;
        forever #(CLK_PERIOD/2) clk_i = ~clk_i;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        resetn_i = 0;
        i_axi_awaddr = 0;
        i_axi_awvalid = 0;
        i_axi_awprot = 0;
        i_axi_wdata = 0;
        i_axi_wstrb = 0;
        i_axi_wvalid = 0;
        i_axi_bready = 0;
        i_axi_araddr = 0;
        i_axi_arvalid = 0;
        i_axi_arprot = 0;
        i_axi_rready = 0;
        o_bresp_w = 0;
        i_data_r = 0;
        o_rresp_r = 0;

        // Apply reset
        #15 resetn_i = 1;

        // Test case 1: Write transaction
        #10;
        i_axi_awaddr = 32'h0000_1000;
        i_axi_awprot = 3'b000;
        i_axi_awvalid = 1;
        #30 i_axi_awvalid = 0; // Assert for 3 cycles (30ns)
        #(CLK_PERIOD * CYCLE_CLOCK); // Wait for awready (2 cycles = 20ns)
        i_axi_wdata = 32'hDEAD_BEEF;
        i_axi_wstrb = 4'b1111;
        i_axi_wvalid = 1;
        #30 i_axi_wvalid = 0; // Assert for 3 cycles
        #(CLK_PERIOD * CYCLE_CLOCK); // Wait for wready (2 cycles)
        i_axi_bready = 1;
        o_bresp_w = 2'b00; // OKAY response
        #30 i_axi_bready = 0; // Assert for 3 cycles
        #(CLK_PERIOD * CYCLE_CLOCK); // Wait for bvalid (2 cycles)

        // Test case 2: Read transaction
        #10;
        i_axi_araddr = 32'h0000_2000;
        i_axi_arprot = 3'b000;
        i_axi_arvalid = 1;
        #30 i_axi_arvalid = 0; // Assert for 3 cycles
        #(CLK_PERIOD * CYCLE_CLOCK); // Wait for arready (2 cycles)
        i_data_r = 32'hCAFE_1234;
        o_rresp_r = 2'b00; // OKAY response
        i_axi_rready = 1;
        #30 i_axi_rready = 0; // Assert for 3 cycles
        #(CLK_PERIOD * CYCLE_CLOCK); // Wait for rvalid (2 cycles)

        // Test case 3: Write with partial strobe
        #10;
        i_axi_awaddr = 32'h0000_3000;
        i_axi_awprot = 3'b001;
        i_axi_awvalid = 1;
        #30 i_axi_awvalid = 0; // Assert for 3 cycles
        #(CLK_PERIOD * CYCLE_CLOCK);
        i_axi_wdata = 32'h1234_5678;
        i_axi_wstrb = 4'b1100;
        i_axi_wvalid = 1;
        #30 i_axi_wvalid = 0; // Assert for 3 cycles
        #(CLK_PERIOD * CYCLE_CLOCK);
        i_axi_bready = 1;
        o_bresp_w = 2'b00;
        #30 i_axi_bready = 0; // Assert for 3 cycles
        #(CLK_PERIOD * CYCLE_CLOCK);

        // Test case 4: Random transactions
        repeat (3) begin
            #10;
            i_axi_awaddr = $random;
            i_axi_awprot = $random;
            i_axi_awvalid = 1;
            #30 i_axi_awvalid = 0; // Assert for 3 cycles
            #(CLK_PERIOD * CYCLE_CLOCK);
            i_axi_wdata = $random;
            i_axi_wstrb = $random;
            i_axi_wvalid = 1;
            #30 i_axi_wvalid = 0; // Assert for 3 cycles
            #(CLK_PERIOD * CYCLE_CLOCK);
            i_axi_bready = 1;
            o_bresp_w = $random % 4;
            #30 i_axi_bready = 0; // Assert for 3 cycles
            #(CLK_PERIOD * CYCLE_CLOCK);

            #10;
            i_axi_araddr = $random;
            i_axi_arprot = $random;
            i_axi_arvalid = 1;
            #30 i_axi_arvalid = 0; // Assert for 3 cycles
            #(CLK_PERIOD * CYCLE_CLOCK);
            i_data_r = $random;
            o_rresp_r = $random % 4;
            i_axi_rready = 1;
            #30 i_axi_rready = 0; // Assert for 3 cycles
            #(CLK_PERIOD * CYCLE_CLOCK);
        end

        // Test case 5: Reset during transaction
        #10;
        i_axi_awaddr = 32'h0000_4000;
        i_axi_awvalid = 1;
        #15 resetn_i = 0; // Reset after 1.5 cycles
        #10 resetn_i = 1;
        i_axi_awvalid = 0;

        // End simulation
        #20;
        $display("Testbench completed!");
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time=%0t clk_i=%b resetn_i=%b awaddr=%h awvalid=%b awready=%b wdata=%h wstrb=%h wvalid=%b wready=%b bresp=%h bvalid=%b bready=%b araddr=%h arvalid=%b arready=%b rdata=%h rvalid=%b rresp=%h rready=%b o_read_data_r=%b",
                 $time, clk_i, resetn_i, i_axi_awaddr, i_axi_awvalid, o_axi_awready, i_axi_wdata, i_axi_wstrb, i_axi_wvalid, o_axi_wready,
                 o_axi_bresp, o_axi_bvalid, i_axi_bready, i_axi_araddr, i_axi_arvalid, o_axi_arready, o_axi_rdata, o_axi_rvalid, o_axi_rresp, i_axi_rready, o_read_data_r);
    end

endmodule