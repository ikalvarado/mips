//
//-------------------------------------------------------------------------------------------------
// filename:  mips_top_tb.sv
//-------------------------------------------------------------------------------------------------
// modification history
// author          date        description
//-------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
//
// MODULE: mips_top_tb
//
//-------------------------------------------------------------------------------------------------
module mips_top_tb();

  logic clock;
  logic nreset;
  logic [31:0] ex_addr;
  logic [31:0] ex_data_out;

  MIPS_SE_TOP dut(
    .clock      (clock      ),
    .nreset     (nreset     ),
    .ex_addr    (ex_addr    ),
    .ex_data_out(ex_data_out)
  );

  initial begin
    fork : clock_process
      system_clock();
    join_none

    reset_signals();

    for(int i = 0; i < 1000; i++) begin
      @(posedge clock);
    end

    disable clock_process;
  end

  task system_clock();
    clock = 0;
    forever begin
      #500 clock = ~clock;
    end
  endtask

  task reset_signals();
    nreset  = 0;
    ex_addr = 0;
    for(int i = 0; i < 10; i++) begin
      @(posedge clock);
    end
    @(negedge clock);
    nreset = 1;
  endtask

endmodule












