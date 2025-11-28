module HEVC_DCT4_ROM (
    input  logic [1:0] row,
    input  logic [1:0] col, 
    output logic signed [7:0] coeff
);

    // Synthesizable constant array - use case statements or direct wiring
    logic signed [7:0] coeff_out;
    
    // Method 1: Using case statements (most compatible)
    always_comb begin
        case ({row, col})
            // Row 0
            4'b0000: coeff_out = 8'sd64;  // [0][0]
            4'b0001: coeff_out = 8'sd64;  // [0][1]
            4'b0010: coeff_out = 8'sd64;  // [0][2]
            4'b0011: coeff_out = 8'sd64;  // [0][3]
            
            // Row 1
            4'b0100: coeff_out = 8'sd83;  // [1][0]
            4'b0101: coeff_out = 8'sd36;  // [1][1]
            4'b0110: coeff_out = -8'sd36; // [1][2]
            4'b0111: coeff_out = -8'sd83; // [1][3]
            
            // Row 2
            4'b1000: coeff_out = 8'sd64;  // [2][0]
            4'b1001: coeff_out = -8'sd64; // [2][1]
            4'b1010: coeff_out = -8'sd64; // [2][2]
            4'b1011: coeff_out = 8'sd64;  // [2][3]
            
            // Row 3
            4'b1100: coeff_out = 8'sd36;  // [3][0]
            4'b1101: coeff_out = -8'sd83; // [3][1]
            4'b1110: coeff_out = 8'sd83;  // [3][2]
            4'b1111: coeff_out = -8'sd36; // [3][3]
            
            default: coeff_out = 8'sd0;
        endcase
    end

    assign coeff = coeff_out;

endmodule