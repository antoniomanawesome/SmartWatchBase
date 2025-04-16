// Use UART_Rx to receive data from watch
// Store data in FIFO until special char is received
// Use UART_Tx to send FIFO data to esp32 until empty 


module WatchBase #(
    parameter int FPGA_clk_freq = 50000000,
    parameter int baudrate = 115200
    parameter int WIDTH = 8,
    parameter int DEPTH = 16
) (
    input logic         clk,
    input logic         rst,

    // UART RX signals
    input logic         i_RX_Serial,
    output logic        o_RX_DV,

    // UART TX signals
    output logic        o_TX_Active,
    output logic        o_TX_Serial,
    output logic        o_TX_Done
);

//FIFO signals
logic             full,
logic             wr_en,
logic [WIDTH-1:0] wr_data,
logic             empty,
logic             rd_en,
logic [WIDTH-1:0] rd_data



//Receive data from the watch
UART_Rx #(
    .FPGA_clk_freq(FPGA_clk_freq),
    .baudrate(baudrate)) UART_RX_INST_l
    (
        .clk(clk),
        .rst(rst),
        .i_RX_Serial(i_RX_Serial),
        .o_RX_DV(o_RX_DV),
        .o_RX_Byte(wr_data)
    );

//Store data in FIFO until full
fifo #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
) FIFO_INST_l (
    .clk(clk),
    .rst(rst),
    .full(full),
    .wr_en(),
    .wr_data(),
    .empty(empty),
    .rd_en(),
    .rd_data()
    
);

//Send FIFO data to esp32 until empty

//TX_DV should be (full | !empty)

UART_Tx #(
    .FPGA_clk_freq(FPGA_clk_freq),
    .baudrate(cbaudrate)) UART_TX_INST_l
    (
        .clk(clk),
        .rst(rst),
        .i_TX_DV(full | !empty),
        .i_TX_Byte(rd_data),
        .o_TX_Active(o_TX_Active),
        .o_TX_Serial(o_TX_Serial),
        .o_TX_Done(o_TX_Done)
    );

endmodule