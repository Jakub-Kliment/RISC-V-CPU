module register_file (
    input  wire        clk_i,
    input  wire [ 4:0] aa_i,
    input  wire [ 4:0] ab_i,
    input  wire [ 4:0] aw_i,
    input  wire        wren_i,
    input  wire [31:0] wrdata_i,
    output wire [31:0] a_o,
    output wire [31:0] b_o
);
  /////////////////////
  // Internal Registers
  /////////////////////
  //! Do not rename the reg_array_r signal
  //! Use it to store the register file contents
  reg [31:0] reg_array_r[32];

  // Set the value to 0 at address 0
  initial begin
    reg_array_r[0] = 32'b0;
  end

  // Assign read values
  assign a_o = reg_array_r[aa_i];
  assign b_o = reg_array_r[ab_i];

  always @(posedge clk_i) begin
    if (wren_i && aw_i != 5'b0) begin
      reg_array_r[aw_i] <= wrdata_i;
    end
  end

endmodule
