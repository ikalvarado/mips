//
//-------------------------------------------------------------------------------------------------
// filename:  integer_queue.v
// author:    Diana García
// created:   2012-03-30
//-------------------------------------------------------------------------------------------------
// modification history
// author          date        description
// Diana García    2012-03-30  creation
//-------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
//
// MODULE: integer_queue
//
//-------------------------------------------------------------------------------------------------
module integer_queue (
  clock,
  nreset,
  dispatch_enable,
  dispatch_opcode,
  dispatch_rd_tag,
  dispatch_rs_data,
  dispatch_rs_tag,
  dispatch_rs_data_val,
  dispatch_rt_data,
  dispatch_rt_tag,
  dispatch_rt_data_val,
  dispatch_shfamt,
  full,
  cdb_valid,
  cdb_tag,
  cdb_data,
  issueblk_issue,
  issueque_ready,
  issueque_rs_data,
  issueque_rt_data,
  issueque_rd_tag,
  issueque_opcode,
  issueque_shfamt,
  flush_valid
);

  //-----------------------------------------------------------------------------------------------
  //
  // Parameters
  //
  //-----------------------------------------------------------------------------------------------

  //-----------------------------------------------------------------------------------------------
  //
  // Interfaces
  //
  //-----------------------------------------------------------------------------------------------
  input clock;
  input nreset;

  //-------------------------------------------------------------------------------------------------
  // Dispatch interface
  //-------------------------------------------------------------------------------------------------
  input             dispatch_enable;
  input      [ 3:0] dispatch_opcode;
  input      [ 4:0] dispatch_rd_tag;
  input      [31:0] dispatch_rs_data;
  input      [ 4:0] dispatch_rs_tag;
  input             dispatch_rs_data_val;
  input      [31:0] dispatch_rt_data;
  input      [ 4:0] dispatch_rt_tag;
  input             dispatch_rt_data_val;
  input      [ 4:0] dispatch_shfamt;

  output reg        full;

  //-------------------------------------------------------------------------------------------------
  // CDB interface
  //-------------------------------------------------------------------------------------------------
  input             cdb_valid;
  input      [ 4:0] cdb_tag;
  input      [31:0] cdb_data;

  //-------------------------------------------------------------------------------------------------
  // Issue unit interface
  //-------------------------------------------------------------------------------------------------
  input             issueblk_issue;
  output reg        issueque_ready;
  output reg [31:0] issueque_rs_data;
  output reg [31:0] issueque_rt_data;
  output reg [ 4:0] issueque_rd_tag;
  output reg [ 3:0] issueque_opcode;
  output reg [ 4:0] issueque_shfamt;

  //-------------------------------------------------------------------------------------------------
  // ROB interface
  //-------------------------------------------------------------------------------------------------
  input             flush_valid;

  //-----------------------------------------------------------------------------------------------
  //
  // Internal signals
  //
  //-----------------------------------------------------------------------------------------------
  integer i;
  genvar n;

  //-----------------------------------------------------------------------------------------------
  // Variables
  //-----------------------------------------------------------------------------------------------
  reg [4+5+5+32+5+1+32+5+1+1-1:0] shft_regs [0:3];
  reg [4+5+5+32+5+1+32+5+1+1-1:0] cmpt_data [0:3];
  reg [4+5+5+32+5+1+32+5+1+1-1:0] shft_data [0:3];
  reg [4+5+5+32+5+1+32+5+1+1-1:0] shup_data [0:3];
  reg [31:0] updt_rs_data [0:3];
  reg [31:0] updt_rt_data [0:3];

  reg  [ 3:0] ctrl_shf;
  reg  clear_entry;

  wire [ 3:0] rs_match;
  wire [ 3:0] rt_match;
  wire [ 3:0] rs_data_val;
  wire [ 3:0] rt_data_val;
  wire [ 3:0] entry_valid;
  wire [ 3:0] entry_ready;
  wire [ 3:0] opcode[3:0];
  wire [ 4:0] shfamt[3:0];
  wire [ 4:0] rd_tag[3:0];
  wire [31:0] rs_data[3:0];
  wire [31:0] rt_data[3:0];

  //-----------------------------------------------------------------------------------------------
  //
  // Combinational logic
  //
  //-----------------------------------------------------------------------------------------------

  //-----------------------------------------------------------------------------------------------
  // Internal logic
  //-----------------------------------------------------------------------------------------------
  generate
    for(n = 0; n < 4; n = n + 1) begin: INTEG
      assign rs_match[n]    = cdb_valid & (shft_regs[n][44:40] == cdb_tag) & shft_regs[n][0] & !shft_regs[n][39];
      assign rt_match[n]    = cdb_valid & (shft_regs[n][ 6: 2] == cdb_tag) & shft_regs[n][0] & !shft_regs[n][ 1];
      assign rs_data_val[n] = shft_regs[n][39];
      assign rt_data_val[n] = shft_regs[n][ 1];
      assign entry_valid[n] = shft_regs[n][ 0];
      assign entry_ready[n] = shft_regs[n][39] & shft_regs[n][ 1] & shft_regs[n][0];
      assign opcode[n]      = shft_regs[n][90:87];
      assign shfamt[n]      = shft_regs[n][86:82];
      assign rd_tag[n]      = shft_regs[n][81:77];
      assign rs_data[n]     = shft_regs[n][76:45];
      assign rt_data[n]     = shft_regs[n][38: 7];
    end
  endgenerate

  //-----------------------------------------------------------------------------------------------
  // Continuous output assignments
  //-----------------------------------------------------------------------------------------------
  always @(*) begin
    issueque_ready =
      (entry_ready[0]) |
      (entry_ready[1]) |
      (entry_ready[2]) |
      (entry_ready[3]);

    full = (&entry_valid) & !issueblk_issue;

    casex (entry_ready)
    4'b1xxx: begin
      issueque_rs_data = rs_data[3];
      issueque_rt_data = rt_data[3];
      issueque_rd_tag  = rd_tag [3];
      issueque_opcode  = opcode [3];
      issueque_shfamt  = shfamt [3];
    end
    4'b01xx: begin
      issueque_rs_data = rs_data[2];
      issueque_rt_data = rt_data[2];
      issueque_rd_tag  = rd_tag [2];
      issueque_opcode  = opcode [2];
      issueque_shfamt  = shfamt [2];
    end
    4'b001x: begin
      issueque_rs_data = rs_data[1];
      issueque_rt_data = rt_data[1];
      issueque_rd_tag  = rd_tag [1];
      issueque_opcode  = opcode [1];
      issueque_shfamt  = shfamt [1];
    end
    4'b0001: begin
      issueque_rs_data = rs_data[0];
      issueque_rt_data = rt_data[0];
      issueque_rd_tag  = rd_tag [0];
      issueque_opcode  = opcode [0];
      issueque_shfamt  = shfamt [0];
    end
    default: begin
      issueque_rs_data = 0;
      issueque_rt_data = 0;
      issueque_rd_tag  = 0;
      issueque_opcode  = 0;
      issueque_shfamt  = 0;
    end
    endcase
  end

  //-----------------------------------------------------------------------------------------------
  // Register value computation
  //-----------------------------------------------------------------------------------------------
  always @(*) begin
    shft_data[3] = ctrl_shf[3] ? shft_regs[2] : shft_regs[3];
    shft_data[2] = ctrl_shf[2] ? shft_regs[1] : shft_regs[2];
    shft_data[1] = ctrl_shf[1] ? shft_regs[0] : shft_regs[1];
    shft_data[0] = ctrl_shf[0] ? {
      dispatch_opcode,
      dispatch_shfamt,
      dispatch_rd_tag,
      dispatch_rs_data,
      dispatch_rs_tag,
      dispatch_rs_data_val,
      dispatch_rt_data,
      dispatch_rt_tag,
      dispatch_rt_data_val,
      1'b1
    } : shft_regs[0];

    updt_rs_data[3] = ctrl_shf[3] ? (rs_match[2] ? cdb_data : rs_data[2]) : (rs_match[3] ? cdb_data : rs_data[3]);
    updt_rs_data[2] = ctrl_shf[2] ? (rs_match[1] ? cdb_data : rs_data[1]) : (rs_match[2] ? cdb_data : rs_data[2]);
    updt_rs_data[1] = ctrl_shf[1] ? (rs_match[0] ? cdb_data : rs_data[0]) : (rs_match[1] ? cdb_data : rs_data[1]);
    updt_rs_data[0] = dispatch_rs_data;

    updt_rt_data[3] = ctrl_shf[3] ? (rt_match[2] ? cdb_data : rt_data[2]) : (rt_match[3] ? cdb_data : rt_data[3]);
    updt_rt_data[2] = ctrl_shf[2] ? (rt_match[1] ? cdb_data : rt_data[1]) : (rt_match[2] ? cdb_data : rt_data[2]);
    updt_rt_data[1] = ctrl_shf[1] ? (rt_match[0] ? cdb_data : rt_data[0]) : (rt_match[1] ? cdb_data : rt_data[1]);
    updt_rt_data[0] = dispatch_rt_data;

    shup_data[3] = {shft_data[3][90:77],
      updt_rs_data[3], shft_data[3][44:40], shft_data[3][39] | (rs_match[3] & ~ctrl_shf[3]) | (rs_match[2] & ctrl_shf[3]),
      updt_rt_data[3], shft_data[3][ 6: 2], shft_data[3][ 1] | (rt_match[3] & ~ctrl_shf[3]) | (rt_match[2] & ctrl_shf[3]),
      shft_data[3][0]};
    shup_data[2] = {shft_data[2][90:77],
      updt_rs_data[2], shft_data[2][44:40], shft_data[2][39] | (rs_match[2] & ~ctrl_shf[2]) | (rs_match[1] & ctrl_shf[2]),
      updt_rt_data[2], shft_data[2][ 6: 2], shft_data[2][ 1] | (rt_match[2] & ~ctrl_shf[2]) | (rt_match[1] & ctrl_shf[2]),
      shft_data[2][0]};
    shup_data[1] = {shft_data[1][90:77],
      updt_rs_data[1], shft_data[1][44:40], shft_data[1][39] | (rs_match[1] & ~ctrl_shf[1]) | (rs_match[0] & ctrl_shf[1]),
      updt_rt_data[1], shft_data[1][ 6: 2], shft_data[1][ 1] | (rt_match[1] & ~ctrl_shf[1]) | (rt_match[0] & ctrl_shf[1]),
      shft_data[1][0]};
    shup_data[0] = {shft_data[0][90:77],
      updt_rs_data[0], shft_data[0][44:40], shft_data[0][39] | (rs_match[0] & ~ctrl_shf[0]) | (dispatch_rs_data_val & ctrl_shf[0]),
      updt_rt_data[0], shft_data[0][ 6: 2], shft_data[0][ 1] | (rt_match[0] & ~ctrl_shf[0]) | (dispatch_rt_data_val & ctrl_shf[0]),
      shft_data[0][0]};

    cmpt_data[0] = clear_entry ? 0 : shup_data[0];
    cmpt_data[1] = shup_data[1];
    cmpt_data[2] = shup_data[2];
    cmpt_data[3] = shup_data[3];
  end

  //-----------------------------------------------------------------------------------------------
  // Determine shift control signals
  //-----------------------------------------------------------------------------------------------
  always @(*) begin
    clear_entry = !dispatch_enable && !full;
    if(issueblk_issue) begin
      ctrl_shf[0] = dispatch_enable;
      casex (entry_ready)
      4'b1xxx: begin
        ctrl_shf[1] = 1;
        ctrl_shf[2] = 1;
        ctrl_shf[3] = 1;
      end
      4'b01xx: begin
        ctrl_shf[1] = 1;
        ctrl_shf[2] = 1;
        ctrl_shf[3] = 0;
      end
      4'b001x: begin
        ctrl_shf[1] = 1;
        ctrl_shf[2] = 0;
        ctrl_shf[3] = 0;
      end
      4'b0001: begin
        ctrl_shf[1] = 0;
        ctrl_shf[2] = 0;
        ctrl_shf[3] = 0;
      end
      default: begin
        ctrl_shf[1] = 0;
        ctrl_shf[2] = 0;
        ctrl_shf[3] = 0;
      end
      endcase
    end
    else begin
      ctrl_shf[0] = dispatch_enable && !full;
      ctrl_shf[1] = !(shft_regs[1][0] & shft_regs[2][0] & shft_regs[3][0]);
      ctrl_shf[2] = !(shft_regs[2][0] & shft_regs[3][0]);
      ctrl_shf[3] = !(shft_regs[3][0]);
    end
  end

  //-----------------------------------------------------------------------------------------------
  //
  // Registers
  //
  //-----------------------------------------------------------------------------------------------
  always @(posedge clock, negedge nreset) begin
    if(!nreset) begin
      for(i = 0; i < 4; i = i + 1) begin
        shft_regs[i] <= 0;
      end
    end
    else if(flush_valid) begin
      for(i = 0; i < 4; i = i + 1) begin
        shft_regs[i] <= 0;
      end
    end
    else begin
      shft_regs[0] <= cmpt_data[0];
      shft_regs[1] <= cmpt_data[1];
      shft_regs[2] <= cmpt_data[2];
      shft_regs[3] <= cmpt_data[3];
    end
  end

endmodule

















