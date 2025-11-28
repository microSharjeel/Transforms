`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NCDC
// Engineer: Muhammad Junaid
// 
// Create Date: 09/23/2025 10:09:14 AM
// Design Name: 
// Module Name: col_transform
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
module col_transform
#(
parameter int IN_W = 12,
parameter int COEFF_W = 8,
parameter int OUT_W = IN_W + COEFF_W + 2
)
(
input logic signed [IN_W-1:0] in_block [0:3][0:3], //4x4 input after row stage 
output logic signed [OUT_W-1:0] out_block [0:3][0:3] //final DST output 
);
//HEVC A4 Transform Matrix 
localparam signed [COEFF_W-1:0] A4 [0:3][0:3] = '{
'{ 29, 55, 74, 84},
'{ 74, 74,  0,-74},
'{ 84,-29,-74, 55},
'{ 55,-84, 74,-29}
};
genvar i, j;
generate
for (j=0; j<4; j++)begin:COLS //loop over columns
for(i=0; i<4; i++)begin:ROWS
logic signed [IN_W-1:0] col_vec [0:3];
assign col_vec[0] = in_block[0][j];
assign col_vec[1] = in_block[1][j];
assign col_vec[2] = in_block[2][j];
assign col_vec[3] = in_block[3][j];
mac_4 #(.IN_W(IN_W), .COEFF_W(COEFF_W), .OUT_W(OUT_W)) mac_inst (
.x(col_vec),
.c(A4[i]),
.y(out_block[i][j])
);
end
end
endgenerate
endmodule
