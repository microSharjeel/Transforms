`timescale 1ns / 1ps

module row_transform_tb;

  // Parameters
  localparam IN_W    = 12;
  localparam COEFF_W = 8;
  localparam OUT_W   = IN_W + COEFF_W + 2;

  // Inputs / Outputs
  logic signed [IN_W-1:0] in_block [0:3][0:3];
  logic signed [OUT_W-1:0] out_block [0:3][0:3];

  // DUT
  row_transform #(
    .IN_W(IN_W),
    .COEFF_W(COEFF_W),
    .OUT_W(OUT_W)
  ) dut (
    .in_block(in_block),
    .out_block(out_block)
  );

  // Task: display a 4x4 block
  task automatic display_block(string label,
                               input logic signed [31:0] blk [0:3][0:3]);
    $display("%s", label);
    for (int i = 0; i < 4; i++) begin
      $display("%8d %8d %8d %8d", blk[i][0], blk[i][1], blk[i][2], blk[i][3]);
    end
    $display("");
  endtask

  // Stimulus
  initial begin
    // Test 1: All zeros
    in_block = '{default:0};
    #1;
    display_block("Input Block (zeros):", in_block);
    display_block("Row Transform Output:", out_block);

    // Test 2: Increasing numbers
    in_block = '{
      '{12'd100, 12'd200, 12'd300, 12'd400},
      '{12'd150, 12'd250, 12'd350, 12'd450},
      '{12'd200, 12'd300, 12'd400, 12'd500},
      '{12'd250, 12'd350, 12'd450, 12'd550}
    };
    #1;
    display_block("Input Block (increasing):", in_block);
    display_block("Row Transform Output:", out_block);

    // Test 3: Mixed positive/negative
    in_block = '{
      '{12'sd50, -12'sd100, 12'sd150, -12'sd200},
      '{12'sd75, -12'sd125, 12'sd175, -12'sd225},
      '{12'sd100, -12'sd150, 12'sd200, -12'sd250},
      '{12'sd125, -12'sd175, 12'sd225, -12'sd275}
    };
    #1;
    display_block("Input Block (mixed +/-):", in_block);
    display_block("Row Transform Output:", out_block);

    // Test 4: Randomized values
    foreach (in_block[i,j]) begin
      in_block[i][j] = $urandom_range(-1000, 1000);
    end
    #1;
    display_block("Input Block (random):", in_block);
    display_block("Row Transform Output:", out_block);

    $display("---- Row Transform TB Completed ----");
    $finish;
  end

endmodule
