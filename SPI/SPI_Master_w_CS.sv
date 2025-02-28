/*
Created a SPI Wrapper that instantiates an existing SPI module and creates Chip Select Functionality.
Supports arbitrary length byte transfers.

This wrapper only instantiates one chip select.

SPI_MODE

Mode | Clock Polarity (CPOL/CKP) | Clock Phase (CPHA)
 0   |             0             |        0
 1   |             0             |        1
 2   |             1             |        0
 3   |             1             |        1

CLKS_PER_HALF_BIT
Sets frequency of SPI clock, which is derived from clk. Set to integer number
of clocks for each half-bit of SPI data. (ex. 100 MHz clk, CLKS_PER_HALF_BIT = 2, SCK would be 25 MHz)
**Must be >= 2 and clk must be at least 2x faster than SCK

MAX_BYTES_PER_CS
The maximum number of bytes that will be sent during a CS low pulse

CS_INACTIVE_CLKS 
Sets the amount of time in clock cycles to hold the state of CS high before the next command is allowed
on the line. Important if chip requires some time when CS is high between transfers.

*/

module SPI_Master_w_CS #(
    parameter int SPI_MODE = 0,
    parameter int CLKS_PER_HALF_BIT = 2,
    parameter int MAX_BYTES_PER_CS = 2,
    parameter int CS_INACTIVE_CLKS = 1
) (
    input logic  rst,    // FPGA Reset
    input logic  clk,    // FPGA Clock

    //MOSI Signals
    input [$clog2(MAX_BYTES_PER_CS+1)-1:0] i_MOSI_Count,  // # bytes per CS low
    input [7:0]  i_MOSI_Byte,       // Byte to transmit to MOSI
    input        i_MOSI_DV,         // Data Valid Pulse for MOSI
    output       o_MOSI_Ready,      // Transmit Ready for next byte

   //MISO Signals
   output [$clog2(MAX_BYTES_PER_CS+1)-1:0] o_MISO_Count,  // Index MISO byte
   output       o_MISO_DV,     // Data Valid pulse for MISO
   output [7:0] o_MISO_Byte,   // Byte received on MISO

   //SPI
   output SCK,
   input  MISO,
   output MOSI,
   output CS_L //Active low Chip Select
);
    
typedef enum logic [2:0] {
    IDLE,
    TRANSFER,
    INACTIVE_CS
} state_t;

state_t state_r;

logic CS_r;
logic [$clog2(CS_INACTIVE_CLKS)-1:0] CS_Inactive_Count_r;
logic [$clog2(MAX_BYTES_PER_CS+1)-1:0] MOSI_Count_r, MISO_Count_r;
logic Master_Ready;

SPI_Master
#(.SPI_MODE(SPI_MODE),
  .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)
  ) SPI_Master_Inst_l
(

.rst(rst),
.clk(clk),    
.i_MOSI_Byte(i_MOSI_Byte),
.i_MOSI_DV(i_MOSI_DV),
.o_MOSI_Ready(Master_Ready),   

.o_MISO_DV(o_MISO_DV),
.o_MISO_Byte(o_MISO_Byte),

.SCK(SCK),
.MISO(MISO),
.MOSI(MOSI)
);

//Control CS using FSM

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        state_r <= IDLE;
        CS_r  <= 1'b1;
        MOSI_Count_r <= 0;
        CS_Inactive_Count_r <= CS_INACTIVE_CLKS;
    end else begin
        case(state_r)
            IDLE: begin
                if(CS_r & i_MOSI_DV) begin //start of transmission
                    MOSI_Count_r <= i_MOSI_Count - 1'b1; //register count
                    CS_r <= 1'b0; //Drive CS low to start transmission
                    state_r <= TRANSFER;
                end
            end

            TRANSFER: begin //transfer bytes
                if(Master_Ready) begin
                    if(MOSI_Count_r > 0) begin
                        if(i_MOSI_DV) MOSI_Count_r <= MOSI_Count_r - 1'b1;
                    end else begin
                        CS_r <= 1'b1; //set CS high since we're done
                        CS_Inactive_Count_r <= CS_INACTIVE_CLKS;
                        state_r <= INACTIVE_CS;
                    end
                end
            end

            INACTIVE_CS: begin
                if(CS_Inactive_Count_r > 0) CS_Inactive_Count_r <= CS_Inactive_Count_r - 1'b1;
                else state_r <= IDLE;
            end

            default: begin
                CS_r <= 1'b1;
                state_r <= IDLE;
            end
        endcase
    end
end

always_ff @(posedge clk) begin //keep track of the MISO count
    if(CS_r) MISO_Count_r <= '0;
    else if(o_MISO_DV) MISO_Count_r <= MISO_Count_r + 1'b1;
end

assign CS_L = CS_r;
assign o_MISO_Count = MISO_Count_r;
assign o_MOSI_Ready = ((state_r == IDLE) | (state_r == TRANSFER) && (Master_Ready == 1'b1) && (MOSI_Count_r > 0) & i_MOSI_DV);

endmodule