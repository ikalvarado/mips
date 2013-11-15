//
//-------------------------------------------------------------------------------------------------
// filename:  d_cache.v
// author:    lgonzale
// created:   2012-04-07
//-------------------------------------------------------------------------------------------------
// modification history
// author          date        description
// lgonzale        2012-04-07  creation
//-------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
// module: d_cache
//-------------------------------------------------------------------------------------------------

module d_cache (
  nreset,
  clock,
  ls_ready_in,
  ls_issue_out,
  data_in,
  address,
  tag_in,
  opcode,
  ls_ready_out,
  ls_issue_in,
  data_out,
  tag_out,
  ex_addr,
  ex_data_out,
  retire_store_ack
);

  parameter DEPTH = 128;

  //-----------------------------------------------------------------------------------------------
  // inputs
  //-----------------------------------------------------------------------------------------------
  input              nreset;
  input              clock;
  input              ls_ready_in;
  input              ls_issue_in;
  input       [31:0] data_in;
  input       [31:0] address;
  input       [ 4:0] tag_in;
  input              opcode;
  input       [31:0] ex_addr;
  output wire        retire_store_ack;

  //-----------------------------------------------------------------------------------------------
  // outputs
  //-----------------------------------------------------------------------------------------------
  output wire        ls_issue_out;
  output wire        ls_ready_out;
  output wire [31:0] data_out;
  output wire [ 4:0] tag_out;
  output wire [31:0] ex_data_out;

  //-----------------------------------------------------------------------------------------------
  // registers
  //-----------------------------------------------------------------------------------------------

  true_dual_port_ram ram (
    .clk   (clock            ),
    .data_a(data_in          ),
    .addr_a(address[6:2]     ),
    .we_a  (retire_store_ack ),
    .q_a   (data_out         ),
    .data_b(32'h0            ),
    .addr_b(ex_addr[6:2]     ),
    .we_b  (1'h0             ),
    .q_b   (ex_data_out      )
  );

  //-----------------------------------------------------------------------------------------------
  // load
  //-----------------------------------------------------------------------------------------------
  assign ls_ready_out     = ls_ready_in && opcode == 0;
  assign ls_issue_out     = ls_issue_in;
  assign tag_out          = tag_in;
  assign retire_store_ack = ls_ready_in && opcode;

endmodule




