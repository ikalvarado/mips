//
//-------------------------------------------------------------------------------------------------
// filename:  MIPS_SE_TOP.v
//-------------------------------------------------------------------------------------------------
// modification history
// author          date        description
//-------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
//
// MODULE: MIPS_SE_TOP
//
//-------------------------------------------------------------------------------------------------
module MIPS_SE_TOP(clock, nreset, ex_addr, ex_data_out);

  input              clock;
  input              nreset;
  input       [31:0] ex_addr;
  output wire [31:0] ex_data_out;

  //-----------------------------------------------------------------------------------------------
  // instruction fetch queue interface
  //-----------------------------------------------------------------------------------------------
  wire         tag_fifo_empty;
  wire [  4:0] tag_out;
  wire         tag_fifo_ren;

  //-----------------------------------------------------------------------------------------------
  // instruction fetch queue interface
  //-----------------------------------------------------------------------------------------------
  wire         ifetch_empty_flag;
  wire [ 31:0] ifetch_instruction;
  wire [ 31:0] ifetch_pc_plus_four;
  wire         dispatch_ren;
  wire         dispatch_jmp;
  wire [ 31:0] dispatch_jmp_addr;

  //-----------------------------------------------------------------------------------------------
  // architectural register file interface
  //-----------------------------------------------------------------------------------------------
  wire [ 31:0] arf_data_out_rs;
  wire [ 31:0] arf_data_out_rt;
  wire [  4:0] arf_rd_addr_rs;
  wire [  4:0] arf_rd_addr_rt;

  //-----------------------------------------------------------------------------------------------
  // queues interface
  //-----------------------------------------------------------------------------------------------
  wire         dispatch_rs_data_valid;
  wire [ 31:0] dispatch_rs_data;
  wire [  4:0] dispatch_rs_tag;

  wire         dispatch_rt_data_valid;
  wire [ 31:0] dispatch_rt_data;
  wire [  4:0] dispatch_rt_tag;

  wire [  4:0] dispatch_rd_tag;

  //-----------------------------------------------------------------------------------------------
  // integer queue interface
  //-----------------------------------------------------------------------------------------------
  wire         issueque_integer_full;
  wire         dispatch_en_integer;
  wire [  3:0] dispatch_alu_opcode;
  wire [  4:0] dispatch_shfamt;

  //-----------------------------------------------------------------------------------------------
  // load and store queue interface
  //-----------------------------------------------------------------------------------------------
  wire         issueque_ld_st_full;
  wire         dispatch_en_ld_st;
  wire         dispatch_mem_opcode;
  wire [ 15:0] dispatch_imm_ld_st;

  //-----------------------------------------------------------------------------------------------
  // multiplication queue
  //-----------------------------------------------------------------------------------------------
  wire         issueque_mul_full;
  wire         dispatch_en_mul;

  //-----------------------------------------------------------------------------------------------
  // rob query interface
  //-----------------------------------------------------------------------------------------------
  wire         rob_rs_data_valid;
  wire [  5:0] rob_rs_token;
  wire [ 31:0] rob_rs_data_spec;
  wire [  4:0] rob_rs_reg;

  wire         rob_rt_data_valid;
  wire [  5:0] rob_rt_token;
  wire [ 31:0] rob_rt_data_spec;
  wire [  4:0] rob_rt_reg;

  //-----------------------------------------------------------------------------------------------
  // rob update interface
  //-----------------------------------------------------------------------------------------------
  wire         dispatch_update_valid;
  wire [  4:0] dispatch_rd_reg;
  wire [ 31:0] dispatch_pc;
  wire [  1:0] dispatch_inst_type;

  //-----------------------------------------------------------------------------------------------
  // fetch queue
  //-----------------------------------------------------------------------------------------------
  wire         branch_valid;
  wire         rd_en;
  wire [ 31:0] branch_address;
  wire         dout_valid;
  wire         empty;
  wire         i_cache_rd_en;
  wire [ 31:0] pc_in;
  wire [ 31:0] pc_out;
  wire [ 31:0] inst;
  wire [127:0] dout;

  //-----------------------------------------------------------------------------------------------
  // integer issue queue signals
  //-----------------------------------------------------------------------------------------------
  wire [  4:0] cdb_tag;
  wire [ 31:0] cdb_data;
  wire         cdb_valid;
  wire         flush_valid;
  wire         integer_issueblk_issue;
  wire         integer_issueque_ready;
  wire [ 31:0] integer_issueque_rs_data;
  wire [ 31:0] integer_issueque_rt_data;
  wire [  4:0] integer_issueque_rd_tag;
  wire [  3:0] integer_issueque_opcode;
  wire [  4:0] integer_issueque_shfamt;
  wire         mult_issueblk_issue;
  wire         mult_issueque_ready;
  wire [ 31:0] mult_issueque_rs_data;
  wire [ 31:0] mult_issueque_rt_data;
  wire [  4:0] mult_issueque_rd_tag;
  wire         ldst_issueque_ready;
  wire         ldst_issueblk_issue;
  wire         ldst_issueque_opcode;
  wire [ 31:0] ldst_issueque_rs_data;
  wire [ 31:0] ldst_issueque_rt_data;
  wire [  4:0] ldst_issueque_rd_tag;

  //-----------------------------------------------------------------------------------------------
  // Retire
  //-----------------------------------------------------------------------------------------------
  wire [  4:0] retire_rd_tag;
  wire         retire_store_ready;
  wire [ 31:0] retire_pc;
  wire         retire_valid;
  wire [ 31:0] retire_data;
  wire [  4:0] retire_rd_reg;

  //-----------------------------------------------------------------------------------------------
  // issue unit signals
  //-----------------------------------------------------------------------------------------------
  wire [ 31:0] int_dout;
  wire [  4:0] int_tag;
  wire         int_branch;
  wire         int_branch_taken;
  wire [ 31:0] mul_dout;
  wire [  4:0] mul_tag;
  wire         mem_ready;
  wire [ 31:0] mem_dout;
  wire [  4:0] mem_tag;
  wire         mem_issue;
  wire         cdb_branch;
  wire         cdb_branch_taken;
  wire         retire_store_ack;

  //-----------------------------------------------------------------------------------------------
  // translations
  //-----------------------------------------------------------------------------------------------
  assign ifetch_empty_flag   = empty;
  assign ifetch_instruction  = inst;
  assign ifetch_pc_plus_four = pc_out;
  assign rd_en               = dispatch_ren;
  assign branch_valid        = dispatch_jmp | flush_valid;
  assign branch_address      = flush_valid ? retire_pc : dispatch_jmp_addr;

  tag_fifo_optimized tag_fifox(
    .clock                 (clock                   ),
    .nreset                (nreset                  ),
    .flush_valid           (flush_valid             ),
    .rd_en                 (tag_fifo_ren            ),
    .wr_en                 (retire_valid            ),
    .tag_in                (retire_rd_tag           ),
    .tag_out               (tag_out                 ),
    .tag_fifo_empty        (tag_fifo_empty          )
  );

  ifq ifqx(
    .clock                 (clock                   ),
    .nreset                (nreset                  ),
    .rd_en                 (rd_en                   ),
    .branch_valid          (branch_valid            ),
    .dout_valid            (dout_valid              ),
    .branch_address        (branch_address          ),
    .dout                  (dout                    ),
    .empty                 (empty                   ),
    .i_cache_rd_en         (i_cache_rd_en           ),
    .pc_in                 (pc_in                   ),
    .pc_out                (pc_out                  ),
    .inst                  (inst                    )
  );

  i_cache i_cachex(
    .clock                 (clock                   ),
    .nreset                (nreset                  ),
    .rd_en                 (i_cache_rd_en           ),
    .pc_in                 (pc_in                   ),
    .dout_valid            (dout_valid              ),
    .dout                  (dout                    )
  );

  register_file arfx(
    .clock                 (clock                   ),
    .nreset                (nreset                  ),
    .w_en                  (arf_retire_valid        ),
    .data_in               (retire_data             ),
    .waddr                 (retire_rd_reg           ),
    .rd_addr_rs            (arf_rd_addr_rs          ),
    .rd_addr_rt            (arf_rd_addr_rt          ),
    .data_out_rs           (arf_data_out_rs         ),
    .data_out_rt           (arf_data_out_rt         )
  );

  dispatcher dispatcherx(
    .clock                 (clock                   ),
    .nreset                (nreset                  ),
    .flush_valid           (flush_valid             ),
    .tag_fifo_empty        (tag_fifo_empty          ),
    .tag_out               (tag_out                 ),
    .tag_fifo_ren          (tag_fifo_ren            ),
    .ifetch_empty_flag     (ifetch_empty_flag       ),
    .ifetch_instruction    (ifetch_instruction      ),
    .ifetch_pc_plus_four   (ifetch_pc_plus_four     ),
    .dispatch_ren          (dispatch_ren            ),
    .dispatch_jmp          (dispatch_jmp            ),
    .dispatch_jmp_addr     (dispatch_jmp_addr       ),
    .arf_data_out_rs       (arf_data_out_rs         ),
    .arf_data_out_rt       (arf_data_out_rt         ),
    .arf_rd_addr_rs        (arf_rd_addr_rs          ),
    .arf_rd_addr_rt        (arf_rd_addr_rt          ),
    .dispatch_rs_data_valid(dispatch_rs_data_valid  ),
    .dispatch_rs_data      (dispatch_rs_data        ),
    .dispatch_rs_tag       (dispatch_rs_tag         ),
    .dispatch_rt_data_valid(dispatch_rt_data_valid  ),
    .dispatch_rt_data      (dispatch_rt_data        ),
    .dispatch_rt_tag       (dispatch_rt_tag         ),
    .dispatch_rd_tag       (dispatch_rd_tag         ),
    .issueque_integer_full (issueque_integer_full   ),
    .dispatch_en_integer   (dispatch_en_integer     ),
    .dispatch_alu_opcode   (dispatch_alu_opcode     ),
    .dispatch_shfamt       (dispatch_shfamt         ),
    .issueque_ld_st_full   (issueque_ld_st_full     ),
    .dispatch_en_ld_st     (dispatch_en_ld_st       ),
    .dispatch_mem_opcode   (dispatch_mem_opcode     ),
    .dispatch_imm_ld_st    (dispatch_imm_ld_st      ),
    .issueque_mul_full     (issueque_mul_full       ),
    .dispatch_en_mul       (dispatch_en_mul         ),
    .rob_rs_data_valid     (rob_rs_data_valid       ),
    .rob_rs_token          (rob_rs_token            ),
    .rob_rs_data_spec      (rob_rs_data_spec        ),
    .rob_rs_reg            (rob_rs_reg              ),
    .rob_rt_data_valid     (rob_rt_data_valid       ),
    .rob_rt_token          (rob_rt_token            ),
    .rob_rt_data_spec      (rob_rt_data_spec        ),
    .rob_rt_reg            (rob_rt_reg              ),
    .dispatch_update_valid (dispatch_update_valid   ),
    .dispatch_rd_reg       (dispatch_rd_reg         ),
    .dispatch_pc           (dispatch_pc             ),
    .dispatch_inst_type    (dispatch_inst_type      ),
    .cdb_tag               (cdb_tag                 ),
    .cdb_data              (cdb_data                ),
    .cdb_valid             (cdb_valid               )
  );

  integer_queue integer_queuex(
    .clock                 (clock                   ),
    .nreset                (nreset                  ),
    .dispatch_rs_data      (dispatch_rs_data        ),
    .dispatch_rs_tag       (dispatch_rs_tag         ),
    .dispatch_rs_data_val  (dispatch_rs_data_valid  ),
    .dispatch_rt_data      (dispatch_rt_data        ),
    .dispatch_rt_tag       (dispatch_rt_tag         ),
    .dispatch_rt_data_val  (dispatch_rt_data_valid  ),
    .dispatch_opcode       (dispatch_alu_opcode     ),
    .dispatch_shfamt       (dispatch_shfamt         ),
    .dispatch_rd_tag       (dispatch_rd_tag         ),
    .dispatch_enable       (dispatch_en_integer     ),
    .full                  (issueque_integer_full   ),
    .cdb_tag               (cdb_tag                 ),
    .cdb_data              (cdb_data                ),
    .cdb_valid             (cdb_valid               ),
    .issueque_ready        (integer_issueque_ready  ),
    .issueque_rs_data      (integer_issueque_rs_data),
    .issueque_rt_data      (integer_issueque_rt_data),
    .issueque_rd_tag       (integer_issueque_rd_tag ),
    .issueque_opcode       (integer_issueque_opcode ),
    .issueque_shfamt       (integer_issueque_shfamt ),
    .issueblk_issue        (integer_issueblk_issue  ),
    .flush_valid           (flush_valid             )
  );

  multiplication_queue multiplication_queuex(
    .clock                 (clock                   ),
    .nreset                (nreset                  ),
    .dispatch_rs_data      (dispatch_rs_data        ),
    .dispatch_rs_tag       (dispatch_rs_tag         ),
    .dispatch_rs_data_val  (dispatch_rs_data_valid  ),
    .dispatch_rt_data      (dispatch_rt_data        ),
    .dispatch_rt_tag       (dispatch_rt_tag         ),
    .dispatch_rt_data_val  (dispatch_rt_data_valid  ),
    .dispatch_rd_tag       (dispatch_rd_tag         ),
    .dispatch_enable       (dispatch_en_mul         ),
    .full                  (issueque_mul_full       ),
    .cdb_tag               (cdb_tag                 ),
    .cdb_data              (cdb_data                ),
    .cdb_valid             (cdb_valid               ),
    .issueque_ready        (mult_issueque_ready     ),
    .issueque_rs_data      (mult_issueque_rs_data   ),
    .issueque_rt_data      (mult_issueque_rt_data   ),
    .issueque_rd_tag       (mult_issueque_rd_tag    ),
    .issueblk_issue        (mult_issueblk_issue     ),
    .flush_valid           (flush_valid             )
  );

  load_store_queue load_store_queuex(
    .clock                 (clock                   ),
    .nreset                (nreset                  ),
    .dispatch_rs_data      (dispatch_rs_data        ),
    .dispatch_rs_tag       (dispatch_rs_tag         ),
    .dispatch_rs_data_val  (dispatch_rs_data_valid  ),
    .dispatch_rt_data      (dispatch_rt_data        ),
    .dispatch_rt_tag       (dispatch_rt_tag         ),
    .dispatch_rt_data_val  (dispatch_rt_data_valid  ),
    .dispatch_rd_tag       (dispatch_rd_tag         ),
    .dispatch_enable       (dispatch_en_ld_st       ),
    .dispatch_opcode       (dispatch_mem_opcode     ),
    .dispatch_offset       (dispatch_imm_ld_st      ),
    .retire_store_ready    (retire_store_ready      ),
    .full                  (issueque_ld_st_full     ),
    .cdb_tag               (cdb_tag                 ),
    .cdb_data              (cdb_data                ),
    .cdb_valid             (cdb_valid               ),
    .issueque_ready        (ldst_issueque_ready     ),
    .issueque_opcode       (ldst_issueque_opcode    ),
    .issueque_rs_data      (ldst_issueque_rs_data   ),
    .issueque_rt_data      (ldst_issueque_rt_data   ),
    .issueque_rd_tag       (ldst_issueque_rd_tag    ),
    .issueblk_issue        (ldst_issueblk_issue     ),
    .flush_valid           (flush_valid             )
  );

  Integer_ALU Integer_ALUx(
    .Operand1              (integer_issueque_rs_data),
    .Operand2              (integer_issueque_rt_data),
    .ShfAmt                (integer_issueque_shfamt ),
    .TAG_IN                (integer_issueque_rd_tag ),
    .ALU_OPCODE            (integer_issueque_opcode ),
    .RESULT                (int_dout                ),
    .TAG_OUT               (int_tag                 ),
    .ALU_BRANCH            (int_branch              ),
    .ALU_BRANCH_TAKEN      (int_branch_taken        )
  );

  multiplier_wrapper multiplier_wrapper(
    .clock                 (clock                   ),
    .op1                   (mult_issueque_rs_data   ),
    .op2                   (mult_issueque_rt_data   ),
    .tag_in                (mult_issueque_rd_tag    ),
    .out                   (mul_dout                ),
    .tag_out               (mul_tag                 )
  );

  d_cache d_cachex(
    .nreset                (nreset                  ),
    .clock                 (clock                   ),
    .ls_ready_in           (ldst_issueque_ready     ),
    .ls_issue_out          (ldst_issueblk_issue     ),
    .data_in               (ldst_issueque_rt_data   ),
    .address               (ldst_issueque_rs_data   ),
    .tag_in                (ldst_issueque_rd_tag    ),
    .opcode                (ldst_issueque_opcode    ),
    .ls_ready_out          (mem_ready               ),
    .ls_issue_in           (mem_issue               ),
    .data_out              (mem_dout                ),
    .tag_out               (mem_tag                 ),
    .ex_addr               (ex_addr                 ),
    .ex_data_out           (ex_data_out             ),
    .retire_store_ack      (retire_store_ack        )
  );

  issue_unit issue_unitx(
    .clock                 (clock                   ),
    .nreset                (nreset                  ),
    .flush_valid           (flush_valid             ),
    .int_ready             (integer_issueque_ready  ),
    .int_dout              (int_dout                ),
    .int_tag               (int_tag                 ),
    .int_branch            (int_branch              ),
    .int_branch_taken      (int_branch_taken        ),
    .int_issue             (integer_issueblk_issue  ),
    .mul_ready             (mult_issueque_ready     ),
    .mul_dout              (mul_dout                ),
    .mul_tag               (mul_tag                 ),
    .mul_issue             (mult_issueblk_issue     ),
    .mem_ready             (mem_ready               ),
    .mem_dout              (mem_dout                ),
    .mem_tag               (mem_tag                 ),
    .mem_issue             (mem_issue               ),
    .cdb_valid             (cdb_valid               ),
    .cdb_branch            (cdb_branch              ),
    .cdb_branch_taken      (cdb_branch_taken        ),
    .cdb_data              (cdb_data                ),
    .cdb_tag               (cdb_tag                 )
  );

  rob robx(
    .clock                 (clock                   ),
    .nreset                (nreset                  ),
    .rs_reg                (rob_rs_reg              ),
    .rt_reg                (rob_rt_reg              ),
    .rs_data_valid         (rob_rs_data_valid       ),
    .rs_token              (rob_rs_token            ),
    .rs_data_spec          (rob_rs_data_spec        ),
    .rt_data_valid         (rob_rt_data_valid       ),
    .rt_token              (rob_rt_token            ),
    .rt_data_spec          (rob_rt_data_spec        ),
    .dispatch_update_valid (dispatch_update_valid   ),
    .dispatch_rd_tag       (dispatch_rd_tag         ),
    .dispatch_rd_reg       (dispatch_rd_reg         ),
    .dispatch_pc           (dispatch_pc             ),
    .dispatch_inst_type    (dispatch_inst_type      ),
    .cdb_valid             (cdb_valid               ),
    .cdb_branch            (cdb_branch              ),
    .cdb_branch_taken      (cdb_branch_taken        ),
    .cdb_tag               (cdb_tag                 ),
    .cdb_data              (cdb_data                ),
    .retire_valid          (retire_valid            ),
    .flush_valid           (flush_valid             ),
    .retire_store_ready    (retire_store_ready      ),
    .retire_rd_tag         (retire_rd_tag           ),
    .retire_rd_reg         (retire_rd_reg           ),
    .retire_data           (retire_data             ),
    .retire_pc             (retire_pc               ),
    .retire_store_ack      (retire_store_ack        ),
    .arf_retire_valid      (arf_retire_valid        )
  );



endmodule












