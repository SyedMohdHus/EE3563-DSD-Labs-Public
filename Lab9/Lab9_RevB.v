`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Lab 9 - 4-bit Comparator  STUDENT TEMPLATE  (Nexys 4 rev B)
// Use with Lab9_RevB.xdc
// Module Name: Comparator - top level
//
// A = SW7:4, B = SW3:0.  LED7:0 = switches.  LED15 = GT, LED14 = EQ, LED13 = LT
// 7-seg: digit 0 (rightmost) = B, digit 1 = A, digit 7 (leftmost) = G / L / E
//
// 1-bit comparator cell: inputs A, B, GTp, LTp -> outputs GT, LT.
//   Bits flow from bit 3 down to bit 0. The first cell (bit 3) gets
//   GTp = 0 and LTp = 0 ("equal so far").
// Fill in the 25 blanks. Do NOT change the port names (they match the .xdc).
//////////////////////////////////////////////////////////////////////////////////

module Comparator (
    input  CLK,
    input  [7:0] SW,
    output [15:0] LED,
    output [7:0] SSEG_CA,
    output reg [7:0] SSEG_AN = 8'b11111111 );

parameter width1 = 100000000;   // slow clock (not used in this lab)
parameter width2 = 10000;       // display multiplex clock

wire [3:0] A = SW[7:4];
wire [3:0] B = SW[3:0];
wire [4:0] GT, LT;              // GT[4], LT[4] = inputs to the first cell
wire EQ;

assign GT[4] = 1'b0;
assign LT[4] = 1'b0;

// Four 1-bit comparators, high order bit first
Comp1 C3 (A[3], B[3], GT[4], LT[4], GT[3], LT[3]);
// HINT: bit 2 cell. Its prior inputs are the outputs of the bit 3 cell.
Comp1 C2 (A[2], B[2], GT[3], LT[3], GT[2], LT[2]);

Comp1 C1 (A[1], B[1], GT[2], LT[2], GT[1], LT[1]);
Comp1 C0 (A[0], B[0], GT[1], LT[1], GT[0], LT[0]);

// HINT: equal means neither greater nor less. Use bitwise operators.
assign EQ  = ~GT[0] & ~LT[0];
// HINT: 16 bits, left to right: GT, EQ, LT, five zeros, then the 8 switches
assign LED = {GT[0], EQ, LT[0], 5'b00000, SW};

// Clock module from the previous labs
wire Clk_Slow, Clk_Multi;
Clk_Divide #(width1, width2) In1 (CLK, Clk_Slow, Clk_Multi);

// Display multiplex: digit 0 = B, digit 1 = A, digit 7 = result
reg [2:0] Count = 0;
reg [4:0] Dig_IN = 5'd18;       // 0-F = hex, 16 = G, 17 = L, 18 = blank
// HINT: pick the symbol number for G, L or E with the ? : operator
wire [4:0] Result = GT[0] ? 5'd16 : (LT[0] ? 5'd17 : 5'd14);

always @(posedge Clk_Multi) begin
    Count <= Count + 1;
    case (Count)
        0: begin SSEG_AN <= 8'b11111110; Dig_IN <= {1'b0, B}; end
        // HINT: digit 1 shows A. Dig_IN is 5 bits wide.
        1: begin SSEG_AN <= 8'b11111101; Dig_IN <= {1'b0, A}; end
        // HINT: leftmost digit. Anodes are active low.
        7: begin SSEG_AN <= 8'b01111111; Dig_IN <= Result;    end
        default: begin SSEG_AN <= 8'b11111111; Dig_IN <= 5'd18; end
    endcase
end

Digit_Set_Segs In2 (Dig_IN, 1'b0, SSEG_CA);

endmodule


//////////////////////////////////////////////////////////////////////////////////
// 1-bit comparator cell (combinational)
//////////////////////////////////////////////////////////////////////////////////
module Comp1 (
    input  A, B,
    input  GTp, LTp,        // result from the higher order bits
    output GT, LT );

// HINT: from your truth table. Use bitwise operators (~ & |), not logical ones.
assign GT = GTp | (~LTp & A & ~B);
assign LT = LTp | (~GTp & ~A & B);

endmodule


//////////////////////////////////////////////////////////////////////////////////
// Clock divider: Clk_Slow (width1) and Clk_Multi (width2)
//////////////////////////////////////////////////////////////////////////////////
module Clk_Divide #(parameter width1 = 100000000, width2 = 10000) (
    input  clk,
    output reg Clk_Slow = 0,
    output reg Clk_Multi = 0 );

reg [31:0] Slow_Counter = 0, Clock_Counter = 0;

always @(posedge clk) begin
    Slow_Counter  <= Slow_Counter + 1;
    Clock_Counter <= Clock_Counter + 1;
    if (Slow_Counter == width1) begin Clk_Slow  <= !Clk_Slow;  Slow_Counter  <= 0; end
    if (Clock_Counter == width2) begin Clk_Multi <= !Clk_Multi; Clock_Counter <= 0; end
end

endmodule


//////////////////////////////////////////////////////////////////////////////////
// 7-segment decoder using a 2D vector. Cathodes = {DP, G, F, E, D, C, B, A}
// A segment is ON when its bit = 0.
//////////////////////////////////////////////////////////////////////////////////
module Digit_Set_Segs (
    input  [4:0] Digit,     // 0-F hex, 16 = G, 17 = L, 18 = blank
    input  DP,              // 1 = decimal point on
    output [7:0] Cathodes );

reg [6:0] Segs [0:18];      // 19 symbols x 7 segments (GFEDCBA)

initial begin
    Segs[0]  = 7'b1000000;  // 0
    // HINT: segments are active low (0 = ON), bit order G F E D C B A. Use 0 as the example.
    Segs[1]  = 7'b1111001;  // 1
    Segs[2]  = 7'b0100100;  // 2
    Segs[3]  = 7'b0110000;  // 3
    Segs[4]  = 7'b0011001;  // 4
    Segs[5]  = 7'b0010010;  // 5
    Segs[6]  = 7'b0000010;  // 6
    Segs[7]  = 7'b1111000;  // 7
    Segs[8]  = 7'b0000000;  // 8
    Segs[9]  = 7'b0010000;  // 9
    Segs[10] = 7'b0001000;  // A
    Segs[11] = 7'b0000011;  // b
    Segs[12] = 7'b1000110;  // C
    Segs[13] = 7'b0100001;  // d
    Segs[14] = 7'b0000110;  // E
    Segs[15] = 7'b0001110;  // F
    // HINT: G and L are not hex digits. Draw them on the 7-segment and work out the code.
    Segs[16] = 7'b1000010;  // G
    Segs[17] = 7'b1000111;  // L
    Segs[18] = 7'b1111111;  // blank
end

assign Cathodes = {~DP, Segs[Digit]};

endmodule
