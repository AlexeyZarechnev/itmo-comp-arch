// 20 transistors
module ternary_min(a, b, out);
  input [1:0] a;
  input [1:0] b;
  output [1:0] out;

  wire a_00, b_00, res;

  and_gate msb_and(a[1], b[1], out[1]);
  
  nor_gate a_00_nor(a[0], a[1], a_00);
  nor_gate b_00_nor(b[0], b[1], b_00);
  nor_gate lsb_nor(a_00, b_00, res);

  xor_gate lsb(out[1], res, out[0]);

endmodule

// 20 transistors
module ternary_max(a, b, out);
  input [1:0] a;
  input [1:0] b;
  output [1:0] out;

  wire a_00, b_00, res;

  or_gate msb_or(a[1], b[1], out[1]);
  
  nor_gate a_00_nor(a[0], a[1], a_00);
  nor_gate b_00_nor(b[0], b[1], b_00);
  nand_gate lsb_nand(a_00, b_00, res);

  xor_gate lsb(out[1], res, out[0]);
endmodule


// 30 transistors
module ternary_any(a, b, out);
  input [1:0] a;
  input [1:0] b;
  output [1:0] out;

  wire diff_msb, eq_lsb, tmp_00_10, not_tmp_00_10;
  wire [1:0] tmp_out;

  and_gate lsb_and(a[0], b[0], tmp_out[0]);
  or_gate msb_or(a[1], b[1], tmp_out[1]);

  xor_gate msb_xor(a[1], b[1], diff_msb);
  eq_gate lsb_eq(a[0], b[0], eq_lsb);
  and_gate check_00_10(diff_msb, eq_lsb, tmp_00_10); 

  or_gate lsb(tmp_out[0], tmp_00_10, out[0]);
  not_gate not_00_10(tmp_00_10, not_tmp_00_10); 
  and_gate msb(tmp_out[1], not_tmp_00_10, out[1]); 

endmodule


// 24 transistors
module ternary_consensus(a, b, out);
  input [1:0] a;
  input [1:0] b;
  output [1:0] out;

  wire diff_msb, eq_lsb, tmp_lsb, tmp_lsb2;
  
  or_gate lsb_or(a[0], b[0], tmp_lsb);
  and_gate msb(a[1], b[1], out[1]);

  xor_gate msb_xor(a[1], b[1], diff_msb);
  eq_gate lsb_eq(a[0], b[0], eq_lsb);
  and_gate check_00_10(diff_msb, eq_lsb, tmp_lsb2);

  or_gate lsb(tmp_lsb, tmp_lsb2, out[0]);

endmodule

// Primitives

// 4 transistors
module nand_gate(a, b, out);
  input wire a, b;
  output out;

  supply1 pwr;
  supply0 gnd;

  wire nmos1_out;

  pmos pmos1(out, pwr, a);
  pmos pmos2(out, pwr, b);

  nmos nmos1(nmos1_out, gnd, b);
  nmos nmos2(out, nmos1_out, a);
endmodule

// 4 transistors
module and_gate(a, b, out);
  input wire a, b;
  output out;

  supply1 pwr;
  supply0 gnd;

  wire nmos1_out;

  pmos pmos1(out, gnd, a);
  pmos pmos2(out, gnd, b);

  nmos nmos1(nmos1_out, pwr, a);
  nmos nmos2(out, nmos1_out, b);

endmodule

// 4 transistors
module nor_gate(a, b, out);
  input wire a, b;
  output out;

  supply1 pwr;
  supply0 gnd;

  wire pmos1_out;

  nmos nmos1(out, gnd, a);
  nmos nmos2(out, gnd, b);

  pmos pmos1(pmos1_out, pwr, a);
  pmos pmos2(out, pmos1_out, b);
endmodule

// 4 transistors
module or_gate(a, b, out);
  input wire a, b;
  output out;

  supply1 pwr;
  supply0 gnd;

  wire pmos1_out;

  nmos nmos1(out, pwr, a);
  nmos nmos2(out, pwr, b);

  pmos pmos1(pmos1_out, gnd, b);
  pmos pmos2(out, pmos1_out, a);
  
endmodule

// 2 transistors
module not_gate(a, out);
  input wire a;
  output out;

  supply1 pwr;
  supply0 gnd;

  pmos pmos1(out, pwr, a);
  nmos nmos1(out, gnd, a);
endmodule

// 4 transistors
module xor_gate(a, b, out);
  input wire a, b;
  output out;

  supply1 pwr;
  supply0 gnd;

  wire b_res;

  pmos b_pmos(b_res, pwr, b);
  nmos b_nmos(b_res, gnd, b);

  pmos a_pmos(out, b, a);
  nmos a_nmos(out, b_res, a);
endmodule

// 4 transistors
module eq_gate(a, b, out);
  input wire a, b;
  output out;

  supply1 pwr;
  supply0 gnd;

  wire b_res;

  pmos b_pmos(b_res, pwr, b);
  nmos b_nmos(b_res, gnd, b);

  pmos a_pmos(out, b_res, a);
  nmos a_nmos(out, b, a);
endmodule