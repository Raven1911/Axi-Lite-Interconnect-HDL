`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2025 09:11:42 AM
// Design Name: 
// Module Name: decoder_tb
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


module decoder_tb();

    reg clk;
    reg resetn;
    reg [31:0]i_axi_awaddr;
    reg [31:0]i_axi_araddr;
    wire [2:0]o_slave_select_write;
    wire [2:0]o_slave_select_read;

    axi_lite_decoder #(
        .NUM_SLAVES(3),
        .ADDR_WIDTH(32)
    ) uut(
        .clk(clk),
        .resetn(resetn),
        .i_axi_awaddr(i_axi_awaddr),           // Input Write Address
        .i_axi_araddr(i_axi_araddr),           // Input Read Address
        .o_slave_select_write(o_slave_select_write),   // Output Slave Select for Write
        .o_slave_select_read(o_slave_select_read)     // Output Slave Select for Read

    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        #0 resetn = 1;
        #10 resetn = 0;
        #10 resetn = 1;
    end

    initial begin
        #100 i_axi_awaddr = 'h0111_1111; i_axi_araddr = 'h0211_1111;
    end





endmodule
