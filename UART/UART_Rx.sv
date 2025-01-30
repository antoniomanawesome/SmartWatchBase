module UART_Rx #(
    parameter int CLKS_PER_BIT = 217 //based on frequency of the clock divided by the uart
    // (FPGA clk) / (baud rate) = CLKS_PER_BIT
    // CLKS_PER_BIT = (frequency of i_Clock)/(Frequency of UART)
) (
    input logic         clk, //FPGA clock
    input logic         i_RX_Serial, //serial data stream coming from computer
    output logic        o_RX_DV, //data valid
    output logic [7:0]  o_RX_Byte //the byte we receive from computer
);
    
localparam logic [2:0] IDLE         = 3'b000;
localparam logic [2:0] RX_START_BIT = 3'b001;
localparam logic [2:0] RX_DATA_BITS = 3'b010;
localparam logic [2:0] RX_STOP_BIT  = 3'b011;
localparam logic [2:0] CLEANUP      = 3'b100;

always_ff @(posedge clk) begin
    
end






endmodule //UART_Rx