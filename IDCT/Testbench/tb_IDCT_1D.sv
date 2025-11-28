`timescale 1ns / 1ps
module tb_IDCT_1D;
    // 1. Parameters
    parameter int N = 4;
    parameter int BIT_DEPTH = 8;

    // 2. Signals
    logic clk;
    logic reset;
    logic start;
    logic done;
    
    logic signed [15:0] x [0:N-1][0:N-1]; // Input
    logic signed [15:0] y [0:N-1][0:N-1]; // Output

    // Loop variables
    integer i, j;

    // 3. Instantiate the DUT
    IDCT_1D #(
        .N(N),
        .BIT_DEPTH(BIT_DEPTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .x(x),
        .y(y),
        .done(done)
    );

    // 4. Clock Generation
    always #5 clk = ~clk;

    // 5. Main Stimulus Process
    initial begin
        // --- Initialization ---
        $display("--- SIMULATION START ---");
        clk = 0;
        reset = 1;
        start = 0;
        
        // Clear input array manually using loops
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                x[i][j] = 0;
            end
        end

        // Hold Reset for a bit
        #20;
        reset = 0;
        #20;

        // ============================================
        // TEST CASE 1: DC Only (Flat Color)
        // ============================================
        $display("\nTest 1: Sending DC value 1000 at x[0][0]...");
        
        // Setup Input
        x[0][0] = 16'd1000;

        // Pulse Start
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait for Done
        wait(done);
        
        // Wait a few cycles to let waveforms settle
        #50;

        // Print Results
        $display("Output Y (Should be approx constant value):");
        for (i = 0; i < N; i = i + 1) begin
            $write("Row %0d: ", i);
            for (j = 0; j < N; j = j + 1) begin
                $write("%6d ", y[i][j]);
            end
            $display(""); // New line
        end

        // ============================================
        // TEST CASE 2: Checkerboard Pattern
        // ============================================
        #50;
        $display("\nTest 2: Sending AC Pattern...");

        // Reset inputs to 0 first
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                x[i][j] = 0;
            end
        end

        // Set a high frequency component
        x[0][1] = 1000; // Top row, 2nd column
        x[1][0] = 1000; // 2nd row, 1st column

        // Pulse Start
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait for Done
        wait(done);
        #50;

        // Print Results
        $display("Output Y (Should show a pattern):");
        for (i = 0; i < N; i = i + 1) begin
            $write("Row %0d: ", i);
            for (j = 0; j < N; j = j + 1) begin
                $write("%6d ", y[i][j]);
            end
            $display(""); 
        end

        $display("\n--- SIMULATION END ---");
        $finish;
    end
endmodule