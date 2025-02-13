/*
SPI_MODE

Mode | Clock Polarity (CPOL/CKP) | Clock Phase (CPHA)
 0   |             0             |        0
 1   |             0             |        1
 2   |             1             |        0
 3   |             1             |        1

CLKS_PER_HALF_BIT
Sets frequency of SPI clock, which is derived from clk. Set to integer number
of clocks for each half-bit of SPI data. (ex. 100 MHz clk, CLKS_PER_HALF_BIT = 2, SPI_CLK would be 25 MHz)
**Must be >= 2 and clk must be at least 2x faster than SPI_CLK
*/

module SPI_Master #(
    parameter int SPI_MODE = 0,
    parameter int CLKS_PER_HALF_BIT = 2
) (

    //FPGA clk and rst
    input logic clk,
    input logic rst,

    //MOSI 
    input logic [7:0] i_MOSI_Byte, //Byte to transmit on MOSI
    input logic i_MOSI_DV, //Data Valid with i_MOSI_Byte
    output logic o_TX_Ready //Transmit is ready for next byte

    //MISO
    output logic o_MISO_DV //Data Valid with MISO
    output logic [7:0] o_MISO_Byte //Byte received on MISO

    //SPI Interface
    output logic SPI_CLK,
    input logic MISO,
    output logic MOSI
);

logic CPOL; //Clock Polarity
logic CPHA; //Clock Phase

logic [$clog2(CLKS_PER_HALF_BIT*2)-1:0] SPI_CLK_Count_r;
logic SPI_CLK_r;
logic [4:0] SPI_CLK_Edges;
logic Leading_Edge_r;
logic Trailing_Edge_r;
logic MOSI_DV_r;
logic [7:0] MOSI_BYTE_r;
logic [2:0] MISO_index;
logic [2:0] MOSI_index;





endmodule