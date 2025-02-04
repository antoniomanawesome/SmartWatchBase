module UART_Rx_tb ();
    //testbench uses same clk as UART
    //Want to interface with 115200 baud
    
parameter c_CLOCK_PERIOD_NS = 40;
parameter c_CLKS_PER_BIT = 217;
parameter c_BIT_PERIOD = 8600;

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