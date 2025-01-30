module csr (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire [11:0] addr_i,
    input  wire [31:0] wdata_i,
    input  wire        irq_i,
    input  wire [31:0] pc_i,
    input  wire        write_i,
    input  wire        set_i,
    input  wire        clear_i,
    input  wire        interrupt_i,
    input  wire        mret_i,
    output wire [31:0] rdata_o,
    output wire [31:0] mtvec_o,
    output wire [31:0] mepc_o,
    output wire        ipending_o
);

  //! Don't change the following definition.
  //! Should be used for storing the CSR registers values as
  //! described in the assignment.
  reg [31:0] mstatus_r, mie_r, mtvec_r, mepc_r, mcause_r, mip_r;

  // Internal wires
  reg [31:0] next_mstatus_r;
  reg [31:0] next_mie_r;
  reg [31:0] next_mtvec_r;
  reg [31:0] next_mepc_r;
  reg [31:0] next_mcause_r;
  reg [31:0] next_mip_r;

  // Local parameters
  // Addresses
  localparam MSTATUS_ADDR = 12'h300;
  localparam MIE_ADDR     = 12'h304;
  localparam MTVEC_ADDR   = 12'h305;
  localparam MEPC_ADDR    = 12'h341;
  localparam MCAUSE_ADDR  = 12'h342;
  localparam MIP_ADDR     = 12'h344;

  // Masks
  localparam MSTATUS_MASK = 32'h00001888;
  localparam MIE_MASK     = 32'h00000800;
  localparam MCASUE_MASK  = 32'h80000800;
  localparam MIP_MASK     = 32'h00000800;

  // Reset values
  localparam MSTATUS_RST  = 32'h00001800;

  always @(*) begin
    next_mstatus_r = mstatus_r;
    next_mie_r     = mie_r;
    next_mtvec_r   = mtvec_r;
    next_mepc_r    = mepc_r;
    next_mcause_r  = mcause_r;
    next_mip_r     = mip_r;
    if (write_i && !set_i && !clear_i) begin
      case (addr_i)
        MSTATUS_ADDR: begin
          next_mstatus_r = (wdata_i | MSTATUS_RST);
        end
        MIE_ADDR: begin
          next_mie_r = (wdata_i & MIE_MASK);
        end
        MTVEC_ADDR: begin
          next_mtvec_r = wdata_i;
        end
        MEPC_ADDR: begin
          next_mepc_r = wdata_i;
        end
        MCAUSE_ADDR: begin
          next_mcause_r = (wdata_i & MCASUE_MASK);
        end
        MIP_ADDR: begin
          next_mip_r = (wdata_i & MIP_MASK);
        end
        default: begin
        end
      endcase
    end else if (!write_i && set_i && !clear_i) begin
      case (addr_i)
        MSTATUS_ADDR: begin
          next_mstatus_r = ((wdata_i | mstatus_r) & MSTATUS_MASK);
        end
        MIE_ADDR: begin
          next_mie_r = ((wdata_i | mie_r) & MIE_MASK);
        end
        MTVEC_ADDR: begin
          next_mtvec_r = (wdata_i | mtvec_r);
        end
        MEPC_ADDR: begin
          next_mepc_r = (wdata_i | mepc_r);
        end
        MCAUSE_ADDR: begin
          next_mcause_r = ((wdata_i | mcause_r) & MCASUE_MASK);
        end
        MIP_ADDR: begin
          next_mip_r = ((wdata_i | mip_r) & MIP_MASK);
        end
        default: begin
        end
      endcase
    end else if (!write_i && !set_i && clear_i) begin
      case (addr_i)
        MSTATUS_ADDR: begin
          next_mstatus_r = ((mstatus_r & ~wdata_i) & MSTATUS_MASK);
        end
        MIE_ADDR: begin
          next_mie_r = ((mie_r & ~wdata_i) & MIE_MASK);
        end
        MTVEC_ADDR: begin
          next_mtvec_r = (mtvec_r & ~wdata_i);
        end
        MEPC_ADDR: begin
          next_mepc_r = (mepc_r & ~wdata_i);
        end
        MCAUSE_ADDR: begin
          next_mcause_r = ((mcause_r & ~wdata_i) & MCASUE_MASK);
        end
        MIP_ADDR: begin
          next_mip_r = ((mip_r & ~wdata_i) & MIP_MASK);
        end
        default: begin
        end
      endcase
    end
    if (irq_i) begin
      next_mip_r[11] = mstatus_r[3] & mie_r[11];
    end
    if (interrupt_i) begin
      next_mepc_r = pc_i;
      next_mstatus_r[7] = mstatus_r[3];
      next_mstatus_r[3] = 1'b0;
      next_mcause_r[31] = 1'b1;
      next_mcause_r[11] = 1'b1;
      next_mip_r[11]    = 1'b0;
    end
    if (mret_i) begin
      next_mstatus_r[3] = mstatus_r[7];
    end
  end

  // Write logic
  always @(posedge clk_i) begin
    if (!rst_ni) begin
      mstatus_r <= MSTATUS_RST;
      mie_r     <= 32'h0;
      mtvec_r   <= 32'h0;
      mepc_r    <= 32'h0;
      mcause_r  <= 32'h0;
      mip_r     <= 32'h0;
    end else begin
      mstatus_r <= next_mstatus_r;
      mie_r     <= next_mie_r;
      mtvec_r   <= next_mtvec_r;
      mepc_r    <= next_mepc_r;
      mcause_r  <= next_mcause_r;
      mip_r     <= next_mip_r;
    end
  end

  // Asychronous read
  assign rdata_o =
    addr_i == MSTATUS_ADDR ? mstatus_r :
    addr_i == MIE_ADDR     ? mie_r :
    addr_i == MTVEC_ADDR   ? mtvec_r :
    addr_i == MEPC_ADDR    ? mepc_r :
    addr_i == MCAUSE_ADDR  ? mcause_r :
    addr_i == MIP_ADDR     ? mip_r :
    32'h0;
  assign mtvec_o = mtvec_r;
  assign mepc_o  = mepc_r;
  assign ipending_o = mip_r != 32'b0;

endmodule
