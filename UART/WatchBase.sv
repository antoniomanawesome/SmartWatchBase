// Use UART_Rx to receive data from watch
// Store data in FIFO until special char is received
// Use UART_Tx to send FIFO data to esp32 until empty 


module WatchBase #(
    parameter int FPGA_clk_freq = 50000000,
    parameter int baudrate = 115200,
    parameter int WIDTH = 8,
    parameter int DEPTH = 4
) (
    input logic         clk,
    input logic         rst,

    // UART RX signals
    input logic         i_RX_Serial,

    // UART TX signals
    output logic        UART_Line,

    // Signals required for testbench
    output logic o_TX_Serial,
    output logic o_TX_Done


);

// Internal FIFO signals
logic             fifo_rst;
logic             full;
logic             wr_en;
logic [WIDTH-1:0] wr_data;
logic             empty;
logic             rd_en;
logic [WIDTH-1:0] rd_data;

// Internal UART TX signals
logic            o_TX_Active;
//logic            o_TX_Serial;

assign UART_Line = o_TX_Active ? o_TX_Serial : 1'b1; // keeps UART line high when transmitter is not active

// Receive data from the watch
UART_Rx #(
    .FPGA_clk_freq(FPGA_clk_freq),
    .baudrate(baudrate)) UART_RX_INST_l
    (
        .clk(clk),
        .rst(rst),
        .i_RX_Serial(i_RX_Serial),
        .o_RX_DV(wr_en),
        .o_RX_Byte(wr_data)
    );

// Store data in FIFO until full
fifo #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
) FIFO_INST_l (
    .clk(clk),
    .rst(fifo_rst),
    .full(full),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .empty(empty),
    .rd_en(rd_en),
    .rd_data(rd_data)
);

// Send FIFO data to esp32 until empty

UART_Tx #(
    .FPGA_clk_freq(FPGA_clk_freq),
    .baudrate(baudrate)) UART_TX_INST_l
    (
        .clk(clk),
        .rst(rst),
        .i_TX_DV(rd_en), // Want to start as soon as full and finish when empty
        .i_TX_Byte(rd_data),
        .o_TX_Active(o_TX_Active),
        .o_TX_Serial(o_TX_Serial),
        .o_TX_Done(o_TX_Done) // Packet is done when FIFO is empty
    );

typedef enum logic [2:0] {
    IDLE,
    TRANSMIT,
    STOP,
    XXX
} state_t;

state_t state_r = IDLE;

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        rd_en <= 1'b0;
        state_r <= IDLE;
        fifo_rst <= 1'b1;
    end else begin
        case(state_r)
            IDLE : begin
                if(full) state_r <= TRANSMIT;
            end

            TRANSMIT : begin
                if(!empty) begin
                    rd_en <= 1'b1;

                end else begin
                    rd_en <= 1'b0;
                    state_r <= STOP;
                end
            end

            STOP : begin
                fifo_rst <= 1'b1;
                if(empty) begin
                    fifo_rst <= 1'b0;
                    state_r <= IDLE;
                end
            end
        endcase
    end
end

endmodule