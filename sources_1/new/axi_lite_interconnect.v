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
 * AXI4-Lite Interconnect for picorv32_axi (1 Master, Multiple Slaves)
 ***************************************************************/
module axi_lite_interconnect #(
    parameter NUM_SLAVES = 3,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // Clock and Reset
    input                     clk,
    input                     reset_n,

    // AXI4-Lite Master Interface (from picorv32_axi)
    input                     i_m_axi_awvalid,    // Master Write Address Valid
    output                    o_m_axi_awready,    // Master Write Address Ready
    input  [ADDR_WIDTH-1:0]   i_m_axi_awaddr,     // Master Write Address
    input  [2:0]              i_m_axi_awprot,     // Master Write Protection
    input                     i_m_axi_wvalid,     // Master Write Data Valid
    output                    o_m_axi_wready,     // Master Write Data Ready
    input  [DATA_WIDTH-1:0]   i_m_axi_wdata,      // Master Write Data
    input  [DATA_WIDTH/8-1:0] i_m_axi_wstrb,      // Master Write Strobe
    output                    o_m_axi_bvalid,     // Master Write Response Valid
    input                     i_m_axi_bready,     // Master Write Response Ready
    input                     i_m_axi_arvalid,    // Master Read Address Valid
    output                    o_m_axi_arready,    // Master Read Address Ready
    input  [ADDR_WIDTH-1:0]   i_m_axi_araddr,     // Master Read Address
    input  [2:0]              i_m_axi_arprot,     // Master Read Protection
    output                    o_m_axi_rvalid,     // Master Read Data Valid
    input                     i_m_axi_rready,     // Master Read Data Ready
    output [DATA_WIDTH-1:0]   o_m_axi_rdata,      // Master Read Data

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

    // Internal signals for slave selection
    wire [NUM_SLAVES-1:0] slave_select_write;
    wire [NUM_SLAVES-1:0] slave_select_write_data;
    wire [NUM_SLAVES-1:0] slave_select_write_bresp;
    wire [NUM_SLAVES-1:0] slave_select_read;
    wire [NUM_SLAVES-1:0] slave_select_read_data;

    // Decoder: Select slave based on address
    axi_lite_decoder #(
        .NUM_SLAVES(NUM_SLAVES),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) decoder (
        .i_axi_awaddr(i_m_axi_awaddr),
        .i_axi_araddr(i_m_axi_araddr),
        .i_axi_awvalid(i_m_axi_awvalid),
        .i_axi_wvalid(i_m_axi_wvalid),
        .i_axi_bready(i_m_axi_bready),
        .i_axi_arvalid(i_m_axi_arvalid),
        .i_axi_rready(i_m_axi_rready),
        .o_slave_select_write(slave_select_write),
        .o_slave_select_write_data(slave_select_write_data),
        .o_slave_select_write_bresp(slave_select_write_bresp),
        .o_slave_select_read(slave_select_read),
        .o_slave_select_read_data(slave_select_read_data)
    );

    // Multiplexer: Route data between master and selected slave
    axi_lite_mux #(
        .NUM_SLAVES(NUM_SLAVES),
        .DATA_WIDTH(DATA_WIDTH)
    ) mux (
        .i_m_axi_awvalid(i_m_axi_awvalid),
        .o_m_axi_awready(o_m_axi_awready),
        .i_m_axi_wvalid(i_m_axi_wvalid),
        .o_m_axi_wready(o_m_axi_wready),
        .i_m_axi_wdata(i_m_axi_wdata),
        .i_m_axi_wstrb(i_m_axi_wstrb),
        .o_m_axi_bvalid(o_m_axi_bvalid),
        .i_m_axi_bready(i_m_axi_bready),
        .i_m_axi_arvalid(i_m_axi_arvalid),
        .o_m_axi_arready(o_m_axi_arready),
        .o_m_axi_rvalid(o_m_axi_rvalid),
        .i_m_axi_rready(i_m_axi_rready),
        .o_m_axi_rdata(o_m_axi_rdata),
        .i_slave_select_write(slave_select_write),
        .i_slave_select_write_data(slave_select_write_data),
        .i_slave_select_write_bresp(slave_select_write_bresp),
        .i_slave_select_read(slave_select_read),
        .i_slave_select_read_data(slave_select_read_data),
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

    // Address and Protection signal routing
    // genvar i;
    // generate
    //     for (i = 0; i < NUM_SLAVES; i = i + 1) begin : slave_routing
    //         assign o_s_axi_awaddr[i] = (slave_select_write[i]) ? i_m_axi_awaddr : 0;
    //         assign o_s_axi_araddr[i] = (slave_select_read[i])  ? i_m_axi_araddr : 0;
    //         assign o_s_axi_awprot[i] = (slave_select_write[i]) ? i_m_axi_awprot : 0;
    //         assign o_s_axi_arprot[i] = (slave_select_read[i])  ? i_m_axi_arprot : 0;
    //     end
    // endgenerate
    assign o_s_axi_awaddr = i_m_axi_awaddr;
    assign o_s_axi_araddr = i_m_axi_araddr;

endmodule
/***************************************************************
 * AXI4-Lite Decoder
 ***************************************************************/
module axi_lite_decoder #(
    parameter NUM_SLAVES = 3,
    parameter ADDR_WIDTH = 32
)(
    input  [ADDR_WIDTH-1:0]     i_axi_awaddr,      // Input Write Address
    input  [ADDR_WIDTH-1:0]     i_axi_araddr,      // Input Read Address
    input                       i_axi_awvalid,     // Input Write Address Valid
    input                       i_axi_wvalid,
    input                       i_axi_bready,
    input                       i_axi_arvalid,     // Input Read Address Valid
    input                       i_axi_rready,
    output reg [NUM_SLAVES-1:0] o_slave_select_write,  // Output Slave Select for Write
    output reg [NUM_SLAVES-1:0] o_slave_select_write_data,
    output reg [NUM_SLAVES-1:0] o_slave_select_write_bresp,
    output reg [NUM_SLAVES-1:0] o_slave_select_read,    // Output Slave Select for Read
    output reg [NUM_SLAVES-1:0] o_slave_select_read_data
);

    // Address map (example): 
    // S0: 0x0000_0000 - 0x00FF_FFFF
    // S1: 0x0100_0000 - 0x01FF_FFFF
    wire [31:0] write_addr_upper = i_axi_awaddr[31:0];
    wire [31:0] read_addr_upper  = i_axi_araddr[31:0];

    always @(*) begin
        o_slave_select_write = 'b0;
        o_slave_select_write_data = 'b0;
        o_slave_select_write_bresp = 'b0;
        o_slave_select_read  = 'b0;
        o_slave_select_read_data = 'b0;
        
        //decoder write channel
        if (i_axi_awvalid) begin
            casex (write_addr_upper)
                'h00xx_xxxx: o_slave_select_write = 'b001;  // Slave 0
                'h01xx_xxxx: o_slave_select_write = 'b010;  // Slave 1
                'h02xx_xxxx: o_slave_select_write = 'b100;  // Slave 2
                default:  o_slave_select_write = 'b000;  // No slave selected
            endcase
        end
        if (i_axi_wvalid) begin
            casex (write_addr_upper)
                'h00xx_xxxx: o_slave_select_write_data = 'b001;  // Slave 0
                'h01xx_xxxx: o_slave_select_write_data = 'b010;  // Slave 1
                'h02xx_xxxx: o_slave_select_write_data = 'b100;  // Slave 2
                default:  o_slave_select_write_data = 'b000;  // No slave selected
            endcase
        end
        if (i_axi_bready) begin
            casex (write_addr_upper)
                'h00xx_xxxx: o_slave_select_write_bresp = 'b001;  // Slave 0
                'h01xx_xxxx: o_slave_select_write_bresp = 'b010;  // Slave 1
                'h02xx_xxxx: o_slave_select_write_bresp = 'b100;  // Slave 2
                default:  o_slave_select_write_bresp = 'b000;  // No slave selected
            endcase
        end

        //decoder read channel
        if (i_axi_arvalid) begin
            casex (read_addr_upper)
                'h00xx_xxxx: o_slave_select_read = 'b001;  // Slave 0
                'h01xx_xxxx: o_slave_select_read = 'b010;  // Slave 1
                'h02xx_xxxx: o_slave_select_read = 'b100;  // Slave 2
                default:  o_slave_select_read = 'b000;  // No slave selected
            endcase
        end
        if (i_axi_rready) begin
            casex (read_addr_upper)
                'h00xx_xxxx: o_slave_select_read_data = 'b001;  // Slave 0
                'h01xx_xxxx: o_slave_select_read_data = 'b010;  // Slave 1
                'h02xx_xxxx: o_slave_select_read_data = 'b100;  // Slave 2
                default:  o_slave_select_read_data = 'b000;  // No slave selected
            endcase
        end
    end

endmodule

/***************************************************************
 * AXI4-Lite Multiplexer
 ***************************************************************/
module axi_lite_mux #(
    parameter NUM_SLAVES = 3,
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
    input  [NUM_SLAVES-1:0]                     i_slave_select_write_data,
    input  [NUM_SLAVES-1:0]                     i_slave_select_write_bresp,
    input  [NUM_SLAVES-1:0]                     i_slave_select_read,  // Slave Select for Read
    input  [NUM_SLAVES-1:0]                     i_slave_select_read_data,
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
    assign o_s_axi_awvalid =    i_slave_select_write[0] ? {1'b0, 1'b0, i_m_axi_awvalid} :
                                i_slave_select_write[1] ? {1'b0, i_m_axi_awvalid, 1'b0} :
                                i_slave_select_write[2] ? {i_m_axi_awvalid, 1'b0, 1'b0} : 0;

    assign o_m_axi_awready =    i_slave_select_write[0] ? i_s_axi_awready[0] : 
                                i_slave_select_write[1] ? i_s_axi_awready[1] :
                                i_slave_select_write[2] ? i_s_axi_awready[2] : 0;

    // Write Data Channel
    assign o_s_axi_wvalid = i_slave_select_write_data[0] ? {1'b0, 1'b0, i_m_axi_wvalid} :
                            i_slave_select_write_data[1] ? {1'b0, i_m_axi_wvalid, 1'b0} :
                            i_slave_select_write_data[2] ? {i_m_axi_wvalid, 1'b0, 1'b0} : 0;

    assign o_s_axi_wdata[0] = (i_slave_select_write_data[0]) ? i_m_axi_wdata : 0;
    assign o_s_axi_wdata[1] = (i_slave_select_write_data[1]) ? i_m_axi_wdata : 0;
    assign o_s_axi_wdata[2] = (i_slave_select_write_data[2]) ? i_m_axi_wdata : 0;

    assign o_s_axi_wstrb[0] = (i_slave_select_write_data[0]) ? i_m_axi_wstrb : 0;
    assign o_s_axi_wstrb[1] = (i_slave_select_write_data[1]) ? i_m_axi_wstrb : 0;
    assign o_s_axi_wstrb[2] = (i_slave_select_write_data[2]) ? i_m_axi_wstrb : 0;
    
    assign o_m_axi_wready = i_slave_select_write_data[0] ? i_s_axi_wready[0] : 
                            i_slave_select_write_data[1] ? i_s_axi_wready[1] :
                            i_slave_select_write_data[2] ? i_s_axi_wready[2] : 0;

                            
    // Write Response Channel
    assign o_m_axi_bvalid = i_slave_select_write_bresp[0] ? i_s_axi_bvalid[0] :
                            i_slave_select_write_bresp[1] ? i_s_axi_bvalid[1] :
                            i_slave_select_write_bresp[2] ? i_s_axi_bvalid[2] : 0;

    assign o_s_axi_bready = i_slave_select_write_bresp[0] ? {1'b0, 1'b0, i_m_axi_bready} :
                            i_slave_select_write_bresp[1] ? {1'b0, i_m_axi_bready, 1'b0} :
                            i_slave_select_write_bresp[2] ? {i_m_axi_bready, 1'b0, 1'b0} : 0;

    // Read Address Channel
    assign o_s_axi_arvalid =    i_slave_select_read[0] ? 'b001 :
                                i_slave_select_read[1] ? 'b010 :
                                i_slave_select_read[2] ? 'b100 : 'b0;

    assign o_m_axi_arready =    i_slave_select_read[0] ? i_s_axi_arready[0] : 
                                i_slave_select_read[1] ? i_s_axi_arready[1] :
                                i_slave_select_read[2] ? i_s_axi_arready[2] : 0;

    // Read Data Channel
    assign o_m_axi_rdata =  i_s_axi_rvalid[0] ? i_s_axi_rdata[0] :
                            i_s_axi_rvalid[1] ? i_s_axi_rdata[1] :
                            i_s_axi_rvalid[2] ? i_s_axi_rdata[2] : 0;

    assign o_m_axi_rvalid = i_slave_select_read_data[0] ? i_s_axi_rvalid[0] : 
                            i_slave_select_read_data[1] ? i_s_axi_rvalid[1] :
                            i_slave_select_read_data[2] ? i_s_axi_rvalid[2] : 0;

    assign o_s_axi_rready = i_slave_select_read_data[0] ? {1'b0, 1'b0, i_m_axi_rready} :
                            i_slave_select_read_data[1] ? {1'b0, i_m_axi_rready, 1'b0} :
                            i_slave_select_read_data[2] ? {i_m_axi_rready, 1'b0, 1'b0} : 0;


endmodule