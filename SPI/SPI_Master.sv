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
    output logic o_MOSI_Ready //Transmit is ready for next byte

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
logic [4:0] SPI_CLK_Edges_r;
logic Leading_Edge_r;
logic Trailing_Edge_r;
logic MOSI_DV_r;
logic [7:0] MOSI_BYTE_r;
logic [2:0] MISO_Bit_Count_r;
logic [2:0] MOSI_Bit_Count_r;

//CPOL = 0 means clock idles at 0, so leading edge is rising edge.
//CPOL = 1 means clock idles at 1, so leading edge is falling edge.
assign CPOL = (SPI_MODE == 2) | (SPI_MODE == 3);

//CPHA = 0 means the "out" side changes the data on the trailing edge of the clock and the "in" side captures data on leading edge
//CPHA = 1 means the "out" side changes the data on the leading edge of the clock and the "in" side captures data on trailing edge
assign CPHA = (SPI_MODE == 1) | (SPI_MODE == 3);

//Generating SPI clock the correct number of times when DV pulse comes
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        o_MOSI_Ready <= 1'b0;
        SPI_CLK_Edges_r <= 1'b0;
        Leading_Edge_r <= 1'b0;
        Trailing_Edge_r <= 1'b0;
        SPI_CLK_r <= CPOL; //assigning default state to idle 
        SPI_CLK_Count_r <= 1'b0;
    end else begin
        Leading_Edge_r <= 1'b0;
        Trailing_Edge_r <= 1'b0;

        if(MOSI_DV) begin 
            o_MOSI_Ready <= 1'b0;
            SPI_CLK_Edges_r <= 16; //Total # of edges in one byte is always 16
        end else if (SPI_CLK_Edges_r > 0) begin
            o_MOSI_Ready <= 1'b0;

            if(SPI_CLK_Count_r == CLKS_PER_HALF_BIT*2-1) begin
                SPI_CLK_Edges_r <= SPI_CLK_Edges_r - 1'b1;
                Trailing_Edge_r <= 1'b1;
                SPI_CLK_Count_r <= '0;
                SPI_CLK_r <= ~SPI_CLK_r;

            end else if(SPI_CLK_Count_r == CLKS_PER_HALF_BIT-1) begin
                SPI_CLK_Edges_r <= SPI_CLK_Edges_r - 1'b1;
                Leading_Edge_r <= 1'b1;
                SPI_CLK_Count_r <= SPI_CLK_Count_r + 1'b1;
                SPI_CLK_r <= ~SPI_CLK_r;

            end else begin
                SPI_CLK_Count_r <= SPI_CLK_Count_r + 1'b1;
            end
        end
        
        
    end
end

//Reisters MOSI_Byte when DV is pulsed and keeps local storage of byte in case higher level module changes the data
always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        MOSI_BYTE_r <= '0;
        MOSI_DV_r <= 1'b0;
    end else begin
        MOSI_DV_r <= MOSI_DV; //1 clk cycle delay
        if(MOSI_DV) MOSI_BYTE_r <= MOSI_Byte;
    end
end

//Generate MOSI Data (works with CPHA=0 and CPHA1)
always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        MOSI <= 1'b0;
        MOSI_Bit_Count_r <= 3'b111; //send MSB first
    end else if begin 
        if(o_MOSI_Ready) MOSI_Bit_Count_r <= 3'b111; //if ready is true, reset bit counts to default
        else if (MOSI_DV_r & ~CPHA) begin //start transaction and CPHA = 0
            MOSI <= MOSI_BYTE_r[3'b111];
            MISO_Bit_Count_r <= 3'b110;
        end else if((Leading_Edge_r & CPHA) & (Trailing_Edge_r & ~CPHA)) begin
            MISO_Bit_Count_r <= MISO_Bit_Count_r - 1'b1;
            MOSI <= MOSI_BYTE_r[MISO_Bit_Count_r];
        end
    end
end

//Read MISO Data
always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        o_MISO_Byte <= '0;
        o_MISO_DV <= 1'b0;
        MISO_Bit_Count_r <= 3'b111;
    end else begin
        o_MISO_DV <= 1'b0;
        if(o_MOSI_Ready) MISO_Bit_Count_r <= 3'b111; //if ready is true, reset bit counts to default
        else if((Leading_Edge_r & ~CPHA) | (Trailing_Edge_r & CPHA)) begin
            o_MISO_Byte[MISO_Bit_Count_r] <= MISO; //sample data here
            MISO_Bit_Count_r <= MISO_Bit_Count_r - 1'b1;
            if(MISO_Bit_Count_r == 3'b000) o_MISO_DV <= 1'b1; //Byte is done
        end
    end
end

//Add clock delay to signals because we are basing the output of SPI_CLK on Leading_Edge_r which is a cycle behind
always_ff @(posedge clk or posedge rst) begin
    if(rst) SPI_CLK <= CPOL;
    else SPI_CLK <= SPI_CLK_r;
end

endmodule