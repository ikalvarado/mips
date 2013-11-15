//
//-------------------------------------------------------------------------------------------------
// filename:  ifq.v
// author:    ikalvarado
// created:   2012-02-03
//-------------------------------------------------------------------------------------------------
// modification history
// author          date        description
// ialvarado       2012-02-03  creation
//-------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
//
// MODULE: ifq
//
//-------------------------------------------------------------------------------------------------
module ifq (
  clock,
  nreset,
  rd_en,
  branch_valid,
  dout_valid,
  branch_address,
  dout,
  empty,
  i_cache_rd_en,
  pc_in,
  pc_out,
  inst
);

  //-----------------------------------------------------------------------------------------------
  // Inputs
  //-----------------------------------------------------------------------------------------------
  input clock;
  input nreset;
  input rd_en;
  input branch_valid;
  input dout_valid;

  input [31:0]  branch_address;
  input [127:0] dout;

  //-----------------------------------------------------------------------------------------------
  // Outputs
  //-----------------------------------------------------------------------------------------------
  output empty;
  output i_cache_rd_en;

  output [31:0] pc_in;
  output [31:0] pc_out;
  output [31:0] inst;

  //-----------------------------------------------------------------------------------------------
  // Memory
  //-----------------------------------------------------------------------------------------------
  reg [127:0] memory_array [0:3];

  //-----------------------------------------------------------------------------------------------
  // Variables
  //-----------------------------------------------------------------------------------------------
  reg  [ 4:0] wr_ptr;
  reg  [ 4:0] rd_ptr;
  reg  [31:0] pc_out;
  reg  [31:0] pc_inr;
  reg  [31:0] inst;
  reg         i_cache_rd_en;
  wire [31:0] pc_in;

  //-----------------------------------------------------------------------------------------------
  // Nets
  //-----------------------------------------------------------------------------------------------
  wire empty;
  wire internal_empty_flag;
  wire full;

  //-----------------------------------------------------------------------------------------------
  // logic
  //-----------------------------------------------------------------------------------------------
  assign internal_empty_flag = (wr_ptr[4:2] == rd_ptr[4:2]) | branch_valid;
  assign empty = internal_empty_flag;
  assign full  = (wr_ptr[4] != rd_ptr[4]) && (wr_ptr[3:2] == rd_ptr[3:2]);
  assign pc_in = branch_valid ? {branch_address[31:4], 4'h0}: pc_inr;

  //-----------------------------------------------------------------------------------------------
  // Registers logic
  //-----------------------------------------------------------------------------------------------
  always @(posedge clock, negedge nreset) begin
    if(!nreset) begin
      rd_ptr <= 0;
      pc_out <= 0;
    end
    else if (branch_valid) begin
      rd_ptr <= {2'b0, branch_address[3:2]};
      pc_out <= branch_address;
    end
    else begin
      if(rd_en && !empty) begin
        rd_ptr <= rd_ptr + 1;
        pc_out <= pc_out + 4;
      end
    end
  end

  //-----------------------------------------------------------------------------------------------
  // Registers logic
  //-----------------------------------------------------------------------------------------------
  always @(posedge clock, negedge nreset) begin
    if(!nreset) begin
      i_cache_rd_en <= 0;
      wr_ptr <= 0;
      pc_inr <= 0;
    end
    else if (branch_valid) begin
      wr_ptr <= 0;
      pc_inr <= {branch_address[31:4], 4'h0};
    end
    else begin
      if(!dout_valid && !full) begin
        i_cache_rd_en <= 1;
      end
      else if(i_cache_rd_en && dout_valid && !full) begin
        i_cache_rd_en <= 0;
        memory_array[wr_ptr[3:2]] <= dout;
        wr_ptr <= wr_ptr + 4;
        pc_inr <= pc_inr+ 16;
      end
    end
  end

  //-----------------------------------------------------------------------------------------------
  // Multiplexors
  //-----------------------------------------------------------------------------------------------
  always @(*) begin
    if(internal_empty_flag & dout_valid) begin
      case(rd_ptr[1:0])
        'h0: inst = dout[ 31: 0];
        'h1: inst = dout[ 63:32];
        'h2: inst = dout[ 95:64];
        'h3: inst = dout[127:96];
      endcase
    end
    else begin
      case(rd_ptr[1:0])
        'h0: inst = memory_array[rd_ptr[3:2]][ 31: 0];
        'h1: inst = memory_array[rd_ptr[3:2]][ 63:32];
        'h2: inst = memory_array[rd_ptr[3:2]][ 95:64];
        'h3: inst = memory_array[rd_ptr[3:2]][127:96];
      endcase
    end
  end


endmodule
