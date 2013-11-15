//
//-------------------------------------------------------------------------------------------------
// filename:  rob.v
// author:    ikalvarado
// created:   2012-03-30
//-------------------------------------------------------------------------------------------------
// modification history
// author          date        description
// ialvarado       2012-03-30  creation
//-------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
//
// MODULE: rob
//
//-------------------------------------------------------------------------------------------------
module rob (
  clock,
  nreset,
  rs_reg,
  rt_reg,
  rs_data_valid,
  rs_token,
  rs_data_spec,
  rt_data_valid,
  rt_token,
  rt_data_spec,
  dispatch_update_valid,
  dispatch_rd_tag,
  dispatch_rd_reg,
  dispatch_pc,
  dispatch_inst_type,
  cdb_valid,
  cdb_branch,
  cdb_branch_taken,
  cdb_tag,
  cdb_data,
  retire_valid,
  flush_valid,
  retire_store_ack,
  retire_store_ready,
  retire_rd_tag,
  retire_rd_reg,
  retire_data,
  retire_pc,
  arf_retire_valid
);

  //-----------------------------------------------------------------------------------------------
  //
  // Interfaces
  //
  //-----------------------------------------------------------------------------------------------
  input              clock;
  input              nreset;

  //-----------------------------------------------------------------------------------------------
  // dispatch consults the status or source registers
  //-----------------------------------------------------------------------------------------------
  input       [ 4:0] rs_reg;
  input       [ 4:0] rt_reg;
  output wire        rs_data_valid;
  output wire [ 5:0] rs_token;
  output wire [31:0] rs_data_spec;
  output wire        rt_data_valid;
  output wire [ 5:0] rt_token;
  output wire [31:0] rt_data_spec;

  //-----------------------------------------------------------------------------------------------
  // dispatch writes a new entry in the rob
  //-----------------------------------------------------------------------------------------------

  input              dispatch_update_valid;
  input       [ 4:0] dispatch_rd_tag;
  input       [ 4:0] dispatch_rd_reg;
  input       [31:0] dispatch_pc;
  input       [ 1:0] dispatch_inst_type;

  //-----------------------------------------------------------------------------------------------
  // cdb interface
  //-----------------------------------------------------------------------------------------------
  input              cdb_valid;
  input              cdb_branch;
  input              cdb_branch_taken;
  input       [ 4:0] cdb_tag;
  input       [31:0] cdb_data;

  //-----------------------------------------------------------------------------------------------
  // retire bus
  //-----------------------------------------------------------------------------------------------
  input              retire_store_ack;
  output wire        retire_valid;
  output wire        arf_retire_valid;
  output wire        flush_valid;
  output wire        retire_store_ready;
  output wire [ 4:0] retire_rd_tag;
  output wire [ 4:0] retire_rd_reg;
  output wire [31:0] retire_data;
  output wire [31:0] retire_pc;

  //-----------------------------------------------------------------------------------------------
  //
  // Internal signals
  //
  //-----------------------------------------------------------------------------------------------

  //-----------------------------------------------------------------------------------------------
  // Variables
  //-----------------------------------------------------------------------------------------------
  wire        ret_tag_ready;
  wire [ 4:0] ret_tag;
  wire        ret_acknowledge;
  wire [ 4:0] ret_reg;
  wire [31:0] ret_pc;
  wire [ 1:0] ret_inst_type;
  wire        ret_branch_taken;
  wire [31:0] ret_data;
  wire        oq_full;
  wire        oq_empty;
  wire        rft_rs_data_valid;
  wire        rft_rt_data_valid;

  //-----------------------------------------------------------------------------------------------
  //
  // Logic
  //
  //-----------------------------------------------------------------------------------------------

  assign retire_valid       = ret_acknowledge || retire_store_ack;
  assign flush_valid        = ret_acknowledge && ret_branch_taken;
  assign retire_store_ready = ret_inst_type == 2'h2;
  assign retire_rd_tag      = ret_tag;
  assign retire_rd_reg      = ret_reg;
  assign retire_data        = ret_data;
  assign retire_pc          = ret_pc;
  assign arf_retire_valid   = ret_acknowledge && !(ret_inst_type == 2'h1);
  assign rs_data_valid      = rft_rs_data_valid & rs_token[5];
  assign rt_data_valid      = rft_rt_data_valid & rt_token[5];
  assign ret_tag_ready      = ~oq_empty;

  //-----------------------------------------------------------------------------------------------
  //
  // Modules
  //
  //-----------------------------------------------------------------------------------------------

  //-----------------------------------------------------------------------------------------------
  // Unhelpful comment
  //-----------------------------------------------------------------------------------------------
  register_status_table rs_tablex
  (
    .clock             (clock                 ),
    .nreset            (nreset                ),
    .Wdata_rst         (dispatch_rd_tag       ),
    .Waddr_rst         (dispatch_rd_reg       ),
    .Wen_rst           (dispatch_update_valid ),
    .flush             (flush_valid           ),
    .Rsaddr_rst        (rs_reg                ),
    .Rstag_rst         (rs_token[4:0]         ),
    .Rsvalid_rst       (rs_token[5]           ),
    .Rtaddr_rst        (rt_reg                ),
    .Rttag_rst         (rt_token[4:0]         ),
    .Rtvalid_rst       (rt_token[5]           ),
    .RB_tag_rst        (retire_rd_tag         ),
    .RB_valid_rst      (retire_valid          )
  );

  //-----------------------------------------------------------------------------------------------
  // Unhelpful comment
  //-----------------------------------------------------------------------------------------------
  order_queue order_quex
  (
    .clock             (clock                 ),
    .nreset            (nreset                ),
    .clear             (flush_valid           ),
    .rd_en             (retire_valid          ),
    .wr_en             (dispatch_update_valid ),
    .data_in           (dispatch_rd_tag       ),
    .empty             (oq_empty              ),
    .full              (oq_full               ),
    .data_out          (ret_tag               )
  );

  //-----------------------------------------------------------------------------------------------
  // Unhelpful comment
  //-----------------------------------------------------------------------------------------------
  reg_file_tmp regfiletempx
  (
    .clock              (clock                ),
    .nreset             (nreset               ),
    .flush_valid        (flush_valid           ),
    .dispatch_valid     (dispatch_update_valid),
    .dispatch_rd_tag    (dispatch_rd_tag      ),
    .dispatch_rd_reg    (dispatch_rd_reg      ),
    .dispatch_inst_type (dispatch_inst_type   ),
    .dispatch_pc        (dispatch_pc          ),
    .cdb_valid          (cdb_valid            ),
    .cdb_branch         (cdb_branch           ),
    .cdb_branch_taken   (cdb_branch_taken     ),
    .cdb_tag            (cdb_tag              ),
    .cdb_data           (cdb_data             ),
    .rs_tag             (rs_token[4:0]        ),
    .rt_tag             (rt_token[4:0]        ),
    .rs_data_valid      (rft_rs_data_valid    ),
    .rs_data_spec       (rs_data_spec         ),
    .rt_data_valid      (rft_rt_data_valid    ),
    .rt_data_spec       (rt_data_spec         ),
    .retire_tag_ready   (ret_tag_ready        ),
    .retire_tag         (ret_tag              ),
    .retire_store_ack   (retire_store_ack     ),
    .retire_acknowledge (ret_acknowledge      ),
    .retire_reg         (ret_reg              ),
    .retire_pc          (ret_pc               ),
    .retire_inst_type   (ret_inst_type        ),
    .retire_branch_taken(ret_branch_taken     ),
    .retire_data        (ret_data             )
  );

endmodule

















