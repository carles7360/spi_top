module pulse_generator
# (parameter SIZE = 4)( //Declarem el parametre per definir la mida del numero a comptar
	input Clk,			//Declarem les entrades i sortides del módul	
	input Rst_n,
	input [SIZE-1:0] CPre,
	output Pulse
);

reg [SIZE-1:0] count; //Declarem el registre per comptar	
reg pulsereg;		  //Declarem el registre on posarem la sortida

assign Pulse = pulsereg; //Assignem el valor del registre del pols a la sortida

//Creem 2 blocs always per poder fer 2 instruccións a cada flanc de clock ja que volem que la sortida vaigi al mateix temps que el comptador
//Aquests s'activen quan hi hagi un flanc de pujada del clock o un flanc de baixada del reset
always@ (posedge Clk or negedge Rst_n)
	if (!Rst_n) begin
		pulsereg = 1'b0; //Fem el reset del registre de sortida quan la senyal de reset sigui 0
	end
	else begin
			//Si el comptador es igual al valor de CPre menys 1 es posa la sortida a 1
		if (count == (CPre - 1'd1)) begin 
			pulsereg = 1'b1;
		end
		else begin
			//Si no es compleix la condició anterior la sortida es igual a la XOR reductora del valor de CPre (només serà 1 quan CPre sigui 0)
			pulsereg = ~|CPre;   
		end
	end

always@ (posedge Clk or negedge Rst_n)
	if (!Rst_n) begin
		count = {SIZE{1'b0}}; //Fem reset del registre del comptador
	end
	else begin
		if (count < CPre) begin
			//Si el valor del registre del comptador es mes petit que el de CPre sumem 1 
			count = count + 1;
		end
		else begin
			//Si no es compleix la condició anterior es posa el registre del comptador a 0
			count = {SIZE{1'b0}};
		end
	end
endmodule	

