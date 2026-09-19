// cla64_flat.v
// 64-bit flat / unblocked carry-lookahead adder.
// Every carry is calculated directly from p, g and cin.
// No carry depends on a previous carry.

module cla64_flat(
  input  [63:0] a,
  input  [63:0] b,
  input         cin,
  output [63:0] sum,
  output        cout
);

  wire [63:0] p;
  wire [63:0] g;

  // c[1] ... c[64]
  wire [64:1] c;

  // Each row contains the direct product terms for one carry.
  // Using [0:63] avoids the problematic carry_terms[64] index.
  wire [64:0] carry_terms [0:63];

  // ------------------------------------------------------------
  // Step 1: propagate and generate
  // ------------------------------------------------------------

  genvar i;

  generate
    for (i = 0; i < 64; i = i + 1) begin : gen_pg
      xor #(2) (p[i], a[i], b[i]);
      and #(2) (g[i], a[i], b[i]);
    end
  endgenerate

  // ------------------------------------------------------------
  // Step 2: direct carry-lookahead equations
  //
  // For carry c[k]:
  //
  // c[k] =
  //     g[k-1]
  //   | p[k-1]g[k-2]
  //   | p[k-1]p[k-2]g[k-3]
  //   | ...
  //   | p[k-1]...p[0]cin
  //
  // No c[k] uses c[k-1].
  // ------------------------------------------------------------

  genvar k;
  genvar j;

  generate
    for (k = 1; k <= 64; k = k + 1) begin : gen_carries

      for (j = 0; j <= 64; j = j + 1) begin : gen_terms

        // First term: g[k-1]
        if (j == 0) begin : first_term

          assign #(2) carry_terms[k-1][j] = g[k-1];

        end

        // Middle terms:
        //
        // j = 1:
        //   p[k-1] & g[k-2]
        //
        // j = 2:
        //   p[k-1] & p[k-2] & g[k-3]
        //
        // etc.
        else if (j < k) begin : generate_term

          assign #(2) carry_terms[k-1][j] =
              (&p[k-1:j]) & g[j-1];

        end

        // Final cin term:
        //
        // p[k-1] & p[k-2] & ... & p[0] & cin
        else if (j == k) begin : cin_term

          assign #(2) carry_terms[k-1][j] =
              (&p[k-1:0]) & cin;

        end

        // Everything beyond the required terms is zero.
        else begin : unused_term

          assign #(2) carry_terms[k-1][j] = 1'b0;

        end

      end

      // OR all direct terms together.
      assign #(2) c[k] = |carry_terms[k-1];

    end
  endgenerate

  // ------------------------------------------------------------
  // Step 3: sum
  // ------------------------------------------------------------

  assign #(2) sum = p ^ {c[63:1], cin};

  // Final carry
  assign #(2) cout = c[64];

endmodule