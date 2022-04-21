// time scale definiton
`timescale 1 ns / 1 ps
// delay between clock posedge and check
`define DELAY 2
`include "../rtl/spi_defines.vh"

module tb_spi_top(); // module name (same as the file)

  //___________________________________________________________________________
  // input output signals for the DUT
  reg 			clk;     // rellotge del sistema
  reg 			rst_n;   // reset del sistema asíncorn i actiu nivell baix
  reg 	[7:0]	dataWr;
  reg 			miso;
  reg 	[1:0]	addr;
  reg 			wr;
  wire 			sck;
  wire			mosi;
  wire 	[7:0]	ss;
  wire	[7:0]	dataRd;
  reg   [1:0]   mode;

  // test signals
  integer         errors;    // Accumulated errors during the simulation
  integer         bitCntr;   // used to count bits
  reg 			  vExpected;  // expected value
  reg  			  vObtained; // obtained value

  //___________________________________________________________________________
  // Instantiation of the module to be verified
  spi_top DUT(
    .Clk            (clk),
    .Rst_n          (rst_n),
	.DataWr			(dataWr),
	.Addr			(addr),
	.Wr				(wr),
	.MISO			(miso),
	.SCK			(sck),
	.MOSI			(mosi),
	.SS				(ss),
	.DataRd			(dataRd)
  );
  
  spislave_fm SLAVE(
	.Mode			(mode),
	.SCK			(tb_spi_top.DUT.SCK),
	.SDI			(tb_spi_top.DUT.MOSI),
	.SDO			(tb_spi_top.DUT.MISO),
	.CS				(tb_spi_top.DUT.SS[0])
  );

  //___________________________________________________________________________
  // 100 MHz clock generation
  initial clk = 1'b0;
  always #10 clk = ~ clk;

  //___________________________________________________________________________
  // signals and vars initialization
  initial begin
    rst_n = 1'b1;
	dataWr = 8'b0;
	addr = 4'b0;
	wr = 1'b0;
	miso = 1'b0;
	mode = 2'd0;
  end

  //___________________________________________________________________________
  // Test Vectors
  initial begin
    $timeformat(-9, 2, " ns", 10); // format for the time print
    errors = 0;                    // inicialize the errors counter	
	waitClk;
	resetDUT;	
	$display("[Info- %t] Test SPI", $time);
	testcu(8'h09, 8'hFE, 2'd0, 8'hAA);
	testcu(8'h19, 8'hFE, 2'd1, 8'h55);
	testcu(8'h29, 8'hFE, 2'd2, 8'hAA);
	testcu(8'h39, 8'hFE, 2'd3, 8'h55);
    $stop;
  end

  //___________________________________________________________________________
  // Test tasks
  // Test del generador de polsos
    task writeReg;
    // Task automatically generates a write to a register.
    // Inputs data to write and reg address.
		input [7:0] datawrite;
		input [3:0] address;
		begin
			wr = 1'b1;
			dataWr = datawrite;
			addr = address;
			waitClk;
			wr = 1'b0;
			waitClk;
		end
    endtask
	
	task waitEnd;
    // Task automatically generates a write to a register.
    // Inputs data to write and reg address.
		begin
			wait(!tb_spi_top.DUT.REGS.busy); 
		end
    endtask
	
	task testcu;
    // Task automatically generates a write to a register.
    // Inputs data to write and reg address.
		input [7:0] sckconfig;
		input [7:0] slaveselect;
		input [1:0] slavemode;
		input [7:0] datasend;
		begin
			mode = slavemode;
			writeReg(sckconfig, `SPI_CONFIG);			// 00 (CPol)0 (CPha)1 (CPre)1001 = h29
			writeReg(8'h01, `SPI_CTRL);
			writeReg(slaveselect, `SPI_SSELEC);
			writeReg(datasend, `SPI_BUFFER);
			waitEnd;
			writeReg(8'hFF, `SPI_SSELEC);
			waitCycles(10);
		end
    endtask
  //___________________________________________________________________________
  // Basic tasks

  // Synchronous output check
  task syncCheck;
    begin
      waitClk;
      if (vExpected != vObtained) begin
        $display("[Error! %t] The value is %h and should be %h", $time, vObtained, vExpected);
        errors = errors + 1;
      end else begin
        $display("[Info- %t] Successful check at time", $time);
      end
    end
  endtask

  // Asynchronous output check
  task asyncCheck;
    begin
      #`DELAY;
      if (vExpected != vObtained) begin
        $display("[Error! %t] The value is %h and should be %h", $time, vObtained, vExpected);
        errors = errors + 1;
      end else begin
        $display("[Info- %t] Successful check at time", $time);
      end
    end
  endtask

  // generation of reset pulse
  task resetDUT;
    begin
      $display("[Info- %t] Reset", $time);
	  waitClk;
      rst_n = 1'b0;
	  #5;
	  vExpected = 1'b0;
      waitCycles(3);
      rst_n = 1'b1;
    end
  endtask

  // wait for N clock cycles
  task waitCycles;
    input [32-1:0] Ncycles;
    begin
      repeat(Ncycles) begin
        waitClk;
      end
    end

  endtask

  // wait the next posedge clock
  task waitClk;
    begin
      @(posedge clk);
        #`DELAY;
    end //begin
  endtask

  // Check for errors during the simulation
  task checkErrors;
      begin
          if (errors==0) begin
              $display("********** TEST PASSED **********");
          end else begin
              $display("********** TEST FAILED **********");
          end
      end
  endtask

endmodule