`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2025 04:45:12 PM
// Design Name: 
// Module Name: mac_4_tb
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


module mac_4_tb();
 // Parameters
  localparam int IN_W     = 12;
  localparam int COEFF_W  = 8;
  localparam int OUT_W    = IN_W + COEFF_W + 2;

  // DUT I/O
  logic signed [IN_W-1:0]     x [0:3];
  logic signed [COEFF_W-1:0]  c [0:3];
  logic signed [OUT_W-1:0]    y;
  logic signed [OUT_W-1:0]    expected;

  // Instantiate DUT
  mac_4 #(
    .IN_W(IN_W),
    .COEFF_W(COEFF_W),
    .OUT_W(OUT_W)
  ) dut (
    .x(x),
    .c(c),
    .y(y)
  );

  initial begin
    $display("---- Starting MAC testbench ----");

    // Test 1: all zeros
    x[0]=0; x[1]=0; x[2]=0; x[3]=0;
    c[0]=0; c[1]=0; c[2]=0; c[3]=0;
    #1;
    expected = 0;
    $display("Test1: y=%0d, expected=%0d", y, expected);

    // Test 2: all ones
    x[0]=1; x[1]=1; x[2]=1; x[3]=1;
    c[0]=1; c[1]=1; c[2]=1; c[3]=1;
    #1;
    expected = 4;
    $display("Test2: y=%0d, expected=%0d", y, expected);

    // Test 3: all -1
    x[0]=-1; x[1]=-1; x[2]=-1; x[3]=-1;
    c[0]=-1; c[1]=-1; c[2]=-1; c[3]=-1;
    #1;
    expected = 4;
    $display("Test3: y=%0d, expected=%0d", y, expected);

    // Test 4: max positive values
    x[0] =  2**(IN_W-1)-1;  x[1]=0; x[2]=0; x[3]=0;
    c[0] =  2**(COEFF_W-1)-1; c[1]=0; c[2]=0; c[3]=0;
    #1;
    expected = x[0]*c[0];
    $display("Test4: y=%0d, expected=%0d", y, expected);

    // Test 5: min negative values
    x[0] = -(2**(IN_W-1));  x[1]=0; x[2]=0; x[3]=0;
    c[0] = -(2**(COEFF_W-1)); c[1]=0; c[2]=0; c[3]=0;
    #1;
    expected = x[0]*c[0];
    $display("Test5: y=%0d, expected=%0d", y, expected);

    // Test 6: mixed signs
    x[0]=10; x[1]=-20; x[2]=30; x[3]=-40;
    c[0]=3;  c[1]=-2;  c[2]=1;  c[3]=-1;
    #1;
    expected = x[0]*c[0] + x[1]*c[1] + x[2]*c[2] + x[3]*c[3];
    $display("Test6: y=%0d, expected=%0d", y, expected);

    // Test 7: weighted sum
    x[0]=100; x[1]=200; x[2]=300; x[3]=400;
    c[0]=-5;  c[1]=4;   c[2]=-3;  c[3]=2;
    #1;
    expected = x[0]*c[0] + x[1]*c[1] + x[2]*c[2] + x[3]*c[3];
    $display("Test7: y=%0d, expected=%0d", y, expected);

    // Test 8-12: random vectors
    x[0]=$urandom_range(-(2**(IN_W-1)), 2**(IN_W-1)-1);
    x[1]=$urandom_range(-(2**(IN_W-1)), 2**(IN_W-1)-1);
    x[2]=$urandom_range(-(2**(IN_W-1)), 2**(IN_W-1)-1);
    x[3]=$urandom_range(-(2**(IN_W-1)), 2**(IN_W-1)-1);
    c[0]=$urandom_range(-(2**(COEFF_W-1)), 2**(COEFF_W-1)-1);
    c[1]=$urandom_range(-(2**(COEFF_W-1)), 2**(COEFF_W-1)-1);
    c[2]=$urandom_range(-(2**(COEFF_W-1)), 2**(COEFF_W-1)-1);
    c[3]=$urandom_range(-(2**(COEFF_W-1)), 2**(COEFF_W-1)-1);
    #1;
    expected = x[0]*c[0] + x[1]*c[1] + x[2]*c[2] + x[3]*c[3];
    $display("Random Test: y=%0d, expected=%0d", y, expected);

    $display("---- All tests completed ----");
    $finish;
  end
endmodule
