
//-------------------------------------------------------------------------------------------------
// filename:  signed_multiplier.v
// author:    lgonzale
// created:   2012-04-05
//-------------------------------------------------------------------------------------------------
// modification history
// author          date        description
// lgonzale        2012-04-06  creation
//-------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
//
// MODULE: signed_multiplier
//
//-------------------------------------------------------------------------------------------------
module signed_multiplier (out, clk, a, b);

  output       [31:0] out;
  input               clk;
  input signed [15:0] a;
  input signed [15:0] b;

  reg   signed [15:0] a_tmp;
  reg   signed [15:0] b_tmp;
  reg   signed [15:0] a_reg;
  reg   signed [15:0] b_reg;

  reg   signed [31:0] out;
  wire  signed [31:0] mult_out;

  assign mult_out = a_reg * b_reg;

  always @ (posedge clk)
  begin
    a_tmp <= a;
    b_tmp <= b;
    a_reg <= a_tmp;
    b_reg <= b_tmp;
    out   <= mult_out;
  end
endmodule
