module WatchBase_tb;

    localparam FPGA_clk_freq = 50000000;
    localparam baudrate = 115200;
    localparam WIDTH = 8;
    localparam DEPTH = 4;
    localparam c_CLOCK_PERIOD_NS = 20; //1/(FPGA clk frequency) in nanoseconds
    localparam c_BIT_PERIOD = 8680; //1/baudrate

    logic clk;
    logic rst;
    logic i_RX_Serial;
    logic o_TX_Serial;
    logic UART_Line;
    logic o_TX_Done;

    WatchBase #(
        .FPGA_clk_freq(FPGA_clk_freq),
        .baudrate(baudrate),
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) WatchBase_INST_l (
        .clk(clk),
        .rst(rst),
        .i_RX_Serial(i_RX_Serial),
        .UART_Line(UART_Line),
        .o_TX_Done(o_TX_Done),
        .o_TX_Serial(o_TX_Serial)
    );

    initial begin : generate_clock
        clk <= 1'b0;
        forever #(c_CLOCK_PERIOD_NS/2) clk <= !clk;
    end

    task UART_WRITE_BYTE;
    input [7:0] i_Data;
    begin
        @(posedge clk);
        //Send Start Bit
        i_RX_Serial <= 1'b0;
        #(c_BIT_PERIOD);

        //Send Data Byte
        for(int i=0; i<8;i++) begin
            i_RX_Serial <= i_Data[i];
            #(c_BIT_PERIOD);
        end

        //Send Stop Bit
        i_RX_Serial <= 1'b1;
        #(c_BIT_PERIOD);
        @(posedge clk);
    end
endtask //UART_WRITE_BYTE

    initial begin
        rst     <= 1'b1;
        i_RX_Serial <= 1'b1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst <= 1'b0;

        @(posedge clk);
        UART_WRITE_BYTE(8'h37);
        UART_WRITE_BYTE(8'h38);
        UART_WRITE_BYTE(8'h39);
        UART_WRITE_BYTE(8'h40);

        @(posedge o_TX_Done);

        disable generate_clock;
        $display("Tests Completed.");
    end





endmodule