# Digital Systems Design Labs

Verilog lab code for a digital systems design course. Board: Digilent Nexys 4 (rev B, part `xc7a100tcsg324-1`), built in Vivado.

| Lab | Topic | Files | Status |
|-----|-------|-------|--------|
| [Lab6](Lab6) | Complement and hex display (8-digit multiplexed 7-seg) | design + testbench + xdc | Passes testbench |
| [Lab7](Lab7) | State machine chart, ROM version and logic-equation version | two designs + xdc | Simulated against the state table |
| [Lab8](Lab8) | Non-sequential 4-bit counter (C, A, 4, 5, 7, 3, F, 6, 9) | design + testbench + xdc | Passes testbench |
| [Lab9](Lab9) | 4-bit comparator built from 1-bit cells | design + testbench + xdc | Passes testbench |

Lab7 has two separate implementations of the same state machine (`Lab7_ROM_RevB.v` and `Lab7_SM_RevB.v`). Use one per project, since both define module `SM`.

## Build notes
- New RTL project for part `xc7a100tcsg324-1`. Add the lab's design `.v` as a design source and the `.xdc` as a constraint.
- Testbench (`*_TB.v`): add as a simulation source, run behavioral simulation (`run all`), and check PASS/FAIL in the Tcl console.
- Then synthesis, implementation, generate bitstream, and program the board.
