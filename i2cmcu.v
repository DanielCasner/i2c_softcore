/// Soft-core (MCU) for operating as an I2C master
/// @author Daniel Casner <www.danielcasner.org>

module i2cmcu #(
	parameter NUM_OUTPUT_REG = 1
)
(
	input 	   nReset,
	input 	   clk,
	inout 	   sda,
	inout 	   scl,
	output reg [7:0] outReg[0:NUM_OUPUT_REG-1]
);

	reg  [7:0]  pcntr;       ///< Program counter
	reg  [7:0]  pRegs[0:3];  ///< i2c mcu internal registers
	reg         fetchWait;	 ///< Block for fetch wait
	wire [15:0] instruction; ///< Instruction from RAM
	wire        instRE;      ///< Instruction read enable
	wire        instClkE;    ///< Instruction RAM clock enable

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
		.RCLKE(instClkE),
		.RCLK(clk)
	);

	/// Low level I2C IP
	iCE_I2C i2c (

	);

	initial begin
		outReg = (others 8'h00);
		pcntr  = 8'h00;
		pRegs  = (others 8'h00);
		fetchWait = 1'b1;
	end
	always @(posedge clk)
		if (nReset == 1'b0) begin
			pcntr  = 8'h00;
			pRegs  = (others 8'h00);
			fetchWait = 1'b1;
		else begin
			if (fetchWait == 1'b1) begin // Waiting for instruction to fetch from RAM
				fetchWait <= 1'b0; // Clear flag
			end
			else begin
			
			end
		end
	end



endmodule
