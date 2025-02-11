module UART_toplevel (
    input logic         clk,
    input logic         RX_Serial,
    output logic        RX_DV,
    output logic [6:0]  SSG1,
    output logic [6:0]  SSG2,
    output logic [7:0] RX_Byte
);

//logic [7:0] RX_Byte;
logic data_valid;

assign RX_DV = ~data_valid;

UART_Rx #(
    .CLKS_PER_BIT()) UART_RX_INST_l
    (
        .clk(clk),
        .i_RX_Serial(RX_Serial),
        .o_RX_DV(data_valid),
        .o_RX_Byte(RX_Byte)
    );

BCD_conv SevenSeg0_l(
    .number_in(RX_Byte[7:4]),
    .number_out(SSG2)
);

BCD_conv SevenSeg1_l(
    .number_in(RX_Byte[3:0]),
    .number_out(SSG1)
);

endmodule