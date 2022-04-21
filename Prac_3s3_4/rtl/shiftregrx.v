module shiftregrx
# ( parameter SIZE = 8)( //Declarem el parametre per definir la mida del registre
	input Clk,			 //Declarem les entrades i sortides del modul 
	input Rst_n,
	input En,
	output wire [SIZE-1:0] DataOut,
	input SerIn
);

reg [SIZE-1:0] registre; //Declarem un registre on guardarem les dades que calculem

assign DataOut = registre; 			//Assignem el valor del registre a la sortida en paral·lel

always@ (posedge Clk or negedge Rst_n) 
//Cada vegada que hi hagi un flanc de pujada del clock o un de baixada del reset s'executa el codi inferior
	if (!Rst_n) begin  //Si el reset es negatiu es posa el valor del registre a 0
		registre = {SIZE{1'b0}};
	end
	else begin
		if (En) begin //Si el valor de En (enable) es 1 es carrega el valor en serie al LSB del registre fen un shift dels altres valors
			registre = {registre[SIZE-2:0],SerIn};
		end
		else begin //Si cap de les opcions anteriors es compleix, es manté el valor del registre
			registre <= registre;
		end	
	end	
endmodule	
