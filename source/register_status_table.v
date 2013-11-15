//-------------------------------------------------------------------------------------------------
// filename:  register_status_table.v
// author:    lgonzale
// created:   2012-03-20
//-------------------------------------------------------------------------------------------------
// modification history
// author          date        description
// lgonzale        2012-03-20  creation
// ikalvarado      2012-08-04  fixed rob clear bug
//-------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
// MODULE: register_status_table
//-------------------------------------------------------------------------------------------------
module register_status_table (
  nreset,
  clock,
  Wdata_rst,
  Waddr_rst,
  Wen_rst,
  flush,

  Rsaddr_rst,
  Rstag_rst,
  Rsvalid_rst,
  Rtaddr_rst,
  Rttag_rst,
  Rtvalid_rst,

  RB_tag_rst,
  RB_valid_rst
);

  //-----------------------------------------------------------------------------------------------
  // Inputs
  //-----------------------------------------------------------------------------------------------
  input nreset;
  input [4:0]Wdata_rst;
  input [4:0]Waddr_rst;
  input Wen_rst;
  input [4:0]Rsaddr_rst;
  input [4:0]Rtaddr_rst;
  input [4:0]RB_tag_rst;
  input RB_valid_rst;
  input clock;
  input flush;

  //-----------------------------------------------------------------------------------------------
  // Outputs
  //-----------------------------------------------------------------------------------------------
  output wire [4:0]Rstag_rst;
  output wire Rsvalid_rst;
  output wire [4:0]Rttag_rst;
  output wire Rtvalid_rst;

  //-----------------------------------------------------------------------------------------------
  // Wires
  //-----------------------------------------------------------------------------------------------
  wire [31:0] rob_wen;

  //-----------------------------------------------------------------------------------------------
  // Registers
  //-----------------------------------------------------------------------------------------------
  reg [5:0] RST_array [0:31];

  //-----------------------------------------------------------------------------------------------
  // Logic
  //-----------------------------------------------------------------------------------------------
  assign Rstag_rst   = RST_array[Rsaddr_rst][4:0];
  assign Rsvalid_rst = RST_array[Rsaddr_rst][5:5];
  assign Rttag_rst   = RST_array[Rtaddr_rst][4:0];
  assign Rtvalid_rst = RST_array[Rtaddr_rst][5:5];
  
  genvar n;
  generate
    for(n = 0; n < 32; n = n + 1) begin
      assign rob_wen[n] = {1'b1, RB_tag_rst} == RST_array[n[4:0]] ? 1 : 0;
    end
  endgenerate

  integer i = 0;

  always @(posedge clock, negedge nreset) begin
    if (!nreset) begin
      for (i = 0; i < 32; i = i + 1) begin
      RST_array [i] <= 0;
      end
    end
    else if (flush) begin
      for (i = 0; i < 32; i = i + 1) begin
      RST_array [i] <= 0;
      end
    end
    else begin
      for(i = 0; i < 32; i = i + 1) begin
        if(rob_wen[i[4:0]] && RB_valid_rst) begin
          RST_array[i] <= 0;
        end
      end
      if (Wen_rst) begin
        RST_array[Waddr_rst] <= {1'b1,Wdata_rst};
      end
    end
  end
endmodule

