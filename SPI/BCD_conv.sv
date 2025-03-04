module BCD_conv ( 
    input logic [3:0] number_in,
    output logic [6:0] number_out   
);

always_comb begin
    unique case(number_in)

    4'b0000 : number_out = 7'b1000000;
    4'b0001 : number_out = 7'b1111001;
    4'b0010 : number_out = 7'b0100100;
    4'b0011 : number_out = 7'b0110000;
    4'b0100 : number_out = 7'b0011001;
    4'b0110 : number_out = 7'b0000010;
    4'b0101 : number_out = 7'b0010010;
    4'b0111 : number_out = 7'b1111000;
    4'b1000 : number_out = 7'b0000000;
    4'b1001 : number_out = 7'b0010000;
    4'b1010 : number_out = 7'b0001000;
    4'b1011 : number_out = 7'b0000011;
    4'b1100 : number_out = 7'b1000110;
    4'b1101 : number_out = 7'b0100001;
    4'b1110 : number_out = 7'b0000110;
    4'b1111 : number_out = 7'b0001110;

    endcase
end
endmodule