`timescale 1ns / 1ps
// Lab 6 Testbench - Nexys 4 (rev B) version (tests Lab6_RevB.v)
// width2 is overridden to 10 so a full 8-digit scan takes ~1.8 us instead of ~1.6 ms.
// Run in Vivado with: run 50 us  (or set simulation runtime to 50us)
// Results print in the Tcl console; waveforms also available.

module Lab6_RevB_TB;

reg clk = 0;
reg [7:0] sw = 0;
wire [6:0] seg;
wire dp;
wire [7:0] an;

integer errors = 0;
integer checks = 0;

// Named port connections; width2 = 10 only for simulation speed
nf #(.width2(10)) uut (
    .clk(clk),
    .sw(sw),
    .seg(seg),
    .dp(dp),
    .an(an)
);

always #5 clk = ~clk;   // 100 MHz clock (10 ns period)

// Convert the active-low segment pattern back into a hex digit
function [4:0] seg2hex;          // returns 5'h1F if the pattern is not a valid digit
    input [6:0] s;
    case (~s)
        7'b0111111: seg2hex = 5'h0;
        7'b0000110: seg2hex = 5'h1;
        7'b1011011: seg2hex = 5'h2;
        7'b1001111: seg2hex = 5'h3;
        7'b1100110: seg2hex = 5'h4;
        7'b1101101: seg2hex = 5'h5;
        7'b1111101: seg2hex = 5'h6;
        7'b0000111: seg2hex = 5'h7;
        7'b1111111: seg2hex = 5'h8;
        7'b1100111: seg2hex = 5'h9;
        7'b1110111: seg2hex = 5'hA;
        7'b1111100: seg2hex = 5'hB;
        7'b0111001: seg2hex = 5'hC;
        7'b1011110: seg2hex = 5'hD;
        7'b1111001: seg2hex = 5'hE;
        7'b1110001: seg2hex = 5'hF;
        default:    seg2hex = 5'h1F;
    endcase
endfunction

// Check one digit: expected value vs what the segments show
task check_digit;
    input [7:0] an_expected;
    input [3:0] value;
    begin
        checks = checks + 1;
        if (an !== an_expected || seg2hex(seg) !== {1'b0,value} || dp !== 1'b1) begin
            errors = errors + 1;
            $display("  FAIL t=%0t sw=%b an=%b shows %h (expected an=%b digit %h), dp=%b",
                     $time, sw, an, seg2hex(seg), an_expected, value, dp);
        end
    end
endtask

// Sample each of the 8 digit slots (middle of each slot) for one full scan
task check_scan;
    input [7:0] val;
    integer k;
    begin
        for (k = 0; k < 8; k = k + 1) begin
            @(negedge uut.Clk_Multi);
            case (an)
                8'b01111111: check_digit(8'b01111111, val[7:4]);    // leftmost: SW high nibble
                8'b10111111: check_digit(8'b10111111, val[3:0]);    // SW low nibble
                8'b11111101: check_digit(8'b11111101, ~val[7:4]);   // complement high nibble
                8'b11111110: check_digit(8'b11111110, ~val[3:0]);   // rightmost: complement low nibble
                8'b11111111: ;                                      // blank digits (an[5:2])
                default: begin
                    errors = errors + 1;
                    $display("  FAIL t=%0t unexpected an pattern %b", $time, an);
                end
            endcase
        end
    end
endtask

// Apply a switch value, let it settle for one scan, then verify the next two scans
task test_value;
    input [7:0] val;
    begin
        sw = val;
        repeat (8) @(negedge uut.Clk_Multi);   // settle (flush old digits)
        check_scan(val);
        check_scan(val);
        $display("sw = %b -> display %h%h ____ ____ %h%h",
                 val, val[7:4], val[3:0], ~val[7:4], ~val[3:0]);
    end
endtask

initial begin
    $display("---- Lab 6 rev B testbench ----");
    wait (an !== 8'bx);            // wait for the first scan step
    test_value(8'b1111_1010);      // lab example: FA / 05
    test_value(8'b0000_0000);      // 00 / FF
    test_value(8'b1111_1111);      // FF / 00
    test_value(8'b0011_1100);      // 3C / C3
    test_value(8'b1010_0101);      // A5 / 5A
    test_value(8'b0001_0010);      // 12 / ED
    $display("---- %0d checks, %0d errors ----", checks, errors);
    if (errors == 0) $display("PASS");
    else             $display("FAIL");
    $finish;
end

endmodule
