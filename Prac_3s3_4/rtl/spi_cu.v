module spi_cu (
  input Clk, Rst_n, CPol, CPha, Pulse, StartTx, 
  output reg EndTx, ShiftRx, ShiftTx, LoadTx, PulseEn, SCK
);

  reg [7:0] count;
  reg txmode, rxmode, sckconfig;

  parameter [2:0]
	IDLE = 3'd0,
	START = 3'd1,
	WORK = 3'd2,
	TX = 3'd3,
	RX = 3'd4,
	END = 3'd5;
	
  reg [2:0] state, next;
  
  always @(posedge Clk or negedge Rst_n)
	if (!Rst_n) state <= IDLE;
	else 		state <= next;
	
  always @(state or CPha or Pulse or StartTx or CPol) begin
	case (state)
	IDLE: begin
		if 		(StartTx) 			next = START;
		else 						next = IDLE;
	end
	START: begin
		if (sckconfig)				next = WORK;
		else						next = START;
	end
	WORK: begin
		if		(count > 31)		next = END;
		else if (count % 2 == 0)	next = WORK;
		else if (txmode & Pulse) 	next = TX;
		else if (rxmode & Pulse) 	next = RX;
		else 						next = WORK;
	end
	TX: begin
		if 		(!Pulse)			next = WORK;
		else 						next = TX;
	end
	RX: begin
		if (!Pulse)					next = WORK;
		else 						next = RX;
	end
	END: begin
									next = IDLE;
	end
	endcase
  end
  
  always @(state or CPha or Pulse or StartTx or CPol) begin
	case (state)
	IDLE: begin
		PulseEn = 0; LoadTx = 0; EndTx = 0; ShiftRx = 0; ShiftTx = 0;
		txmode = 0;	rxmode = 0;	count = 0; SCK = 0; sckconfig = 0;
	end
	START: begin
		if (sckconfig) begin
			if (CPha) SCK = !SCK;
			else 	  SCK = SCK;
		end
		else begin
			if (CPol) SCK = 1;
			else	  SCK = 0;
		end
		PulseEn = 1;
		LoadTx = 1;
		txmode = 1;
		rxmode = 0;
		count = 0;
		if (Pulse) sckconfig = sckconfig + 1;
		else sckconfig = sckconfig;
	end
	WORK: begin
		if (count > 15) begin
			txmode = 0; 
			rxmode = 1;
		end
		else begin
			txmode = 1;
			rxmode = 0;
		end
		ShiftTx = 0;
		ShiftRx = 0;
		LoadTx = 0;
		if (Pulse) begin
			count = count + 1;
			SCK = !SCK;
		end
		else begin
			count = count;
			SCK = SCK;
		end
	end
	TX: begin
		ShiftTx = 1;
	end
	RX: begin
		ShiftRx = 1;
	end
	END: begin
		EndTx = 1;
		PulseEn = 0;
		count = 0;
	end
	endcase
  end
endmodule