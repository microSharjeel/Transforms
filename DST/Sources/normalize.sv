`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NCDC
// Engineer: Muhammad Junaid
// 
// Create Date: 09/24/2025 10:27:36 AM
// Design Name: 
// Module Name: normalize
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
module normalize
#(
parameter int IN_W  = 24,
parameter int OUT_W = 16,
parameter int SHIFT = 14
)(
input  logic signed [IN_W-1:0]  in_block  [0:3][0:3],
output logic signed [OUT_W-1:0] out_block [0:3][0:3]
);

// rounding constant = 2^(SHIFT-1)
localparam logic signed [IN_W-1:0] ROUND = (1 <<< (SHIFT-1));

logic signed [IN_W:0] rounded;   // one extra bit
logic signed [IN_W:0] shifted;
logic signed [OUT_W-1:0] saturated;

always_comb begin
for (int i=0; i<4; i++) begin
for (int j=0; j<4; j++) begin

// 1) Apply rounding before shifting
rounded = in_block[i][j] + ROUND;

// 2) Arithmetic shift
shifted = rounded >>> SHIFT;

// 3) Saturate to OUT_W bits
if (shifted >  $signed({1'b0,{(OUT_W-1){1'b1}}}))     // +32767 for OUT_W=16
saturated =  $signed({1'b0,{(OUT_W-1){1'b1}}});
else if (shifted < $signed({1'b1,{(OUT_W-1){1'b0}}})) // -32768 for OUT_W=16
saturated =  $signed({1'b1,{(OUT_W-1){1'b0}}});
else
saturated = shifted[OUT_W-1:0];

out_block[i][j] = saturated;
end
end
end

endmodule
