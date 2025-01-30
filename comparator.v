module comparator (
    input  wire       a_31_i,
    input  wire       b_31_i,
    input  wire       diff_31_i,
    input  wire       carry_i,
    input  wire       zero_i,
    input  wire [2:0] op_i,
    output wire       r_o
);
    // Assign output of the comparison
    assign r_o = (op_i == 3'b000) ? zero_i  :
                 (op_i == 3'b001) ? ~zero_i :
                 (op_i == 3'b100) ? (( a_31_i & ~b_31_i) |
                                        ((a_31_i ~^ b_31_i)) &  diff_31_i) :
                 (op_i == 3'b101) ? ((~a_31_i &  b_31_i) |
                                        ((a_31_i ~^ b_31_i)) & ~diff_31_i) :
                 (op_i == 3'b110) ? (~carry_i & ~zero_i) :
                 (op_i == 3'b111) ? ( carry_i |  zero_i) :
                 1'b0;
endmodule
