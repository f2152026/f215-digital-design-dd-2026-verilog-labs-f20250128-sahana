// cla64_hier.v
// BONUS -- open-ended. No detailed scaffold is provided; this is meant to
// be a genuine design exercise. Not required for lab submission.
//
// You will likely need to modify cla4.v (or add signals alongside it) so
// that block-generate/block-propagate summaries of its own Gi, Pi signals
// are exposed as outputs, since the second-level lookahead unit below
// needs them. As with every module in this lab from Task 2 onward, every
// gate/assign you add should carry an explicit delay.
//
// Starting point (from Tutorial 3, Q4(d)):
//   - Reuse 16 four-bit CLA blocks (your cla4.v) -- their internal logic
//     doesn't change.
//   - For each block k, define:
//       Gblk_k = "this block produces a carry regardless of its incoming
//                 carry" -- a Boolean function of that block's own 4
//                 bit-level Gi, Pi signals.
//       Pblk_k = "an incoming carry sails straight through this whole
//                 block" -- likewise a function of its own Gi, Pi.
//   - Build a second-level lookahead unit -- structurally identical to
//     cla4.v, just one level up -- that computes each block's carry-in
//     directly from Gblk_0..Gblk_15, Pblk_0..Pblk_15, and cin, instead of
//     rippling block to block.
//
// To test this, wire it into dut.v as a fourth option (copy the pattern
// used for the other three) and run it through the same tb.v. Compare
// your final delay to cla64_blocked.v from Task 4.

module cla64_hier(
  input  [63:0] a,
  input  [63:0] b,
  input         cin,
  output [63:0] sum,
  output        cout
);

  // TODO: your hierarchical design goes here.

    // Generate/propagate for each 4-bit CLA block
    wire [15:0] Gblk;
    wire [15:0] Pblk;

    // Carry into each 4-bit CLA block
    wire [16:0] c;

    // Generate/propagate for each group of four CLA blocks
    wire [3:0] Ggrp;
    wire [3:0] Pgrp;

    // Carry into each 16-bit group
    wire [4:0] gc;

    assign c[0]  = cin;
    assign gc[0] = cin;


    // ==================================================
    // LEVEL 1
    // 16 individual 4-bit CLA blocks
    // ==================================================

    genvar i;

    generate
        for (i = 0; i < 16; i = i + 1) begin : CLA_BLOCKS

            cla4 CLA (
                .a    (a[4*i +: 4]),
                .b    (b[4*i +: 4]),
                .cin  (c[i]),
                .sum  (sum[4*i +: 4]),
                .cout (),
                .Gblk (Gblk[i]),
                .Pblk (Pblk[i])
            );

        end
    endgenerate


    // ==================================================
    // LEVEL 2
    // Group 0: blocks 0,1,2,3
    // ==================================================

    assign #(2) Pgrp[0] =
          Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0];

    assign #(2) Ggrp[0] =
          Gblk[3]
        | (Pblk[3] & Gblk[2])
        | (Pblk[3] & Pblk[2] & Gblk[1])
        | (Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0]);


    // Group 1: blocks 4,5,6,7

    assign #(2) Pgrp[1] =
          Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4];

    assign #(2) Ggrp[1] =
          Gblk[7]
        | (Pblk[7] & Gblk[6])
        | (Pblk[7] & Pblk[6] & Gblk[5])
        | (Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4]);


    // Group 2: blocks 8,9,10,11

    assign #(2) Pgrp[2] =
          Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8];

    assign #(2) Ggrp[2] =
          Gblk[11]
        | (Pblk[11] & Gblk[10])
        | (Pblk[11] & Pblk[10] & Gblk[9])
        | (Pblk[11] & Pblk[10] & Pblk[9] & Gblk[8]);


    // Group 3: blocks 12,13,14,15

    assign #(2) Pgrp[3] =
          Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12];

    assign #(2) Ggrp[3] =
          Gblk[15]
        | (Pblk[15] & Gblk[14])
        | (Pblk[15] & Pblk[14] & Gblk[13])
        | (Pblk[15] & Pblk[14] & Pblk[13] & Gblk[12]);


    // ==================================================
    // LEVEL 3
    // Lookahead between the four 16-bit groups
    // ==================================================

    assign #(2) gc[1] =
          Ggrp[0]
        | (Pgrp[0] & cin);

    assign #(2) gc[2] =
          Ggrp[1]
        | (Pgrp[1] & Ggrp[0])
        | (Pgrp[1] & Pgrp[0] & cin);

    assign #(2) gc[3] =
          Ggrp[2]
        | (Pgrp[2] & Ggrp[1])
        | (Pgrp[2] & Pgrp[1] & Ggrp[0])
        | (Pgrp[2] & Pgrp[1] & Pgrp[0] & cin);

    assign #(2) gc[4] =
          Ggrp[3]
        | (Pgrp[3] & Ggrp[2])
        | (Pgrp[3] & Pgrp[2] & Ggrp[1])
        | (Pgrp[3] & Pgrp[2] & Pgrp[1] & Ggrp[0])
        | (Pgrp[3] & Pgrp[2] & Pgrp[1] & Pgrp[0] & cin);


    // ==================================================
    // Carries INSIDE group 0
    // Blocks 0 -> 3
    // ==================================================

    assign #(2) c[1] =
          Gblk[0]
        | (Pblk[0] & gc[0]);

    assign #(2) c[2] =
          Gblk[1]
        | (Pblk[1] & Gblk[0])
        | (Pblk[1] & Pblk[0] & gc[0]);

    assign #(2) c[3] =
          Gblk[2]
        | (Pblk[2] & Gblk[1])
        | (Pblk[2] & Pblk[1] & Gblk[0])
        | (Pblk[2] & Pblk[1] & Pblk[0] & gc[0]);

    assign c[4] = gc[1];


    // ==================================================
    // Carries INSIDE group 1
    // Blocks 4 -> 7
    // ==================================================

    assign #(2) c[5] =
          Gblk[4]
        | (Pblk[4] & gc[1]);

    assign #(2) c[6] =
          Gblk[5]
        | (Pblk[5] & Gblk[4])
        | (Pblk[5] & Pblk[4] & gc[1]);

    assign #(2) c[7] =
          Gblk[6]
        | (Pblk[6] & Gblk[5])
        | (Pblk[6] & Pblk[5] & Gblk[4])
        | (Pblk[6] & Pblk[5] & Pblk[4] & gc[1]);

    assign c[8] = gc[2];


    // ==================================================
    // Carries INSIDE group 2
    // Blocks 8 -> 11
    // ==================================================

    assign #(2) c[9] =
          Gblk[8]
        | (Pblk[8] & gc[2]);

    assign #(2) c[10] =
          Gblk[9]
        | (Pblk[9] & Gblk[8])
        | (Pblk[9] & Pblk[8] & gc[2]);

    assign #(2) c[11] =
          Gblk[10]
        | (Pblk[10] & Gblk[9])
        | (Pblk[10] & Pblk[9] & Gblk[8])
        | (Pblk[10] & Pblk[9] & Pblk[8] & gc[2]);

    assign c[12] = gc[3];


    // ==================================================
    // Carries INSIDE group 3
    // Blocks 12 -> 15
    // ==================================================

    assign #(2) c[13] =
          Gblk[12]
        | (Pblk[12] & gc[3]);

    assign #(2) c[14] =
          Gblk[13]
        | (Pblk[13] & Gblk[12])
        | (Pblk[13] & Pblk[12] & gc[3]);

    assign #(2) c[15] =
          Gblk[14]
        | (Pblk[14] & Gblk[13])
        | (Pblk[14] & Pblk[13] & Gblk[12])
        | (Pblk[14] & Pblk[13] & Pblk[12] & gc[3]);

    assign c[16] = gc[4];

    // Final carry
    assign cout = c[16];

endmodule
