module UART_Rx #(

    parameter int FPGA_clk_freq = 50000000,
    parameter int baudrate = 115200
) (
    input logic         clk, //FPGA clock
    input logic         rst,
    input logic         i_RX_Serial, //serial data stream coming from computer
    output logic        o_RX_DV, //data valid
    output logic [7:0]  o_RX_Byte //the location we are storing the data stream in
);

localparam int CLKS_PER_BIT = FPGA_clk_freq / baudrate;
// (FPGA clk frequency) / (baud rate) = CLKS_PER_BIT
//DE10-Lite CLK is 50 MHz
// CLKS_PER_BIT = (frequency of clk)/(Frequency of UART)
    
//defining states for the FSM
typedef enum logic [2:0] {
    IDLE,
    START_BIT,
    DATA_BITS,
    STOP_BIT,
    CLEANUP,
    XXX
} state_t;

//state type
state_t state_r = IDLE;

//creating registers
logic [$clog2(CLKS_PER_BIT):0] Clock_Count_r = '0; //counter for the CLKS_PER_BIT, size is determined by the counter number
logic [2:0] Bit_Index_r = '0; //the index for where we are storing the data stream
logic [7:0] RX_Byte_r = '0; //reg for o_RX_Byte
logic       RX_DV_r = 1'b0; //reg for o_RX_DV

//Creating a timeout counter to see if we can restart the FSMD if it gets stuck on a state
logic [$clog2(CLKS_PER_BIT*12):0] timeout_counter = 0;
logic timeout;
always_ff @(posedge clk) begin
    if (rst || state_r == IDLE) begin
        timeout_counter <= 0;
        timeout <= 1'b0;
    end else begin
        if (timeout_counter < CLKS_PER_BIT*12)  // ~12 bit times
            timeout_counter <= timeout_counter + 1;
        else
            timeout <= 1'b1;
    end
end

//main FSMD block
always_ff @(posedge clk) begin
    if(rst) begin
        state_r <= IDLE;
        Clock_Count_r <= '0;
        Bit_Index_r <= '0;
        RX_Byte_r <= '0;
        RX_DV_r <= 1'b0;
    end else begin
        
        case(state_r)
            IDLE: begin //Data line is held high during IDLE, so we stay here until a low is received from the line
                RX_DV_r <= 1'b0;
                Clock_Count_r <= '0;
                Bit_Index_r <= '0;

                if(i_RX_Serial == 1'b0) state_r <= START_BIT; //Data line is low, indicating we are in the start bit
            end //IDLE

            START_BIT: begin //In the start bit right now
                if(Clock_Count_r == (CLKS_PER_BIT-1)/2) begin
                    if(i_RX_Serial == 1'b0) begin //When line is pulled low, check middle of start bit to make sure it's still low
                        Clock_Count_r <= '0; //Reset counter because we found the middle of the start bit
                        state_r <= DATA_BITS;
                    end else state_r <= IDLE; //Line is high, go back to IDLE
                end else begin
                    Clock_Count_r <= Clock_Count_r + 1'b1; //Increment the counter until we reach the middle of the bit
                end
            end //RX_START_BIT

            DATA_BITS: begin //Found the start bit, so now we are waiting for the data bits
                if(Clock_Count_r < CLKS_PER_BIT-1) begin //Increment counter if it's not at the max value yet
                    Clock_Count_r <= Clock_Count_r + 1'b1;
                end else begin //Counter is at its max value, which means we are in the middle of the data bit, so we sample
                    Clock_Count_r <= '0;
                    RX_Byte_r[Bit_Index_r] <= i_RX_Serial;

                    //check if we received all of the bits
                    if(Bit_Index_r < 7) begin
                        Bit_Index_r <= Bit_Index_r + 1'b1;
                    end else begin
                        Bit_Index_r <= '0;
                        state_r <= STOP_BIT;
                    end
                end
            end //RX_DATA_BITS

            STOP_BIT: begin //Check counter one last time for stop bit and assert data valid
                if(Clock_Count_r < CLKS_PER_BIT-1) begin
                    Clock_Count_r <= Clock_Count_r + 1'b1;
                end else begin
                    Clock_Count_r <= '0;

                    if(i_RX_Serial == 1'b1) begin //stop bit is reached so assert DV and move to cleanup state
                        RX_DV_r <= 1'b1;
                        state_r <= CLEANUP;
                    end else state_r <= IDLE; //framing error so discard byte
                end
            end

            CLEANUP: begin
                RX_DV_r <= 1'b0; //DV only valid for one clk cycle and go back
                state_r <= IDLE;
            end

            XXX: begin
                state_r <= XXX;
            end

            default: state_r <= IDLE;
        endcase

        if (timeout) begin
            Clock_Count_r <= 0;
            Bit_Index_r <= 0;
            RX_DV_r <= 1'b0;
            state_r <= IDLE;
        end
    end
end

//assigning registered outputs to the outputs of the module
assign o_RX_DV = RX_DV_r;
assign o_RX_Byte = RX_Byte_r;

endmodule //UART_Rx