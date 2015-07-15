`timescale 1ns / 1ps
/// Soft-core (MCU) for operating as an I2C master
/// @author Daniel Casner <www.danielcasner.org>

module i2cmcu #(
  parameter NUM_OUTPUT_REG = 1
)
(
  input            clk, ///< processor clock
  inout 	   sda, ///< I2C data
  inout 	   scl, ///< I2C clock
  output reg [7:0] outReg[0:NUM_OUPUT_REG-1] ///< Output (result) registers
);

  reg  [7:0] 	   pcntr;       ///< Program counter
  reg  [7:0] 	   retPtr;      ///< Return pointer
  reg  [7:0] 	   pRegs[0:3];  ///< i2c mcu internal registers
  reg 		   fetchWait;	 ///< Block for fetch wait
  wire [15:0] 	   instruction; ///< Instruction from RAM
  wire 	           instRE;      ///< Instruction read enable

  /// Block RAM storing the i2c softcore program
  SB_RAM256x16 progRAM (
			.WDATA(16'h0000), // Program is initalized during chip programming.
			.MASK(16'hFFFF),  // We don't write to the program RAM.
			.WADDR(8'h00),
			.WE(1'b0),
			.WCLKE(1'b0),
			.WCLK(clk),
			.RDATA(instruction),
			.RADDR(pcntr),
			.RE(instRE),
			.RCLKE(instRE),
			.RCLK(clk)
			);

   /// Low level I2C IP
   iCE_I2C i2c (

		);

   initial begin
      outReg <= (others 8'h00);
      pcntr  <= 8'h00;
      retPtr <= 8'h00;
      pRegs  <= (others 8'h00);
      fetchWait <= 1'b1;
      instRE <= 1'b1;
   end
   always @(posedge clk) begin
      if (nReset == 1'b0) begin
	 pcntr  = 8'h00;
	 pRegs  = (others 8'h00);
	 fetchWait = 1'b1;
      end
      else begin
	 if (fetchWait == 1'b1) begin // Waiting for instruction to fetch from RAM
	    fetchWait <= 1'b0; // Clear flags
	    i2cStop   <= 1'b0;
	 end
	 else begin
	    fetchWait <= 1'b1;
	    if (instruction == 16'h0000) begin // No operation
	       pcntr <= pcntr + 1;
	    end
	    else if (instruction == 16'h0001) begin // Reset
	       pcntr <= 0;
	    end
	    else if (instruction == 16'h0002) begin // Halt
	       instRE <= 1'b0;
	    end
	    else if (instruction == 16'h0003) begin // Return
	       pcntr  <= retPtr;
	       retPtr <= 8'h00;
	    end
	    else if (instruction == 16'h0004) begin // I2C stop
	       i2cStop <= 1'b1;
	    end
	    else if (instruction[15:12] == 4'h1) begin // Write to internal register
	       pRegs[instruction[11:10]] <= instruction[:0];
	    end
	    else if (instruction[15:12] == 4'h2) begin // Write to output
	       outReg[instruction[15:
	 end
      end
   end
   
   

endmodule
