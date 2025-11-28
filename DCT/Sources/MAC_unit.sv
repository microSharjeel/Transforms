module HEVC_MAC_unit (
input  logic clk,
input  logic reset,
input  logic enable,
input  logic clear,
input  logic signed [15:0] x,
input  logic signed [7:0] c,
output logic signed [31:0] acc
);

logic signed [31:0] accumulator;
logic signed [23:0] product;
logic signed [31:0] sum;

// Pre-calculate saturation limits (Cadence compatible)
localparam logic signed [31:0] MAX_POS = 32'sh7FFFFFFF;  // 2**31-1
localparam logic signed [31:0] MAX_NEG = 32'sh80000000;  // -2**31

always_ff @(posedge clk or posedge reset) begin
if (reset) begin
accumulator <= 0;
product <= 0;
end else if (clear) begin
accumulator <= 0;
product <= 0;
end else if (enable) begin
// Multiply with proper sign extension
product <= x * c;

// Calculate sum for saturation check
sum = accumulator + product;

// Accumulate with saturation check - Cadence compatible
if (product > 0 && accumulator > (MAX_POS - product)) begin
accumulator <= MAX_POS;  // Saturate positive
end else if (product < 0 && accumulator < (MAX_NEG - product)) begin
accumulator <= MAX_NEG;   // Saturate negative
end else begin
accumulator <= sum;
end
end
end

assign acc = accumulator;

endmodule