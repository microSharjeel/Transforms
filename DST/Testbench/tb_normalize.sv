`timescale 1ns/1ps

module tb_normalize;

  // Parameters
  localparam int IN_W   = 24;
  localparam int OUT_W  = 16;
  localparam int SHIFT  = 14;

  // DUT I/O
  logic signed [IN_W-1:0]  in_block [0:3][0:3];
  logic signed [OUT_W-1:0] out_block [0:3][0:3];

  // Instantiate DUT
  normalize #(
    .IN_W(IN_W),
    .OUT_W(OUT_W),
    .SHIFT(SHIFT)
  ) dut (
    .in_block(in_block),
    .out_block(out_block)
  );

  // Test stimulus
  initial begin
    // Apply some test values (covering positive, negative, zero, large)
    in_block = '{
      '{  8192,  -16384,  24576,  12288 },  // Row 0
      '{  -4096,   2048,   8192,  -1024 },  // Row 1
      '{ 16384,   32768,  -8192,   4096 },  // Row 2
      '{ -24576, -12288,   1024,   2048 }   // Row 3
    };

    #1; // small delay for combinational logic to settle

    // Display input and output
    $display("==== Normalize Test ====");
    for (int i=0; i<4; i++) begin
      for (int j=0; j<4; j++) begin
        $display("in_block[%0d][%0d] = %0d  ->  out_block[%0d][%0d] = %0d",
                  i, j, in_block[i][j], i, j, out_block[i][j]);
      end
    end

    $finish;
  end

endmodule
