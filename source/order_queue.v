//
//-------------------------------------------------------------------------------------------------
// filename:  order_queue.v
// author:    ikalvarado
// created:   2012-03-05
//-------------------------------------------------------------------------------------------------
// modification history
// author          date        description
// ialvarado       2012-03-05  creation
//-------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
//
// MODULE: order_queue
//
//-------------------------------------------------------------------------------------------------
module order_queue (
  clock,
  nreset,
  clear,
  rd_en,
  wr_en,
  empty,
  full,
  data_in,
  data_out
);

  //-----------------------------------------------------------------------------------------------
  // Inputs
  //-----------------------------------------------------------------------------------------------
  input clock;
  input nreset;
  input clear;
  input rd_en;
  input wr_en;

  input [4:0] data_in;

  //-----------------------------------------------------------------------------------------------
  // Outputs
  //-----------------------------------------------------------------------------------------------
  output empty;
  output full;
  output [4:0] data_out;

  //-----------------------------------------------------------------------------------------------
  // Memory
  //-----------------------------------------------------------------------------------------------
  reg [4:0] memory_array [0:31];

  //-----------------------------------------------------------------------------------------------
  // Variables
  //-----------------------------------------------------------------------------------------------
  reg [5:0] wr_ptr;
  reg [5:0] rd_ptr;

  //-----------------------------------------------------------------------------------------------
  // logic
  //-----------------------------------------------------------------------------------------------
  assign empty    = (wr_ptr == rd_ptr);
  assign full     = (wr_ptr[5] != rd_ptr[5]) && (wr_ptr[4:0] == rd_ptr[4:0]);
  assign data_out = empty ? 0 : memory_array[rd_ptr[4:0]];

  //-----------------------------------------------------------------------------------------------
  // Registers logic
  //-----------------------------------------------------------------------------------------------
  always @(posedge clock, negedge nreset) begin
    if(!nreset) begin
      rd_ptr <= 0;
    end
    else if(clear) begin
      rd_ptr <= 0;
    end
    else begin
      if(rd_en && !empty) begin
        rd_ptr <= rd_ptr + 1;
      end
    end
  end

  //-----------------------------------------------------------------------------------------------
  // Registers logic
  //-----------------------------------------------------------------------------------------------
  always @(posedge clock, negedge nreset) begin
    if(!nreset) begin
      wr_ptr <= 0;
    end
    else if(clear) begin
      wr_ptr <= 0;
    end
    else begin
      if(wr_en && !full) begin
        memory_array[wr_ptr[4:0]] <= data_in;
        wr_ptr <= wr_ptr + 1;
      end
    end
  end

endmodule