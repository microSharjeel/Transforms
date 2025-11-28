`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NCDC
// Engineer: Muhammad Junaid
// 
// Create Date: 09/24/2025 10:39:43 AM
// Design Name: 
// Module Name: dst4x4_top
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
module dst4x4_top #(
parameter int IN_W = 12,
parameter int COEFF_W = 8,
parameter int MID_W = IN_W + COEFF_W + 2, // safe growth
parameter int COL_W = MID_W + COEFF_W + 2, // extra growth after column
parameter int OUT_W = 16,
parameter int SHIFT = 14
)(
input  logic signed [IN_W-1:0] in_block [0:3][0:3],
output logic signed [OUT_W-1:0] out_block [0:3][0:3]
);

logic signed [MID_W-1:0] row_out [0:3][0:3];
logic signed [COL_W-1:0] col_out [0:3][0:3];

// Stage 1: row transform
row_transform #(.IN_W(IN_W), .COEFF_W(COEFF_W), .OUT_W(MID_W)) u_row (
.in_block(in_block),
.out_block(row_out)
);

// Stage 2: column transform
col_transform #(.IN_W(MID_W), .COEFF_W(COEFF_W), .OUT_W(COL_W)) u_col (
.in_block(row_out),
.out_block(col_out)
);

// Stage 3: normalization
normalize #(.IN_W(COL_W), .OUT_W(OUT_W), .SHIFT(SHIFT)) u_norm (
.in_block(col_out),
.out_block(out_block)
);

endmodule
