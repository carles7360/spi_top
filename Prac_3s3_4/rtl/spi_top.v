module spi_top (
  input [7:0] DataWr,
  input [1:0] Addr,
  input Clk, Rst_n, Wr, 
  input MISO,
  output SCK, MOSI, 
  output [7:0] SS, DataRd
);
  wire pulseRst;
  wire pulseEnable;
  
  assign pulseRst = (pulseEnable & Rst_n);
  
  spi_regs REGS(
	.Clk 			(Clk),
	.Rst_n			(Rst_n),
	.Addr 			(Addr),
	.Wr				(Wr),
	.DataWr			(DataWr),
	.DataRd			(DataRd),
	.CPol			(spi_top.CU.CPol),
	.CPha			(spi_top.CU.CPha),
	.CPre			(spi_top.GEN.CPre),
	.StartTx		(spi_top.CU.StartTx),
	.EndTx			(spi_top.CU.EndTx),
	.TxData			(spi_top.TX.DataIn),
	.RxData			(spi_top.RX.DataOut),
	.SlaveSelectors (SS)
  );
  
  pulse_generator GEN(
	.Clk			(Clk),
	.Rst_n			(pulseRst),
	.CPre			(spi_top.REGS.CPre),
	.Pulse			(spi_top.CU.Pulse)
  );
  
  shiftregtx TX(
	.Clk			(Clk),
	.Rst_n			(Rst_n),
	.En 			(spi_top.CU.ShiftTx),
	.Load 			(spi_top.CU.LoadTx),
	.DataIn			(spi_top.REGS.TxData),
	.SerOut			(MOSI)
  );
  
  shiftregrx RX(
	.Clk			(Clk),
	.Rst_n			(Rst_n),
	.En 			(spi_top.CU.ShiftRx),
	.DataOut		(spi_top.REGS.RxData),
	.SerIn			(MISO)
  );
  
  spi_cu CU(
	.Clk			(Clk),
	.Rst_n			(Rst_n),
	.CPol			(spi_top.REGS.CPol),
	.CPha			(spi_top.REGS.CPha),
	.Pulse			(spi_top.GEN.Pulse),
	.StartTx		(spi_top.REGS.StartTx),
	.EndTx			(spi_top.REGS.EndTx),
	.ShiftTx		(spi_top.TX.En),
	.ShiftRx		(spi_top.RX.En),
	.LoadTx			(spi_top.TX.Load),
	.PulseEn		(pulseEnable),
	.SCK			(SCK)
  );
endmodule