
module true_dual_port_ram (data_a, data_b, addr_a, addr_b, we_a, we_b, clk, q_a, q_b);

  parameter DATA_WIDTH = 'd32;
  parameter ADDR_WIDTH = 'd05;

  input [(DATA_WIDTH-1):0] data_a, data_b;
  input [(ADDR_WIDTH-1):0] addr_a, addr_b;
  input we_a, we_b, clk;
  output reg [(DATA_WIDTH-1):0] q_a, q_b;

  // Declare the RAM variable
  reg [DATA_WIDTH-1:0] ram[0:2**ADDR_WIDTH-1];
  
  initial begin
    $readmemh("init_dcache.mem", ram);
  end

  always @ (posedge clk) begin // Port A
    if (we_a) begin
      ram[addr_a] <= data_a;
      q_a <= data_a;
    end
    else begin
      q_a <= ram[addr_a];
    end
  end

  always @ (posedge clk) begin // Port b
    if (we_b) begin
      ram[addr_b] <= data_b;
      q_b <= data_b;
    end
    else begin
      q_b <= ram[addr_b];
    end
  end
endmodule

