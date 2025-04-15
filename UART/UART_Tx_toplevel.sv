module UART_Tx_toplevel (
    input logic         clk,
    input logic         rst,
    input logic         TX_DV,
    input logic [7:0]   TX_Byte,
    output logic        Transmit_Done,
    output logic [6:0]  SSG1,
    output logic [6:0]  SSG2
);

//instantiate UART_Tx module, send byte to esp32, print byte on serial monitor

//byte to send is determined by the switches and displayed on the 7 segs
//buttons 0 and 1 are tied to rst and TX_DV to start the transmission
//clk is tied to 50 MHz clock on board

logic TX_Done, TX_Active, TX_Serial;
assign Transmit_Done = TX_Done;

UART_Tx #(
    .CLKS_PER_BIT()) UART_TX_INST_l
    (
        .clk(clk),
        .rst(rst),
        .i_TX_DV(TX_DV),
        .i_TX_Byte(TX_Byte),
        .o_TX_Active(TX_Active),
        .o_TX_Serial(TX_Serial),
        .o_TX_Done(TX_Done)
    );

BCD_conv SevenSeg0_l(
    .number_in(TX_Byte[7:4]),
    .number_out(SSG2)
);

BCD_conv SevenSeg1_l(
    .number_in(TX_Byte[3:0]),
    .number_out(SSG1)
);

endmodule