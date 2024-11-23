`include "primitives.v"

module alu(a, b, control, res);
  input [3:0] a, b; // Операнды
  input [2:0] control; // Управляющие сигналы для выбора операции

  output [3:0] res; // Результат

  wire [3:0] xor_b, not_b, and_a_b, or_a_b, slt, mux_00, mux_01, mux_10, mux_11;
  wire eq_sign, diff_sign, eq_sign_out, diff_sign_out;

  x4_xor xor1(b, control[0], xor_b);
  
  x4_and_x4 and1(a, b, and_a_b);
  x4_xor xor2(and_a_b, control[0], mux_00);

  x4_or_x4 or1(a, b, or_a_b);
  x4_xor xor3(or_a_b, control[0], mux_01);

  x4_adder adder1(a, xor_b, control[0], mux_10);

  to_0 zero1(mux_11[3]);
  to_0 zero2(mux_11[2]);
  to_0 zero3(mux_11[1]);
  x4_not not1(b, not_b);
  supply1 pwr;
  x4_adder adder2(a, not_b, pwr, slt);
  eq_gate eq1(a[3], b[3], eq_sign);
  xor_gate xor4(a[3], b[3], diff_sign);
  and_gate and2(eq_sign, slt[3], eq_sign_out);
  and_gate and3(diff_sign, a[3], diff_sign_out);
  or_gate or2(eq_sign_out, diff_sign_out, mux_11[0]);

  x4_mux mux1(mux_00, mux_01, mux_10, mux_11, control[2:1], res);

endmodule

module to_0(out);
  output out; // Результат

  supply0 gnd;

  pmos pmos1(out, gnd, gnd);

endmodule

module x4_not(a, out);
  input [3:0] a; // Входные данные

  output [3:0] out; // Результат

  not_gate not1(a[0], out[0]);
  not_gate not2(a[1], out[1]);
  not_gate not3(a[2], out[2]);
  not_gate not4(a[3], out[3]);

endmodule

module x4_xor(a, bit, out);
  input [3:0] a; // Входные данные
  input bit; // Бит для операции XOR

  output [3:0] out; // Результат

  xor_gate xor1(a[0], bit, out[0]);
  xor_gate xor2(a[1], bit, out[1]);
  xor_gate xor3(a[2], bit, out[2]);
  xor_gate xor4(a[3], bit, out[3]);

endmodule

module x4_and(a, bit, out);
  input [3:0] a; // Входные данные
  input bit; // Бит для операции AND

  output [3:0] out; // Результат

  and_gate and1(a[0], bit, out[0]);
  and_gate and2(a[1], bit, out[1]);
  and_gate and3(a[2], bit, out[2]);
  and_gate and4(a[3], bit, out[3]);

endmodule

module x4_and_x4(a, b, out);
  input [3:0] a, b; // Входные данные

  output [3:0] out; // Результат

  and_gate and1(a[0], b[0], out[0]);
  and_gate and2(a[1], b[1], out[1]);
  and_gate and3(a[2], b[2], out[2]);
  and_gate and4(a[3], b[3], out[3]);

endmodule

module x4_or_x4(a, b, out);
  input [3:0] a, b; // Входные данные

  output [3:0] out; // Результат

  or_gate or1(a[0], b[0], out[0]);
  or_gate or2(a[1], b[1], out[1]);
  or_gate or3(a[2], b[2], out[2]);
  or_gate or4(a[3], b[3], out[3]);

endmodule

module x4_mux(a, b, c, d, control, out);
  input [3:0] a, b, c, d; // Входные данные
  input [1:0] control; // Управляющий сигнал

  output [3:0] out; // Выходные данные

  wire is_00, is_01, is_10, is_11;
  wire [1:0] not_control;
  wire [3:0] out_a, out_b, out_c, out_d, tmp_ab, tmp_dc;

  not_gate not1(control[0], not_control[0]);
  not_gate not2(control[1], not_control[1]);

  and_gate check_00(not_control[0], not_control[1], is_00);
  and_gate check_01(control[0], not_control[1], is_01);
  and_gate check_10(not_control[0], control[1], is_10);
  and_gate check_11(control[0], control[1], is_11);

  x4_and is_a(a, is_00, out_a);
  x4_and is_b(b, is_01, out_b);
  x4_and is_c(c, is_10, out_c);
  x4_and is_d(d, is_11, out_d);

  x4_or_x4 and1(out_a, out_b, tmp_ab);
  x4_or_x4 and2(out_c, out_d, tmp_dc);
  x4_or_x4 and3(tmp_ab, tmp_dc, out);

endmodule

module x4_adder(a, b, c_in, s);
  input [3:0] a, b; // Операнды
  input c_in; // Входной перенос

  output [3:0] s; // Сумма

  wire c1, c2, c3, c_out;

  full_adder fa1(a[0], b[0], c_in, s[0], c1);
  full_adder fa2(a[1], b[1], c1, s[1], c2);
  full_adder fa3(a[2], b[2], c2, s[2], c3);
  full_adder fa4(a[3], b[3], c3, s[3], c_out);
endmodule

module full_adder(a, b, c_in, s, c_out);
  input a, b; // Операнды
  input c_in; // Входной перенос

  output s; // Сумма
  output c_out; // Выходной перенос

  wire xor_a_b, and_a_b, and_s_c_in;

  xor_gate xor1(a, b, xor_a_b);
  xor_gate xor2(xor_a_b, c_in, s);

  and_gate and1(a, b, and_a_b);
  and_gate and2(xor_a_b, c_in, and_s_c_in);

  or_gate or1(and_a_b, and_s_c_in, c_out);

endmodule

module d_latch(clk, d, we, q);
  input clk; // Сигнал синхронизации
  input d; // Бит для записи в ячейку
  input we; // Необходимо ли перезаписать содержимое ячейки

  output reg q; // Сама ячейка
  // Изначально в ячейке хранится 0
  initial begin
    q <= 0;
  end
  // Значение изменяется на переданное на спаде сигнала синхронизации
  always @ (negedge clk) begin
    // Запись происходит при we = 1
    if (we) begin
      q <= d;
    end
  end
endmodule

module register_file(clk, rd_addr, we_addr, we_data, rd_data, we);
  input clk; // Сигнал синхронизации
  input [1:0] rd_addr, we_addr; // Номера регистров для чтения и записи
  input [3:0] we_data; // Данные для записи в регистровый файл
  input we; // Необходимо ли перезаписать содержимое регистра

  output [3:0] rd_data; // Данные, полученные в результате чтения из регистрового файла
  // TODO: implementation
endmodule

module counter(clk, addr, control, immediate, data);
  input clk; // Сигнал синхронизации
  input [1:0] addr; // Номер значения счетчика которое читается или изменяется
  input [3:0] immediate; // Целочисленная константа, на которую увеличивается/уменьшается значение счетчика
  input control; // 0 - операция инкремента, 1 - операция декремента

  output [3:0] data; // Данные из значения под номером addr, подающиеся на выход
  // TODO: implementation
endmodule
