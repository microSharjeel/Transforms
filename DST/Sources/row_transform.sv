`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NCDC
// Engineer: Muhammad Junaid
// 
// Create Date: 09/22/2025 03:58:42 PM
// Design Name: 
// Module Name: row_transform
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
module row_transform
#(
parameter int IN_W = 12,
parameter int COEFF_W = 8,
parameter int OUT_W = IN_W + COEFF_W + 2
)(
input logic signed [IN_W-1:0] in_block [0:3][0:3], //4x4 input
output logic signed [OUT_W-1:0] out_block [0:3][0:3] //4x4 after row transform
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
for (i=0; i<4; i++) begin: ROWS
for (j=0; j<4; j++) begin: COLS
mac_4 #(.IN_W(IN_W), .COEFF_W(COEFF_W), .OUT_W(OUT_W)) mac_inst (
.x(in_block[i]),
.c(A4[j]),
.y(out_block[i][j])
);
end
end
endgenerate
endmodule
