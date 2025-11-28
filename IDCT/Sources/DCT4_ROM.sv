module HEVC_DCT4_ROM (
input  logic [1:0] row,
input  logic [1:0] col, 
output logic signed [7:0] coeff
);
logic signed [7:0] COEFFS [0:3][0:3] = '{
'{ 64,  64,  64,  64},
'{ 83,  36, -36, -83}, 
'{ 64, -64, -64,  64},
'{ 36, -83,  83, -36}
};
assign coeff = COEFFS[row][col];
endmodule