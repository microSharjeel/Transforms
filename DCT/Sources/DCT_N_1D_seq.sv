module DCT_N_1D_seq #(
parameter int N = 4                    // Transform size: 4, 8, 16, 32
)(
input  logic clk,
input  logic reset,
input  logic start,
input  logic signed [15:0] x [0:N-1],
output logic signed [15:0] y [0:N-1],
output logic done
);

// derive parameters
localparam int M = $clog2(N);            // log2(N)

// HEVC scaling: 2^(6 + M/2) for forward transform
// For N=4: M=2 ? SCALE_SHIFT=7
// For N=8: M=3 ? SCALE_SHIFT=7  
// For N=16: M=4 ? SCALE_SHIFT=8
// For N=32: M=5 ? SCALE_SHIFT=8
localparam int SCALE_SHIFT = 6 + (M >> 1);

// state machine
typedef enum logic [2:0] {IDLE, LOAD_ROW, MAC_LOOP, STORE, NEXT_ROW, DONE} state_t;
state_t state;

// indices
logic [M-1:0] row_idx, col_idx;
logic signed [7:0] coeff;
logic signed [31:0] acc;
logic enable_mac, clear_mac;

// ROM selection based on N
generate
if (N == 4) begin : DCT4_ROM
DCT4_ROM rom (.row(row_idx), .col(col_idx), .coeff(coeff));
end
else if (N == 8) begin : DCT8_ROM
DCT8_ROM rom (.row(row_idx), .col(col_idx), .coeff(coeff));
end
else if (N == 16) begin : DCT16_ROM
DCT16_ROM rom (.row(row_idx), .col(col_idx), .coeff(coeff));
end
else if (N == 32) begin : DCT32_ROM
DCT32_ROM rom (.row(row_idx), .col(col_idx), .coeff(coeff));
end
endgenerate

// MAC unit (separate module)
MAC_unit mac (
.clk(clk), 
.reset(reset),
.enable(enable_mac), 
.clear(clear_mac),
.x(x[col_idx]), 
.c(coeff), 
.acc(acc)
);

// FSM
always_ff @(posedge clk or posedge reset) begin
if (reset) begin
state <= IDLE; 
row_idx <= 0; 
col_idx <= 0; 
done <= 0;
foreach(y[i]) y[i] <= 0;
end else begin
unique case (state)
IDLE: if (start) begin
row_idx <= 0; 
col_idx <= 0; 
done <= 0;
state <= LOAD_ROW;
end

LOAD_ROW: begin
col_idx <= 0;
state <= MAC_LOOP;
end

MAC_LOOP: begin
if (col_idx == N-1)
state <= STORE;
else
col_idx <= col_idx + 1;
end

STORE: begin
y[row_idx] <= (acc + (1 << (SCALE_SHIFT-1))) >>> SCALE_SHIFT;
state <= NEXT_ROW;
end

NEXT_ROW: begin
if (row_idx == N-1)
state <= DONE;
else begin
row_idx <= row_idx + 1;
state <= LOAD_ROW;
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

// MAC control
always_comb begin
enable_mac = (state == MAC_LOOP);
clear_mac  = (state == LOAD_ROW);
end

endmodule
