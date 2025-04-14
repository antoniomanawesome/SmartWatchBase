module UART_Tx #(
    parameter int FPGA_clk_freq = 50000000,
    parameter int baudrate = 115200
) (
    input logic         clk,
    input logic         rst,
    input logic         i_TX_DV,
    input logic [7:0]   i_TX_Byte,
    output logic        o_TX_Active,
    output logic        o_TX_Serial,
    output logic        o_TX_Done
);

localparam int CLKS_PER_BIT = FPGA_clk_freq / baudrate;

typedef enum logic [2:0] {
    IDLE,
    START_BIT,
    DATA_BITS,
    STOP_BIT,
    CLEANUP,
    XXX
} state_t;

state_t state_r = IDLE;

logic [$clog2(CLKS_PER_BIT):0] Clock_Count_r = '0;
logic [2:0] Bit_Index_r = '0;
logic [7:0] TX_Data_r = '0;
logic       TX_Active_r = 1'b0;
logic       TX_Done_r = 1'b0;

always_ff @(posedge clk) begin
    if(rst) begin
        state_r <= IDLE;
        Clock_Count_r <= '0;
        Bit_Index_r <= '0;
        TX_Data_r <= '0;
        TX_Active_r <= 1'b0;
        TX_Done_r <= 1'b0;
    end else begin
        case(state_r)
            IDLE: begin
                o_TX_Serial <= 1'b1; // idle state is high
                TX_Done_r <= 1'b0;
                Clock_Count_r <= '0;
                Bit_Index_r <= '0;

                if(i_TX_DV) begin
                    TX_Active_r <= 1'b1;
                    TX_Data_r <= i_TX_Byte; // load the data
                    state_r <= START_BIT;
                end
            end

            START_BIT: begin
                o_TX_Serial <= 1'b0; // line is pulled low
                if(Clock_Count_r < CLKS_PER_BIT - 1) Clock_Count_r <= Clock_Count_r + 1;
                else begin
                    Clock_Count_r <= '0;
                    state_r <= DATA_BITS;
                end
            end

            DATA_BITS: begin
                o_TX_Serial <= TX_Data_r[Bit_Index_r]; // send the data bit

                if(Clock_Count_r < CLKS_PER_BIT - 1) Clock_Count_r <= Clock_Count_r + 1; // increment the clock count
                else begin
                    Clock_Count_r <= '0;
                    if(Bit_Index_r < 7) Bit_Index_r <= Bit_Index_r + 1; // check to see if we sent all bits
                    else begin
                        Bit_Index_r <= '0; // reset the bit index
                        state_r <= STOP_BIT; // move to stop bit state
                    end
                end
            end

            STOP_BIT: begin
                o_TX_Serial <= 1'b1; // line is pulled high

                if(Clock_Count_r < CLKS_PER_BIT - 1) Clock_Count_r <= Clock_Count_r + 1;
                else begin
                    Clock_Count_r <= '0;
                    TX_Done_r <= 1'b1; // transmission is done
                    TX_Active_r <= 1'b0; // reset active signal
                    state_r <= CLEANUP; // move to cleanup state
                end
            end

            CLEANUP: begin //stay for a clk cycle
                state_r <= IDLE;
            end

            XXX: state_r <= XXX;

            default: state_r <= IDLE;
            
        endcase
    end
end

assign o_TX_Active = TX_Active_r;
assign o_TX_Done = TX_Done_r;


endmodule