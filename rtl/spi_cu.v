module spi_cu ( //Definim les entrades i sortides del modul
  input Clk, Rst_n, CPol, CPha, Pulse, StartTx, 
  output reg EndTx, ShiftRx, ShiftTx, LoadTx, PulseEn, SCK
);
  
  //Creem varies senyals i registres per poder guardar dades
  
  reg [7:0] count;  		//Registre encarregat de comptar els polsos
  reg [1:0] countclk;		//Registre encarregat de comptar els cicles de clk per determinar si cpre = 0
  
  reg txmode, rxmode;		//Senyals que indiquen si estem en mode transmissió o recepció
  reg sckconfig; 			//Senyal que indica que l'SCK esta configurat
  reg change;				//Senyal que indica el canvi de mode tx a rx
  reg shift;				//Senyal que indica que s'ha de fer shift al shift register corresponent
  reg sckvalue;				//Senyal que dona el valor inicial al SCK
  reg cpre;					//Senyal que es posa a 1 si CPre = 0
  reg clkpulse;				//Senyal que substitueix la de Pulse en cas de CPre = 0

  parameter [2:0]			//Asignem valors als diferents estats de la maquina d'estats
	IDLE = 3'd0,
	START = 3'd1,
	WORK = 3'd2,
	SHIFT = 3'd3,
	END = 3'd4;
	
  reg [2:0] state, next;	//Creem els 2 registres per saber l'estat actual i el següent
  
  //El primer always es per fer el canvi d'estat, el reset i per mirar si estem en el cas de CPre = 0
  always @(posedge Clk or negedge Rst_n) begin
	if (!Rst_n) state <= IDLE;
	else 		state <= next;		
	//Per mirar si estem en CPre = 0 hem de mirar quan hi han 2 cicles de rellotge consecutius on pulse no baixa a 0, 
	//si aquest es el cas estem en CPre = 0 ja que si no estem a CPre = 0 el Pulse nomes dura 1 cicle de rellotge.
	if (Clk & Pulse & !cpre) 	countclk = countclk + 1;
	if (countclk == 2) begin
		cpre = 1;
		clkpulse = !clkpulse;
	end
	//Si en algun moment el valor de Pulse baixa vol dir que no estem a CPre = 0 i es torna al procediment normal
	if (!Pulse) begin
		cpre = 0;
		countclk = 0;
		clkpulse = 0;
	end
  end
  
  //El segon always s'encarrega de definir quin serà l'estat següent en funció de les entrades i les senyals internes
  always @(state or Pulse or StartTx or shift or clkpulse) begin
	case (state)
	IDLE: begin										
		if 		(StartTx) 			next = START; 	//Un cop arriba la senyal de StartTx anem a l'estat START
		else 						next = IDLE;
	end
	START: begin									
		if 		(sckconfig)			next = WORK;	//Un cop l'SCK esta configurat anem a l'estat WORK
		else						next = START;
	end
	WORK: begin		
		if		(count > 33)		next = END; 	//Si la conta de polsos arriba a superar 33 anem a l'estat END per acabar la transmissió
		else if (change) 			next = START;	//Si arriba la senyal de canviar de tx a rx tornem a START per tornar a configurar l'SCK
		else if (shift) 			next = SHIFT;	//Si arriba la senyal de shift anem a l'estat de SHIFT on es fara shift del registre corresponent
		else 						next = WORK;	//Si no passa res de l'anterior ens quedem a WORK
	end
	SHIFT: begin										
		if 		(!shift)			next = WORK;	//Quan el shift s'ha acabat tornem a WORK
		else 						next = SHIFT;
	end
	END: begin
		if 		(EndTx)				next = IDLE;	//Quan s'ha generat la senyal de EndTx tornem a IDLE
		else 						next = END;
	end
	endcase
  end
  
  //El tercer always s'encarrega de canviar les sortides i senyals internes en funció de l'estat actual
  always @(state or Pulse or StartTx or shift or clkpulse) begin
	case (state)
	
	//L'estat IDLE simplement posa totes les sortides i senyals internes a 0
	IDLE: begin
		PulseEn = 0; LoadTx = 0; EndTx = 0; ShiftRx = 0; ShiftTx = 0;
		txmode = 0;	rxmode = 0;	count = 0; sckconfig = 0; change = 0;
		SCK = 1'b0; shift = 0; sckvalue = 0; countclk = 0; cpre = 0; clkpulse = 0;
	end
	
	//L'estat START configura el valor inicial del SCK en funció de CPha i CPol 
	START: begin
		//Si no esta definit cap dels 2 modes significa que es l'inici de la comunicació, per tant,
		//s'habilita el generador de polsos (o el pols en cas de CPre = 0), la carrega al hift register de tx i el mode de transmissió
		if (!(txmode || rxmode)) begin
			PulseEn = 1;
			clkpulse = 1;
			LoadTx = 1;
			txmode = 1;
		end
		//Els següens blocks de if configuren el valor inicial del SCK durant 2 senyals de Pulse en funció de CPol i CPha 
		//i un cop fet reinicien les senyals utilitzades
		else if (sckconfig) begin
			if (CPha) sckvalue = !sckvalue;
			else 	  sckvalue = sckvalue;
			change = 0;
			sckconfig = 0;
			SCK = sckvalue;
		end
		else begin
			if (CPol) sckvalue = 1;
			else	  sckvalue = 0;
		end
		if (cpre) begin //Si estem en mode CPre = 0 la senyal clkpulse substitueix a la de Pulse
			if (clkpulse) sckconfig = 1;
		end
		else if (Pulse) sckconfig = 1;
	end
	
	//Aquest es l'estat on es fan tots els calculs i controla quan s'ha de fer shift
	WORK: begin
		if (count > 16) rxmode = 1;		//Si la conta arriba a 16 es que toca canviar a mode recepció
		else begin						//Sino ens quedem en mode transmissió
			txmode = 1;
			rxmode = 0;
		end
		ShiftTx = 0;					//Posem el shift de tx i rx a 0 per quan vinguin dels seus estats
		ShiftRx = 0;	
		LoadTx = 0;						//Posem la senyal de LoadTx a 0 ja que el valor ja ha estat carregat
		
		//Quan arriba un Pulse i la conta es de 16 es posa la senyal de change a 1 per fer el canvi de tx a rx
		//Mentres no s'hagi de canviar de tx a rx cada Pulse es suma 1 al contador i s'inverteix el valor de SCK
		//Si SCK es positiu i estem en el mode 00 o 11 de CPol CPha es dona la senyal de shift
		//Si SCK es negatiu i estem en el mode 01 o 10 de CPol CPha es dona la senyal de shift		
		if (cpre) begin					//Si estem en mode CPre = 0 la senyal clkpulse substitueix a la de Pulse
			if (clkpulse & count == 16) begin
				count = count + 1;
				txmode = 0; 
				rxmode = 1;
				change = 1;
			end
			else if (clkpulse & !change) begin
				count = count + 1;
				SCK = !SCK;
				if (SCK & !(CPha ^ CPol)) shift = 1;
				else if (!SCK & (CPha ^ CPol)) shift = 1;
			end
		end
		else if (Pulse & count == 16) begin
			count = count + 1;
			txmode = 0; 
			rxmode = 1;
			change = 1;
		end
		else if (Pulse & !change) begin
			count = count + 1;
			SCK = !SCK;
			if (SCK & !(CPha ^ CPol)) shift = 1;
			else if (!SCK & (CPha ^ CPol)) shift = 1;
		end				
	end
	//Mode que s'encarrega de fer shift del registre de tx o rx en funció del mode en el que estem
	SHIFT: begin
		if (txmode) 		ShiftTx = 1;
		else if (rxmode)	ShiftRx = 1;
		shift = 0;
	end
	//Mode que indica el final de la transmissió posant la senyal EndTx a 1
	END: begin
		EndTx = 1;
	end
	endcase
  end
endmodule