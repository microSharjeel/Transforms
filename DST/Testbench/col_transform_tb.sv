`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2025 10:23:46 AM
// Design Name: 
// Module Name: col_transform_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module col_transform_tb;

  // Parameters
  localparam IN_W = 12;
  localparam COEFF_W = 8;
  localparam OUT_W = IN_W + COEFF_W + 2;

  // Inputs
  logic signed [IN_W-1:0] in_block [0:3][0:3];
  // Outputs
  logic signed [OUT_W-1:0] out_block [0:3][0:3];

  // Clock and reset
  logic clk;
  logic rst_n;

  // Instantiate the DUT
  col_transform #(
    .IN_W(IN_W),
    .COEFF_W(COEFF_W),
    .OUT_W(OUT_W)
  ) dut (
    .in_block(in_block),
    .out_block(out_block)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100 MHz clock
  end

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n = 0;
    in_block = '{default:0};
    #20;
    rst_n = 1;

    // Test input (4x4 block, same as row_transform input)
    in_block = '{
      '{12'd100, 12'd200, 12'd300, 12'd400},
      '{12'd150, 12'd250, 12'd350, 12'd450},
      '{12'd200, 12'd300, 12'd400, 12'd500},
      '{12'd250, 12'd350, 12'd450, 12'd550}
    };

    // Wait for processing
    #20;

    // Display input block
    $display("Input Block:");
    for (int i = 0; i < 4; i++) begin
      $display("%6d %6d %6d %6d", in_block[i][0], in_block[i][1], in_block[i][2], in_block[i][3]);
    end

    // Display output block
    $display("\nOutput Block (after column transform):");
    for (int i = 0; i < 4; i++) begin
      $display("%8d %8d %8d %8d", out_block[i][0], out_block[i][1], out_block[i][2], out_block[i][3]);
    end

    // Add another test case
    #20;
    in_block = '{
      '{12'd50, 12'd100, 12'd150, 12'd200},
      '{12'd75, 12'd125, 12'd175, 12'd225},
      '{12'd100, 12'd150, 12'd200, 12'd250},
      '{12'd125, 12'd175, 12'd225, 12'd275}
    };

    #20;
    $display("\nInput Block (Test Case 2):");
    for (int i = 0; i < 4; i++) begin
      $display("%6d %6d %6d %6d", in_block[i][0], in_block[i][1], in_block[i][2], in_block[i][3]);
    end
    $display("\nOutput Block (Test Case 2):");
    for (int i = 0; i < 4; i++) begin
      $display("%8d %8d %8d %8d", out_block[i][0], out_block[i][1], out_block[i][2], out_block[i][3]);
    end

    #20;
    $finish;
  end
endmodule