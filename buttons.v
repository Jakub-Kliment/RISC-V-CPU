module buttons (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire        en_i,
    input  wire        we_i,
    input  wire [31:0] addr_i,
    input  wire [31:0] wdata_i,
    input  wire [ 9:0] push_i,
    input  wire [ 7:0] switch_i,
    output wire [31:0] rdata_o,
    output wire        irq_o
);
    // Internal nets (registers)
    reg [31:0] val_r;
    reg [31:0] src_r;
    reg [31:0] next_src_r;
    reg [31:0] ptm_r;
    reg [31:0] stm_r;

    // Output logic registers
    reg [31:0] addr_r;
    reg        read_r;

    // Adresses
    localparam VAL_ADDR = 32'h70000000;
    localparam SRC_ADDR = 32'h70000004;
    localparam PTM_ADDR = 32'h70000008;
    localparam STM_ADDR = 32'h7000000C;

    // Masks
    localparam SRC_MASK = 32'h00FF03FF;
    localparam PTM_MASK = 32'h000FFFFF;
    localparam STM_MASK = 32'h0000FFFF;

    // Trigger modes
    localparam ACTIVE_LOW   = 2'b00;
    localparam RISING_EDGE  = 2'b01;
    localparam FALLING_EDGE = 2'b10;
    localparam ACTIVE_HIGH  = 2'b11;

    // Next state of src logic
    always @(*) begin
        next_src_r = src_r;
        // Push buttons loop
        for (integer i = 0; i < 10; i = i + 1) begin
            case (ptm_r[2*i+:2])
                ACTIVE_LOW: begin
                    if (!push_i[i]) begin
                        next_src_r[i] = 1'b1;
                    end
                end
                RISING_EDGE: begin
                    if (!val_r[i] && push_i[i]) begin
                        next_src_r[i] = 1'b1;
                    end
                end
                FALLING_EDGE: begin
                    if (val_r[i] && !push_i[i]) begin
                        next_src_r[i] = 1'b1;
                    end
                end
                ACTIVE_HIGH: begin
                    if (push_i[i]) begin
                        next_src_r[i] = 1'b1;
                    end
                end
                default: begin
                    next_src_r[i] = 1'b0;
                end
            endcase
        end

        // Switches loop
        for (integer i = 0; i < 8; i = i + 1) begin
            case (stm_r[2*i+:2])
                ACTIVE_LOW: begin
                    if (!switch_i[i]) begin
                        next_src_r[i + 16] = 1'b1;
                    end
                end
                RISING_EDGE: begin
                    if (!val_r[i + 16] && switch_i[i]) begin
                        next_src_r[i + 16] = 1'b1;
                    end
                end
                FALLING_EDGE: begin
                    if (val_r[i + 16] && !switch_i[i]) begin
                        next_src_r[i + 16] = 1'b1;
                    end
                end
                ACTIVE_HIGH: begin
                    if (switch_i[i]) begin
                        next_src_r[i + 16] = 1'b1;
                    end
                end
                default: begin
                    next_src_r[i + 16] = 1'b0;
                end
            endcase
        end
    end

    // Write logic
    always @(posedge clk_i) begin
        if (!rst_ni) begin
            val_r    <= 32'h0;
            src_r    <= 32'h0;
            ptm_r    <= PTM_MASK;
            stm_r    <= STM_MASK;
        end else if (en_i && we_i) begin
            case (addr_i)
                SRC_ADDR: begin
                    if (wdata_i == 32'b0) begin
                        src_r <= 32'b0;
                    end
                end
                PTM_ADDR: begin
                    ptm_r <= (wdata_i & PTM_MASK);
                end
                STM_ADDR: begin
                    stm_r <= (wdata_i & STM_MASK);
                end
                default: begin
                end
            endcase
            if (addr_i != SRC_ADDR || wdata_i != 32'b0) begin
                src_r <= next_src_r;
            end
            val_r <= {8'b0, switch_i, 6'b0, push_i};
        end else begin
            src_r <= next_src_r;
            val_r <= {8'b0, switch_i, 6'b0, push_i};
        end
    end

    // Read logic
    always @(posedge clk_i) begin
        read_r <= en_i;
        addr_r <= addr_i;
    end

    // Assign output
    assign rdata_o = read_r ? (
        addr_r == VAL_ADDR ? val_r :
        addr_r == SRC_ADDR ? src_r :
        32'h0
    ) : 32'h0;
    assign irq_o = src_r != 32'b0;
endmodule
