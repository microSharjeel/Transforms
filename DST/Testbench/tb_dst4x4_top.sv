`timescale 1ns/1ps

module tb_dst4x4_top;

  // Parameters
  localparam int IN_W    = 12;
  localparam int COEFF_W = 8;
  localparam int MID_W   = 20;
  localparam int OUT_W   = 16;
  localparam int SHIFT   = 14;

  // DUT I/O
  logic signed [IN_W-1:0]  in_block [0:3][0:3];
  logic signed [OUT_W-1:0] out_block [0:3][0:3];

  // Instantiate DUT
  dst4x4_top #(
    .IN_W(IN_W),
    .COEFF_W(COEFF_W),
    .MID_W(MID_W),
    .OUT_W(OUT_W),
    .SHIFT(SHIFT)
  ) dut (
    .in_block(in_block),
    .out_block(out_block)
  );

  // Test stimulus
  initial begin
    // Example input: a simple residual block
    in_block = '{
      '{ 10,  20,  30,  40 },  // Row 0
      '{ -5, -15, -25, -35 },  // Row 1
      '{ 12,   0, -12, -24 },  // Row 2
      '{  8,  16, - 8, -16 }   // Row 3
    };

    #1; // wait for combinational logic to settle

    $display("==== DST4x4 Transform Test ====");
    $display("Input Block:");
    for (int i=0; i<4; i++) begin
      $display("%p", in_block[i]);
    end

    $display("\nOutput Block (Normalized Coefficients):");
    for (int i=0; i<4; i++) begin
      $display("%p", out_block[i]);
    end

    $finish;
  end

endmodule
