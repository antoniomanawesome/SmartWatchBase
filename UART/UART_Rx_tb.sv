`timescale 1ns/10ps

module UART_Rx_tb ();
//This testbench is only for my FPGA clock frequency (50MHz) and baud rate (115200 bits/s)

localparam int c_FPGA_clk_freq = 50000000;
localparam int c_baudrate = 115200;
parameter c_CLOCK_PERIOD_NS = 20; //1/(FPGA clk frequency) in nanoseconds
parameter c_BIT_PERIOD = 8680; //1/baudrate

logic clk = 1'b0;
logic RX_Serial_r = 1'b1;
logic RX_DV;
logic [7:0] RX_Byte;

//Takes in input byte and serializes it
//OLD
task UART_WRITE_BYTE;
    input [7:0] i_Data;
    begin
        //Send Start Bit
        RX_Serial_r <= 1'b0;
        #(c_BIT_PERIOD);

        //Send Data Byte
        for(int i=0; i<8;i++) begin
            RX_Serial_r <= i_Data[i];
            #(c_BIT_PERIOD);
        end

        //Send Stop Bit
        RX_Serial_r <= 1'b1;
        #(c_BIT_PERIOD);
    end
endtask //UART_WRITE_BYTE


UART_Rx #(
    .FPGA_clk_freq(c_FPGA_clk_freq),
    .baudrate(c_baudrate)) UART_RX_INST_l
    (
        .clk(clk),
        .i_RX_Serial(RX_Serial_r),
        .o_RX_DV(RX_DV),
        .o_RX_Byte(RX_Byte)
    );

always #(c_CLOCK_PERIOD_NS/2) clk <= !clk;

//main test
initial begin
    //Send command to UART
    @(posedge clk);
    UART_WRITE_BYTE(8'h37);
    @(posedge clk);

    //Check that correct command was received
    if(RX_Byte == 8'h37) $display("Test Passed - Correct Byte Received");
    else $display("Test Failed - Incorrect Byte Received");
    $finish();
end

initial begin
    //Required to dump signals to EPWave
    $dumpfile("dump.vcd");
    $dumpvars(0);
end

endmodule