module spi_top (	//Definim les entrades i sortides del mòdul
  input [7:0] DataWr,
  input [1:0] Addr,
  input Clk, Rst_n, Wr, 
  input MISO,
  output SCK, MOSI, 
  output [7:0] SS, DataRd
);
  
  //Creem 2 seyals per fer la AND que necessita el pulse generator per fer el reset
  wire pulseRst;
  wire pulseEnable;

  //Creem cables per unir tots els mòduls entre ells
  wire CPol, CPha, StartTx, EndTx, Pulse, ShiftRx, ShiftTx, LoadTx;
  wire [3:0] CPre;
  wire [7:0] DataIn, DataOut;
  
  //Fem la AND i posem el seu valor a pulseRst
  assign pulseRst = (pulseEnable & Rst_n);
    
  //S'instancien tots els mòduls utilitzats
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