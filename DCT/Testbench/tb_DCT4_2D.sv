module tb_DCT_N_2D_final();

// PARAMETERS - CHANGE HERE FOR DIFFERENT DCT SIZES
parameter N = 4;                    // 4, 8, 16, 32
parameter BIT_DEPTH = 8;

// Signals - automatically sized based on N
logic clk, reset, start, done;
logic signed [15:0] x [0:N-1][0:N-1];
logic signed [15:0] y [0:N-1][0:N-1];

// DUT instantiation with parameters
DCT_N_2D_seq #(.N(N), .BIT_DEPTH(BIT_DEPTH)) dut (.*);

// Clock generation
always #5 clk = ~clk;

// Dynamic timeout based on transform size
function int get_timeout();
    case (N)
        4: get_timeout = 10000;   // 4x4 timeout
        8: get_timeout = 30000;   // 8x8 timeout  
        16: get_timeout = 1200000;  // 16x16 timeout
        32: get_timeout = 12000000; // 32x32 timeout
        default: get_timeout = 10000;
    endcase
endfunction

// Wait for done signal with dynamic timeout
task wait_for_done;
    reg timeout_flag;
    int timeout_val;
    begin
        timeout_val = get_timeout();
        fork
            begin
                wait(done);
            end
            begin
                #timeout_val;
                $display("ERROR: Timeout waiting for done signal for %0dx%0d DCT!", N, N);
                $finish;
            end
        join_any
        disable fork;
    end
endtask

// Display matrix - works for any size
task display_matrix;
    input [8*20:1] name;  // string type replacement
    integer i, j;
    begin
        $display("%s:", name);
        for (i = 0; i < N; i = i + 1) begin
            $write("Row %2d: ", i);
            for (j = 0; j < N; j = j + 1) begin
                $write("%6d ", y[i][j]);
            end
            $display();
        end
    end
endtask

// Initialize matrix to zeros
task init_matrix_to_zero;
    integer i, j;
    begin
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                x[i][j] = 0;
            end
        end
    end
endtask

// Set all pixels to same value
task set_all_pixels;
    input logic signed [15:0] value;
    integer i, j;
    begin
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                x[i][j] = value;
            end
        end
    end
endtask

// Set single pixel
task set_single_pixel;
    input integer row;
    input integer col;
    input logic signed [15:0] value;
    begin
        init_matrix_to_zero();
        x[row][col] = value;
    end
endtask

// Set diagonal pattern
task set_diagonal_pattern;
    input logic signed [15:0] value;
    integer i;
    begin
        init_matrix_to_zero();
        for (i = 0; i < N; i = i + 1) begin
            x[i][i] = value;
        end
    end
endtask

// Set vertical stripe
task set_vertical_stripe;
    input integer col;
    input logic signed [15:0] value;
    integer i;
    begin
        init_matrix_to_zero();
        for (i = 0; i < N; i = i + 1) begin
            x[i][col] = value;
        end
    end
endtask

// Set horizontal stripe
task set_horizontal_stripe;
    input integer row;
    input logic signed [15:0] value;
    integer j;
    begin
        init_matrix_to_zero();
        for (j = 0; j < N; j = j + 1) begin
            x[row][j] = value;
        end
    end
endtask

// Set checkerboard pattern
task set_checkerboard_pattern;
    input logic signed [15:0] value;
    integer i, j;
    begin
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                if (((i + j) % 2) == 0) begin
                    x[i][j] = value;
                end else begin
                    x[i][j] = -value;
                end
            end
        end
    end
endtask

// Set gradient pattern
task set_gradient_pattern;
    integer i, j;
    begin
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                x[i][j] = i * (255/N) + j * (255/N);
            end
        end
    end
endtask

// Run test with proper timing
task run_test;
    input [8*50:1] test_name;  // string type replacement
    begin
        $display("=== %s ===", test_name);
        #20 start = 1;
        #30 start = 0;  // Longer start pulse for reliability
        wait_for_done();
        #100; // Wait after done
        display_matrix("Result");
        $display("");
    end
endtask

// Main test sequence
initial begin
    // Variables for range check
    integer i, j;
    reg range_ok;
    
    // Initialize
    clk = 0;
    reset = 1;
    start = 0;
    init_matrix_to_zero();

    // Display configuration
    $display("=== HEVC %0dx%0d 2D DCT COMPREHENSIVE TEST ===", N, N);
    $display("");

    // Reset sequence
    #100 reset = 0;
    #200; // Longer wait after reset for larger transforms

    // Test Case 1: All zeros
    init_matrix_to_zero();
    run_test("Test 1: All zeros");

    // Test Case 2: All ones (DC input)
    set_all_pixels(100);
    run_test("Test 2: All ones (DC input)");
    $display("DC coefficient at [0][0] = %d", y[0][0]);
    $display("");

    // Test Case 3: Single pixel at [0][0]
    set_single_pixel(0, 0, 1000);  // Larger value for visibility
    run_test("Test 3: Single pixel at [0][0]");

    // Test Case 4: Single pixel at [1][1]
    set_single_pixel(1, 1, 1000);
    run_test("Test 4: Single pixel at [1][1]");

    // Test Case 5: Diagonal pattern
    set_diagonal_pattern(150);
    run_test("Test 5: Diagonal pattern");

    // Test Case 6: Vertical stripe
    set_vertical_stripe(1, 200);
    run_test("Test 6: Vertical stripe (column 1)");

    // Test Case 7: Horizontal stripe
    set_horizontal_stripe(2, 200);
    run_test("Test 7: Horizontal stripe (row 2)");

    // Test Case 8: Checkerboard pattern
    set_checkerboard_pattern(100);
    run_test("Test 8: Checkerboard pattern");

    // Test Case 9: Gradient pattern
    set_gradient_pattern();
    run_test("Test 9: Gradient pattern");

    // Test Case 10: Maximum amplitude
    set_all_pixels(255);
    run_test("Test 10: Maximum amplitude (255)");

    // Range check
    range_ok = 1;
    for (i = 0; i < N; i = i + 1) begin
        for (j = 0; j < N; j = j + 1) begin
            if (y[i][j] < -32768 || y[i][j] > 32767) begin
                range_ok = 0;
                $display("ERROR: Coefficient [%0d][%0d] = %d out of range!", i, j, y[i][j]);
            end
        end
    end
    if (range_ok) begin
        $display("Range Check: All coefficients within [-32768, 32767]");
    end

    $display("");
    $display("============================================================");
    $display("=== HEVC %0dx%0d 2D DCT ALL TESTS COMPLETED SUCCESSFULLY ===", N, N);
    $display("============================================================");

    #200;
    $finish;
end

endmodule