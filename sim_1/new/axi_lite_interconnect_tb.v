`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2025 07:45:11 AM
// Design Name: 
// Module Name: axi_lite_interconnect_tb
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


module axi_lite_interconnect_tb;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter NUM_SLAVES = 1;
    // Clock and Reset
    reg                     clk;
    reg                     resetn;
    // AXI4-Lite Master Interface (from picorv32_axi)
    reg                     i_m_axi_awvalid;    // Master Write Address Valid
    wire                    o_m_axi_awready;    // Master Write Address Ready
    reg  [ADDR_WIDTH-1:0]   i_m_axi_awaddr;     // Master Write Address
    reg  [2:0]              i_m_axi_awprot;     // Master Write Protection
    reg                     i_m_axi_wvalid;     // Master Write Data Valid
    wire                    o_m_axi_wready;     // Master Write Data Ready
    reg  [DATA_WIDTH-1:0]   i_m_axi_wdata;      // Master Write Data
    reg  [DATA_WIDTH/8-1:0] i_m_axi_wstrb;      // Master Write Strobe
    wire                    o_m_axi_bvalid;     // Master Write Response Valid
    reg                     i_m_axi_bready;     // Master Write Response Ready
    reg                     i_m_axi_arvalid;    // Master Read Address Valid
    wire                    o_m_axi_arready;    // Master Read Address Ready
    reg  [ADDR_WIDTH-1:0]   i_m_axi_araddr;     // Master Read Address
    reg  [2:0]              i_m_axi_arprot;     // Master Read Protection
    wire                    o_m_axi_rvalid;     // Master Read Data Valid
    reg                     i_m_axi_rready;     // Master Read Data Ready
    wire [DATA_WIDTH-1:0]   o_m_axi_rdata;      // Master Read Data

    // AXI4-Lite Slave Interfaces
    wire                 [ADDR_WIDTH-1:0]    o_s_axi_awaddr;   // Slave Write Address
    wire                     o_s_axi_awvalid;  // Slave Write Address Valid
    reg                      i_s_axi_awready;  // Slave Write Address Ready
    wire [2:0]               o_s_axi_awprot;   // Slave Write Protection
    wire [DATA_WIDTH-1:0]    o_s_axi_wdata;    // Slave Write Data
    wire [DATA_WIDTH/8-1:0]  o_s_axi_wstrb;    // Slave Write Strobe
    wire                     o_s_axi_wvalid;   // Slave Write Data Valid
    reg                      i_s_axi_wready;   // Slave Write Data Ready
    reg                      i_s_axi_bvalid;   // Slave Write Response Valid
    wire                     o_s_axi_bready;   // Slave Write Response Ready
    wire                 [ADDR_WIDTH-1:0]    o_s_axi_araddr;   // Slave Read Address
    wire                     o_s_axi_arvalid;  // Slave Read Address Valid
    reg                      i_s_axi_arready;  // Slave Read Address Ready
    wire [2:0]               o_s_axi_arprot;   // Slave Read Protection
    reg  [DATA_WIDTH-1:0]    i_s_axi_rdata;    // Slave Read Data
    reg                      i_s_axi_rvalid;   // Slave Read Data Valid
    wire                     o_s_axi_rready;   // Slave Read Data Ready


     // Instantiate DUT
    axi_lite_interconnect #(
        .NUM_SLAVES(NUM_SLAVES),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .i_m_axi_awvalid(i_m_axi_awvalid),
        .o_m_axi_awready(o_m_axi_awready),
        .i_m_axi_awaddr(i_m_axi_awaddr),
        .i_m_axi_awprot(i_m_axi_awprot),
        .i_m_axi_wvalid(i_m_axi_wvalid),
        .o_m_axi_wready(o_m_axi_wready),
        .i_m_axi_wdata(i_m_axi_wdata),
        .i_m_axi_wstrb(i_m_axi_wstrb),
        .o_m_axi_bvalid(o_m_axi_bvalid),
        .i_m_axi_bready(i_m_axi_bready),
        .i_m_axi_arvalid(i_m_axi_arvalid),
        .o_m_axi_arready(o_m_axi_arready),
        .i_m_axi_araddr(i_m_axi_araddr),
        .i_m_axi_arprot(i_m_axi_arprot),
        .o_m_axi_rvalid(o_m_axi_rvalid),
        .i_m_axi_rready(i_m_axi_rready),
        .o_m_axi_rdata(o_m_axi_rdata),
        
        .o_s_axi_awaddr(o_s_axi_awaddr),
        .o_s_axi_awvalid(o_s_axi_awvalid),
        .i_s_axi_awready(i_s_axi_awready),
        .o_s_axi_awprot(o_s_axi_awprot),
        .o_s_axi_wdata(o_s_axi_wdata),
        .o_s_axi_wstrb(o_s_axi_wstrb),
        .o_s_axi_wvalid(o_s_axi_wvalid),
        .i_s_axi_wready(i_s_axi_wready),
        .i_s_axi_bvalid(i_s_axi_bvalid),
        .o_s_axi_bready(o_s_axi_bready),
        .o_s_axi_araddr(o_s_axi_araddr),
        .o_s_axi_arvalid(o_s_axi_arvalid),
        .i_s_axi_arready(i_s_axi_arready),
        .o_s_axi_arprot(o_s_axi_arprot),
        .i_s_axi_rdata(i_s_axi_rdata),
        .i_s_axi_rvalid(i_s_axi_rvalid),
        .o_s_axi_rready(o_s_axi_rready)
    );





    // Clock
    always #5 clk = ~clk;

    initial begin
        clk = 0; resetn = 1;
        #20 resetn = 0;



    end
endmodule

