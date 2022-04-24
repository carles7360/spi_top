module spi_cu (
  input Clk, Rst_n, CPol, CPha, Pulse, StartTx, 
  output reg EndTx, ShiftRx, ShiftTx, LoadTx, PulseEn, SCK
);

  reg [7:0] count;
  reg txmode, rxmode, sckconfig, change;

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
		if 		(sckconfig)			next = WORK;
		else						next = START;
	end
	WORK: begin
		if		(count > 31)		next = END;
		else if (change) 			next = START;
		else if (count % 2 == 1)	next = WORK;
		else if (txmode & Pulse) 	next = TX;
		else if (rxmode & Pulse) 	next = RX;
	end
	TX: begin
		if 		(!Pulse)			next = WORK;
		else 						next = TX;
	end
	RX: begin
		if 		(!Pulse)			next = WORK;
		else 						next = RX;
	end
	END: begin
		if 		(EndTx)				next = IDLE;
		else 						next = END;
	end
	endcase
  end
  
  always @(state or CPha or Pulse or StartTx or CPol) begin
	case (state)
	IDLE: begin
		PulseEn = 0; LoadTx = 0; EndTx = 0; ShiftRx = 0; ShiftTx = 0;
		txmode = 0;	rxmode = 0;	count = 0; sckconfig = 0; change = 0;
		SCK = 1'bz;
	end
	START: begin
		if (!(txmode || rxmode)) begin
			PulseEn = 1;
			LoadTx = 1;
			txmode = 1;
		end
		else if (sckconfig) begin
			if (CPha) SCK = !SCK;
			else 	  SCK = SCK;
			change = 0;
		end
		else begin
			if (CPol) SCK = 1;
			else	  SCK = 0;
		end
		if (Pulse) sckconfig = sckconfig + 1;
	end
	WORK: begin
		if (count > 15) rxmode = 1;
		else begin
			txmode = 1;
			rxmode = 0;
		end
		sckconfig = 0;
		ShiftTx = 0;
		ShiftRx = 0;
		LoadTx = 0;
		if (Pulse & count == 15) begin
			count = count + 1;
			txmode = 0; 
			rxmode = 1;
			change = 1;
		end
		else if (Pulse) begin
			count = count + 1;
			SCK = !SCK;
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
	end
	endcase
  end
endmodule