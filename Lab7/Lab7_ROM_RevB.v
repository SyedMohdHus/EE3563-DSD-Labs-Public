`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Lab 7 - State Machine Chart with ROM  (Nexys 4 rev B)
// Module Name: SM   - top level, ROM implementation of the SM chart
//
// State assignment: S0 = 00, S1 = 01, S2 = 10, 11 = don't care (goes to S0)
// ROM address = {q1, q0, X3, X2, X1}   (q1 = high order bit)
// ROM word    = {Z3, Z2, Z1, Q1+, Q0+}
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

reg [4:0] Store [0:31];     // 32 x 5 ROM
wire Q1P, Q0P;              // next state -> D inputs of the FFs
wire tick;                  // one CLK-wide enable: button press or slow clock

initial     // Fill the ROM:  {Z3,Z2,Z1,Q1+,Q0+}
 begin
 // S0 (q1q0 = 00)  -- done for you, use these rows as your example
 Store[0]  = 5'b01001;   // X3X2X1=000  Z2     -> S1
 Store[1]  = 5'b01001;   // 001         Z2     -> S1
 Store[2]  = 5'b10110;   // 010         Z3 Z1  -> S2
 Store[3]  = 5'b00101;   // 011         Z1     -> S1
 Store[4]  = 5'b01001;   // 100         Z2     -> S1
 Store[5]  = 5'b01001;   // 101         Z2     -> S1
 Store[6]  = 5'b10110;   // 110         Z3 Z1  -> S2
 Store[7]  = 5'b00110;   // 111         Z1     -> S2

 // S1 (q1q0 = 01)  rows 8-15
 Store[8]  = 5'b00101;   // X3X2X1=000  Z1     -> S1
 Store[9]  = 5'b00101;   // 001         Z1     -> S1
 Store[10] = 5'b00110;   // 010         Z1     -> S2
 Store[11] = 5'b00110;   // 011         Z1     -> S2
 Store[12] = 5'b00101;   // 100         Z1     -> S1
 Store[13] = 5'b00101;   // 101         Z1     -> S1
 Store[14] = 5'b00110;   // 110         Z1     -> S2
 Store[15] = 5'b00110;   // 111         Z1     -> S2

 // S2 (q1q0 = 10)  rows 16-23
 Store[16] = 5'b00101;   // X3X2X1=000  Z1     -> S1
 Store[17] = 5'b00100;   // 001         Z1     -> S0
 Store[18] = 5'b00101;   // 010         Z1     -> S1
 Store[19] = 5'b00100;   // 011         Z1     -> S0
 Store[20] = 5'b00101;   // 100         Z1     -> S1
 Store[21] = 5'b00100;   // 101         Z1     -> S0
 Store[22] = 5'b00101;   // 110         Z1     -> S1
 Store[23] = 5'b00100;   // 111         Z1     -> S0

 // q1q0 = 11  rows 24-31
 Store[24] = 5'b00000;   // unused state: all 0's -> back to S0
 Store[25] = 5'b00000;
 Store[26] = 5'b00000;
 Store[27] = 5'b00000;
 Store[28] = 5'b00000;
 Store[29] = 5'b00000;
 Store[30] = 5'b00000;
 Store[31] = 5'b00000;
 end

wire [4:0] index;
assign index = {q1, q0, X3, X2, X1};

assign Z3  = Store[index][4];
assign Z2  = Store[index][3];
assign Z1  = Store[index][2];
assign Q1P = Store[index][1];
assign Q0P = Store[index][0];

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
