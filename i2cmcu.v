`timescale 1ns / 1ps
/// Soft-core (MCU) for operating as an I2C master
/// @author Daniel Casner <www.danielcasner.org>

module i2cmcu #(
  parameter NUM_OUTPUT_REG = 1
  )
  (
    input      clk, ///< processor clock
    inout 	   sda, ///< I2C data
    inout 	   scl, ///< I2C clock
    output reg [7:0] outReg[0:NUM_OUPUT_REG-1] ///< Output (result) registers
  );

  reg  [7:0] 	   pcntr;       ///< Program counter
  reg  [7:0] 	   retPtr;      ///< Return pointer
  reg  [7:0] 	   pRegs[0:3];  ///< i2c mcu internal registers
  reg 		       fetchWait;	  ///< Block for fetch wait
  wire [15:0] 	 instruction; ///< Instruction from RAM
  wire 	         instRE;      ///< Instruction read enable

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

   reg  [9:0] i2cDataTx;
   wire [7:0] i2cDataRx;
   wire       i2xRxStrobe;
   reg        i2cReadNWrite;
   reg        i2cStart;
   reg        i2cStop;
   reg        i2cSendAck;
   wire       i2cRecvAck;
   wire       i2cBusy;


   /// Low level I2C IP
   i2c_master driver (
     .clk(clk),
     .scl(scl),
     .sda(sda),
     .dIn(i2cDataTx),
     .readNWrite(i2cReadNWrite),
     .start(i2cStart),
     .stop(i2cStop),
     .sendAck(i2cSendAck),
     .dOut(i2cDataRx),
     .dOutStrobe(i2cRxStrobe),
     .recvAck(i2cRecvAck),
     .busy(i2cBusy)
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
      i2cStart  <= 1'b0;
	    i2cStop   <= 1'b0;
	 end
	 else begin
	    if (instruction == 16'h0000) begin // No operation
         fetchWait <= 1'b1;
	       pcntr <= pcntr + 1;
	    end
	    else if (instruction == 16'h0001) begin // Reset
         fetchWait <= 1'b1;
	       pcntr <= 0;
	    end
	    else if (instruction == 16'h0002) begin // Halt
	       instRE <= 1'b0;
         fetchWait <= 1'b1;
	       pcntr <= pcntr + 1;
	    end
	    else if (instruction == 16'h0003) begin // Return
         fetchWait <= 1'b1;
	       pcntr  <= retPtr;
	       retPtr <= 8'h00;
	    end
	    else if (instruction == 16'h0004) begin // I2C stop
         i2cStop <= 1'b1;
         if (i2cBusy == 1'b0) begin
           fetchWait <= 1'b1;
           pcntr <= pcntr + 1;
          end
	    end
	    else begin
	       case(instruction[15:12])
	        4'h1:  begin // Write to internal register
	           pRegs[instruction[9:8]] <= instruction[7:0];
             fetchWait <= 1'b1;
	           pcntr <= pcntr + 1;
	        end
    	    4'h2:  begin // Write to output
    	       outReg[instruction[11:8]] <= instruction[7:0];
             fetchWait <= 1'b1;
    	       pcntr <= pcntr + 1;
    	    end
    	    4'h3:  begin // Copy register to output
    	       outReg[instructions[5:2]] <= pRegs[1:0];
             fetchWait <= 1'b1;
    	       pcntr <= pcntr + 1;
    	    end
    	    4'h4:  begin // Conditionally skip next instruction;
             fetchWait <= 1'b1;
    	       case (instruction(11:10))
          		 2'b00: begin // If register equals value
          		    if (pRegs[instruction[9:8]] == instruction[7:0]) begin
            	       pcntr <= pcntr + 2;
          		    end
          		    else begin
                     pcntr <= pcntr + 1;
          		    end
          		 end
          		 2'b01: begin // If register not equal to value
          		    if (pRegs[instruction[9:8]] != instruction[7:0]) begin
                     pcntr <= pcntr + 2;
          		    end
          		    else begin
          		       pcntr <= pcntr + 1;
          		    end
          		 end
          		 2'b10: begin // If the register and the mask value
          		    if (pRegs[instruction[9:8]] && instruction[7:0]) begin
          		       pcntr <= pcntr + 2;
          		    end
          		    else begin
          		       pcntr <= pcntr + 1;
          		    end
          		 end
          		 2'b11: begin // If the register or the mask value
          		    if (pRegs[instruction[9:8]] || instruction[7:0]) begin
          		       pcntr <= pcntr + 2;
          		    end
          		    else begin
          		       pcntr <= pcntr + 1;
          		    end
          		 end
    	       endcase // case (instruction(11:10))
    	    end // if (instruction[15:12] == 4'h4)
	        4'h5: begin // Jump
	          retPtr <= pcntr + 1;
            fetchWait <= 1'b1;
            pcntr  <= instruction[7:0];
          end
          4'h6: begin // Jump if register not and post decrement the register
            fetchWait <= 1'b1;
            if (pRegs[instruction[9:8]] != 0) begin
              retPtr <= pcntr + 1;
              pcntr  <= instruction[7:0];
              pRegs[instruction[9:8]] <= pRegs[instruction[9:8]] - 1;
            end
            else begin
              pcntr <= pcntr + 1;
            end
          end
          4'h7: begin // I2C start with device address
            i2cDataTx     <= instruction[10:1];
            i2cReadNWrite <= instruction[0];
            i2cStart      <= 1'b1;
            if (i2cBusy == 1'b0) // Wait for end of current operation
              fetchWait     <= 1'b1;
              pcntr         <= pcntr + 1;
            end;
          end
          4'h8: begin // I2C write
            case (instruction[11:8])
              4'h0: i2cDataTx <= instruction[7:0];
              4'h1: i2cDataTx <= pRegs[instruction[1:0]];
            endcase
            if (i2cBusy == 1'b0) begin
              fetchWaiter <= 1'b1;
              pcntr       <= pcntr + 1;
            end
          end
          4'h9: begin
            i2cSendAck <= instruction[0];
            if (i2cRxStrobe == 1'b1) begin
              case (instruction[11:8])
                4'h0: pRegs[instruction[2:1]]  <= i2cDataRx;
                4'h1: outReg[instruction[4:1]] <= i2cDataRx
              endcase
            end
            if (i2cBusy == 1'b0) begin // End of read
              fetchWait <= 1'b1;
              pctnr     <= pcntr + 1;
            end
          end
          4'hA: begin
            if (recvAck == 1'b0) begin
              retPtr    <= pcntr + 1;
              fetchWait <= 1'b0;
              pcntr     <= instruction[7:0];
            end
            else
              fetchWait <= 1'b1;
              pcntr     <= pctnr + 1;
            end
          end
        endcase
	    end
   end

endmodule
