module spi_peripheral (
  input wire clk,
  input wire rst_n,

  // SPI Inputs
  input wire SCLK,
  input wire COPI,
  input wire nCS,

  // Outputs to Peripherals
  output reg [7:0] en_reg_out_7_0,
  output reg [7:0] en_reg_out_15_8,
  output reg [7:0] en_reg_pwm_7_0,
  output reg [7:0] en_reg_pwm_15_8,
  output reg [7:0] pwm_duty_cycle 
);

reg [1:0] COPI_sync;
reg [1:0] nCS_sync;
reg [2:0] SCLK_sync;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    COPI_sync <= 2'b00;
    nCS_sync <= 2'b11;
    SCLK_sync <= 3'b000;
  end else begin
    COPI_sync <= {COPI_sync[0], COPI};
    nCS_sync <= {nCS_sync[0], nCS};
    SCLK_sync <= {SCLK_sync[1:0], SCLK};
  end
end

wire COPI_stable = COPI_sync[1];
wire nCS_stable = nCS_sync[1];
wire SCLK_posedge = SCLK_sync[1] & ~SCLK_sync[2];

reg [15:0]  command;
reg [4:0]   bit_count;

always @ (posedge clk) begin
  if (!rst_n) begin
    command         <= 16'b0;
    bit_count       <= 5'b0;
    en_reg_out_7_0  <= 8'h00;
    en_reg_out_15_8 <= 8'h00;
    en_pwm_out_7_0  <= 8'h00;
    en_pwm_out_15_8 <= 8'h00;
    pwm_duty_cycle  <= 8'h00;

  end else begin

    if (!nCS_stable) begin
      // Peripheral Selected for Transactions
      if (SCLK_posedge) begin 
        command   <= {command[14:0], COPI_stable};
        bit_count <= bit_count + 1'b1;
      end
    end else begin
      // Transaction Completed
      if (bit_count == 5'd16) begin
        // Write Command Branch
        if (command[15] == 1'b1) begin
          case (command[14:8])
            7'b00: en_reg_out_7_0   <= command[7:0];
            7'b01: en_reg_out_15_8  <= command[7:0];
            7'b02: en_pwm_out_7_0   <= command[7:0];
            7'b03: en_pwm_out_15_8  <= command[7:0];
            7'b04: pwm_duty_cycle   <= command[7:0];
            default: ;
          endcase
        end
      end
      bit_count <= 5'b0;
    end
  end
end