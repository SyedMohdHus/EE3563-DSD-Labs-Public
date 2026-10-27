`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Lab 8 testbench - runs NS_Counter on the fast clock (FAST = 1)
// Results print in the Tcl console. Same file for both boards.
//////////////////////////////////////////////////////////////////////////////////
module Lab8_TB;

reg  CLK = 0, Start = 0;
wire [3:0] LED;
wire [7:0] SSEG_CA, SSEG_AN;

NS_Counter #(.FAST(1)) uut (.CLK(CLK), .Start(Start), .LED(LED),
                            .SSEG_CA(SSEG_CA), .SSEG_AN(SSEG_AN));

always #5 CLK = ~CLK;        // 100 MHz, 10 ns period

reg [3:0] seq [0:8];
reg [7:0] seg [0:15];
integer i, errors = 0;

task check(input [3:0] expect);
    begin
        if (LED !== expect || SSEG_CA !== seg[expect] || SSEG_AN !== 8'hFE) begin
            errors = errors + 1;
            $display("ERROR t=%0t: LED=%h (expected %h) SSEG_CA=%b", $time, LED, expect, SSEG_CA);
        end
        else
            $display("t=%0t  Start=%b  count=%h  SSEG_CA=%b", $time, Start, LED, SSEG_CA);
    end
endtask

initial begin
    seq[0]=4'hC; seq[1]=4'hA; seq[2]=4'h4; seq[3]=4'h5; seq[4]=4'h7;
    seq[5]=4'h3; seq[6]=4'hF; seq[7]=4'h6; seq[8]=4'h9;
    seg[0]=8'hC0; seg[1]=8'hF9; seg[2]=8'hA4; seg[3]=8'hB0; seg[4]=8'h99; seg[5]=8'h92;
    seg[6]=8'h82; seg[7]=8'hF8; seg[8]=8'h80; seg[9]=8'h90; seg[10]=8'h88; seg[11]=8'h83;
    seg[12]=8'hC6; seg[13]=8'hA1; seg[14]=8'h86; seg[15]=8'h8E;

    // 1. Power-up with Start = 0: stays on C
    $display("-- Start = 0: should hold on C");
    #2 check(4'hC);
    repeat (3) begin @(posedge CLK); #1 check(4'hC); end

    // 2. Start = 1: two full cycles of the sequence
    $display("-- Start = 1: two full counts");
    Start = 1;
    for (i = 1; i <= 18; i = i + 1) begin @(posedge CLK); #1 check(seq[i % 9]); end

    // 3. Turn Start off in the middle (on 7): must finish the count, then hold on C
    $display("-- Start = 0 mid-count: should finish and hold on C");
    for (i = 1; i <= 4; i = i + 1) begin @(posedge CLK); #1 check(seq[i]); end
    Start = 0;
    for (i = 5; i <= 9; i = i + 1) begin @(posedge CLK); #1 check(seq[i % 9]); end
    repeat (3) begin @(posedge CLK); #1 check(4'hC); end

    if (errors == 0) $display("PASS: all checks correct");
    else             $display("FAIL: %0d errors", errors);
    $finish;
end

endmodule
