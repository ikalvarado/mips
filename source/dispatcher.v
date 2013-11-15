//
//-------------------------------------------------------------------------------------------------
// filename:  dispatcher.v
// author:    ikalvarado
// created:   2012-03-25
//-------------------------------------------------------------------------------------------------
// modification history
// author          date        description
// ialvarado       2012-03-25  creation
//-------------------------------------------------------------------------------------------------

`define ADD   4'h0
`define ADDU  4'h1
`define SUB   4'h2
`define AND   4'h3
`define OR    4'h4
`define NOR   4'h5
`define SLT   4'h6
`define SLTU  4'h7
`define SLL   4'h8
`define SRL   4'h9
`define BEQ   4'ha
`define BNE   4'hb

//-------------------------------------------------------------------------------------------------
//
// MODULE: dispatcher
//
//-------------------------------------------------------------------------------------------------
module dispatcher (
  clock,
  nreset,
  flush_valid,
  tag_fifo_empty,
  tag_out,
  tag_fifo_ren,
  ifetch_empty_flag,
  ifetch_instruction,
  ifetch_pc_plus_four,
  dispatch_ren,
  dispatch_jmp,
  dispatch_jmp_addr,
  arf_data_out_rs,
  arf_data_out_rt,
  arf_rd_addr_rs,
  arf_rd_addr_rt,
  dispatch_rs_data_valid,
  dispatch_rs_data,
  dispatch_rs_tag,
  dispatch_rt_data_valid,
  dispatch_rt_data,
  dispatch_rt_tag,
  dispatch_rd_tag,
  issueque_integer_full,
  dispatch_en_integer,
  dispatch_alu_opcode,
  dispatch_shfamt,
  issueque_ld_st_full,
  dispatch_en_ld_st,
  dispatch_mem_opcode,
  dispatch_imm_ld_st,
  issueque_mul_full,
  dispatch_en_mul,
  rob_rs_data_valid,
  rob_rs_token,
  rob_rs_data_spec,
  rob_rs_reg,
  rob_rt_data_valid,
  rob_rt_token,
  rob_rt_data_spec,
  rob_rt_reg,
  dispatch_update_valid,
  dispatch_rd_reg,
  dispatch_pc,
  dispatch_inst_type,
  cdb_valid,
  cdb_tag,
  cdb_data
);

  //-----------------------------------------------------------------------------------------------
  //
  // Parameters
  //
  //-----------------------------------------------------------------------------------------------
  parameter JUMP_OPCODE = 6'h02;
  parameter LOAD        = 1'b0;
  parameter DISPATCH    = 1'b1;
  parameter MULT_OPCODE = {6'h00, 6'h19};
  parameter LOAD_OPC    = 6'h23;
  parameter STORE_OPC   = 6'h2b;

  //-----------------------------------------------------------------------------------------------
  //
  // Interfaces
  //
  //-----------------------------------------------------------------------------------------------
  input clock;
  input nreset;
  input flush_valid;

  //-----------------------------------------------------------------------------------------------
  // taq fifo interface
  //-----------------------------------------------------------------------------------------------
  input              tag_fifo_empty;
  input       [ 4:0] tag_out;
  output reg         tag_fifo_ren;

  //-----------------------------------------------------------------------------------------------
  // instruction fetch queue interface
  //-----------------------------------------------------------------------------------------------
  input              ifetch_empty_flag;
  input       [31:0] ifetch_instruction;
  input       [31:0] ifetch_pc_plus_four;
  output reg         dispatch_ren;
  output reg         dispatch_jmp;
  output reg  [31:0] dispatch_jmp_addr;

  //-----------------------------------------------------------------------------------------------
  // architectural register file interface
  //-----------------------------------------------------------------------------------------------
  input       [31:0] arf_data_out_rs;
  input       [31:0] arf_data_out_rt;
  output reg  [ 4:0] arf_rd_addr_rs;
  output reg  [ 4:0] arf_rd_addr_rt;

  //-----------------------------------------------------------------------------------------------
  // queues interface
  //-----------------------------------------------------------------------------------------------
  output reg         dispatch_rs_data_valid;
  output reg  [31:0] dispatch_rs_data;
  output reg  [ 4:0] dispatch_rs_tag;

  output reg         dispatch_rt_data_valid;
  output reg  [31:0] dispatch_rt_data;
  output reg  [ 4:0] dispatch_rt_tag;

  output reg  [ 4:0] dispatch_rd_tag;

  //-----------------------------------------------------------------------------------------------
  // integer queue interface
  //-----------------------------------------------------------------------------------------------
  input              issueque_integer_full;
  output reg         dispatch_en_integer;
  output reg  [ 3:0] dispatch_alu_opcode;
  output reg  [ 4:0] dispatch_shfamt;

  //-----------------------------------------------------------------------------------------------
  // load and store queue interface
  //-----------------------------------------------------------------------------------------------
  input              issueque_ld_st_full;
  output reg         dispatch_en_ld_st;
  output reg         dispatch_mem_opcode;
  output reg  [15:0] dispatch_imm_ld_st;

  //-----------------------------------------------------------------------------------------------
  // multiplication queue
  //-----------------------------------------------------------------------------------------------
  input              issueque_mul_full;
  output reg         dispatch_en_mul;

  //-----------------------------------------------------------------------------------------------
  // rob query interface
  //-----------------------------------------------------------------------------------------------
  input              rob_rs_data_valid;
  input       [ 5:0] rob_rs_token;
  input       [31:0] rob_rs_data_spec;
  output reg  [ 4:0] rob_rs_reg;

  input              rob_rt_data_valid;
  input       [ 5:0] rob_rt_token;
  input       [31:0] rob_rt_data_spec;
  output reg  [ 4:0] rob_rt_reg;

  //-----------------------------------------------------------------------------------------------
  // rob update interface
  //-----------------------------------------------------------------------------------------------
  output reg         dispatch_update_valid;
  output reg  [ 4:0] dispatch_rd_reg;
  output reg  [31:0] dispatch_pc;
  output reg  [ 1:0] dispatch_inst_type;

  //-----------------------------------------------------------------------------------------------
  // rob update interface
  //-----------------------------------------------------------------------------------------------
  input              cdb_valid;
  input       [ 4:0] cdb_tag;
  input       [31:0] cdb_data;

  //-----------------------------------------------------------------------------------------------
  //
  // Internal signals
  //
  //-----------------------------------------------------------------------------------------------

  //-----------------------------------------------------------------------------------------------
  // Variables
  //-----------------------------------------------------------------------------------------------
  reg        crstate;
  reg        nxstate;
  reg [31:0] br_addr_value;
  reg [31:0] imm_extended;
  reg [11:0] opcode;
  reg [ 4:0] destiny_register;
  reg [ 1:0] inst_type;
  reg        comb_jmp;
  reg [31:0] comb_jmp_addr;

  reg        saved_cdb_valid;
  reg [ 4:0] saved_cdb_tag;
  reg [31:0] saved_cdb_data;
  reg        rstkvld;
  reg        rttkvld;

  reg        imm_inst;

  //-----------------------------------------------------------------------------------------------
  //
  // Combinational logic
  //
  //-----------------------------------------------------------------------------------------------
  always @(*) begin
    opcode = {ifetch_instruction[31:26], ifetch_instruction[5:0]};
  end

  //-----------------------------------------------------------------------------------------------
  // query logic
  //-----------------------------------------------------------------------------------------------
  always @(*) begin
    arf_rd_addr_rs = ifetch_instruction[25:21];
    rob_rs_reg     = ifetch_instruction[25:21];
    arf_rd_addr_rt = ifetch_instruction[20:16];
    rob_rt_reg     = ifetch_instruction[20:16];
  end

  //-----------------------------------------------------------------------------------------------
  // sign extension
  //-----------------------------------------------------------------------------------------------
  always @(*) begin
    imm_extended = {{16{ifetch_instruction[15]}}, ifetch_instruction[15:0]};
  end

  //-----------------------------------------------------------------------------------------------
  // jump and branch address calculation
  //-----------------------------------------------------------------------------------------------
  always @(*) begin
    br_addr_value = ifetch_pc_plus_four + {imm_extended[29:0], 2'h0} + 4;
    comb_jmp      = ifetch_instruction[31:26] == JUMP_OPCODE;
    comb_jmp_addr = {ifetch_pc_plus_four[31:28], ifetch_instruction[25:0], 2'h0};
  end

  //-----------------------------------------------------------------------------------------------
  // find the data for the operands rs and rt
  //-----------------------------------------------------------------------------------------------
  always @(*) begin
    dispatch_rs_tag = rob_rs_token[5] ? rob_rs_token[4:0] : 0;
    dispatch_rt_tag = rob_rt_token[5] ? rob_rt_token[4:0] : 0;
    rstkvld         = rob_rs_token[5];
    rttkvld         = rob_rt_token[5];

    imm_inst = opcode[11:6] == 6'h08 || opcode[11:6] == 6'h09 || opcode[11:6] == 6'h0a ||
      opcode[11:6] == 6'h0c || opcode[11:6] == 6'h0d;

    dispatch_rs_data_valid = rob_rs_data_valid || !rob_rs_token[5] ||
      (cdb_valid       && (dispatch_rs_tag == cdb_tag)) ||
      (saved_cdb_valid && (dispatch_rs_tag == saved_cdb_tag));

    dispatch_rs_data       = rob_rs_data_valid ?
      rob_rs_data_spec : (cdb_valid       && rstkvld && (dispatch_rs_tag == cdb_tag)) ?
      cdb_data         : (saved_cdb_valid && rstkvld && (dispatch_rs_tag == saved_cdb_tag)) ?
      saved_cdb_data   : arf_data_out_rs;
    
    dispatch_rt_data_valid = imm_inst ? 1 : rob_rt_data_valid || !rob_rt_token[5] ||
      (cdb_valid       && (dispatch_rt_tag == cdb_tag)) ||
      (saved_cdb_valid && (dispatch_rt_tag == saved_cdb_tag));

    dispatch_rt_data       = imm_inst ? imm_extended: rob_rt_data_valid ?
      rob_rt_data_spec : (cdb_valid       && rttkvld && (dispatch_rt_tag == cdb_tag)) ?
      cdb_data         : (saved_cdb_valid && rttkvld && (dispatch_rt_tag == saved_cdb_tag)) ?
      saved_cdb_data   : arf_data_out_rt;
  end

  //-----------------------------------------------------------------------------------------------
  // determine which part of the ocpode is the destination register
  //-----------------------------------------------------------------------------------------------
  always @(*) begin
    if(opcode[11:6] == 6'h00) begin
      destiny_register = ifetch_instruction[15:11];
    end
    else begin
      destiny_register = ifetch_instruction[20:16];
    end
  end

  //-----------------------------------------------------------------------------------------------
  // determine the instruction type
  //-----------------------------------------------------------------------------------------------
  always @(*) begin
    if(opcode[11:6] == STORE_OPC) begin
      inst_type = 2'h2;
    end
    else if(opcode[11:6] == 6'h04 || opcode[11:6] == 6'h04) begin
      inst_type = 2'h1;
    end
    else begin
      inst_type = 2'h0;
    end
  end

  //-----------------------------------------------------------------------------------------------
  // alu opcode decoding for integer queue
  //-----------------------------------------------------------------------------------------------
  always @(*) begin
    casex(opcode)
      {6'h00, 6'h20}: dispatch_alu_opcode = `ADD;  // R-type
      {6'h00, 6'h21}: dispatch_alu_opcode = `ADDU; // R-type
      {6'h00, 6'h22}: dispatch_alu_opcode = `SUB;  // R-type
      {6'h00, 6'h24}: dispatch_alu_opcode = `AND;  // R-type
      {6'h00, 6'h25}: dispatch_alu_opcode = `OR;   // R-type
      {6'h00, 6'h27}: dispatch_alu_opcode = `NOR;  // R-type
      {6'h00, 6'h2a}: dispatch_alu_opcode = `SLT;  // R-type
      {6'h00, 6'h2b}: dispatch_alu_opcode = `SLTU; // R-type
      {6'h00, 6'h00}: dispatch_alu_opcode = `SLL;  // R-type
      {6'h00, 6'h02}: dispatch_alu_opcode = `SRL;  // R-type
      {6'h08, 6'hxx}: dispatch_alu_opcode = `ADD;  // I-type
      {6'h09, 6'hxx}: dispatch_alu_opcode = `ADDU; // I-type
      {6'h0c, 6'hxx}: dispatch_alu_opcode = `AND;  // I-type
      {6'h0d, 6'hxx}: dispatch_alu_opcode = `OR;   // I-type
      {6'h0a, 6'hxx}: dispatch_alu_opcode = `SLT;  // I-type
      {6'h04, 6'hxx}: dispatch_alu_opcode = `BEQ;  // Branch
      {6'h05, 6'hxx}: dispatch_alu_opcode = `BNE;  // Branch
      default:        dispatch_alu_opcode = 0;
    endcase
    dispatch_shfamt = ifetch_instruction[10:6];
  end

  //-----------------------------------------------------------------------------------------------
  // load and store queue
  //-----------------------------------------------------------------------------------------------
  always @(*) begin
    dispatch_mem_opcode = ifetch_instruction[29];
    dispatch_imm_ld_st  = ifetch_instruction[15:0];
  end

  //-----------------------------------------------------------------------------------------------
  //
  // State dependent logic
  //
  //-----------------------------------------------------------------------------------------------
  always @(*) begin
    nxstate = crstate;
    dispatch_ren          = 0;
    dispatch_en_integer   = 0;
    dispatch_en_ld_st     = 0;
    dispatch_en_mul       = 0;
    dispatch_update_valid = 0;
    dispatch_rd_tag       = 0;
    dispatch_rd_reg       = 0;
    dispatch_pc           = 0;
    dispatch_inst_type    = 0;
    tag_fifo_ren          = 0;
    dispatch_jmp          = 0;
    dispatch_jmp_addr     = 0;

    if(flush_valid) begin
      nxstate = LOAD;
      dispatch_ren          = 0;
      dispatch_en_integer   = 0;
      dispatch_en_ld_st     = 0;
      dispatch_en_mul       = 0;
      dispatch_update_valid = 0;
      dispatch_rd_tag       = 0;
      dispatch_rd_reg       = 0;
      dispatch_pc           = 0;
      dispatch_inst_type    = 0;
      tag_fifo_ren          = 0;
      dispatch_jmp          = 0;
      dispatch_jmp_addr     = 0;
    end
    else if(crstate == LOAD) begin
      dispatch_ren          = 0;
      dispatch_en_ld_st     = 0;
      dispatch_en_mul       = 0;
      dispatch_update_valid = 0;
      tag_fifo_ren          = 0;
      if(ifetch_empty_flag == 0) begin
        nxstate = DISPATCH;
        dispatch_ren = 0;
      end
    end
    else begin
      dispatch_jmp      = comb_jmp;
      dispatch_jmp_addr = comb_jmp_addr;
      if(!tag_fifo_empty) begin
        dispatch_rd_tag    = tag_out;
        dispatch_rd_reg    = destiny_register;
        dispatch_pc        = inst_type == 1 ? br_addr_value : ifetch_pc_plus_four;
        dispatch_inst_type = inst_type;

        if(opcode != MULT_OPCODE && opcode[11:6] != LOAD_OPC && opcode[11:6] != STORE_OPC &&
          !issueque_integer_full) begin
          // issue queue submit success save new entry in rob and look for the next instruction
          dispatch_ren          = 1;
          tag_fifo_ren          = 1;
          dispatch_en_integer   = 1;
          // rob update
          dispatch_update_valid = 1;
          // return to load
          nxstate = LOAD;
        end
        if(opcode[11:6] == LOAD_OPC || opcode[11:6] == STORE_OPC && !issueque_ld_st_full) begin
          // issue queue submit success save new entry in rob and look for the next instruction
          dispatch_ren          = 1;
          tag_fifo_ren          = 1;
          dispatch_en_ld_st     = 1;
          // rob update
          dispatch_update_valid = 1;
          // return to load
          nxstate = LOAD;
        end
        if(opcode == MULT_OPCODE && !issueque_mul_full) begin
          // issue queue submit success save new entry in rob and look for the next instruction
          dispatch_ren          = 1;
          tag_fifo_ren          = 1;
          dispatch_en_mul       = 1;
          // rob update
          dispatch_update_valid = 1;
          // return to load
          nxstate = LOAD;
        end
      end
    end
  end

  //-----------------------------------------------------------------------------------------------
  //
  // State register
  //
  //-----------------------------------------------------------------------------------------------
  always @(posedge clock, negedge nreset) begin
    if(!nreset) begin
      crstate         <= LOAD;
      saved_cdb_valid <= 0;
      saved_cdb_tag   <= 0;
      saved_cdb_data  <= 0;
    end
    else if(flush_valid) begin
      crstate         <= LOAD;
      saved_cdb_valid <= 0;
      saved_cdb_tag   <= 0;
      saved_cdb_data  <= 0;
    end
    else begin
      crstate <= nxstate;
      if(cdb_valid) begin
        saved_cdb_valid <= 1;
        saved_cdb_tag   <= cdb_tag;
        saved_cdb_data  <= cdb_data;
      end
    end
  end

endmodule

















