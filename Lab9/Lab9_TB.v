`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Lab 9 testbench - tests all 256 A/B combinations. Same file for both boards.
// width2 is overridden to 2 so the display scans quickly. In Vivado: run all
// and read PASS/FAIL in the Tcl console.
//////////////////////////////////////////////////////////////////////////////////
module Lab9_TB;

reg  CLK = 0;
reg  [7:0] SW = 0;
wire [15:0] LED;
wire [7:0] SSEG_CA, SSEG_AN;

Comparator #(.width1(4), .width2(2)) uut (.CLK(CLK), .SW(SW), .LED(LED),
                                          .SSEG_CA(SSEG_CA), .SSEG_AN(SSEG_AN));

always #5 CLK = ~CLK;

reg [7:0] seg [0:18];
integer a, b, k, errors = 0;
reg gt, eq, lt;
reg [7:0] d0, d1, d7;

initial begin
    seg[0]=8'hC0; seg[1]=8'hF9; seg[2]=8'hA4; seg[3]=8'hB0; seg[4]=8'h99; seg[5]=8'h92;
    seg[6]=8'h82; seg[7]=8'hF8; seg[8]=8'h80; seg[9]=8'h90; seg[10]=8'h88; seg[11]=8'h83;
    seg[12]=8'hC6; seg[13]=8'hA1; seg[14]=8'h86; seg[15]=8'h8E;
    seg[16]=8'hC2; seg[17]=8'hC7;           // G, L

    $display("---- Lab 9 testbench ----");
    for (a = 0; a < 16; a = a + 1)
        for (b = 0; b < 16; b = b + 1) begin
            SW = {a[3:0], b[3:0]};
            #1;                                  // comparator is combinational
            gt = a > b; eq = a == b; lt = a < b;
            if (LED !== {gt, eq, lt, 5'b0, SW}) begin
                errors = errors + 1;
                $display("LED ERROR A=%h B=%h LED=%b", a[3:0], b[3:0], LED);
            end
            // watch one full display scan (8 digits) after the next refresh
            d0 = 8'hxx; d1 = 8'hxx; d7 = 8'hxx;
            repeat (2) @(posedge uut.Clk_Multi);
            for (k = 0; k < 8; k = k + 1) begin
                @(posedge uut.Clk_Multi); #1;
                case (SSEG_AN)
                    8'b11111110: d0 = SSEG_CA;
                    8'b11111101: d1 = SSEG_CA;
                    8'b01111111: d7 = SSEG_CA;
                    8'b11111111: if (SSEG_CA !== 8'hFF) begin errors = errors + 1;
                                    $display("BLANK ERROR A=%h B=%h", a[3:0], b[3:0]); end
                    default: begin errors = errors + 1;
                                   $display("ANODE ERROR %b", SSEG_AN); end
                endcase
            end
            if (d0 !== seg[b] || d1 !== seg[a] || d7 !== (gt ? seg[16] : lt ? seg[17] : seg[14])) begin
                errors = errors + 1;
                $display("DISPLAY ERROR A=%h B=%h", a[3:0], b[3:0]);
            end
            if (b == a || (a == 9 && b == 10) || (a == 10 && b == 9))
                $display("A=%h B=%h  GT EQ LT = %b%b%b  left digit = %s", a[3:0], b[3:0],
                         LED[15], LED[14], LED[13], gt ? "G" : lt ? "L" : "E");
        end

    if (errors == 0) $display("PASS: all 256 combinations correct");
    else             $display("FAIL: %0d errors", errors);
    $finish;
end

endmodule
