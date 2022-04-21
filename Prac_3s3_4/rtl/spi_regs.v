/********1*********2*********3*********4*********5*********6*********7*********8
* File : spi_regs.v
*_______________________________________________________________________________
*
* Revision history
*
* Name          Date        Observations
* ------------------------------------------------------------------------------
* -            01/02/2022   First version.
* ------------------------------------------------------------------------------
*_______________________________________________________________________________
* Description
* Configuration and Status Registers for SPI Bus.
*
* ============================================================================== 
*  SPI_CTRL:   Serial Peripheral Interface Control Register           
*              (Write/Read) Default: 0x00
* ------------------------------------------------------------------------------
*    bit[7]  : BUSY ? SPI Bus Busy Flag (Read only)
*                 1 = Transmission not complete.
*                 0 = Transmission completed.
*    bit[6:1]: Reserved bits.
*    bit[0]  : ENABLE ? Serial Peripheral Master Enable
*                0 = SPI master off
*                1 = SPI master on
* 
* ============================================================================== 
*  SPI_BUFFER: Serial Peripheral Interface Transmited/Received Data Register 
*              (Write/Read) Default: 0x00
*
* ============================================================================== 
*  SPI_CONFIG: Serial Preipheral Interface SCK Configuration Register
*              (Write/Read) Default: 0x00
* ------------------------------------------------------------------------------
*    bit[7:6]: Reserved bits.
*    bit[5]  : CPOL ? Clock Polarity
*                0 = the base value of the clock is zero
*                1 = the base value of the clock is one
*    bit[4]  : CPHA ? Clock Phase
*                At CPOL=0 the base value of the clock is zero:
*                  - For CPHA=0: data are captured on the clock's rising 
*                    edge (low2high transition) and data are propagated on a 
*                    falling edge.
*                  - For CPHA=1: data are captured on the clock's falling edge
*                    and data are propagated on a rising edge.
*                At CPOL=1 the base value of the clock is one (inversion of CPOL=0)
*                  - For CPHA=0: data are captured on clock's falling edge and 
*                    data are propagated on a rising edge.
*                  - For CPHA=1: data are captured on clock's rising edge and 
*                    data are propagated on a falling edge.
*    bit[3:0]: CPre ? Prescaled Value used to determine the bus baud rate. The
*              SCK clock obtained is given by: SCK = Clk/[2(CPre+1)] where Clk is 
*              the system clock.
*
* ==============================================================================
*  SPI_SSELEC: Serial Peripheral Interface Slave Selector Register       
*              (Write/Read) Default: 0xFF
* ------------------------------------------------------------------------------
*    Each bit is used to select one slave.  
*_______________________________________________________________________________ 
*
* (c) Copyright Universitat de Barcelona, 2022
*
*********1*********2*********3*********4*********5*********6*********7*********/


`include "spi_defines.vh"

module spi_regs #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 2
)(
  input  Clk,                      // system cloc
  input  Rst_n,                    // system reset asynch, active low
  input  [ADDR_WIDTH-1:0] Addr,    // registers addres
  input  Wr,                       // registers write enable
  input  [DATA_WIDTH-1:0] DataWr,  // registers data input
  output reg [DATA_WIDTH-1:0] DataRd,  // registers data output

  output CPol,                     // Used to select the SCK polarization
  output CPha,                     // Used to select the SCK phase
  output [4-1:0] CPre,             // SCK clock prescale, number of clk ticks to defin one SCK semi period
  output reg StartTx,              // Initiates the transmission.
  input  EndTx,                    // Indicates the end of transission
  output [DATA_WIDTH-1:0] TxData,
  input  [DATA_WIDTH-1:0] RxData,
  output [DATA_WIDTH-1:0] SlaveSelectors
);

  // spi registers
  reg [DATA_WIDTH-1:0] ctrl;       // SPI_CTRL register with busy flag and enable bits
  reg [DATA_WIDTH-1:0] buffer;     // SPI_BUFFER register
  reg [DATA_WIDTH-1:0] sckConfig;  // SPI SCK COnfiguration registers CPOL CPHA CPRE
  reg [DATA_WIDTH-1:0] sselect;    // SPI Slave Selector register

  // other registers
  reg busy;          // flag to indicate there is a transmission in course
  wire enable;       // used to mask de start signal enabling or disabling the spi master

  // output assignaments
  assign enable = ctrl[0];  //Posem la senyal de enable al bit 0 del registre de control

  assign CPol = sckConfig[5];     // Posem la senyal de CPol al bit 5 del registre de configuració del sck
  assign CPha = sckConfig[4];     // Posem la senyal de CPha al bit 4 del registre de configuració del sck
  assign CPre = sckConfig[3:0];   // Posem la senyal de CPre als bits del 3 al 0 del registre de configuració del sck

  assign SlaveSelectors = sselect;// Assignem el registre de slave select a la seva sortida

  assign TxData = buffer;         // Assignem el registre de buffer a la sortida de dades de transmissió

  // write synch
  // Creem diferents always per poder fer moltes instruccions a cada flanc de pujada de clock o flanc de baixada de reset
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)									// Si el valor del reset es 0 fem reset al valor del registre de control
      ctrl <= {DATA_WIDTH{1'b0}};                
    else if(Wr==1'b1 && Addr==`SPI_CTRL)		// Si el valor de write enable es 1 i la adreça es del registre de control es posen les dades al registre
      ctrl <= DataWr;
    else
      ctrl <= ctrl;								// Si passa qualsevol altra cosa es manté el valor del registre

  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)									// Si el valor del reset es 0 fem reset al valor del registre de configuracio de sck
      sckConfig <= {DATA_WIDTH{1'b0}};
    else if(Wr==1'b1 && Addr==`SPI_CONFIG)		// Si el valor de write enable es 1 i la adreça es del registre de configuració de sck es posen les dades al registre
      sckConfig <= DataWr;
    else
      sckConfig <= sckConfig; 					// Si passa qualsevol altra cosa es manté el valor del registre

  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)									// Si el valor del reset es 0 fem reset al valor del registre de slave select
      sselect <= {DATA_WIDTH{1'b1}};
    else if(Wr==1'b1 && Addr==`SPI_SSELEC)		// Si el valor de write enable es 1 i la adreça es del registre de slave select es posen les dades al registre
      sselect <= DataWr;
    else
      sselect <= sselect;						// Si passa qualsevol altra cosa es manté el valor del registre

  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)									// Si el valor del reset es 0 fem reset al valor del registre de buffer
      buffer <= {DATA_WIDTH{1'b0}};
    else if(EndTx)								// Si el valor de la senyal de final de transmissió es 1 es posen les dades rebudes al buffer
      buffer <= RxData;							
    else if(Wr==1'b1 && Addr==`SPI_BUFFER)  	// Si el valor de write enable es 1 i la adreça es del registre de buffer es posen les dades al registre
      buffer <= DataWr;
    else	
      buffer <= buffer;							// Si passa qualsevol altra cosa es manté el valor del registre

  // logic to generate Start and loadTx signals
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)									// Si el valor del reset es 0 fem reset del valor de la senyal
      StartTx <= 1'b0;							
    else if(Wr==1'b1 && Addr==`SPI_BUFFER)		// Si el valor de write enable es 1 i la adreça es del registre de buffer s'habilita el començament de la transmissió
      StartTx <= enable;
    else
      StartTx <= 1'b0;							// Si passa qualsevol altra cosa es posa el valor de la senyal a 0

  // logic to generate the busy flag
  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n)									// Si el valor del reset es 0 fem reset del valor de la senyal
      busy <= 1'b0;
    else if(StartTx)							// Quan comença la transmissió (StartTx = 1) es posa el valor de la senyal de busy a 1
      busy <= 1'b1;
    else if(EndTx)								// Quan acaba la transmissió (EndTx = 1) es posa el valor de la senyal de busy a 0
      busy <= 1'b0;
    else
      busy <= busy;								// Si passa qualsevol altra cosa es manté el valor de la senyal

  // asynch read
  // Entrem a aquest always sempre que hi hagi un canvi de adreça
  always @(*)
    case(Addr)
      `SPI_CTRL   : DataRd = {busy, ctrl[DATA_WIDTH-2:0]};  // Si la adreça es la del registre de control es posen les dades d'aquest i la senyal de busy al registre de dades a llegir
      `SPI_BUFFER : DataRd = buffer;						// Si la adreça es la del registre de buffer es posen les dades d'aquest al registre de dades a llegir
      `SPI_CONFIG : DataRd = sckConfig;						// Si la adreça es la del registre de configuració de sck es posen les dades d'aquest al registre de dades a llegir
      `SPI_SSELEC : DataRd = sselect;						// Si la adreça es la del registre de slave select es posen les dades d'aquest al registre de dades a llegir
      default : DataRd = {DATA_WIDTH{1'b0}};				// Per defecte les dades del registre a llegir son 0, no hauria d'arribar mai a aquesta instrucció
    endcase

endmodule

