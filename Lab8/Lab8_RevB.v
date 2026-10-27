`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Lab 8 - Non-sequential 4-bit counter  (Nexys 4 rev B)
// Module Name: NS_Counter - top level
//
// Count sequence (hex): C, A, 4, 5, 7, 3, F, 6, 9, back to C
// Start = SW0. Start = 1: keep cycling. Start = 0: finish the count and
//   hold on C. At power-up the counter sits on C.
// State coding: straight binary, the state IS the count (Q3 Q2 Q1 Q0).
// Unused states (0,1,2,8,B,D,E) go to C.
//
// I/O:  SW0 = Start     LED3:0 = count     7-seg digit 0 = count in hex
// Clock: FAST = 0 -> divided clock (counter_out[26], ~1.3 s per count)
//        FAST = 1 -> 100 MHz board clock (used by the testbench)
//////////////////////////////////////////////////////////////////////////////////

module NS_Counter #(parameter FAST = 0)    // change to 1 to run on the fast clock
(
    input  CLK,
    input  Start,
    output [3:0] LED,
    output reg [7:0] SSEG_CA,
    output [7:0] SSEG_AN );

// Clock divider (from the lab handout)
reg [26:0] counter_out = 0;
reg        Clk_Slow    = 0;
always @(posedge CLK) begin
    counter_out <= counter_out + 1;
    Clk_Slow    <= counter_out[26];
end

wire Clk_Use = FAST ? CLK : Clk_Slow;

wire [3:0] State;           // present state = Q3 Q2 Q1 Q0
reg  [3:0] Next_State;      // D inputs of the FFs

// Always block 1: next state with the Start switch
// Each line: present state -> next state in the count, same format as 4'h4 below
always @(*)
    case (State)
        4'hC:    Next_State = Start ? 4'hA : 4'hC;   // only C looks at Start
        4'hA:    Next_State = 4'h4;
        4'h4:    Next_State = 4'h5;
        4'h5:    Next_State = 4'h7;
        4'h7:    Next_State = 4'h3;
        4'h3:    Next_State = 4'hF;
        4'hF:    Next_State = 4'h6;
        4'h6:    Next_State = 4'h9;
        4'h9:    Next_State = 4'hC;
        default: Next_State = 4'hC;                  // unused states
    endcase

// Always block 2 (inside DFF): State <= Next_State on the clock edge
// INIT sets the power-up state to C = 1100
DFF #(.INIT(1'b1)) FF3 (.CLK(Clk_Use), .D(Next_State[3]), .Q(State[3]), .QN());
DFF #(.INIT(1'b1)) FF2 (.CLK(Clk_Use), .D(Next_State[2]), .Q(State[2]), .QN());
DFF #(.INIT(1'b0)) FF1 (.CLK(Clk_Use), .D(Next_State[1]), .Q(State[1]), .QN());
DFF #(.INIT(1'b0)) FF0 (.CLK(Clk_Use), .D(Next_State[0]), .Q(State[0]), .QN());

assign LED = State;

// Seven segment: first (rightmost) digit only, active low
// SSEG_CA = {DP, G, F, E, D, C, B, A}, active low (0 = segment on), keep DP off
// 0 is done for you, use it as the example
assign SSEG_AN = 8'b1111_1110;

always @(*)
    case (State)
        4'h0: SSEG_CA = 8'b1100_0000;
        4'h1: SSEG_CA = 8'b1111_1001;
        4'h2: SSEG_CA = 8'b1010_0100;
        4'h3: SSEG_CA = 8'b1011_0000;
        4'h4: SSEG_CA = 8'b1001_1001;
        4'h5: SSEG_CA = 8'b1001_0010;
        4'h6: SSEG_CA = 8'b1000_0010;
        4'h7: SSEG_CA = 8'b1111_1000;
        4'h8: SSEG_CA = 8'b1000_0000;
        4'h9: SSEG_CA = 8'b1001_0000;
        4'hA: SSEG_CA = 8'b1000_1000;
        4'hB: SSEG_CA = 8'b1000_0011;
        4'hC: SSEG_CA = 8'b1100_0110;
        4'hD: SSEG_CA = 8'b1010_0001;
        4'hE: SSEG_CA = 8'b1000_0110;
        4'hF: SSEG_CA = 8'b1000_1110;
    endcase

endmodule


//////////////////////////////////////////////////////////////////////////////////
// D flip-flop with Q and Q' outputs, INIT = power-up value
//////////////////////////////////////////////////////////////////////////////////
module DFF #(parameter INIT = 1'b0)
(
    input  CLK,
    input  D,
    output reg Q,
    output QN );

initial Q = INIT;

always @(posedge CLK)
    Q <= D;

assign QN = ~Q;

endmodule
