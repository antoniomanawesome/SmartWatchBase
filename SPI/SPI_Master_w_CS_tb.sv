module SPI_Master_w_CS_tb;
    
parameter int SPI_MODE = 3;           // CPOL = 1, CPHA = 1
parameter int CLKS_PER_HALF_BIT = 4;  // 6.25 MHz
parameter int MAIN_CLK_DELAY = 2;     // 25 MHz
parameter int MAX_BYTES_PER_CS = 2;   // 2 bytes per chip select
parameter int CS_INACTIVE_CLKS = 10;  // Adds delay between bytes

logic rst     = 1'b1;  
logic SCK;
logic clk       = 1'b0;
logic CS_L;
logic MOSI;

logic [7:0] Master_MOSI_Byte_r = 0;
logic Master_MOSI_DV_r = 1'b0;
logic Master_MOSI_Ready;
logic Master_MISO_DV;
logic [7:0] Master_MISO_Byte;
logic [$clog2(MAX_BYTES_PER_CS+1)-1:0] Master_MISO_Count, Master_MOSI_Count_r = 2'b10;

always #(MAIN_CLK_DELAY) clk = ~clk;

SPI_Master_w_CS
  #(.SPI_MODE(SPI_MODE),
    .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT),
    .MAX_BYTES_PER_CS(MAX_BYTES_PER_CS),
    .CS_INACTIVE_CLKS(CS_INACTIVE_CLKS)
    ) UUT
  (

   .rst(rst),
   .clk(clk),
   
   //MOSI Signals
   .i_MOSI_Count(Master_MOSI_Count_r),   // Number of bytes per CS
   .i_MOSI_Byte(Master_MOSI_Byte_r),     // Byte to transmit on MOSI
   .i_MOSI_DV(Master_MOSI_DV_r),         // Data Valid Pulse with i_MOSI_Byte
   .o_MOSI_Ready(Master_MOSI_Ready),   // Transmit Ready for Byte
   
   //MISO Signals
   .o_MISO_Count(Master_MISO_Count), // Index of RX'd byte
   .o_MISO_DV(Master_MISO_DV),       // Data Valid pulse (1 clock cycle)
   .o_MISO_Byte(Master_MISO_Byte),   // Byte received on MISO

   //SPI
   .SCK(SCK),
   .MISO(MOSI),
   .MOSI(MOSI),
   .CS_L(CS_L)
   );

task SendSingleByte(input [7:0] data);
    @(posedge clk);
    Master_MOSI_Byte_r <= data;
    Master_MOSI_DV_r   <= 1'b1;
    @(posedge clk);
    Master_MOSI_DV_r <= 1'b0;
    @(posedge clk);
    @(posedge Master_MOSI_Ready);
endtask

initial begin

  repeat(10) @(posedge clk);
  rst  = 1'b1;
  repeat(10) @(posedge clk);
  rst          = 1'b0;
  
  // Test sending 2 bytes
  SendSingleByte(8'h37);
  $display("Sent out 0x37, Received 0x%X", Master_MISO_Byte); 
  SendSingleByte(8'h38);
  $display("Sent out 0x38, Received 0x%X", Master_MISO_Byte); 

  repeat(10) @(posedge clk);
  $finish();      
end

endmodule