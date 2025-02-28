/*
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
*/

module SPI_Master
  #(parameter SPI_MODE = 0,
    parameter CLKS_PER_HALF_BIT = 2
    ) (

   input logic  rst,    // FPGA Reset
   input logic  clk,    // FPGA Clock
   
   //MOSI Signals
   input logic [7:0]  i_MOSI_Byte,        // Byte to transmit on MOSI
   input logic        i_MOSI_DV,          // Data Valid with MOSI
   output logic       o_MOSI_Ready,       // Transmit Ready for next byte
   
   //MISO Signals
   output logic       o_MISO_DV,     // Data Valid with MISO
   output logic [7:0] o_MISO_Byte,   // Byte received on MISO

   // SPI
   output logic SCK,
   input logic  MISO,
   output logic MOSI
   );

  // SPI Interface (All Runs at SPI Clock Domain)
  logic CPOL;     // Clock polarity
  logic CPHA;     // Clock phase

  logic [$clog2(CLKS_PER_HALF_BIT*2)-1:0] SCK_Count_r;
  logic SCK_r;
  logic [4:0] SCK_Edges_r;
  logic Leading_Edge_r;
  logic Trailing_Edge_r;
  logic       MOSI_DV_r;
  logic [7:0] MOSI_Byte_r;

  logic [2:0] MOSI_Bit_Count_r;
  logic [2:0] MISO_Bit_Count_r;

  // CPOL: Clock Polarity
  // CPOL=0 when clock idles at 0, leading edge is rising edge.
  // CPOL=1 when clock idles at 1, leading edge is falling edge.
  assign CPOL  = (SPI_MODE == 2) | (SPI_MODE == 3);

  // CPHA: Clock Phase
  // CPHA=0 when "out" side changes data on trailing edge of clock
  //              the "in" side captures data on leading edge
  // CPHA=1 when "out" side changes data on leading edge of clock
  //              the "in" side captures data on the trailing edge
  assign CPHA  = (SPI_MODE == 1) | (SPI_MODE == 3);



  // Generate SPI Clock when DV is true
  always @(posedge clk or posedge rst)
  begin
    if (rst) begin
      o_MOSI_Ready      <= 1'b0;
      SCK_Edges_r <= '0;
      Leading_Edge_r  <= 1'b0;
      Trailing_Edge_r <= 1'b0;
      SCK_r       <= CPOL; // assign default state to idle
      SCK_Count_r <= '0;
    end else begin

      // Default assignments
      Leading_Edge_r  <= 1'b0;
      Trailing_Edge_r <= 1'b0;
      
      if (i_MOSI_DV) begin //if DV is true
        o_MOSI_Ready      <= 1'b0;
        SCK_Edges_r <= 16; // Total # edges in 1 byte is always 16
      end
      else if (SCK_Edges_r > 0) begin //if DV not true
        o_MOSI_Ready <= 1'b0;
        
        if (SCK_Count_r == CLKS_PER_HALF_BIT*2-1) begin
          SCK_Edges_r <= SCK_Edges_r - 1'b1;
          Trailing_Edge_r <= 1'b1;
          SCK_Count_r <= '0;
          SCK_r       <= ~SCK_r;
        end
        else if (SCK_Count_r == CLKS_PER_HALF_BIT-1) begin
          SCK_Edges_r <= SCK_Edges_r - 1'b1;
          Leading_Edge_r  <= 1'b1;
          SCK_Count_r <= SCK_Count_r + 1'b1;
          SCK_r       <= ~SCK_r;
        end else SCK_Count_r <= SCK_Count_r + 1'b1;
      end else o_MOSI_Ready <= 1'b1;
    end
  end

  //Register MOSI_Byte when DV is true and store byte in case higher lvl module changes data
  always @(posedge clk or posedge rst)
  begin
    if (rst) begin
      MOSI_Byte_r <= '0;
      MOSI_DV_r   <= 1'b0;
    end else begin
        MOSI_DV_r <= i_MOSI_DV; // 1 clock cycle delay
        if (i_MOSI_DV) MOSI_Byte_r <= i_MOSI_Byte;
      end
  end


  //Generate MOSI MSB first (works with CPHA=0 and CPHA=1) 
  always @(posedge clk or posedge rst)
  begin
    if (rst) begin
      MOSI     <= 1'b0;
      MOSI_Bit_Count_r <= 3'b111; //Index is MSB first here
    end
    else begin

      if (o_MOSI_Ready) MOSI_Bit_Count_r <= 3'b111; //if ready is true, rst bit counts to default
      else if (MOSI_DV_r & ~CPHA) begin // Catch the case where we start transaction and CPHA = 0
        MOSI     <= MOSI_Byte_r[3'b111];
        MOSI_Bit_Count_r <= MOSI_Bit_Count_r - 1'b1;
      end else if ((Leading_Edge_r & CPHA) | (Trailing_Edge_r & ~CPHA)) begin
        MOSI_Bit_Count_r <= MOSI_Bit_Count_r - 1'b1;
        MOSI <= MOSI_Byte_r[MOSI_Bit_Count_r];
      end
    end
  end


  //Read MISO
  always @(posedge clk or posedge rst)
  begin
    if (rst) begin
      o_MISO_Byte      <= '0;
      o_MISO_DV        <= 1'b0;
      MISO_Bit_Count_r <= 3'b111;
    end else begin

      // Default Assignment
      o_MISO_DV   <= 1'b0;

      if (o_MOSI_Ready) MISO_Bit_Count_r <= 3'b111; //If Ready is true, rst count to default (MSB)

      else if ((Leading_Edge_r & ~CPHA) | (Trailing_Edge_r & CPHA)) begin
        o_MISO_Byte[MISO_Bit_Count_r] <= MISO;  // Sample data
        MISO_Bit_Count_r <= MISO_Bit_Count_r - 1'b1;
        if (MISO_Bit_Count_r == 3'b000) o_MISO_DV   <= 1'b1;
      end
    end
  end
  
  
  //Add clock delay to signals because we are basing the output of SCK on Leading_Edge_r which is a cycle behind
  always @(posedge clk or posedge rst) begin
    if (rst) SCK  <= CPOL;
    else SCK <= SCK_r;
  end

endmodule // SPI_Master

