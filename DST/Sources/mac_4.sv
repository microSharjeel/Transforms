`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NCDC
// Engineer: Muhammad Junaid
// 
// Create Date: 09/18/2025 03:39:06 PM
// Design Name: 
// Module Name: mac_4
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


module mac_4
#(
parameter int IN_W = 12,
parameter int COEFF_W = 8,
parameter int OUT_W = IN_W + COEFF_W + 2
)(
input logic signed [IN_W-1:0] x [0:3], //4 input samples
input logic signed [COEFF_W-1:0] c [0:3], //4 Coefficients
output logic signed [OUT_W-1:0] y //MAC result
);
always_comb
begin
y = c[0] * x[0] + c[1] * x[1] + c[2] * x[2] + c[3] * x[3];
end
endmodule
