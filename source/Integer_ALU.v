//-------------------------------------------------------------------------------------------------
// filename:  Integer_ALU.v
// author:    lgonzale
// created:   2012-04-05
//-------------------------------------------------------------------------------------------------
// modification history
// author          date        description
// lgonzale        2012-04-06  creation
//-------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
// MODULE: Integer_ALU
//-------------------------------------------------------------------------------------------------
module Integer_ALU(
	Operand1,
	Operand2,
	ShfAmt,
	TAG_IN,
	ALU_OPCODE,
	
	RESULT,
	TAG_OUT,
	ALU_BRANCH,
	ALU_BRANCH_TAKEN
	
    );

  
  //-----------------------------------------------------------------------------------------------
  // Input
  //-----------------------------------------------------------------------------------------------
  	input [31:0]Operand1;
	input [31:0]Operand2;
	input [4:0]ShfAmt;
	input [4:0]TAG_IN;
	input [3:0]ALU_OPCODE;

  
    
  //-----------------------------------------------------------------------------------------------
  // Outputs
  //-----------------------------------------------------------------------------------------------
   output reg[31:0]RESULT;
	output [4:0]TAG_OUT;
	output ALU_BRANCH;
	output reg ALU_BRANCH_TAKEN;
  
    
  //-----------------------------------------------------------------------------------------------
  // Reg
  //-----------------------------------------------------------------------------------------------
   wire signed[31:0]Operand1_signed;
	wire signed[31:0]Operand2_signed;
  
    
  //-----------------------------------------------------------------------------------------------
  // Wire
  //-----------------------------------------------------------------------------------------------
  
  
      
  //-----------------------------------------------------------------------------------------------
  // Parameter
  //-----------------------------------------------------------------------------------------------
	 
	parameter ADD = 	5'h0;
	parameter ADDU  = 5'h1;
	parameter SUB  = 	5'h2;
	parameter AND  = 	5'h3;
	parameter OR = 	5'h4;
	parameter NOR = 	5'h5;
	parameter SLT  = 	5'h6;
	parameter SLTU  = 5'h7;
	parameter SLL  = 	5'h8;
	parameter SRL  = 	5'h9;
	parameter BEQ = 	5'hA;
	parameter BNE = 	5'hB;
	
	//-----------------------------------------------------------------------------------------------
	// Logic
	//-----------------------------------------------------------------------------------------------

	assign Operand1_signed = Operand1;
	assign Operand2_signed = Operand2;

	always @(*)
	
	begin
	ALU_BRANCH_TAKEN = 0;
  RESULT           = 0;
	case (ALU_OPCODE)
	ADD : RESULT = Operand1_signed + Operand2_signed;
	ADDU : RESULT = Operand1 + Operand2;
	SUB : RESULT = Operand1_signed - Operand2_signed;
	AND : RESULT = Operand1 & Operand2;
	OR  : RESULT = Operand1 | Operand2;
	NOR : RESULT = ~(Operand1 | Operand2);
	SLT : RESULT = Operand1_signed<Operand2_signed?1:0;
	SLTU : RESULT = Operand1<Operand2?1:0;
	SLL : RESULT = Operand1 << ShfAmt;
	SRL : RESULT = Operand1 >> ShfAmt;
	BEQ : ALU_BRANCH_TAKEN = (Operand1 - Operand2)==0?1:0;
	BNE : ALU_BRANCH_TAKEN = (Operand1 - Operand2)==0?0:1;
	default: RESULT = 'b0;
	endcase
	end
 
	assign ALU_BRANCH = ((ALU_OPCODE==BEQ)||(ALU_OPCODE==BNE))?1:0; 
	assign TAG_OUT = TAG_IN;
	 
	 
endmodule
