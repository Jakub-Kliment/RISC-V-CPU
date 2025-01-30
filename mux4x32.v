module mux4x32 (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire [31:0] c_i,
    input  wire [31:0] d_i,
    input  wire [ 1:0] sel_i,
    output wire [31:0] o_o
);
    // Assign output value
    assign o_o = (sel_i == 2'b00) ? a_i :
                 (sel_i == 2'b01) ? b_i :
                 (sel_i == 2'b10) ? c_i :
                 (sel_i == 2'b11) ? d_i :
                 32'b0;
endmodule
