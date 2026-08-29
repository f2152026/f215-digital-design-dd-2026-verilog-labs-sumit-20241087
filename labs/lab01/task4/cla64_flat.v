// cla64_flat.v
// 64-bit flat, unblocked carry-lookahead adder.
// Every carry is computed directly from p/g and cin.
// No carry depends on a previous carry.

module cla64_flat(
  input  [63:0] a,
  input  [63:0] b,
  input         cin,
  output [63:0] sum,
  output        cout
);

  wire [63:0] p, g;

  // c[1] through c[64]
  wire [64:1] c;

  // Each carry has up to 65 direct product terms:
  //
  // c[k] =
  //   g[k-1]
  //   | p[k-1]g[k-2]
  //   | p[k-1]p[k-2]g[k-3]
  //   | ...
  //   | p[k-1]...p[0]cin
  //
  // terms[k][0]     = g[k-1]
  // terms[k][j]     = p[k-1]...p[j] g[j-1]
  // terms[k][k]     = p[k-1]...p[0] cin
  wire [64:0] terms [1:64];

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
  // ------------------------------------------------------------

  genvar k, j;

  generate

    // Generate all 64 carries.
    for (k = 1; k <= 64; k = k + 1) begin : gen_carries

      // g[k-1]
      assign #(2) terms[k][0] = g[k-1];

      // p[k-1]...p[j] g[j-1]
      for (j = 1; j < 64; j = j + 1) begin : gen_g_terms

        if (j < k) begin : active_g_term
          assign #(2) terms[k][j] =
              (&p[k-1:j]) & g[j-1];
        end
        else begin : inactive_g_term
          assign #(2) terms[k][j] = 1'b0;
        end

      end

      // p[k-1]...p[0] cin
      assign #(2) terms[k][k] =
          (&p[k-1:0]) & cin;

      // Unused terms are zero.
      for (j = 1; j < 64; j = j + 1) begin : gen_unused
        if (j > k) begin : zero_unused
          assign #(2) terms[k][j] = 1'b0;
        end
      end

      // OR all direct terms to produce c[k].
      assign #(2) c[k] = |terms[k];

    end

  endgenerate

  // ------------------------------------------------------------
  // Step 3: sum
  // c[1] corresponds to bit 1 carry,
  // so bit 0 uses cin.
  // ------------------------------------------------------------

  assign #(2) sum = p ^ {c[63:1], cin};

  assign #(2) cout = c[64];

endmodule
