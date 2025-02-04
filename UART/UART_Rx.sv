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
    
typedef enum logic [2:0] {
    IDLE,
    RX_START_BIT,
    RX_DATA_BITS,
    RX_STOP_BIT,
    CLEANUP
} state_t;

state_t state_r;

logic [7:0] r_Clock_Count = '0;
logic [2:0] r_Bit_Index = '0;
logic [7:0] r_RX_Byte = '0;
logic       r_RX_DV = 1'b0;
logic [2:0] r_SM_Main = '0;



always_ff @(posedge clk) begin
    case(state_r)
        IDLE: begin //Data line is held high during IDLE, so we stay here until a low is received from the line
            r_RX_DV <= 1'b0;
            r_Clock_Count <= '0;
            r_Bit_Index <= '0;

            if(i_RX_Serial == 1'b0) state_r <= RX_START_BIT;
        end //IDLE

        RX_START_BIT: begin //When line is pulled low, check middle of start bit to make sure it's still low
            if(r_Clock_Count == (CLKS_PER_BIT-1)/2) begin
                if(i_RX_Serial == 1'b0) begin
                    r_Clock_Count <= '0; //reset counter because we found the middle of the start bit
                    state_r <= RX_DATA_BITS;
                end else state_r <= IDLE; //line is high, go back to IDLE
            end else begin
                r_Clock_Count <= r_Clock_Count + 1;
            end
        end //RX_START_BIT

        RX_DATA_BITS: begin //Found the start bit, so now we are waiting for the data bits
            if(r_Clock_Count < CLKS_PER_BIT-1) begin
                r_Clock_Count <= r_Clock_Count + 1;
            end else begin
                r_Clock_Count <= '0;
                r_RX_Byte[r_Bit_Index] <= i_RX_Serial;

                //check if we received all of the bits
                if(r_Bit_Index < 7) begin
                    r_Bit_Index <= r_Bit_Index + 1;
                end else begin
                    r_Bit_Index <= '0;
                    state_r <= RX_STOP_BIT
                end
            end
        end //RX_DATA_BITS

        RX_STOP_BIT: begin
            if(r_Clock_Count < CLKS_PER_BIT-1) begin
                r_Clock_Count <= r_Clock_Count + 1;
            end else begin
                r_RX_DV <= 1'b1;
                r_Clock_Count <= '0;
                state_r <= CLEANUP;
            end
        end

        CLEANUP: begin //stay here 1 clock
            r_RX_DV <= 1'b0;
            state_r <= IDLE;
        end

    endcase;

end


endmodule //UART_Rx