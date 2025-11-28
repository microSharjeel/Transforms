module DCT_N_2D_seq #(
parameter N = 4,                    // Transform size: 4, 8, 16, 32
parameter BIT_DEPTH = 8             // HEVC typically uses 8-bit input
)(
input  logic clk,
input  logic reset,
input  logic start,
input  logic signed [15:0] x [0:N-1][0:N-1],
output logic signed [15:0] y [0:N-1][0:N-1],
output logic done
);

// HEVC compliant parameters - use fixed values for better synthesis
localparam M = (N == 4) ? 2 : (N == 8) ? 3 : (N == 16) ? 4 : 5; // $clog2(N) replacement
localparam B = BIT_DEPTH;

// HEVC scaling factors
localparam ROW_SCALE = (N==4) ? 6 : (N==8) ? 7 : (N==16) ? 8 : 9;
localparam COL_SCALE = (N==4) ? 6 : (N==8) ? 7 : (N==16) ? 8 : 9;

// state machine - use simple encoding
typedef enum logic [2:0] {
IDLE = 3'b000,
ROW_TRANSFORM = 3'b001, 
STORE_ROW_RESULT = 3'b010,
COL_TRANSFORM = 3'b011,
STORE_COL_RESULT = 3'b100,
DONE = 3'b101
} state_t;

state_t state;

// indices and signals
logic [M-1:0] row_idx, col_idx;
logic [M-1:0] inner_idx;
logic signed [7:0] coeff;
logic signed [31:0] acc;
logic enable_mac, clear_mac;
logic row_transform_active;

// Intermediate storage for row transform results
logic signed [15:0] row_results [0:N-1][0:N-1];

// ROM addressing - DIFFERENT for row vs column transforms
logic [M-1:0] rom_row_addr, rom_col_addr;

// Input selection for MAC
logic signed [15:0] mac_input;

// ROM selection based on N - Cadence compatible generate
generate
if (N == 4) begin : HEVC_DCT4_ROM
HEVC_DCT4_ROM rom (.row(rom_row_addr), .col(rom_col_addr), .coeff(coeff));
end else if (N == 8) begin : HEVC_DCT8_ROM
HEVC_DCT8_ROM rom (.row(rom_row_addr), .col(rom_col_addr), .coeff(coeff));
end else if (N == 16) begin : HEVC_DCT16_ROM
HEVC_DCT16_ROM rom (.row(rom_row_addr), .col(rom_col_addr), .coeff(coeff));
end else if (N == 32) begin : HEVC_DCT32_ROM
HEVC_DCT32_ROM rom (.row(rom_row_addr), .col(rom_col_addr), .coeff(coeff));
end
endgenerate

// CORRECTED ROM addressing - unchanged functionality
always_comb begin
if (row_transform_active) begin
// Row transform: need C[inner_idx][col_idx] for X × C?
rom_row_addr = inner_idx;
rom_col_addr = col_idx;
end else begin
// Column transform: need C[inner_idx][row_idx] for C × TEMP  
rom_row_addr = inner_idx;
rom_col_addr = row_idx;
end
end

// MAC unit
HEVC_MAC_unit mac (
.clk(clk), 
.reset(reset),
.enable(enable_mac), 
.clear(clear_mac),
.x(mac_input), 
.c(coeff), 
.acc(acc)
);

// CORRECTED Input selection MUX - unchanged functionality
always_comb begin
if (row_transform_active) begin
// Row transform: process row 'row_idx', element 'inner_idx'
mac_input = x[row_idx][inner_idx];
end else begin
// Column transform: process column 'col_idx', element 'inner_idx'
mac_input = row_results[inner_idx][col_idx];
end
end

// FSM for 2D DCT - Cadence compatible version
always_ff @(posedge clk or posedge reset) begin
if (reset) begin
state <= IDLE; 
row_idx <= 0; 
col_idx <= 0;
inner_idx <= 0;
done <= 0;
row_transform_active <= 1;

// Initialize arrays with nested for-loops (Cadence compatible)
for (int i = 0; i < N; i = i + 1) begin
for (int j = 0; j < N; j = j + 1) begin
row_results[i][j] <= 0;
y[i][j] <= 0;
end
end

end else begin
// Use simple case instead of unique case
case (state)
IDLE: begin
if (start) begin
row_idx <= 0; 
col_idx <= 0;
inner_idx <= 0;
done <= 0;
row_transform_active <= 1;
state <= ROW_TRANSFORM;
end
end

ROW_TRANSFORM: begin
if (inner_idx == (N-1)) begin
// Finished dot product for current row/coefficient
state <= STORE_ROW_RESULT;
inner_idx <= 0;
end else begin
inner_idx <= inner_idx + 1;
end
end

STORE_ROW_RESULT: begin
// Store row transform result with scaling and rounding
row_results[row_idx][col_idx] <= 
(acc + (1 << (ROW_SCALE-1))) >>> ROW_SCALE;

if (col_idx == (N-1)) begin
// Finished all coefficients for current row
col_idx <= 0;
if (row_idx == (N-1)) begin
// All rows transformed, move to column transform
row_idx <= 0;
row_transform_active <= 0;
state <= COL_TRANSFORM;
end else begin
// Move to next row
row_idx <= row_idx + 1;
state <= ROW_TRANSFORM;
end
end else begin
// Move to next coefficient in same row
col_idx <= col_idx + 1;
state <= ROW_TRANSFORM;
end
end

COL_TRANSFORM: begin
if (inner_idx == (N-1)) begin
// Finished dot product for current column/coefficient
state <= STORE_COL_RESULT;
inner_idx <= 0;
end else begin
inner_idx <= inner_idx + 1;
end
end

STORE_COL_RESULT: begin
// Store final 2D DCT result with scaling and rounding
y[row_idx][col_idx] <= 
(acc + (1 << (COL_SCALE-1))) >>> COL_SCALE;

if (col_idx == (N-1)) begin
// Finished all coefficients for current output row
col_idx <= 0;
if (row_idx == (N-1)) begin
// All output rows completed
state <= DONE;
end else begin
// Move to next output row
row_idx <= row_idx + 1;
state <= COL_TRANSFORM;
end
end else begin
// Move to next coefficient in same output row
col_idx <= col_idx + 1;
state <= COL_TRANSFORM;
end
end

DONE: begin
done <= 1;
if (!start) state <= IDLE;
end

default: state <= IDLE;
endcase
end
end

// MAC control - unchanged functionality
always_comb begin
enable_mac = (state == ROW_TRANSFORM) || (state == COL_TRANSFORM);
// Only clear at the very beginning of each dot product
clear_mac = ((state == ROW_TRANSFORM) && (inner_idx == 0)) || 
((state == COL_TRANSFORM) && (inner_idx == 0));
end

endmodule