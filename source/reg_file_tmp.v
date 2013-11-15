//
//-------------------------------------------------------------------------------------------------
// filename:  reg_file_tmp.v
// author:    ikalvarado
// created:   2012-03-05
//-------------------------------------------------------------------------------------------------
// modification history
// author          date        description
// ialvarado       2012-03-05  creation
//-------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
//
// MODULE: reg_file_tmp
//
//-------------------------------------------------------------------------------------------------
module reg_file_tmp (
  clock,
  nreset,
  flush_valid,
  dispatch_valid,
  dispatch_rd_tag,
  dispatch_rd_reg,
  dispatch_inst_type,
  dispatch_pc,
  cdb_valid,
  cdb_branch,
  cdb_branch_taken,
  cdb_tag,
  cdb_data,
  rs_tag,
  rt_tag,
  rs_data_valid,
  rs_data_spec,
  rt_data_valid,
  rt_data_spec,
  retire_tag_ready,
  retire_tag,
  retire_store_ack,
  retire_acknowledge,
  retire_reg,
  retire_pc,
  retire_inst_type,
  retire_data,
  retire_branch_taken
);

  //-----------------------------------------------------------------------------------------------
  // Inputs
  //-----------------------------------------------------------------------------------------------
  input clock;
  input nreset;
  input flush_valid;
  // Dispatch new entry interface
  input        dispatch_valid;
  input [4:0]  dispatch_rd_tag;
  input [4:0]  dispatch_rd_reg;
  input [1:0]  dispatch_inst_type;
  input [31:0] dispatch_pc;
  // CDB update entry interface
  input        cdb_valid;
  input        cdb_branch;
  input        cdb_branch_taken;
  input [4:0]  cdb_tag;
  input [31:0] cdb_data;
  // Dispatch consult interface for RS
  input [4:0]  rs_tag;
  // Dispatch consult interface for RT
  input [4:0]  rt_tag;
  // Retire interface
  input        retire_tag_ready;
  input [4:0]  retire_tag;
  input        retire_store_ack;

  //-----------------------------------------------------------------------------------------------
  // Outputs
  //-----------------------------------------------------------------------------------------------
  // Dispatch consult interface for RS
  output wire        rs_data_valid;
  output wire [31:0] rs_data_spec;
  // Dispatch consult interface for RT
  output wire        rt_data_valid;
  output wire [31:0] rt_data_spec;
  // Retire interface
  output wire        retire_acknowledge;
  output wire [ 4:0] retire_reg;
  output wire [31:0] retire_pc;
  output wire [ 1:0] retire_inst_type;
  output wire [31:0] retire_data;
  output wire        retire_branch_taken;

  //-----------------------------------------------------------------------------------------------
  // Memory
  //-----------------------------------------------------------------------------------------------
  reg [(5+32+2+1+32+1+1)-1:0] memory_array [0:31];

  //-----------------------------------------------------------------------------------------------
  // Variables
  //-----------------------------------------------------------------------------------------------
  integer i;

  //-----------------------------------------------------------------------------------------------
  // Logic
  //-----------------------------------------------------------------------------------------------
  assign rs_data_valid = &(memory_array[rs_tag][ 1:0]);
  assign rs_data_spec  =  (memory_array[rs_tag][33:2]);
  assign rt_data_valid = &(memory_array[rt_tag][ 1:0]);
  assign rt_data_spec  =  (memory_array[rt_tag][33:2]);

  assign retire_acknowledge = retire_tag_ready && memory_array[retire_tag][0] &&
    (memory_array[retire_tag][1]) && (memory_array[retire_tag][36:35] != 2'h2);
  assign retire_reg          = memory_array[retire_tag][73:69];
  assign retire_pc           = memory_array[retire_tag][68:37];
  assign retire_inst_type    = memory_array[retire_tag][36:35];
  assign retire_branch_taken = memory_array[retire_tag][34:34];
  assign retire_data         = memory_array[retire_tag][33:02];

  //-----------------------------------------------------------------------------------------------
  // Registers
  //-----------------------------------------------------------------------------------------------
  always @(posedge clock, negedge nreset) begin
    if(!nreset) begin
      for(i = 0; i < 32; i = i + 1) begin
        memory_array[i] <= 0;
      end
    end
    else if(flush_valid) begin
      for(i = 0; i < 32; i = i + 1) begin
        memory_array[i] <= 0;
      end
    end
    else begin
      if(cdb_valid) begin
        memory_array[cdb_tag][34:1] <= {cdb_branch_taken, cdb_data, 1'b1};
      end
      if(dispatch_valid) begin
        memory_array[dispatch_rd_tag] <=
          {dispatch_rd_reg, dispatch_pc, dispatch_inst_type, 34'b0, 1'b1};
      end
      else if(retire_acknowledge || retire_store_ack) begin
        memory_array[retire_tag] <= 0;
      end
    end
  end

endmodule
