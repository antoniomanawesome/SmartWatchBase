module SPI_Master_tb();
    parameter int SPI_MODE = 3;
    parameter int CLKS_PER_HALF_BIT = 4; //6.25 MHz
    parameter int MAIN_CLK_DELAY = 2; //25 MHz

    logic rst = 1'b1;
    logic SPI_CLK;
    logic clk = 1'b0;
    logic MOSI;

    //Master signals
    logic [7:0] Master_MOSI_Byte_r = '0;
    logic Master_MOSI_DV_r = 1'b0;
    logic Master_MOSI_Ready;
    logic Master_MISO_DV_r;
    logic [7:0] Master_MISO_Byte_r;

    always #(MAIN_CLK_DELAY) clk = ~clk;

    SPI_Master
    #(
        .SPI_MODE(SPI_MODE),
        .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)
    ) SPI_Master_INST_l
    (
        //FPGA Data Signals
        .rst(rst),
        .clk(clk),

        //MOSI Signals
        .i_MOSI_Byte(Master_MOSI_Byte_r), //Byte to transmit MOSI
        .i_MOSI_DV(Master_MISO_DV_r), //Data valid
        .o_MOSI_Ready(Master_MOSI_Ready), //Transmit ready

        //MISO Signals
        .o_MISO_DV(Master_MISO_DV_r), //Data valid
        .o_MISO_Byte(Master_MISO_Byte_r), //Byte received MISO

        //SPICK Signals
        .SPI_CLK(SPI_CLK),
        .MISO(MOSI),
        .MOSI(MOSI)

    );

    task SendSingleByte(input [7:0] data);
        @(posedge clk);
        Master_MOSI_Byte_r <= data;
        Master_MOSI_DV_r <= 1'b1;
        @(posedge clk);
        Master_MOSI_DV_r <= 1'b0;
        @(posedge Master_MOSI_Ready);

    endtask //SendSingleByte

    initial begin
        repeat(10) @(posedge clk);
        rst = 1'b1;
        repeat(10) @(posedge clk);
        rst = 1'b0;

        //Testing single Byte
        SendSingleByte(8'h37);
        $display("Send out 0x37 and Received 0x%X", Master_MISO_Byte_r);
        
        //Testing double byte
        SendSingleByte(8'h38);
        $display("Send out 0x38 and Received 0x%X", Master_MISO_Byte_r);
        SendSingleByte(8'h39);
        $display("Send out 0x39 and Received 0x%X", Master_MISO_Byte_r);
        repeat(10) @(posedge clk);
        $finish();
    end

endmodule