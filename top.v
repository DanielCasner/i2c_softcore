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



   

endmodule
   
