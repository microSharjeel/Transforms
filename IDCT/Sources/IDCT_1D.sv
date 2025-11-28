`timescale 1ns / 1ps
module IDCT_1D #(
    parameter int N = 4,
    parameter int BIT_DEPTH = 8
)(
    input  logic clk,
    input  logic reset,
    input  logic start,
    input  logic signed [15:0] x [0:N-1][0:N-1],
    output logic signed [15:0] y [0:N-1][0:N-1],
    output logic done
);

    localparam int M = $clog2(N);
    
    // HEVC Shift Constants (Check H.265 Spec 8.7.2.2)
    // Note: These values depend on BitIncrement. Assuming standard 8-bit video.
    localparam int SHIFT_1 = (N==4)? 7 : (N==8)? 7 : (N==16)? 7 : 7; // Example simplification
    localparam int SHIFT_2 = 12; // Example for 2nd stage, typically 20 - bit_depth

    typedef enum logic [3:0] {
        IDLE, ROW_TRANSFORM, ROW_WAIT, // Added Wait for pipeline alignment
        COL_TRANSFORM, COL_WAIT, 
        DONE
    } state_t;

    state_t state;
    logic [M-1:0] row_idx, col_idx, inner_idx;
    logic signed [7:0] coeff;
    logic signed [31:0] acc;
    logic enable_mac, start_acc; // Changed clear to start_acc
    logic row_transform_active;
    
    // Intermediate Memory
    logic signed [15:0] row_results [0:N-1][0:N-1];

    logic [M-1:0] rom_row_addr, rom_col_addr;
    logic signed [15:0] mac_input;

    // ----------------------------------------------------------------
    // ROM Instantiation (Same as your code)
    // ----------------------------------------------------------------
    generate
        if (N == 4)       HEVC_DCT4_ROM rom (.row(rom_row_addr), .col(rom_col_addr), .coeff(coeff));
        else if (N == 8)  HEVC_DCT8_ROM rom (.row(rom_row_addr), .col(rom_col_addr), .coeff(coeff));
        else if (N == 16) HEVC_DCT16_ROM rom (.row(rom_row_addr), .col(rom_col_addr), .coeff(coeff));
        else if (N == 32) HEVC_DCT32_ROM rom (.row(rom_row_addr), .col(rom_col_addr), .coeff(coeff));
    endgenerate

    // ----------------------------------------------------------------
    // ADDRESSING CORRECTION FOR IDCT
    // ----------------------------------------------------------------
    always_comb begin
        if (row_transform_active) begin
            // ROW IDCT: Y = X * C^T
            // Element (row, col) = Dot Product (X_row, C_col_transpose)
            // C_col_transpose is actually Row 'col' of the C matrix.
            // We need to sum over k (inner_idx).
            // We need C[col_idx][inner_idx].
            rom_row_addr = inner_idx;   // Select the Row of C based on our output Column
            rom_col_addr = col_idx; // Traverse the row
        end else begin
            // COL IDCT: Y = C^T * RowResult
            // Element (row, col) = Dot Product (C^T_row, RowResult_col)
            // C^T_row is Column 'row' of C matrix.
            // We need C[inner_idx][row_idx].
            rom_row_addr = inner_idx;
            rom_col_addr = row_idx; 
        end
    end

    // ----------------------------------------------------------------
    // MAC INPUT MUX
    // ----------------------------------------------------------------
    always_comb begin
        if (row_transform_active) begin
            mac_input = x[row_idx][inner_idx];
        end else begin
            mac_input = row_results[inner_idx][col_idx];
        end
    end

    // MAC Instance
    HEVC_MAC_unit mac (
        .clk(clk), 
        .reset(reset),
        .enable(enable_mac), 
        .start_acc(start_acc), // Changed signal name
        .x(mac_input), 
        .c(coeff), 
        .acc(acc)
    );

    // ----------------------------------------------------------------
    // CLIPPER FUNCTION (HEVC Requirement)
    // ----------------------------------------------------------------
    function automatic logic signed [15:0] clip_val(input logic signed [31:0] val);
        if (val > 32767) return 32767;
        else if (val < -32768) return -32768;
        else return val[15:0];
    endfunction

    // ----------------------------------------------------------------
    // FSM
    // ----------------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE; 
            row_idx <= 0; col_idx <= 0; inner_idx <= 0;
            done <= 0; row_transform_active <= 1;
            // Note: Clearing arrays in reset is bad for synthesis area. 
            // In ASIC, we just let them have garbage until written.
        end else begin
            case (state)
                IDLE: if (start) begin
                    row_idx <= 0; col_idx <= 0; inner_idx <= 0;
                    done <= 0; row_transform_active <= 1;
                    state <= ROW_TRANSFORM;
                end

                ROW_TRANSFORM: begin
                    if (inner_idx == N-1) begin
                        state <= ROW_WAIT; // Need 1 cycle for MAC to register final add
                        inner_idx <= 0;
                    end else begin
                        inner_idx <= inner_idx + 1;
                    end
                end

                ROW_WAIT: begin
                    // One cycle delay to allow MAC output to settle
                    // Apply Scaling and Rounding: (Acc + Offset) >> Shift
                    // Note: Simplified scaling logic for readability
                    row_results[row_idx][col_idx] <= clip_val((acc + (1 << (6-1))) >>> 6); // Using 6 as generic example
                    
                    if (col_idx == N-1) begin
                        col_idx <= 0;
                        if (row_idx == N-1) begin
                            row_idx <= 0;
                            row_transform_active <= 0;
                            state <= COL_TRANSFORM;
                        end else begin
                            row_idx <= row_idx + 1;
                            state <= ROW_TRANSFORM;
                        end
                    end else begin
                        col_idx <= col_idx + 1;
                        state <= ROW_TRANSFORM;
                    end
                end

                COL_TRANSFORM: begin
                    if (inner_idx == N-1) begin
                        state <= COL_WAIT;
                        inner_idx <= 0;
                    end else begin
                        inner_idx <= inner_idx + 1;
                    end
                end

                COL_WAIT: begin
                    // Final Write
                    y[row_idx][col_idx] <= clip_val((acc + (1 << (6-1))) >>> 6);

                    if (col_idx == N-1) begin
                        col_idx <= 0;
                        if (row_idx == N-1) begin
                            state <= DONE;
                        end else begin
                            row_idx <= row_idx + 1;
                            state <= COL_TRANSFORM;
                        end
                    end else begin
                        col_idx <= col_idx + 1;
                        state <= COL_TRANSFORM;
                    end
                end

                DONE: begin
                    done <= 1;
                    if (!start) state <= IDLE;
                end
            endcase
        end
    end

    // ----------------------------------------------------------------
    // CONTROLS
    // ----------------------------------------------------------------
    always_comb begin
        enable_mac = (state == ROW_TRANSFORM) || (state == COL_TRANSFORM);
        // Start new accumulation on the first index (0)
        start_acc  = (inner_idx == 0); 
    end
endmodule