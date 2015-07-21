`timescale 1ns / 1ps
/// Basic I2C master driver with minimal internal state
/// @author Daniel Casner <www.danielcasner.org>

module i2c_master #(
  parameter CLOCK_IN_HZ  = 12000000, ///< Clock input rate
  parameter I2C_CLOCK_HZ = 100000,    ///< Desired I2C clock rate
  parameter ADDRESS_BITS = 7
  )
  (
    // Basic inputs
    input  clk, ///< FPGA logic clock
    // I2C bus
    inout  scl, ///< I2C clock line
    inout  sda, ///< I2C data line
    // Control signals
    input [9:0]      dIn,        ///< Data for writing or address during start / restart`
    input            readNWrite, ///< read / not-write flag for starts / restarts
    input            start,      ///< Execute a start signal, dIn must be valid at rising edge
    input            stop,       ///< Execute stop signal
    input            sendAck,    ///< Whether to send an ACK
    output reg [7:0] dOut,       ///< Received data
    output wire      dOutStrobe, ///< Output data balid strobe
    output reg       recvAck,    ///< Whether we received an ack
    output reg       busy        ///< Held high during operations. recvAck is valid on falling edge
  );


  integer FULL_PERIOD = CLOCK_IN_HZ / I2S_CLOCK_HZ; // Number of timer counts for one I2C clock period
  integer HALF_PERIOD = FULL_PERIOD / 2; // Half a clock period

  reg [11:0] timer; // Used for timing clock periods

  reg [3:0] bitCounter; ///< Counts data bits being shifted in or out

  enum reg [2:0] {idle, waiting, starting, addressing, reading, writing, stopping} state;

  reg [10:0] dInReg; // Sampled dIn register

  reg sclLow;
  reg sdaLow;

  assign scl = sclLow ? 1'b0 : 1'bz;
  assign sda = sdaLow ? 1'b0 : 1'bz;

  initial begin
    timer        <= 12'h000;
    state        <= idle;
    bitCounter   <= 4'h0;
    sclLow       <= 1'b0;
    sdaLow       <= 1'b0;
    dOut         <= 8'h00;
    dOutStrobe   <= 1'b0;
    recvAck      <= 1'b0;
    busy         <= 1'b0;
  end
  always (@posedge clk) begin
    case (state)
      idle: begin // Nothing started
        timer      <= 0;
        bitCounter <= 4'h0;
        sclLow     <= 1'b0;
        sdaLow     <= 1'b0;
        busy       <= 1'b0;
        if (start == 1'b1) begin // If start signal
          state <= waiting; // Go through waiting state on way to starting for transition edge effects
        end
      end // idle
      waiting: begin // Waiting for a command
        timer      <= 0;
        bitCounter <= 0;
        busy       <= 1'b1;
        if (start == 1'b1) begin
          state  <= starting;
          dInReg <= dIn;
        end
        else if (stop == 1'b1)
          state <= stopping;
        end
        else if (readNWrite == 1'b1) begin // reading
          state <= reading;
        else begin // writing
          state  <= writing;
          dInReg <= dIn;
        end;
      end // waiting
      starting: begin
        if (timer != FULL_PERIOD) timer <= timer + 1;
        else timer <= 0;
        case (timer)
          0: begin
            sclLow <= 1'b0;
            sdaLow <= 1'b0;
          end
          HALF_PERIOD: begin
            sdaLow <= 1'b1;
          end
          FULL_PERIOD: begin
            sclLow  <= 1'b1;
            state   <= addressing;
          end
        endcase
      end // starting
      addressing: begin
        if (bitCounter < ADDRESS_BITS) begin
          case (timer):
            0: begin
              sdaLow <= !dInReg[ADDRESS_BITS-1];
              dInReg <= {dInReg[9:0], 1'bx};
              timer  <= timer + 1;
            end
            HALF_PERIOD: begin
              sclLow  <= 1'b0;
              timer   <= timer + 1;
            end
            FULL_PERIOD: begin
              sclLow <= 1'b1;
              timer  <= 0;
              bitCounter <= bitCounter + 1;
            end
            default: timer <= timer + 1;
          endcase
        end // Writing Address out
        else begin
          timer <= timer + 1;
          if (bitCounter == ADDRESS_BITS) begin: // Write read / not write bit
            case (timer)
              0: begin
                sdaLow <= !readNWrite;
              end
              HALF_PERIOD: begin
                sclLow <= 1'b0;
              end
              FULL_PERIOD: begin
                sclLow <= 1'b1;
                sdaLow <= 1'b0;
                bitCounter <= bitCounter + 1;
              end
            endcase
          end
          else begin // Reading Ack
            case (timer)
              HALF_PERIOD: begin
                sclLow  <= 1'b0;
                recvAck <= !sda;
              end
              FULL_PERIOD: begin
                sclLow <= 1'b1;
                sdaLow <= 1'b0;
                state  <= waiting;
                busy   <= 1'b0;
              end
            endcase
          end
        end
      end // addressing
      stopping: begin
        timer <= timer + 1;
        case (timer)
          0: begin
            sclLow <= 1'b0;
          end;
          HALF_PERIOD: begin
            sdaLow <= 1'b0;
          end
          FULL_PERIOD: begin
            state <= idle;
            busy  <= 1'b0;
          end
        endcase
      end // stopping
      reading: begin
        if (bitCounter < 8) begin
          case (timer)
            HALF_PERIOD: begin
              sclLow <= 1'b0;
              dOut   <= {dOut[6:0], sda};
              timer  <= timer + 1;
            end
            FULL_PERIOD: begin
              sclLow     <= 1'b1;
              bitCounter <= bitCounter + 1;
              timer      <= 0;
              dOutStrobe <= 1'b1;
            end
            default: timer <= timer + 1;
          endcase
        end
        else begin // Sending ack
          timer <= timer + 1;
          case (timer)
            0: begin
              dOutStrobe <= 1'b0;
              sdaLow <= sendAck;
            end
            HALF_PERIOD: begin
              sclLow  <= 1'b0;
            end
            FULL_PERIOD: begin
              sclLow <= 1'b1;
              sdaLow <= 1'b0;
              state  <= waiting;
              busy   <= 1'b0;
            end
          endcase
        end
      end // reading
      writing: begin
        if (bitCounter < 8) begin
          case (timer)
            0: begin
              sdaLow <= !dInReg[7];
              dInReg <= {dInReg[9:0], 1'b0};
              timer  <= timer + 1;
            end
            HALF_PERIOD: begin
              sclLow <= 1'b0;
              timer  <= timer + 1;
            end
            FULL_PERIOD: begin
              sclLow     <= 1'b1;
              bitCounter <= bitCounter + 1;
              timer      <= 0;
            end
            default: timer <= timer + 1;
          endcase
        end
        else // Receiving ACK
          timer <= timer + 1;
          case (timer)
            0: begin
              sdaLow <= 1'b0; // Make SDA an input
            end
            HALF_PERIOD: begin
              sclLow  <= 1'b0;
              recvAck <= !sda;
            end
            FULL_PERIOD: begin
              sclLow <= 1'b0;
              state  <= waiting;
              busy   <= 1'b0;
            end;
          endcase
        end
      end // writing
    endcase // State
  end // posedge clk

endmodule;
