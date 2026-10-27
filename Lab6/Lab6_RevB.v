`timescale 1ns / 1ps
// Lab 6 - Complement and Hex Display (Nexys 4 rev B)
// Shows the switch byte on the two leftmost digits and its complement
// on the two rightmost digits. The middle four digits are blank.
//   an[7] an[6]  an[5..2]  an[1]  an[0]
//   SW hi  SW lo   blank   ~SW hi ~SW lo
// The eight digits share one set of segment lines, so they are
// time division multiplexed: one digit is lit at a time, fast enough
// that the eye sees all of them at once.

module nf #(parameter width2 = 10000)   // clk cycles per half period of Clk_Multi
(
    input            clk,      // 100 MHz board clock
    input      [7:0] sw,       // input byte
    output     [6:0] seg,      // segments g..a, active low
    output           dp,       // decimal point, active low
    output reg [7:0] an        // digit enables, active low
);

    // ---- Clock divider: makes the multiplex clock Clk_Multi ----
    // Clk_Multi toggles every (width2+1) clk cycles.
    // width2 = 10000 -> about 200 us per digit, 1.6 ms for all 8 digits.
    reg [31:0] count = 0;
    reg        Clk_Multi = 0;

    always @(posedge clk) begin
        if (count == width2) begin
            count     <= 0;
            Clk_Multi <= ~Clk_Multi;
        end else
            count <= count + 1;
    end

    // ---- Digit select: 3-bit counter steps through the 8 digits ----
    reg [2:0] digit = 0;

    always @(posedge Clk_Multi)
        digit <= digit + 1;

    // ---- Pick which digit is on and which nibble it shows ----
    wire [7:0] comp = ~sw;     // complement of the input byte
    reg  [3:0] hex;            // nibble sent to the decoder
    reg        blank;          // 1 = this digit shows nothing

    always @(*) begin
        an    = 8'b11111111;   // all digits off by default
        hex   = 4'h0;
        blank = 1'b1;
        case (digit)
            3'd7: begin an = 8'b01111111; hex = sw[7:4];   blank = 0; end
            3'd6: begin an = 8'b10111111; hex = sw[3:0];   blank = 0; end
            3'd1: begin an = 8'b11111101; hex = comp[7:4]; blank = 0; end
            3'd0: begin an = 8'b11111110; hex = comp[3:0]; blank = 0; end
            default: ;         // digits 5..2 stay blank
        endcase
    end

    // ---- Hex to seven-segment decoder, active low ----
    // seg[0] = a (top), seg[1] = b, ... seg[6] = g (middle)
    reg [6:0] seg_raw;

    always @(*) begin
        case (hex)                //  gfedcba
            4'h0: seg_raw = 7'b1000000;
            4'h1: seg_raw = 7'b1111001;
            4'h2: seg_raw = 7'b0100100;
            4'h3: seg_raw = 7'b0110000;
            4'h4: seg_raw = 7'b0011001;
            4'h5: seg_raw = 7'b0010010;
            4'h6: seg_raw = 7'b0000010;
            4'h7: seg_raw = 7'b1111000;
            4'h8: seg_raw = 7'b0000000;
            4'h9: seg_raw = 7'b0011000;
            4'hA: seg_raw = 7'b0001000;
            4'hB: seg_raw = 7'b0000011;
            4'hC: seg_raw = 7'b1000110;
            4'hD: seg_raw = 7'b0100001;
            4'hE: seg_raw = 7'b0000110;
            4'hF: seg_raw = 7'b0001110;
            default: seg_raw = 7'b1111111;
        endcase
    end

    assign seg = blank ? 7'b1111111 : seg_raw;
    assign dp  = 1'b1;         // decimal point off

endmodule
