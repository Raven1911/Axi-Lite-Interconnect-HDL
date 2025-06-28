`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2025 02:14:35 AM
// Design Name: 
// Module Name: axi_lite_interconnect
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

/***************************************************************
 * AXI4-Lite Interconnect for picorv32_axi (Multiple Masters, Multiple Slaves)
 * This module connects multiple AXI4-Lite masters to multiple slaves using an arbiter,
 * decoder, and multiplexer. The arbiter selects one master at a time (Round-Robin),
 * the decoder selects the target slave based on address, and the multiplexer routes
 * signals between the selected master and slave.
 ***************************************************************/
module axi_lite_interconnect #(
    parameter NUM_MASTERS = 3,          // Number of masters
    parameter NUM_SLAVES  = 5,          // Number of slaves
    parameter ADDR_WIDTH  = 32,         // Address width
    parameter DATA_WIDTH  = 32          // Data width
)(
    // Clock and Reset
    input                           clk,        // Added clock for arbiter
    input                           resetn,

    // AXI4-Lite Master Interfaces (multiple masters)
    input  [NUM_MASTERS-1:0]                    i_m_axi_awvalid,    // Master Write Address Valid
    output [NUM_MASTERS-1:0]                    o_m_axi_awready,    // Master Write Address Ready
    input  [NUM_MASTERS-1:0][ADDR_WIDTH-1:0]    i_m_axi_awaddr,     // Master Write Address
    input  [NUM_MASTERS-1:0][2:0]               i_m_axi_awprot,     // Master Write Protection
    input  [NUM_MASTERS-1:0]                    i_m_axi_wvalid,     // Master Write Data Valid
    output [NUM_MASTERS-1:0]                    o_m_axi_wready,     // Master Write Data Ready
    input  [NUM_MASTERS-1:0][DATA_WIDTH-1:0]    i_m_axi_wdata,      // Master Write Data
    input  [NUM_MASTERS-1:0][DATA_WIDTH/8-1:0]  i_m_axi_wstrb,      // Master Write Strobe
    output [NUM_MASTERS-1:0]                    o_m_axi_bvalid,     // Master Write Response Valid
    input  [NUM_MASTERS-1:0]                    i_m_axi_bready,     // Master Write Response Ready
    input  [NUM_MASTERS-1:0]                    i_m_axi_arvalid,    // Master Read Address Valid
    output [NUM_MASTERS-1:0]                    o_m_axi_arready,    // Master Read Address Ready
    input  [NUM_MASTERS-1:0][ADDR_WIDTH-1:0]    i_m_axi_araddr,     // Master Read Address
    input  [NUM_MASTERS-1:0][2:0]               i_m_axi_arprot,     // Master Read Protection
    output [NUM_MASTERS-1:0]                    o_m_axi_rvalid,     // Master Read Data Valid
    input  [NUM_MASTERS-1:0]                    i_m_axi_rready,     // Master Read Data Ready
    output [NUM_MASTERS-1:0][DATA_WIDTH-1:0]    o_m_axi_rdata,      // Master Read Data

    // AXI4-Lite Slave Interfaces
    output                 [ADDR_WIDTH-1:0]    o_s_axi_awaddr,   // Slave Write Address
    output [NUM_SLAVES-1:0]                    o_s_axi_awvalid,  // Slave Write Address Valid
    input  [NUM_SLAVES-1:0]                    i_s_axi_awready,  // Slave Write Address Ready
    output [NUM_SLAVES-1:0][2:0]               o_s_axi_awprot,   // Slave Write Protection
    output [NUM_SLAVES-1:0][DATA_WIDTH-1:0]    o_s_axi_wdata,    // Slave Write Data
    output [NUM_SLAVES-1:0][DATA_WIDTH/8-1:0]  o_s_axi_wstrb,    // Slave Write Strobe
    output [NUM_SLAVES-1:0]                    o_s_axi_wvalid,   // Slave Write Data Valid
    input  [NUM_SLAVES-1:0]                    i_s_axi_wready,   // Slave Write Data Ready
    input  [NUM_SLAVES-1:0]                    i_s_axi_bvalid,   // Slave Write Response Valid
    output [NUM_SLAVES-1:0]                    o_s_axi_bready,   // Slave Write Response Ready
    output                 [ADDR_WIDTH-1:0]    o_s_axi_araddr,   // Slave Read Address
    output [NUM_SLAVES-1:0]                    o_s_axi_arvalid,  // Slave Read Address Valid
    input  [NUM_SLAVES-1:0]                    i_s_axi_arready,  // Slave Read Address Ready
    output [NUM_SLAVES-1:0][2:0]               o_s_axi_arprot,   // Slave Read Protection
    input  [NUM_SLAVES-1:0][DATA_WIDTH-1:0]    i_s_axi_rdata,    // Slave Read Data
    input  [NUM_SLAVES-1:0]                    i_s_axi_rvalid,   // Slave Read Data Valid
    output [NUM_SLAVES-1:0]                    o_s_axi_rready    // Slave Read Data Ready
);

    // Internal signals for slave selection and arbiter outputs
    wire [NUM_SLAVES-1:0]   slave_select_write; // Slave selected for write channel
    wire [NUM_SLAVES-1:0]   slave_select_read;  // Slave selected for read channel
    
    wire [ADDR_WIDTH-1:0]   selected_awaddr;    // Selected write address from arbiter
    wire [ADDR_WIDTH-1:0]   selected_araddr;    // Selected read address from arbiter

    wire [2:0]              selected_awprot;    // Selected write protection
    wire [2:0]              selected_arprot;    // Selected read protection
    wire                    selected_awvalid;   // Selected write address valid
    wire                    selected_wvalid;    // Selected write data valid
    wire [DATA_WIDTH-1:0]   selected_wdata;     // Selected write data
    wire [DATA_WIDTH/8-1:0] selected_wstrb;   // Selected write strobe
    wire                    selected_bready;    // Selected write response ready
    wire                    selected_arvalid;   // Selected read address valid
    wire                    selected_rready;    // Selected read data ready
    wire                    arbiter_awready;    // Write address ready from mux to arbiter
    wire                    arbiter_wready;     // Write data ready from mux to arbiter
    wire                    arbiter_bvalid;     // Write response valid from mux to arbiter
    wire                    arbiter_arready;    // Read address ready from mux to arbiter
    wire                    arbiter_rvalid;     // Read data valid from mux to arbiter
    wire [DATA_WIDTH-1:0]   arbiter_rdata;      // Read data from mux to arbiter

    // Arbiter: Select one master at a time using Round-Robin
    axi_lite_arbiter #(
        .NUM_MASTERS(NUM_MASTERS),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) arbiter (
        // Clock and reset
        .clk(clk),
        .resetn(resetn),
        // Master interfaces (connect directly to interconnect inputs/outputs)
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
        // Slave interfaces (connect to internal signals for decoder and mux)
        .o_s_axi_awvalid(selected_awvalid),
        .i_s_axi_awready(arbiter_awready),
        .o_s_axi_awaddr(selected_awaddr),
        .o_s_axi_awprot(selected_awprot), 
        .o_s_axi_wvalid(selected_wvalid),
        .i_s_axi_wready(arbiter_wready),
        .o_s_axi_wdata(selected_wdata),
        .o_s_axi_wstrb(selected_wstrb),
        .i_s_axi_bvalid(arbiter_bvalid),
        .o_s_axi_bready(selected_bready),
        .o_s_axi_arvalid(selected_arvalid),
        .i_s_axi_arready(arbiter_arready),
        .o_s_axi_araddr(selected_araddr),
        .o_s_axi_arprot(selected_arprot),
        .i_s_axi_rvalid(arbiter_rvalid),
        .o_s_axi_rready(selected_rready),
        .i_s_axi_rdata(arbiter_rdata)
    );

    // Decoder: Select slave based on address from arbiter
    axi_lite_decoder #(
        .NUM_SLAVES(NUM_SLAVES),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) decoder (
        .resetn(resetn),
        // Use addresses from arbiter (selected by granted master)
        .i_axi_awaddr(selected_awaddr),
        .i_axi_araddr(selected_araddr),
        // Output slave selection signals
        .o_slave_select_write(slave_select_write),
        .o_slave_select_read(slave_select_read)
    );

    // Multiplexer: Route signals between selected master and selected slave
    axi_lite_mux #(
        .NUM_SLAVES(NUM_SLAVES),
        .DATA_WIDTH(DATA_WIDTH)
    ) mux (
        // Inputs from arbiter (selected master signals)
        .i_m_axi_awvalid(selected_awvalid),
        .o_m_axi_awready(arbiter_awready),
        .i_m_axi_wvalid(selected_wvalid),
        .o_m_axi_wready(arbiter_wready),
        .i_m_axi_wdata(selected_wdata),
        .i_m_axi_wstrb(selected_wstrb),
        .o_m_axi_bvalid(arbiter_bvalid),
        .i_m_axi_bready(selected_bready),
        .i_m_axi_arvalid(selected_arvalid),
        .o_m_axi_arready(arbiter_arready),
        .o_m_axi_rvalid(arbiter_rvalid),
        .i_m_axi_rready(selected_rready),
        .o_m_axi_rdata(arbiter_rdata),
        // Slave selection from decoder
        .i_slave_select_write(slave_select_write),
        .i_slave_select_read(slave_select_read),
        // Slave interfaces (connect to interconnect outputs/inputs)
        .o_s_axi_awvalid(o_s_axi_awvalid),
        .i_s_axi_awready(i_s_axi_awready),
        .o_s_axi_wvalid(o_s_axi_wvalid),
        .i_s_axi_wready(i_s_axi_wready),
        .o_s_axi_wdata(o_s_axi_wdata),
        .o_s_axi_wstrb(o_s_axi_wstrb),
        .i_s_axi_bvalid(i_s_axi_bvalid),
        .o_s_axi_bready(o_s_axi_bready),
        .o_s_axi_arvalid(o_s_axi_arvalid),
        .i_s_axi_arready(i_s_axi_arready),
        .i_s_axi_rvalid(i_s_axi_rvalid),
        .o_s_axi_rready(o_s_axi_rready),
        .i_s_axi_rdata(i_s_axi_rdata)
    );

    // Address and Protection signal routing to slaves
    genvar i;
    generate
        for (i = 0; i < NUM_SLAVES; i = i + 1) begin : slave_routing
            // Route protection signals to selected slave only
            assign o_s_axi_awprot[i] = (slave_select_write[i]) ? selected_awprot : 0;
            assign o_s_axi_arprot[i] = (slave_select_read[i]) ? selected_arprot : 0;
        end
    endgenerate

    // Route selected addresses to all slaves
    assign o_s_axi_awaddr = selected_awaddr;
    assign o_s_axi_araddr = selected_araddr;



endmodule

/***************************************************************
 * AXI4-Lite Round-Robin Arbiter
 ***************************************************************/
module axi_lite_arbiter #(
    parameter NUM_MASTERS = 3,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input                           clk,
    input                           resetn,
    // Master inputs
    input       [NUM_MASTERS-1:0]                    i_m_axi_awvalid,    // Master Write Address Valid
    output      [NUM_MASTERS-1:0]                    o_m_axi_awready,    // Master Write Address Ready
    input       [NUM_MASTERS-1:0][ADDR_WIDTH-1:0]    i_m_axi_awaddr,     // Master Write Address

    input       [NUM_MASTERS-1:0][2:0]               i_m_axi_awprot,     // Master Write Protection
    input       [NUM_MASTERS-1:0]                    i_m_axi_wvalid,     // Master Write Data Valid
    output      [NUM_MASTERS-1:0]                    o_m_axi_wready,     // Master Write Data Ready
    input       [NUM_MASTERS-1:0][DATA_WIDTH-1:0]    i_m_axi_wdata,      // Master Write Data
    input       [NUM_MASTERS-1:0][DATA_WIDTH/8-1:0]  i_m_axi_wstrb,      // Master Write Strobe

    output      [NUM_MASTERS-1:0]                    o_m_axi_bvalid,     // Master Write Response Valid
    input       [NUM_MASTERS-1:0]                    i_m_axi_bready,     // Master Write Response Ready

    input       [NUM_MASTERS-1:0]                    i_m_axi_arvalid,    // Master Read Address Valid
    output      [NUM_MASTERS-1:0]                    o_m_axi_arready,    // Master Read Address Ready
    input       [NUM_MASTERS-1:0][ADDR_WIDTH-1:0]    i_m_axi_araddr,     // Master Read Address
    input       [NUM_MASTERS-1:0][2:0]               i_m_axi_arprot,     // Master Read Protection
    output      [NUM_MASTERS-1:0]                    o_m_axi_rvalid,     // Master Read Data Valid
    input       [NUM_MASTERS-1:0]                    i_m_axi_rready,     // Master Read Data Ready
    output      [NUM_MASTERS-1:0][DATA_WIDTH-1:0]    o_m_axi_rdata,      // Master Read Data

    // Arbiter outputs
    output                                           o_s_axi_awvalid,    // Slave Write Address Valid
    input                                            i_s_axi_awready,    // Slave Write Address Ready
    output                       [ADDR_WIDTH-1:0]    o_s_axi_awaddr,     // Slave Write Address

    output                       [2:0]               o_s_axi_awprot,     // Slave Write Protection
    output                                           o_s_axi_wvalid,     // Slave Write Data Valid
    input                                            i_s_axi_wready,     // Slave Write Data Ready
    output                       [DATA_WIDTH-1:0]    o_s_axi_wdata,      // Slave Write Data
    output                       [DATA_WIDTH/8-1:0]  o_s_axi_wstrb,      // Slave Write Strobe

    input                                            i_s_axi_bvalid,     // Slave Write Response Valid
    output                                           o_s_axi_bready,     // Slave Write Response Ready

    output                                           o_s_axi_arvalid,    // Slave Read Address Valid
    input                                            i_s_axi_arready,    // Slave Read Address Ready
    output                       [ADDR_WIDTH-1:0]    o_s_axi_araddr,     // Slave Read Address
    output                       [2:0]               o_s_axi_arprot,     // Slave Read Protection
    input                                            i_s_axi_rvalid,     // Slave Read Data Valid
    output                                           o_s_axi_rready,     // Slave Read Data Ready
    input                        [DATA_WIDTH-1:0]    i_s_axi_rdata       // Slave Read Data
);
 

    // Write Channel States
    localparam  W_START   =   'd0,
                W_S1_0    =   'd1,
                W_S2_1    =   'd2,
                W_S3_0    =   'd3,
                W_S3_1    =   'd4,
                W_S4_2    =   'd5,
                W_S5_0    =   'd6,
                W_S5_2    =   'd7,
                W_S6_1    =   'd8,
                W_S6_2    =   'd9,
                W_S7_0    =   'd10,
                W_S7_1    =   'd11,
                W_S7_2    =   'd12;

    // Read Channel States
    localparam  R_START   =   'd0,
                R_S1_0    =   'd1,
                R_S2_1    =   'd2,
                R_S3_0    =   'd3,
                R_S3_1    =   'd4,
                R_S4_2    =   'd5,
                R_S5_0    =   'd6,
                R_S5_2    =   'd7,
                R_S6_1    =   'd8,
                R_S6_2    =   'd9,
                R_S7_0    =   'd10,
                R_S7_1    =   'd11,
                R_S7_2    =   'd12;
        
    // Write Channel Variables
    reg     [3:0]               w_state_reg, w_state_next;
    reg                         w_active_capture_reg, w_active_capture_next;

    reg     [ADDR_WIDTH-1:0]    w_select_s_axi_awaddr_reg, w_select_s_axi_awaddr_next;
    reg                         w_select_s_axi_awvalid_reg, w_select_s_axi_awvalid_next;
    reg     [NUM_MASTERS-1:0]   w_select_m_axi_awready_reg, w_select_m_axi_awready_next;

    reg     [2:0]               w_select_s_axi_awprot_reg, w_select_s_axi_awprot_next;
    reg                         w_select_s_axi_wvalid_reg, w_select_s_axi_wvalid_next;
    reg     [NUM_MASTERS-1:0]   w_select_m_axi_wready_reg, w_select_m_axi_wready_next;
    reg     [DATA_WIDTH-1:0]    w_select_s_axi_wdata_reg, w_select_s_axi_wdata_next;
    reg     [DATA_WIDTH/8-1:0]  w_select_s_axi_wstrb_reg, w_select_s_axi_wstrb_next;

    reg                         w_select_s_axi_bready_reg, w_select_s_axi_bready_next;
    reg     [NUM_MASTERS-1:0]   w_select_m_axi_bvalid_reg, w_select_m_axi_bvalid_next;

    // Read Channel Variables
    reg     [3:0]               r_state_reg, r_state_next;
    reg                         r_active_capture_reg, r_active_capture_next;

    reg     [ADDR_WIDTH-1:0]    r_select_s_axi_araddr_reg, r_select_s_axi_araddr_next;
    reg                         r_select_s_axi_arvalid_reg, r_select_s_axi_arvalid_next;
    reg     [NUM_MASTERS-1:0]   r_select_m_axi_arready_reg, r_select_m_axi_arready_next;

    reg     [2:0]               r_select_s_axi_arprot_reg, r_select_s_axi_arprot_next;
    reg                         r_select_s_axi_rready_reg, r_select_s_axi_rready_next;
    reg     [NUM_MASTERS-1:0]   r_select_m_axi_rvalid_reg, r_select_m_axi_rvalid_next;
    reg     [DATA_WIDTH-1:0]    r_select_m_axi_rdata0_reg, r_select_m_axi_rdata0_next;
    reg     [DATA_WIDTH-1:0]    r_select_m_axi_rdata1_reg, r_select_m_axi_rdata1_next;
    reg     [DATA_WIDTH-1:0]    r_select_m_axi_rdata2_reg, r_select_m_axi_rdata2_next;


    wire                        w_enb_awvalid, w_enb_wvalid, w_enb_bready, w_enb_quantum_time;
    wire                        r_enb_arvalid, r_enb_rready, r_enb_quantum_time;

    //wirte channel sequential circuit
    always @(posedge clk or negedge resetn) begin
        if (~resetn) begin
            w_state_reg                   <= W_START;
            w_active_capture_reg          <= 0;

            w_select_s_axi_awaddr_reg     <= 0;
            w_select_s_axi_awvalid_reg    <= 0;
            w_select_m_axi_awready_reg    <= 0;
            w_select_s_axi_awprot_reg     <= 0;
            w_select_s_axi_wvalid_reg     <= 0;
            w_select_m_axi_wready_reg     <= 0;
            w_select_s_axi_wdata_reg      <= 0;
            w_select_s_axi_wstrb_reg      <= 0;
            w_select_s_axi_bready_reg     <= 0;
            w_select_m_axi_bvalid_reg     <= 0;

        end
        else begin
            w_state_reg                   <= w_state_next;
            w_active_capture_reg          <= w_active_capture_next;

            w_select_s_axi_awaddr_reg     <= w_select_s_axi_awaddr_next;
            w_select_s_axi_awvalid_reg    <= w_select_s_axi_awvalid_next;
            w_select_m_axi_awready_reg    <= w_select_m_axi_awready_next;
            w_select_s_axi_awprot_reg     <= w_select_s_axi_awprot_next;
            w_select_s_axi_wvalid_reg     <= w_select_s_axi_wvalid_next;
            w_select_m_axi_wready_reg     <= w_select_m_axi_wready_next;
            w_select_s_axi_wdata_reg      <= w_select_s_axi_wdata_next;
            w_select_s_axi_wstrb_reg      <= w_select_s_axi_wstrb_next;
            w_select_s_axi_bready_reg     <= w_select_s_axi_bready_next;
            w_select_m_axi_bvalid_reg     <= w_select_m_axi_bvalid_next;

        end
        
    end


    //wirte channel combi circuit
    always @(*) begin
        w_active_capture_next         = w_active_capture_reg;
        w_state_next                  = w_state_reg;
        w_select_s_axi_awaddr_next    = w_select_s_axi_awaddr_reg;
        w_select_s_axi_awvalid_next   = w_select_s_axi_awvalid_reg;
        w_select_m_axi_awready_next   = w_select_m_axi_awready_reg;
        w_select_s_axi_awprot_next    = w_select_s_axi_awprot_reg;
        w_select_s_axi_wvalid_next    = w_select_s_axi_wvalid_reg;
        w_select_m_axi_wready_next    = w_select_m_axi_wready_reg;
        w_select_s_axi_wdata_next     = w_select_s_axi_wdata_reg;
        w_select_s_axi_wstrb_next     = w_select_s_axi_wstrb_reg;
        w_select_s_axi_bready_next    = w_select_s_axi_bready_reg;
        w_select_m_axi_bvalid_next    = w_select_m_axi_bvalid_reg;

        case (w_state_reg)
            W_START: begin
                w_select_s_axi_awaddr_next    = 0;
                w_select_s_axi_awvalid_next   = 0;
                w_select_m_axi_awready_next   = 0;
                w_select_s_axi_awprot_next    = 0;
                w_select_s_axi_wvalid_next    = 0;
                w_select_m_axi_wready_next    = 0;
                w_select_s_axi_wdata_next     = 0;
                w_select_s_axi_wstrb_next     = 0;
                w_select_s_axi_bready_next    = 0;
                w_select_m_axi_bvalid_next    = 0;



                if (|i_m_axi_awvalid == 1) begin
                    w_active_capture_next = 1;
                    case (i_m_axi_awvalid)
                        'b001: begin
                            w_state_next = W_S1_0;
                        end 
                        'b010: begin
                            w_state_next = W_S2_1;
                        end 
                        'b011: begin
                            w_state_next = W_S3_0;
                        end 
                        'b100: begin
                            w_state_next = W_S4_2;
                        end 
                        'b101: begin
                            w_state_next = W_S5_0;
                        end 
                        'b110: begin
                            w_state_next = W_S6_1;
                        end 
                        'b111: begin
                            w_state_next = W_S7_0;
                        end
                        default: begin
                            w_state_next = W_START;
                        end 
                    endcase
                end  
            end 
            W_S1_0, W_S3_0, W_S5_0, W_S7_0: begin
                w_active_capture_next         = 0;
                w_select_s_axi_awaddr_next    = i_m_axi_awaddr[0];
                w_select_s_axi_awvalid_next   = i_m_axi_awvalid[0];
                w_select_m_axi_awready_next   = {1'b0, 1'b0, i_s_axi_awready};

                w_select_s_axi_awprot_next    = i_m_axi_awprot[0];
                w_select_s_axi_wvalid_next    = i_m_axi_wvalid[0];
                w_select_m_axi_wready_next    = {1'b0, 1'b0, i_s_axi_wready};
                w_select_s_axi_wdata_next     = i_m_axi_wdata[0];
                w_select_s_axi_wstrb_next     = i_m_axi_wstrb[0];

                w_select_m_axi_bvalid_next    = {1'b0, 1'b0, i_s_axi_bvalid};
                w_select_s_axi_bready_next    = i_m_axi_bready[0];

                case (w_state_reg)
                    W_S1_0: begin
                        if (((w_select_m_axi_bvalid_reg[0] == 1) && (i_m_axi_bready[0] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_START;
                    end
                    W_S3_0: begin
                        if (((w_select_m_axi_bvalid_reg[0] == 1) && (i_m_axi_bready[0] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_S3_1;
                    end
                    W_S5_0: begin
                        if (((w_select_m_axi_bvalid_reg[0] == 1) && (i_m_axi_bready[0] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_S5_2;
                    end
                    W_S7_0: begin
                        if (((w_select_m_axi_bvalid_reg[0] == 1) && (i_m_axi_bready[0] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_S7_1;
                    end 
                    default: begin
                    end
                endcase
            end
            W_S2_1, W_S3_1, W_S6_1, W_S7_1: begin
                w_active_capture_next        = 0;
                w_select_s_axi_awaddr_next    = i_m_axi_awaddr[1];
                w_select_s_axi_awvalid_next   = i_m_axi_awvalid[1];
                w_select_m_axi_awready_next   = {1'b0, i_s_axi_awready, 1'b0}
                ;
                w_select_s_axi_awprot_next    = i_m_axi_awprot[1];
                w_select_s_axi_wvalid_next    = i_m_axi_wvalid[1];
                w_select_m_axi_wready_next    = {1'b0, i_s_axi_wready, 1'b0};
                w_select_s_axi_wdata_next     = i_m_axi_wdata[1];
                w_select_s_axi_wstrb_next     = i_m_axi_wstrb[1];

                w_select_m_axi_bvalid_next    = {1'b0, i_s_axi_bvalid, 1'b0};
                w_select_s_axi_bready_next    = i_m_axi_bready[1];

                case (w_state_reg)
                    W_S2_1: begin
                        if (((w_select_m_axi_bvalid_reg[1] == 1) && (i_m_axi_bready[1] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_START;
                    end
                    W_S3_1: begin
                        if (((w_select_m_axi_bvalid_reg[1] == 1) && (i_m_axi_bready[1] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_START;
                    end
                    W_S6_1: begin
                        if (((w_select_m_axi_bvalid_reg[1] == 1) && (i_m_axi_bready[1] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_S6_2;
                    end
                    W_S7_1: begin
                        if (((w_select_m_axi_bvalid_reg[1] == 1) && (i_m_axi_bready[1] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_S7_2;
                    end 
                    default: begin
                    end
                endcase
            end
            W_S4_2, W_S5_2, W_S6_2, W_S7_2: begin
                w_active_capture_next        = 0;
                w_select_s_axi_awaddr_next    = i_m_axi_awaddr[2];
                w_select_s_axi_awvalid_next   = i_m_axi_awvalid[2];
                w_select_m_axi_awready_next   = {i_s_axi_awready, 1'b0, 1'b0};

                w_select_s_axi_awprot_next    = i_m_axi_awprot[2];
                w_select_s_axi_wvalid_next    = i_m_axi_wvalid[2];
                w_select_m_axi_wready_next    = {i_s_axi_wready, 1'b0, 1'b0};
                w_select_s_axi_wdata_next     = i_m_axi_wdata[2];
                w_select_s_axi_wstrb_next     = i_m_axi_wstrb[2];
                
                w_select_m_axi_bvalid_next    = {i_s_axi_bvalid, 1'b0, 1'b0};
                w_select_s_axi_bready_next    = i_m_axi_bready[2];

                case (w_state_reg)
                    W_S4_2: begin
                        if (((w_select_m_axi_bvalid_reg[2] == 1) && (i_m_axi_bready[2] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_START;
                    end
                    W_S5_2: begin
                        if (((w_select_m_axi_bvalid_reg[2] == 1) && (i_m_axi_bready[2] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_START;
                    end
                    W_S6_2: begin
                        if (((w_select_m_axi_bvalid_reg[2] == 1) && (i_m_axi_bready[2] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_START;
                    end
                    W_S7_2: begin
                        if (((w_select_m_axi_bvalid_reg[2] == 1) && (i_m_axi_bready[2] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_START;
                    end 
                    default: begin
                    end
                endcase
            end
            default: begin
                w_state_next = W_START;
            end
        endcase
    end

    // Read Channel Sequential Circuit
    always @(posedge clk or negedge resetn) begin
        if (~resetn) begin
            r_state_reg                   <= R_START;
            r_active_capture_reg          <= 0;
            r_select_s_axi_araddr_reg     <= 0;
            r_select_s_axi_arvalid_reg    <= 0;
            r_select_m_axi_arready_reg    <= 0;
            r_select_s_axi_arprot_reg     <= 0;
            r_select_s_axi_rready_reg     <= 0;
            r_select_m_axi_rvalid_reg     <= 0;

            r_select_m_axi_rdata0_reg     <= 0;
            r_select_m_axi_rdata1_reg     <= 0;
            r_select_m_axi_rdata2_reg     <= 0;
        end
        else begin
            r_state_reg                   <= r_state_next;
            r_active_capture_reg          <= r_active_capture_next;
            r_select_s_axi_araddr_reg     <= r_select_s_axi_araddr_next;
            r_select_s_axi_arvalid_reg    <= r_select_s_axi_arvalid_next;
            r_select_m_axi_arready_reg    <= r_select_m_axi_arready_next;
            r_select_s_axi_arprot_reg     <= r_select_s_axi_arprot_next;
            r_select_s_axi_rready_reg     <= r_select_s_axi_rready_next;
            r_select_m_axi_rvalid_reg     <= r_select_m_axi_rvalid_next;

            r_select_m_axi_rdata0_reg     <= r_select_m_axi_rdata0_next;
            r_select_m_axi_rdata1_reg     <= r_select_m_axi_rdata1_next;
            r_select_m_axi_rdata2_reg     <= r_select_m_axi_rdata2_next;
        end
    end

    
    // Read Channel Combinational Circuit
    always @(*) begin
        r_active_capture_next         = r_active_capture_reg;
        r_state_next                  = r_state_reg;
        r_select_s_axi_araddr_next    = r_select_s_axi_araddr_reg;
        r_select_s_axi_arvalid_next   = r_select_s_axi_arvalid_reg;
        r_select_m_axi_arready_next   = r_select_m_axi_arready_reg;
        r_select_s_axi_arprot_next    = r_select_s_axi_arprot_reg;
        r_select_s_axi_rready_next    = r_select_s_axi_rready_reg;
        r_select_m_axi_rvalid_next    = r_select_m_axi_rvalid_reg;
        
        r_select_m_axi_rdata0_next     = r_select_m_axi_rdata0_reg;
        r_select_m_axi_rdata1_next     = r_select_m_axi_rdata1_reg;
        r_select_m_axi_rdata2_next     = r_select_m_axi_rdata2_reg;

        case (r_state_reg)
            R_START: begin
                r_select_s_axi_araddr_next    = 0;
                r_select_s_axi_arvalid_next   = 0;
                r_select_m_axi_arready_next   = 0;
                r_select_s_axi_arprot_next    = 0;
                r_select_s_axi_rready_next    = 0;
                r_select_m_axi_rvalid_next    = 0;
                
                r_select_m_axi_rdata0_next     = 0;
                r_select_m_axi_rdata1_next     = 0;
                r_select_m_axi_rdata2_next     = 0;

                if (|i_m_axi_arvalid == 1) begin
                    r_active_capture_next = 1;
                    case (i_m_axi_arvalid)
                        'b001: begin
                            r_state_next = R_S1_0;
                        end 
                        'b010: begin
                            r_state_next = R_S2_1;
                        end 
                        'b011: begin
                            r_state_next = R_S3_0;
                        end 
                        'b100: begin
                            r_state_next = R_S4_2;
                        end 
                        'b101: begin
                            r_state_next = R_S5_0;
        
                        end 
                        'b110: begin
                            r_state_next = R_S6_1;
                        end 
                        'b111: begin
                            r_state_next = R_S7_0;
                        end
                        default: begin
                            r_state_next = R_START;
                        end 
                    endcase
                end  
            end 
            R_S1_0, R_S3_0, R_S5_0, R_S7_0: begin
                r_active_capture_next         = 0;
                r_select_s_axi_araddr_next    = i_m_axi_araddr[0];
                r_select_s_axi_arvalid_next   = i_m_axi_arvalid[0];
                r_select_m_axi_arready_next   = {1'b0, 1'b0, i_s_axi_arready};

                r_select_s_axi_arprot_next    = i_m_axi_arprot[0];
                r_select_s_axi_rready_next    = i_m_axi_rready[0];
                r_select_m_axi_rvalid_next    = {1'b0, 1'b0, i_s_axi_rvalid};
                r_select_m_axi_rdata0_next    = i_s_axi_rdata;
                r_select_m_axi_rdata1_next    = 0;
                r_select_m_axi_rdata2_next    = 0;

                case (r_state_reg)
                    R_S1_0: begin
                        if (((r_select_m_axi_rvalid_reg[0] == 1) && (i_m_axi_rready[0] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_START;
                    end
                    R_S3_0: begin
                        if (((r_select_m_axi_rvalid_reg[0] == 1) && (i_m_axi_rready[0] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_S3_1;
                    end
                    R_S5_0: begin
                        if (((r_select_m_axi_rvalid_reg[0] == 1) && (i_m_axi_rready[0] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_S5_2;
                    end
                    R_S7_0: begin
                        if (((r_select_m_axi_rvalid_reg[0] == 1) && (i_m_axi_rready[0] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_S7_1;
                    end 
                    default: begin
                    end
                endcase
            end
            R_S2_1, R_S3_1, R_S6_1, R_S7_1: begin
                r_active_capture_next         = 0;
                r_select_s_axi_araddr_next    = i_m_axi_araddr[1];
                r_select_s_axi_arvalid_next   = i_m_axi_arvalid[1];
                r_select_m_axi_arready_next   = {1'b0, i_s_axi_arready, 1'b0};

                r_select_s_axi_arprot_next    = i_m_axi_arprot[1];
                r_select_s_axi_rready_next    = i_m_axi_rready[1];
                r_select_m_axi_rvalid_next    = {1'b0, i_s_axi_rvalid, 1'b0};
                r_select_m_axi_rdata0_next  = 0;
                r_select_m_axi_rdata1_next  = i_s_axi_rdata;
                r_select_m_axi_rdata2_next  = 0;

                case (r_state_reg)
                    R_S2_1: begin
                        if (((r_select_m_axi_rvalid_reg[1] == 1) && (i_m_axi_rready[1] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_START;
                    end
                    R_S3_1: begin
                        if (((r_select_m_axi_rvalid_reg[1] == 1) && (i_m_axi_rready[1] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_START;
                    end
                    R_S6_1: begin
                        if (((r_select_m_axi_rvalid_reg[1] == 1) && (i_m_axi_rready[1] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_S6_2;
                    end
                    R_S7_1: begin
                        if (((r_select_m_axi_rvalid_reg[1] == 1) && (i_m_axi_rready[1] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_S7_2;
                    end 
                    default: begin
                    end
                endcase
            end
            R_S4_2, R_S5_2, R_S6_2, R_S7_2: begin
                r_active_capture_next         = 0;
                r_select_s_axi_araddr_next    = i_m_axi_araddr[2];
                r_select_s_axi_arvalid_next   = i_m_axi_arvalid[2];
                r_select_m_axi_arready_next   = {i_s_axi_arready, 1'b0, 1'b0};

                r_select_s_axi_arprot_next    = i_m_axi_arprot[2];
                r_select_s_axi_rready_next    = i_m_axi_rready[2];
                r_select_m_axi_rvalid_next    = {i_s_axi_rvalid, 1'b0, 1'b0};
                r_select_m_axi_rdata0_next  = 0;
                r_select_m_axi_rdata1_next  = 0;
                r_select_m_axi_rdata2_next  = i_s_axi_rdata;

                case (r_state_reg)
                    R_S4_2: begin
                        if (((r_select_m_axi_rvalid_reg[2] == 1) && (i_m_axi_rready[2] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_START;
                    end
                    R_S5_2: begin
                        if (((r_select_m_axi_rvalid_reg[2] == 1) && (i_m_axi_rready[2] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_START;
                    end
                    R_S6_2: begin
                        if (((r_select_m_axi_rvalid_reg[2] == 1) && (i_m_axi_rready[2] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_START;
                    end
                    R_S7_2: begin
                        if (((r_select_m_axi_rvalid_reg[2] == 1) && (i_m_axi_rready[2] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_START;
                    end 
                    default: begin
                    end
                endcase
            end
            default: begin
                r_state_next = R_START;
            end
        endcase
    end



   // Write Channel Assignments
    assign o_s_axi_awaddr       = w_select_s_axi_awaddr_reg;
    assign o_s_axi_awvalid      = (w_enb_awvalid) ? 0 : w_select_s_axi_awvalid_reg;
    assign o_m_axi_awready      = w_select_m_axi_awready_reg;

    assign o_s_axi_awprot       = w_select_s_axi_awprot_reg;
    assign o_s_axi_wvalid       = (w_enb_wvalid) ? 0 : w_select_s_axi_wvalid_reg;
    assign o_m_axi_wready       = w_select_m_axi_wready_reg;
    assign o_s_axi_wdata        = w_select_s_axi_wdata_reg;
    assign o_s_axi_wstrb        = w_select_s_axi_wstrb_reg;

    assign o_m_axi_bvalid       = w_select_m_axi_bvalid_reg;
    assign o_s_axi_bready       = (w_enb_bready) ? 0 : w_select_s_axi_bready_reg;

    // Read Channel Assignments
    assign o_s_axi_araddr       = r_select_s_axi_araddr_reg;
    assign o_s_axi_arvalid      = (r_enb_arvalid) ? 0 : r_select_s_axi_arvalid_reg;
    assign o_m_axi_arready      = r_select_m_axi_arready_reg;

    assign o_s_axi_arprot       = r_select_s_axi_arprot_reg;
    assign o_s_axi_rready       = (r_enb_rready) ? 0 : r_select_s_axi_rready_reg;
    assign o_m_axi_rvalid       = r_select_m_axi_rvalid_reg;
    assign o_m_axi_rdata[0]        = r_select_m_axi_rdata0_reg;
    assign o_m_axi_rdata[1]        = r_select_m_axi_rdata1_reg;
    assign o_m_axi_rdata[2]        = r_select_m_axi_rdata2_reg;


    // Write Channel Timer
    timer_write_channel timer_write (
        .clk(clk),
        .resetn(resetn & (!w_active_capture_reg)),

        .s_awready(i_s_axi_awready),
        .s_wready(i_s_axi_wready),
        .s_bvalid(i_s_axi_bvalid),
        .s_start_quantum(o_s_axi_awvalid),

        .enb_awvalid(w_enb_awvalid),
        .enb_wvalid(w_enb_wvalid),
        .enb_bready(w_enb_bready),
        .enb_quantum_time(w_enb_quantum_time)
    );

    // Read Channel Timer
    timer_read_channel timer_read (
        .clk(clk),
        .resetn(resetn & (!r_active_capture_reg)),

        .s_arready(i_s_axi_arready),
        .s_rvalid(i_s_axi_rvalid),
        .s_start_quantum(o_s_axi_arvalid),

        .enb_arvalid(r_enb_arvalid),
        .enb_rready(r_enb_rready),
        .enb_quantum_time(r_enb_quantum_time)
    );

endmodule

// module child
module timer_write_channel(
    input clk,
    input resetn,

    input s_awready,
    input s_wready,
    input s_bvalid,
    input s_start_quantum,

    output enb_awvalid,
    output enb_wvalid,
    output enb_bready,
    output enb_quantum_time
);


    localparam IDLE = 'b00,
               START = 'b01;

    localparam QUANTUM_SIZE = 14; // clock

    reg [1:0] state_quantum_reg, state_quantum_next;

    reg [2:0]count0_reg, count0_next;
    reg [2:0]count1_reg, count1_next;
    reg [2:0]count2_reg, count2_next;
    reg [3:0]count_quantum_reg, count_quantum_next;

    reg flag_awvalid_reg, flag_awvalid_next;
    reg flag_wvalid_reg, flag_wvalid_next;
    reg flag_bready_reg, flag_bready_next;

    reg enb_awvalid_reg, enb_awvalid_next;
    reg enb_wvalid_reg, enb_wvalid_next;
    reg enb_bready_reg, enb_bready_next;
    reg enb_quantum_time_reg, enb_quantum_time_next;

    always @(posedge clk, negedge resetn) begin
        if(~resetn) begin
            state_quantum_reg <= IDLE;
            count0_reg <= 0;
            count1_reg <= 0;
            count2_reg <= 0;
            count_quantum_reg <= 0;
            
            flag_awvalid_reg <= 0;
            flag_wvalid_reg <= 0;
            flag_bready_reg <= 0;

            enb_awvalid_reg <= 0;
            enb_wvalid_reg  <= 0;
            enb_bready_reg  <= 0;
            enb_quantum_time_reg <= 0;
        end
        else begin
            state_quantum_reg <= state_quantum_next;

            count0_reg <= count0_next;
            count1_reg <= count1_next;
            count2_reg <= count2_next;
            count_quantum_reg <= count_quantum_next;

            flag_awvalid_reg <= flag_awvalid_next;
            flag_wvalid_reg <= flag_wvalid_next;
            flag_bready_reg <= flag_bready_next;

            enb_awvalid_reg <= enb_awvalid_next;
            enb_wvalid_reg  <= enb_wvalid_next;
            enb_bready_reg  <= enb_bready_next;
            enb_quantum_time_reg <= enb_quantum_time_next;
        end
        
    end

    always @(*) begin
        state_quantum_next = state_quantum_reg;
        count0_next = count0_reg;
        count1_next = count1_reg;
        count2_next = count2_reg;
        count_quantum_next = count_quantum_reg;

        flag_awvalid_next = flag_awvalid_reg;
        flag_wvalid_next = flag_wvalid_reg;
        flag_bready_next = flag_bready_reg;

        enb_awvalid_next = enb_awvalid_reg;
        enb_wvalid_next  = enb_wvalid_reg;
        enb_bready_next  = enb_bready_reg;
        enb_quantum_time_next = enb_quantum_time_reg;

        // branch signal transaction
        case ({s_bvalid, s_wready, s_awready})
            'b001: begin: signal_awready
                flag_awvalid_next = 1;
            end
            'b010: begin: signal_wready
                flag_wvalid_next = 1;
            end
            'b100: begin: signal_bvalid
                flag_bready_next = 1;
            end
            default: begin
            end
        endcase

        if (flag_awvalid_next == 1) begin
            count0_next = count0_next + 1;
            enb_awvalid_next = 1;
            if (count0_reg > 1) begin
                flag_awvalid_next = 0;
                count0_next = 0;
                enb_awvalid_next = 0;
            end
        end
        if (flag_wvalid_next == 1) begin
            count1_next = count1_next + 1;
            enb_wvalid_next = 1;
            if (count1_reg > 1) begin
                flag_wvalid_next = 0;
                count1_next = 0;
                enb_wvalid_next = 0;
            end
        end
        if (flag_bready_next == 1) begin
            count2_next = count2_next + 1;
            enb_bready_next = 1;
            if (count2_reg > 1) begin
                flag_bready_next = 0;
                count2_next = 0;
                enb_bready_next = 0;
            end
        end

        //time quantum process
        case (state_quantum_reg)
            IDLE: begin
                enb_quantum_time_next = 0;
                if (s_start_quantum == 1  && enb_quantum_time_reg == 0) begin
                    state_quantum_next = START;
                    count_quantum_next = 0; //count_quantum_next + 1;
                end
            end
            START: begin
                count_quantum_next = count_quantum_next + 1;
                if ((count_quantum_reg > QUANTUM_SIZE)) begin
                    count_quantum_next = 0;
                    enb_quantum_time_next = 1;
                    state_quantum_next = IDLE;
                end
                if (enb_bready_reg) begin
                    count_quantum_next = 0;
                    enb_quantum_time_next = 0;
                    state_quantum_next = IDLE;
                end      
            end 
            default: state_quantum_next = IDLE;
        endcase
        

    end

    assign enb_awvalid = enb_awvalid_reg;
    assign enb_wvalid = enb_wvalid_reg;
    assign enb_bready = enb_bready_reg;
    assign enb_quantum_time = enb_quantum_time_reg;

endmodule



// Read Channel Timer Module
module timer_read_channel (
    input clk,
    input resetn,

    input s_arready,
    input s_rvalid,
    input s_start_quantum,

    output enb_arvalid,
    output enb_rready,
    output enb_quantum_time
);
    localparam IDLE = 'b00,
               START = 'b01;
    localparam QUANTUM_SIZE = 14; // clock

    reg [1:0] state_quantum_reg, state_quantum_next;
    reg [2:0] count0_reg, count0_next;
    reg [2:0] count1_reg, count1_next;
    reg [3:0] count_quantum_reg, count_quantum_next;

    reg flag_arvalid_reg, flag_arvalid_next;
    reg flag_rready_reg, flag_rready_next;

    reg enb_arvalid_reg, enb_arvalid_next;
    reg enb_rready_reg, enb_rready_next;
    reg enb_quantum_time_reg, enb_quantum_time_next;


    always @(posedge clk, negedge resetn) begin
        if(~resetn) begin
            state_quantum_reg <= IDLE;
            count0_reg <= 0;
            count1_reg <= 0;
            count_quantum_reg <= 0;
            
            flag_arvalid_reg <= 0;
            flag_rready_reg <= 0;

            enb_arvalid_reg <= 0;
            enb_rready_reg  <= 0;
            enb_quantum_time_reg <= 0;
        end
        else begin
            state_quantum_reg <= state_quantum_next;

            count0_reg <= count0_next;
            count1_reg <= count1_next;
            count_quantum_reg <= count_quantum_next;

            flag_arvalid_reg <= flag_arvalid_next;
            flag_rready_reg <= flag_rready_next;

            enb_arvalid_reg <= enb_arvalid_next;
            enb_rready_reg  <= enb_rready_next;
            enb_quantum_time_reg <= enb_quantum_time_next;
        end
        
    end

    always @(*) begin
        state_quantum_next  = state_quantum_reg;
        count0_next         = count0_reg;
        count1_next         = count1_reg;
        count_quantum_next  = count_quantum_reg;

        flag_arvalid_next   = flag_arvalid_reg;
        flag_rready_next    = flag_rready_reg;

        enb_arvalid_next = enb_arvalid_reg;
        enb_rready_next  = enb_rready_reg;
        enb_quantum_time_next = enb_quantum_time_reg;

        // branch signal transaction
        case ({s_rvalid, s_arready})
            'b01: begin
                flag_arvalid_next = 1;
            end
            'b10: begin
                flag_rready_next = 1;
            end
            default: begin
            end
        endcase

        if (flag_arvalid_next == 1) begin
            count0_next = count0_next + 1;
            enb_arvalid_next = 1;
            if (count0_reg > 1) begin
                flag_arvalid_next = 0;
                count0_next = 0;
                enb_arvalid_next = 0;
            end
        end
        if (flag_rready_next == 1) begin
            count1_next = count1_next + 1;
            enb_rready_next = 1;
            if (count1_reg > 1) begin
                flag_rready_next = 0;
                count1_next = 0;
                enb_rready_next = 0;
            end
        end

        //time quantum process
        case (state_quantum_reg)
            IDLE: begin
                enb_quantum_time_next = 0;
                if (s_start_quantum == 1  && enb_quantum_time_reg == 0) begin
                    state_quantum_next = START;
                    count_quantum_next = 0; //count_quantum_next + 1;
                end
            end
            START: begin
                count_quantum_next = count_quantum_next + 1;
                if ((count_quantum_reg > QUANTUM_SIZE)) begin
                    count_quantum_next = 0;
                    enb_quantum_time_next = 1;
                    state_quantum_next = IDLE;
                end
                if (enb_rready_reg) begin
                    count_quantum_next = 0;
                    enb_quantum_time_next = 0;
                    state_quantum_next = IDLE;
                end      
            end 
            default: state_quantum_next = IDLE;
        endcase
        

    end

    assign enb_arvalid = enb_arvalid_reg;
    assign enb_rready = enb_rready_reg;
    assign enb_quantum_time = enb_quantum_time_reg;

endmodule

    










/***************************************************************
 * AXI4-Lite Decoder
 ***************************************************************/
module axi_lite_decoder #(
    parameter NUM_SLAVES = 5,
    parameter ADDR_WIDTH = 32
)(  
    //input                       clk,
    input                       resetn,
    input  [ADDR_WIDTH-1:0]     i_axi_awaddr,           // Input Write Address
    input  [ADDR_WIDTH-1:0]     i_axi_araddr,           // Input Read Address
    output reg [NUM_SLAVES-1:0] o_slave_select_write,   // Output Slave Select for Write
    output reg [NUM_SLAVES-1:0] o_slave_select_read     // Output Slave Select for Read
);

    // Comb circuit with direct output assignment
    always @(*) begin
        if (~resetn) begin
            o_slave_select_write <= 0;
            o_slave_select_read  <= 0;
        end
        else begin
            // Write channel decoder
            casex (i_axi_awaddr)
                'h00xx_xxxx: o_slave_select_write <= 'b00001;  // Slave 0
                //'h0100_xxxx: o_slave_select_write <= 'b0010;  // Slave 1
                'h0200_2xxx: o_slave_select_write <= 'b00100;  // Slave 2
                'h0200_3xxx: o_slave_select_write <= 'b01000;  // Slave 3
                'h0101_xxxx: o_slave_select_write <= 'b10000;  // Slave 4
                default:     o_slave_select_write <= 'b00000;  // No slave selected
            endcase

            // Read channel decoder
            casex (i_axi_araddr)
                'h00xx_xxxx: o_slave_select_read <= 'b00001;  // Slave 0
                'h0100_xxxx: o_slave_select_read <= 'b00010;  // Slave 1
                'h0200_2xxx: o_slave_select_read <= 'b00100;  // Slave 2
                'h0200_3xxx: o_slave_select_read <= 'b01000;  // Slave 3
                'h0101_xxxx: o_slave_select_read <= 'b10000;  // Slave 4
                default:     o_slave_select_read <= 'b00000;  // No slave selected
            endcase
        end
    end

endmodule



/***************************************************************
 * AXI4-Lite Multiplexer
 ***************************************************************/
module axi_lite_mux #(
    parameter NUM_SLAVES = 5,
    parameter DATA_WIDTH = 32
)(
    // Master Interface (from picorv32_axi)
    input                     i_m_axi_awvalid,    // Master Write Address Valid
    output                    o_m_axi_awready,    // Master Write Address Ready
    input                     i_m_axi_wvalid,     // Master Write Data Valid
    output                    o_m_axi_wready,     // Master Write Data Ready
    input  [DATA_WIDTH-1:0]   i_m_axi_wdata,      // Master Write Data
    input  [DATA_WIDTH/8-1:0] i_m_axi_wstrb,      // Master Write Strobe
    output                    o_m_axi_bvalid,     // Master Write Response Valid
    input                     i_m_axi_bready,     // Master Write Response Ready
    input                     i_m_axi_arvalid,    // Master Read Address Valid
    output                    o_m_axi_arready,    // Master Read Address Ready
    output                    o_m_axi_rvalid,     // Master Read Data Valid
    input                     i_m_axi_rready,     // Master Read Data Ready
    output [DATA_WIDTH-1:0]   o_m_axi_rdata,      // Master Read Data
    // Slave Interfaces
    input  [NUM_SLAVES-1:0]                     i_slave_select_write, // Slave Select for Write
    input  [NUM_SLAVES-1:0]                     i_slave_select_read,  // Slave Select for Read
    output [NUM_SLAVES-1:0]                     o_s_axi_awvalid,      // Slave Write Address Valid
    input  [NUM_SLAVES-1:0]                     i_s_axi_awready,      // Slave Write Address Ready
    output [NUM_SLAVES-1:0]                     o_s_axi_wvalid,       // Slave Write Data Valid
    input  [NUM_SLAVES-1:0]                     i_s_axi_wready,       // Slave Write Data Ready
    output [NUM_SLAVES-1:0][DATA_WIDTH-1:0]     o_s_axi_wdata,    // Slave Write Data
    output [NUM_SLAVES-1:0][DATA_WIDTH/8-1:0]   o_s_axi_wstrb,    // Slave Write Strobe
    input  [NUM_SLAVES-1:0]                     i_s_axi_bvalid,   // Slave Write Response Valid
    output [NUM_SLAVES-1:0]                     o_s_axi_bready,   // Slave Write Response Ready
    output [NUM_SLAVES-1:0]                     o_s_axi_arvalid,  // Slave Read Address Valid
    input  [NUM_SLAVES-1:0]                     i_s_axi_arready,  // Slave Read Address Ready
    input  [NUM_SLAVES-1:0][DATA_WIDTH-1:0]     i_s_axi_rdata,    // Slave Read Data
    input  [NUM_SLAVES-1:0]                     i_s_axi_rvalid,   // Slave Read Data Valid
    output [NUM_SLAVES-1:0]                     o_s_axi_rready    // Slave Read Data Ready
);

    // Write Address Channel
    generate
        for (genvar i = 0; i < NUM_SLAVES; i = i + 1) begin : awvalid_loop
            assign o_s_axi_awvalid[i] = i_slave_select_write[i] ? i_m_axi_awvalid : 1'b0;
        end
    endgenerate

    assign o_m_axi_awready = i_slave_select_write[0] ? i_s_axi_awready[0] : 
                             i_slave_select_write[1] ? i_s_axi_awready[1] :
                             i_slave_select_write[2] ? i_s_axi_awready[2] :
                             i_slave_select_write[3] ? i_s_axi_awready[3] :
                             i_slave_select_write[4] ? i_s_axi_awready[4] : 0;

    // Write Data Channel
    generate
        for (genvar i = 0; i < NUM_SLAVES; i = i + 1) begin : wvalid_loop
            assign o_s_axi_wvalid[i] = i_slave_select_write[i] ? i_m_axi_wvalid : 1'b0;
        end
    endgenerate

    generate
        for (genvar i = 0; i < NUM_SLAVES; i = i + 1) begin : wdata_wstrb_loop
            assign o_s_axi_wdata[i] = i_slave_select_write[i] ? i_m_axi_wdata : 0;
            assign o_s_axi_wstrb[i] = i_slave_select_write[i] ? i_m_axi_wstrb : 0;
        end
    endgenerate

    assign o_m_axi_wready = i_slave_select_write[0] ? i_s_axi_wready[0] : 
                            i_slave_select_write[1] ? i_s_axi_wready[1] :
                            i_slave_select_write[2] ? i_s_axi_wready[2] :
                            i_slave_select_write[3] ? i_s_axi_wready[3] :
                            i_slave_select_write[4] ? i_s_axi_wready[4] : 0;

    // Write Response Channel
    assign o_m_axi_bvalid = i_slave_select_write[0] ? i_s_axi_bvalid[0] :
                            i_slave_select_write[1] ? i_s_axi_bvalid[1] :
                            i_slave_select_write[2] ? i_s_axi_bvalid[2] :
                            i_slave_select_write[3] ? i_s_axi_bvalid[3] :
                            i_slave_select_write[4] ? i_s_axi_bvalid[4] : 0;

    generate
        for (genvar i = 0; i < NUM_SLAVES; i = i + 1) begin : bready_loop
            assign o_s_axi_bready[i] = i_slave_select_write[i] ? i_m_axi_bready : 1'b0;
        end
    endgenerate

    // Read Address Channel
    generate
        for (genvar i = 0; i < NUM_SLAVES; i = i + 1) begin : arvalid_loop
            assign o_s_axi_arvalid[i] = i_slave_select_read[i] ? i_m_axi_arvalid : 1'b0;
        end
    endgenerate

    assign o_m_axi_arready = i_slave_select_read[0] ? i_s_axi_arready[0] : 
                             i_slave_select_read[1] ? i_s_axi_arready[1] :
                             i_slave_select_read[2] ? i_s_axi_arready[2] :
                             i_slave_select_read[3] ? i_s_axi_arready[3] : 
                             i_slave_select_read[4] ? i_s_axi_arready[4] : 0;

    // Read Data Channel
    assign o_m_axi_rdata = i_slave_select_read[0] ? i_s_axi_rdata[0] :
                           i_slave_select_read[1] ? i_s_axi_rdata[1] :
                           i_slave_select_read[2] ? i_s_axi_rdata[2] :
                           i_slave_select_read[3] ? i_s_axi_rdata[3] :
                           i_slave_select_read[4] ? i_s_axi_rdata[4] : 0;

    assign o_m_axi_rvalid = i_slave_select_read[0] ? i_s_axi_rvalid[0] : 
                            i_slave_select_read[1] ? i_s_axi_rvalid[1] :
                            i_slave_select_read[2] ? i_s_axi_rvalid[2] :
                            i_slave_select_read[3] ? i_s_axi_rvalid[3] :
                            i_slave_select_read[4] ? i_s_axi_rvalid[4] : 0;

    generate
        for (genvar i = 0; i < NUM_SLAVES; i = i + 1) begin : rready_loop
            assign o_s_axi_rready[i] = i_slave_select_read[i] ? i_m_axi_rready : 1'b0;
        end
    endgenerate
endmodule