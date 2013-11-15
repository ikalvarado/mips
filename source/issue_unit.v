//
//-------------------------------------------------------------------------------------------------
// filename:  issue_unit.v
// author:    ikalvarado
// created:   2012-03-30
//-------------------------------------------------------------------------------------------------
// modification history
// author          date        description
// ialvarado       2012-03-30  creation
//-------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
//
// MODULE: issue_unit
//
//-------------------------------------------------------------------------------------------------
module issue_unit (
  clock,
  nreset,
  flush_valid,
  int_ready,
  int_dout,
  int_tag,
  int_branch,
  int_branch_taken,
  int_issue,
  mul_ready,
  mul_dout,
  mul_tag,
  mul_issue,
  mem_ready,
  mem_dout,
  mem_tag,
  mem_issue,
  cdb_valid,
  cdb_branch,
  cdb_branch_taken,
  cdb_data,
  cdb_tag
);

  //-----------------------------------------------------------------------------------------------
  //
  // Interfaces
  //
  //-----------------------------------------------------------------------------------------------
  input              clock;
  input              nreset;
  input              flush_valid;

  //-----------------------------------------------------------------------------------------------
  // interface with the integer execution qeueue
  //-----------------------------------------------------------------------------------------------
  input              int_ready;
  input       [31:0] int_dout;
  input       [ 4:0] int_tag;
  input              int_branch;
  input              int_branch_taken;
  output wire        int_issue;

  //-----------------------------------------------------------------------------------------------
  // interface with the multiplication execution qeueue
  //-----------------------------------------------------------------------------------------------
  input              mul_ready;
  input       [31:0] mul_dout;
  input       [ 4:0] mul_tag;
  output wire        mul_issue;

  //-----------------------------------------------------------------------------------------------
  // interface with the multiplication execution qeueue
  //-----------------------------------------------------------------------------------------------
  input              mem_ready;
  input       [31:0] mem_dout;
  input       [ 4:0] mem_tag;
  output wire        mem_issue;

  //-----------------------------------------------------------------------------------------------
  // common data bus
  //-----------------------------------------------------------------------------------------------
  output reg         cdb_valid;
  output reg         cdb_branch;
  output reg         cdb_branch_taken;
  output reg  [ 4:0] cdb_tag;
  output wire [31:0] cdb_data;

  //-----------------------------------------------------------------------------------------------
  //
  // Internal signals
  //
  //-----------------------------------------------------------------------------------------------
  wire [2:0] access_vector;

  //-----------------------------------------------------------------------------------------------
  // Variables
  //-----------------------------------------------------------------------------------------------
  reg [ 2:0] mult_cntr;
  reg [ 1:0] int_lru;
  reg [ 1:0] mem_lru;
  reg [ 1:0] dlyd_access_vector;
  reg [31:0] cdb_data_ff;

  //-----------------------------------------------------------------------------------------------
  //
  // Combinational logic
  //
  //-----------------------------------------------------------------------------------------------
  assign int_issue  = access_vector[0];
  assign mem_issue  = access_vector[1];
  assign mul_issue  = access_vector[2];
  assign mult_valid  = mul_ready & (~|mult_cntr);

  assign access_vector[2] = mult_valid;
  assign access_vector[1] = !mult_cntr[2] & mem_ready & (int_ready ? (mem_lru <  int_lru) : 1);
  assign access_vector[0] = !mult_cntr[2] & int_ready & (mem_ready ? (int_lru <= mem_lru) : 1);

  assign cdb_data = dlyd_access_vector[1] ? mem_dout : cdb_data_ff;

  //-----------------------------------------------------------------------------------------------
  //
  // Registers
  //
  //-----------------------------------------------------------------------------------------------

  //-----------------------------------------------------------------------------------------------
  // LRU's
  //-----------------------------------------------------------------------------------------------
  always @(posedge clock, negedge nreset) begin
    if(!nreset) begin
      int_lru <= 0;
      mem_lru <= 0;
    end
    else if(flush_valid) begin
      int_lru <= 0;
      mem_lru <= 0;
    end
    else begin
      if(int_issue) begin
        int_lru <= 0;
      end
      else if(int_ready) begin
        int_lru <= int_lru + 1;
      end
      if(mem_issue) begin
        mem_lru <= 0;
      end
      else if(mem_ready) begin
        mem_lru <= mem_lru + 1;
      end
    end
  end

  //-----------------------------------------------------------------------------------------------
  // Multiplication register
  //-----------------------------------------------------------------------------------------------
  always @(posedge clock, negedge nreset) begin
    if(!nreset) begin
      mult_cntr <= 0;
    end
    else if(flush_valid) begin
      mult_cntr <= 0;
    end
    else begin
      mult_cntr <= {mult_cntr[1:0], mult_valid};
    end
  end

  //-----------------------------------------------------------------------------------------------
  // Outputs
  //-----------------------------------------------------------------------------------------------
  always @(posedge clock, negedge nreset) begin
    if(!nreset) begin
      cdb_valid          <= 0;
      cdb_branch         <= 0;
      cdb_branch_taken   <= 0;
      cdb_data_ff        <= 0;
      cdb_tag            <= 0;
      dlyd_access_vector <= 0;
    end
    else if(flush_valid) begin
      cdb_valid          <= 0;
      cdb_branch         <= 0;
      cdb_branch_taken   <= 0;
      cdb_data_ff        <= 0;
      cdb_tag            <= 0;
      dlyd_access_vector <= 0;
    end
    else begin
      cdb_valid          <= 0;
      cdb_branch         <= 0;
      cdb_branch_taken   <= 0;
      cdb_data_ff        <= 0;
      cdb_tag            <= 0;
      dlyd_access_vector <= 0;

      if(mult_cntr[2]) begin
        cdb_valid        <= 1;
        cdb_branch       <= 0;
        cdb_branch_taken <= 0;
        cdb_data_ff      <= mul_dout;
        cdb_tag          <= mul_tag;
      end
      else if(access_vector[0]) begin
        // integer queue has access
        cdb_valid        <= 1;
        cdb_branch       <= int_branch;
        cdb_branch_taken <= int_branch_taken;
        cdb_data_ff      <= int_dout;
        cdb_tag          <= int_tag;
      end
      else if(access_vector[1]) begin
        // load store queue has access
        cdb_valid             <= 1;
        cdb_branch            <= 0;
        cdb_branch_taken      <= 0;
        cdb_data_ff           <= mem_dout;
        cdb_tag               <= mem_tag;
        dlyd_access_vector[1] <= 1;
      end
    end
  end

endmodule

















