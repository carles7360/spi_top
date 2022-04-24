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
  wire 			miso;
  reg 	[1:0]	addr;
  reg 			wr;
  wire 			sck;
  wire			mosi;
  wire 	[7:0]	ss;
  wire	[7:0]	dataRd;
  reg   [1:0]   mode;

  // test signals
  integer         errors;    // Accumulated errors during the simulation
  reg 	[7:0]	  vExpected;  // expected value
  reg  	[7:0]	  vObtained; // obtained value
  integer 		  cpre;
  reg   [7:0] 	  sckdata;
  reg   [7:0] 	  slavedata;
  reg   [7:0] 	  txdata;  

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
	.SCK			(sck),
	.SDI			(mosi),
	.SDO			(miso),
	.CS				(ss[0])
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
	mode = 2'd0;
	sckdata = 8'b0;
	slavedata = 8'b0;
	txdata = 8'b0;	
	vExpected = 0;
	vObtained = 0;
  end

  //___________________________________________________________________________
  // Test Vectors
  initial begin
    $timeformat(-9, 2, " ns", 10); // format for the time print
    errors = 0;                    // inicialize the errors counter	
	waitClk;
	resetDUT;						//Fem un reset per començar el test
	txdata = 8'h5B;					//Donem un valor al byt ea transmetre
	testcpre(0);					//Fem els tests per a 4 valors diferents de CPre: 0, 1, 5 i 13
	testcpre(1);
	testcpre(5);
	testcpre(13);
	$stop;
  end

  //___________________________________________________________________________
  // Test tasks
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
	task readReg;
    // Task automatically generates a write to a register.
    // Input reg address. Output read data.
		input [3:0] address;
		output [7:0] dataread;
		begin
			addr = address;
			dataread = dataRd;
			waitClk;
		end
    endtask
	task waitEnd;
    // Tasca que espera a que la senyal de busy sigui 0
		begin
			wait(!tb_spi_top.DUT.REGS.busy); 
			waitClk;
		end
    endtask
	task datacheck;
		// Tasca que dona valor a les variables de vExpected i vObtained i comprova que siguin iguals
		begin
			wait(tb_spi_top.DUT.CU.change);
			vExpected = dataWr;
			vObtained = tb_spi_top.SLAVE.dataRx;
			$display("[Info- %t] Valor enviat a l'Slave = %b", $time, vExpected);
			$display("[Info- %t] Valor llegit a l'Slave = %b", $time, vObtained);	
			asyncCheck;
			waitEnd;			
			readReg(`SPI_BUFFER, vObtained);
			vExpected = tb_spi_top.SLAVE.dataTx;
			$display("[Info- %t] Valor enviat al Master = %b", $time, vExpected);
			$display("[Info- %t] Valor llegit al Master = %b", $time, vObtained);	
			asyncCheck;
			checkErrors;
			errors = 0;
		end
	endtask
	task testspi;
    // Tasca que fa el test de la comunicació amb l'slave
		input [7:0] sckconfig;
		input [7:0] slaveselect;
		input [7:0] datasend;
		begin
			mode = sckconfig[5:4];
			writeReg(sckconfig, `SPI_CONFIG);		
			writeReg(8'h01, `SPI_CTRL);
			writeReg(slaveselect, `SPI_SSELEC);
			writeReg(datasend, `SPI_BUFFER);
			datacheck;
			writeReg(8'hFF, `SPI_SSELEC);
			waitCycles(10);
		end
    endtask
	
	task testcpre;
	// Tasca que fa el test de 4 comunicacions amb l'slave, una per cada mode, amb el mateix CPre
		input [3:0] cpre;
		begin
			sckdata = 8'h00 + cpre;
			slavedata = 8'hFE;
			$display("[Info- %t] Test SPI Mode 3 per a CPre = %d", $time, sckdata[3:0]);
			testspi(sckdata, slavedata, txdata);
			sckdata = sckdata + 8'h10;
			$display("[Info- %t] Test SPI Mode 3 per a CPre = %d", $time, sckdata[3:0]);
			testspi(sckdata, slavedata, txdata);
			sckdata = sckdata + 8'h10;	
			$display("[Info- %t] Test SPI Mode 3 per a CPre = %d", $time, sckdata[3:0]);
			testspi(sckdata, slavedata, txdata);
			sckdata = sckdata + 8'h10;
			$display("[Info- %t] Test SPI Mode 3 per a CPre = %d", $time, sckdata[3:0]);
			testspi(sckdata, slavedata, txdata);
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
      rst_n = 1'b0;
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