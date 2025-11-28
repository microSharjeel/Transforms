module tb_DCT_N_1D_seq;
parameter N = 4;  // Change this to test DCT4, DCT8, DCT16, DCT32

logic clk, reset, start, done;
logic signed [15:0] x [0:N-1];
logic signed [15:0] y [0:N-1];

DCT_N_1D_seq #(.N(N)) dut (.*);

// Clock generation
always #5 clk = ~clk;

initial begin
// Initialize
clk = 0;
reset = 1;
start = 0;
foreach(x[i]) x[i] = 0;

// Apply reset
#20;
reset = 0;
#20;

// Test 1: Ramp input
$display("=== Testing DCT%d with Ramp Input ===", N);
for (int i = 0; i < N; i++) begin
x[i] = 10 * (i + 1);  // [10, 20, 30, ...]
end
run_test();

// Test 2: DC input (all same values)
$display("\n=== Testing DCT%d with DC Input ===", N);
foreach(x[i]) x[i] = 64;
run_test();

// Test 3: Single non-zero input
$display("\n=== Testing DCT%d with Single Impulse ===", N);
foreach(x[i]) x[i] = 0;
x[0] = 100;
run_test();

$display("\n=== All DCT%d Tests Completed ===", N);
$finish;  // This stops the simulation automatically
end

task run_test();
@(posedge clk);
start = 1;
@(posedge clk);
start = 0;

wait(done);

$display("Input:  ");
for (int i = 0; i < N; i++) $write("%4d ", x[i]);
$display("\nOutput: ");
for (int i = 0; i < N; i++) $write("%4d ", y[i]);
$display("");

// Wait a few cycles between tests
repeat(5) @(posedge clk);
endtask
endmodule