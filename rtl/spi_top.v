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
  
  wire CPol, CPha, StartTx, EndTx, Pulse, ShiftRx, ShiftTx, LoadTx;
  wire [3:0] CPre;
  wire [7:0] DataIn, DataOut;
  
  assign pulseRst = (pulseEnable & Rst_n);
    
  spi_regs REGS(
	.Clk 			(Clk),
	.Rst_n			(Rst_n),
	.Addr 			(Addr),
	.Wr				(Wr),
	.DataWr			(DataWr),
	.DataRd			(DataRd),
	.CPol			(CPol),
	.CPha			(CPha),
	.CPre			(CPre),
	.StartTx		(StartTx),
	.EndTx			(EndTx),
	.TxData			(DataIn),
	.RxData			(DataOut),
	.SlaveSelectors (SS)
  );
  
  pulse_generator GEN(
	.Clk			(Clk),
	.Rst_n			(pulseRst),
	.CPre			(CPre),
	.Pulse			(Pulse)
  );
  
  shiftregtx TX(
	.Clk			(Clk),
	.Rst_n			(Rst_n),
	.En 			(ShiftTx),
	.Load 			(LoadTx),
	.DataIn			(DataIn),
	.SerOut			(MOSI)
  );
  
  shiftregrx RX(
	.Clk			(Clk),
	.Rst_n			(Rst_n),
	.En 			(ShiftRx),
	.DataOut		(DataOut),
	.SerIn			(MISO)
  );
  
  spi_cu CU(
	.Clk			(Clk),
	.Rst_n			(Rst_n),
	.CPol			(CPol),
	.CPha			(CPha),
	.Pulse			(Pulse),
	.StartTx		(StartTx),
	.EndTx			(EndTx),
	.ShiftTx		(ShiftTx),
	.ShiftRx		(ShiftRx),
	.LoadTx			(LoadTx),
	.PulseEn		(pulseEnable),
	.SCK			(SCK)
  );
endmodule