`timescale 1ns/10ps

module UART_Rx_tb ();
    //testbench uses same clk as UART
    //Want to interface with 115200 baud
    //previous values correspond to a 25MHz clock frequency; I'm changing to 50MHz clock frequency which is what the DE10-Lite offers
    
parameter c_CLOCK_PERIOD_NS = 40; //40 previously, 20 new
parameter c_CLKS_PER_BIT = 217; //217 previously, 434 new
parameter c_BIT_PERIOD = 8680; //8600 previously, blank new

logic r_Clock = 0;
logic r_RX_Serial = 1'b1;
logic [7:0] w_RX_Byte;

//Takes in input byte and serializes it
task UART_WRITE_BYTE;
    input [7:0] i_Data;
    begin
        //Send Start Bit
        r_RX_Serial <= 1'b0;
        #(c_BIT_PERIOD);
        #1000;

        //Send Data Byte
        for(int i=0; i<8;i++) begin
            r_RX_Serial <= i_Data[i];
            #(c_BIT_PERIOD);
        end

        //Send Stop Bit
        r_RX_Serial <= 1'b1;
        #(c_BIT_PERIOD);
    end
endtask //UART_WRITE_BYTE

UART_Rx #(
    .CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_RX_INST_l
    (
        .clk(r_Clock),
        .i_RX_Serial(r_RX_Serial),
        .o_RX_DV(),
        .o_RX_Byte(w_RX_Byte)
    );

always #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;

//main test
initial begin
    //Send command to UART
    @(posedge r_Clock);
    UART_WRITE_BYTE(8'h37);
    @(posedge r_Clock);

    //Check that correct command was received
    if(w_RX_Byte == 8'h37) $display("Test Passed - Correct Byte Received");
    else $display("Test Failed - Incorrect Byte Received");
    $finish();
end

initial begin
    //Required to dump signals to EPWave
    $dumpfile("dump.vcd");
    $dumpvars(0);
end

endmodule