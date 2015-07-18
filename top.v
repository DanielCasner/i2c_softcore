`timescale 1ns / 1ps
/// I2C custom soft core demo
/// @author Daniel Casner <www.danielcasner.org>

module softcore_demo (
  input  clk,  ///< Chip clock
  input  sck,  ///< SPI clock
  input  nCS,  ///< SPI chip select
  input  mosi, ///< SPI master out, slave in
  output miso, ///< SPI master in, slave out
  output leds, ///< Debug LEDs
  inout  scl,  ///< I2C clock
  inout  sda  ///< I2C data
  );

  integer NUM_RESULTS = 16;

  wire [7:0] results[0:NUM_RESULTS];

  i2cmcu #(
    .NUM_OUTPUT_REG(NUM_RESULTS)
  ) mcu0 (
    .clk(clk),
    .sda(sda),
    .scl(scl),
    .outReg(results)
  );

  reg [2:0] bitCounter;
  reg [7:0] mosiSR;
  reg [7:0] misoSR;

  assign miso = misoSR[7];

  initial begin
    bitCounter <= 0;
    mosiSR <= 8'h00;
    misoSR <= 8'h00;
  end

  always @(posedge sck) begin
    if (nCS == 1'b1) begin
      bitCoutner <= 0;
      mosiSR     <= 8'h00;
      misoSR     <= 8'h00;
    end
    else begin
      bitCounter <= bitCounter + 1;
      mosiSR <= {mosiSR[6:0], mosi};
      if (bitCounter == 0) begin
        misoSR <= outputs[mosiSR];
      end
      else begin
        misoSR <= {misoSR[6:0], 1'b0};
      end
    end
  end


  wire [2:0] debug;
  wire ledcurpu;

  assign debug = {results[13][0], results[14][0], results[15][0]};


  SB_LED_DRV_CUR currentDriver (
    .EN(1'b1),
    .LEDPU(ledcurpu)
  );

  SB_RGB_DRV #(.RGB0_CURRENT("0b000011"), .RGB1_CURRENT("0b000001"), .RGB2_CURRENT("0b000001")) ledDriver
  (
    .RGBLEDEN(1'b1),
    .RGB0PWM(debug[0]),
    .RGB1PWM(debug[1]),
    .RGB2PWM(debug[2]),
    .RGBPU(ledcurpu),
    .RGB0(rgb[0]),
    .RGB1(rgb[1]),
    .RGB2(rgb[2])
  );

endmodule
