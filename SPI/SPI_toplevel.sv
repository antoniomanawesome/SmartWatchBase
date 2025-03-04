module SPI_toplevel (
    input logic         clk,
    input logic         rst,

);

SPI_Master_w_CS #() SPI_l (

);

BCD_conv SevenSeg0_l(
    .number_in(RX_Byte[7:4]),
    .number_out(SSG2)
);

endmodule