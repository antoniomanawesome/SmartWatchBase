`timescale 1ns / 1ps

module UART_Tx_tb ();

localparam int c_FPGA_clk_freq = 50000000;
localparam int c_baudrate = 115200;
localparam int c_CLOCK_PERIOD_NS = 20;
localparam int c_BIT_PERIOD = 8680;

logic clk = 1'b0, rst = 1'b0;
logic TX_DV = 1'b0, RX_DV;
logic TX_Active, UART_Line, TX_Serial, TX_Done;
logic [7:0] TX_Byte = '0, RX_Byte;

UART_Rx #(
    .FPGA_clk_freq(c_FPGA_clk_freq),
    .baudrate(c_baudrate)) UART_RX_INST_l
    (
        .clk(clk),
        .rst(rst),
        .i_RX_Serial(UART_Line),
        .o_RX_DV(RX_DV),
        .o_RX_Byte(RX_Byte)
    );

UART_Tx #(
    .FPGA_clk_freq(c_FPGA_clk_freq),
    .baudrate(c_baudrate)) UART_TX_INST_l
    (
        .clk(clk),
        .rst(rst),
        .i_TX_DV(TX_DV),
        .i_TX_Byte(TX_Byte),
        .o_TX_Active(TX_Active),
        .o_TX_Serial(TX_Serial),
        .o_TX_Done(TX_Done)
    );

assign UART_Line = TX_Active ? TX_Serial : 1'b1; // keeps UART line high when transmitter is not active

always #(c_CLOCK_PERIOD_NS/2) clk <= !clk;

initial begin
    repeat(2) @(posedge clk);
    TX_DV <= 1'b1;
    TX_Byte <= 8'h37; // send 0x37
    @(posedge clk);
    TX_DV <= 1'b0;

    @(posedge RX_DV); //check that command was received
    if(RX_Byte == 8'h37)
        $display("Test Passed - Correct Byte Received");
    else
        $display("Test Failed - Incorrect Byte Received");
    $finish();
end

initial begin
    //Required to dump signals to EPWave
    $dumpfile("dump.vcd");
    $dumpvars(0);
end

endmodule