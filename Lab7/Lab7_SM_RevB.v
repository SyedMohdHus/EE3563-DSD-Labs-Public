`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Lab 7 - State Machine Chart, logic equations (no ROM)  (Nexys 4 rev B)
// Module Name: SM   - top level, gate/equation implementation of the SM chart
//
// State assignment: S0 = 00, S1 = 01, S2 = 10, 11 = unused (don't care)
//
// I/O:  SW2:0 = X3 X2 X1      BTNC = PBC (manual clock)
//       SW15  = CLK_Speed  (0 = push button, 1 = ~1 Hz slow clock)
//       LED2:0 = Z3 Z2 Z1     LED4:3 = q1 q0     7-seg digit 0 = state (0,1,2)
//
// Fill in all 10 blanks below using the hints next to each one.
//////////////////////////////////////////////////////////////////////////////////

module SM (
    input  CLK,
    input  X3,
    input  X2,
    input  X1,
    input  PBC,
    input  CLK_Speed,
    output Z3,
    output Z2,
    output Z1,
    output q1,
    output q0,
    output [7:0] SSEG_CA,
    output [7:0] SSEG_AN );

wire Q1P, Q0P;              // next state -> D inputs of the FFs
wire tick;                  // one CLK-wide enable: button press or slow clock

// Next state equations (D inputs of the FFs)
// Paths to S2: S0 -X2=1,X1=0-> S2 ; S0 -X2=1,X1=1,X3=1-> S2 ; S1 -X2=1-> S2
//   Q1+ = Q1'Q0'X2X1' + Q1'Q0'X3X2X1 + Q1'Q0X2
//       = Q1'X2X1' + Q1'X3X2 + Q1'Q0X2        (Q0' dropped by combining with Q1'Q0X2)
assign Q1P = (~q1 & X2 & ~X1) | (~q1 & X3 & X2) | (~q1 & q0 & X2);

// Paths to S1: S0 -X2=0-> S1 ; S0 -X2=1,X1=1,X3=0-> S1 ; S1 -X2=0-> S1 ; S2 -X1=0-> S1
//   Q0+ = Q1'Q0'X2' + Q1'Q0'X3'X2X1 + Q1'Q0X2' + Q1Q0'X1'
//       = Q1'X2' + Q1'Q0'X3'X2X1 + Q1Q0'X1'    (first and third terms combine)
// NOTE: the "simplified" Q0+ in the handout is wrong (it has X1'+X3 instead of
//       X3'X1, and it drops the S1 and S2 terms) - checked against the state table.
assign Q0P = (~q1 & ~X2) | (~q1 & ~q0 & ~X3 & X2 & X1) | (q1 & ~q0 & ~X1);

// Output equations
// Z1 = Q1'Q0'X2 + Q1'Q0 + Q1Q0'  = X2 + Q0 + Q1   (using 11 as don't care)
assign Z1 = X2 | q0 | q1;

// Z2 = S0 and X2 = 0
assign Z2 = ~q1 & ~q0 & ~X2;

// Z3 = S0 and X2 = 1 and X1 = 0
assign Z3 = ~q1 & ~q0 & X2 & ~X1;

// Clock select: push button or slow clock
Clock_Gen CG (.CLK(CLK), .PBC(PBC), .CLK_Speed(CLK_Speed), .tick(tick));

// Two D flip-flops hold the state
DFF FF1 (.CLK(CLK), .EN(tick), .D(Q1P), .Q(q1), .QN());
DFF FF0 (.CLK(CLK), .EN(tick), .D(Q0P), .Q(q0), .QN());

// State on the first seven segment display
SevenSeg SS (.q1(q1), .q0(q0), .SSEG_CA(SSEG_CA), .SSEG_AN(SSEG_AN));

endmodule


//////////////////////////////////////////////////////////////////////////////////
// D flip-flop with enable, Q and Q' outputs, starts at 0
//////////////////////////////////////////////////////////////////////////////////
module DFF (
    input  CLK,
    input  EN,
    input  D,
    output reg Q,
    output QN );

initial Q = 1'b0;           // starting state S0

always @(posedge CLK)
    if (EN)
        Q <= D;

assign QN = ~Q;

endmodule


//////////////////////////////////////////////////////////////////////////////////
// Slow clock and push button  (given, do not change except where marked)
// tick = one 100 MHz period wide pulse:
//   CLK_Speed = 0 -> once per debounced press of PBC
//   CLK_Speed = 1 -> once per second
//////////////////////////////////////////////////////////////////////////////////
module Clock_Gen #(parameter SLOW_COUNT = 100_000_000,   // 1 s  at 100 MHz
                   parameter DB_COUNT   = 1_000_000)     // 10 ms debounce
(
    input  CLK,
    input  PBC,
    input  CLK_Speed,
    output tick );

// slow clock
reg [26:0] slow_cnt = 0;
reg        slow_tick = 0;
always @(posedge CLK)
    if (slow_cnt == SLOW_COUNT - 1) begin
        slow_cnt  <= 0;
        slow_tick <= 1'b1;
    end
    else begin
        slow_cnt  <= slow_cnt + 1;
        slow_tick <= 1'b0;
    end

// push button: synchronize, debounce, rising edge
reg [1:0]  pb_sync = 2'b00;
reg [19:0] db_cnt  = 0;
reg        pb_state = 0, pb_last = 0;
always @(posedge CLK) begin
    pb_sync <= {pb_sync[0], PBC};
    if (pb_sync[1] != pb_state) begin
        if (db_cnt == DB_COUNT - 1) begin
            pb_state <= pb_sync[1];
            db_cnt   <= 0;
        end
        else
            db_cnt <= db_cnt + 1;
    end
    else
        db_cnt <= 0;
    pb_last <= pb_state;
end
wire pb_tick = pb_state & ~pb_last;

assign tick = CLK_Speed ? slow_tick : pb_tick;

endmodule


//////////////////////////////////////////////////////////////////////////////////
// Seven segment: shows the state (0, 1, 2) on digit 0, active low
// SSEG_CA = {DP, G, F, E, D, C, B, A}
//////////////////////////////////////////////////////////////////////////////////
module SevenSeg (
    input  q1,
    input  q0,
    output reg [7:0] SSEG_CA,
    output [7:0] SSEG_AN );

assign SSEG_AN = 8'b1111_1110;     // only AN0 on

always @(*)
    case ({q1, q0})
        2'b00:   SSEG_CA = 8'b1100_0000;   // 0
        2'b01:   SSEG_CA = 8'b1111_1001;   // 1  (B C)
        2'b10:   SSEG_CA = 8'b1010_0100;   // 2  (A B D E G)
        default: SSEG_CA = 8'b1011_1111;   // "-" (unused state)
    endcase

endmodule
