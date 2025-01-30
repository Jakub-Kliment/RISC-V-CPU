module shift_unit (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire [ 2:0] op_i,
    input  wire        arithmetic_i,
    output wire [31:0] r_o
);
    // Assign the output
    assign r_o = (op_i == 3'b001)                  ? (a_i << b_i[4:0]) :
                 (op_i == 3'b101 && ~arithmetic_i) ? (a_i >> b_i[4:0]) :
                 (op_i == 3'b101 &&  arithmetic_i) ? $signed(($signed(a_i) >>> b_i[4:0])) :
                 32'b0;
endmodule
