`include "util.v"

module ALU(op, a, b, res, zero);

  input [2:0] op;
  input [31:0] a, b;

  output reg [31:0] res;
  output reg zero;

  always @ (op or a or b) begin
    case(op)
      0 : begin
        assign res = a + b;
        assign zero = 1;
      end
      1 : begin
        assign res = a & b;
        assign zero = 1;
      end
      2 : begin
        assign res = 0;
        assign zero = a == b ? 1 : 0;
      end
      3 : begin
        // $display("bne");
        assign res = 0;
        assign zero = a != b ? 1 : 0;
      end
      4 : begin
        assign res = a - b;
        assign zero = 1;
      end
      5 : begin
        assign res = a | b;
        assign zero = 1;
      end
      6 : begin
        assign res[31:1] = 31'b0000000000000000000000000000000;
        assign res[0] = a < b;
        assign zero = 1;
      end
    endcase
  end

endmodule

module mips_cpu(clk, pc, pc_new, instruction_memory_a, instruction_memory_rd, data_memory_a, data_memory_rd, data_memory_we, data_memory_wd,
                register_a1, register_a2, register_a3, register_we3, register_wd3, register_rd1, register_rd2);
  // сигнал синхронизации
  input clk;
  // текущее значение регистра PC
  inout [31:0] pc;
  // новое значение регистра PC (адрес следующей команды)
  output [31:0] pc_new;
  // we для памяти данных
  output data_memory_we;
  // адреса памяти и данные для записи памяти данных
  output [31:0] instruction_memory_a, data_memory_a, data_memory_wd;
  // данные, полученные в результате чтения из памяти
  inout [31:0] instruction_memory_rd, data_memory_rd;
  // we3 для регистрового файла
  output register_we3;
  // номера регистров
  output [4:0] register_a1, register_a2, register_a3;
  // данные для записи в регистровый файл
  output [31:0] register_wd3;
  // данные, полученные в результате чтения из регистрового файла
  inout [31:0] register_rd1, register_rd2;

  wire [15:0] imm;
  wire [25:0] addr;
  wire [31:0] ext_imm, ext_imm4, srcB, aluResult, pc1, pc2, pc3, pc_tmp, pc_tmp2, register_wd_tmp;

  wire [4:0] write_reg_1, write_reg_2, register_a_tmp;

  wire PCsrc, zero;

  // control unit inputs
  wire [5:0] op, funct;

  // control unit outs
  reg branch, regDst, aluSrc, regWrite, memWrite, memToReg, jType, isJr, isJal;
  reg [2:0] aluControl;

  initial begin
    assign branch = 0;
    assign regDst = 0;
    assign aluSrc = 0;
    assign regWrite = 0;
    assign memWrite = 0;
    assign memToReg = 0;
    assign aluControl = 0;
    assign jType = 0;
    assign isJr = 0;
    assign isJal = 0;
  end

  // parse instruction
  assign instruction_memory_a = pc;
  assign op = instruction_memory_rd[31:26];
  assign addr = instruction_memory_rd[25:0];
  assign register_a1 = instruction_memory_rd[25:21];
  assign register_a2 = instruction_memory_rd[20:16];
  assign write_reg_1 = instruction_memory_rd[20:16];
  assign write_reg_2 = instruction_memory_rd[15:11];
  assign imm = instruction_memory_rd[15:0];
  assign funct = instruction_memory_rd[5:0];


  sign_extend extender(imm, ext_imm);
  assign PCsrc = branch && zero;
  shl_2 shl(ext_imm, ext_imm4);
  assign pc1 = pc + 4;
  assign pc2 = pc1 + ext_imm4;
  assign pc3 = {pc1[31:28], addr, 2'b00};
  mux2_32 pc_mux(pc + 4, pc + 4 + ext_imm4, PCsrc, pc_tmp);
  mux2_32 pc2_mux(pc_tmp, pc3, jType, pc_tmp2);
  mux2_32 pc3_mux(pc_tmp2, register_rd1, isJr, pc_new);
  mux2_5 write_reg_mux(write_reg_1, write_reg_2, regDst, register_a_tmp);
  mux2_5 write_reg2_mux(register_a_tmp, 5'b11111, isJal, register_a3);

  mux2_32 alu_mux(register_rd2, ext_imm, aluSrc, srcB);
  ALU alu(aluControl, register_rd1, srcB, aluResult, zero);
  assign data_memory_a = aluResult;

  assign register_we3 = regWrite;
  mux2_32 write_mux(aluResult, data_memory_rd, memToReg, register_wd_tmp);
  mux2_32 write2_mux(register_wd_tmp, pc1, isJal, register_wd3);

  assign data_memory_we = memWrite;
  assign data_memory_wd = register_rd2;

  // control unit
  always @ (op or funct) begin
    case(op)
      // r-commands
      6'b000000 : begin 
        case(funct)
          // add
          6'b100000 : begin
            assign branch = 0;
            assign regDst = 1;
            assign aluSrc = 0;
            assign regWrite = 1;
            assign memWrite = 0;
            assign memToReg = 0;
            assign aluControl = 0;
            assign jType = 0;
            assign isJr = 0;
            assign isJal = 0;
          end
          // sub
          6'b100010 : begin
            assign branch = 0;
            assign regDst = 1;
            assign aluSrc = 0;
            assign regWrite = 1;
            assign memWrite = 0;
            assign memToReg = 0;
            assign aluControl = 4;
            assign jType = 0;
            assign isJr = 0;
            assign isJal = 0;
          end
          // and
          6'b100100 : begin
            assign branch = 0;
            assign regDst = 1;
            assign aluSrc = 0;
            assign regWrite = 1;
            assign memWrite = 0;
            assign memToReg = 0;
            assign aluControl = 1;
            assign jType = 0;
            assign isJr = 0;
            assign isJal = 0;
          end
          // or
          6'b100101 :  begin
            assign branch = 0;
            assign regDst = 1;
            assign aluSrc = 0;
            assign regWrite = 1;
            assign memWrite = 0;
            assign memToReg = 0;
            assign aluControl = 5;
            assign jType = 0;
            assign isJr = 0;
            assign isJal = 0;
          end
          // slt
          6'b101010 : begin
            assign branch = 0;
            assign regDst = 1;
            assign aluSrc = 0;
            assign regWrite = 1;
            assign memWrite = 0;
            assign memToReg = 0;
            assign aluControl = 6;
            assign jType = 0;
            assign isJr = 0;
            assign isJal = 0;
          end
          // jr
          6'b001000 : begin
            assign branch = 0;
            assign regDst = 0;
            assign aluSrc = 0;
            assign regWrite = 0;
            assign memWrite = 0;
            assign memToReg = 0;
            assign aluControl = 0;
            assign jType = 0;
            assign isJr = 1;
            assign isJal = 0;
          end
        endcase
      end
      // lw
      6'b100011 : begin
        assign branch = 0;
        assign regDst = 0;
        assign aluSrc = 1;
        assign regWrite = 1;
        assign memWrite = 0;
        assign memToReg = 1;
        assign aluControl = 0;
        assign jType = 0;
        assign isJr = 0;
        assign isJal = 0;      
      end
      // sw
      6'b101011 : begin
        assign branch = 0;
        assign regDst = 0;
        assign aluSrc = 1;
        assign regWrite = 0;
        assign memWrite = 1;
        assign memToReg = 0;
        assign aluControl = 0;
        assign jType = 0;
        assign isJr = 0;
        assign isJal = 0;    
      end
      // beq
      6'b000100 : begin
        assign branch = 1;
        assign regDst = 0;
        assign aluSrc = 0;
        assign regWrite = 0;
        assign memWrite = 0;
        assign memToReg = 0;
        assign aluControl = 2;
        assign jType = 0;
        assign isJr = 0;  
        assign isJal = 0;    
      end
      // addi
      6'b001000 : begin
        assign branch = 0;
        assign regDst = 0;
        assign aluSrc = 1;
        assign regWrite = 1;
        assign memWrite = 0;
        assign memToReg = 0;
        assign aluControl = 0;
        assign jType = 0;
        assign isJr = 0;   
        assign isJal = 0;  
      end
      // andi
      6'b001100 : begin
        assign branch = 0;
        assign regDst = 0;
        assign aluSrc = 1;
        assign regWrite = 1;
        assign memWrite = 0;
        assign memToReg = 0;
        assign aluControl = 1;
        assign jType = 0;
        assign isJr = 0;    
        assign isJal = 0;  
      end
      // bne
      6'b000101 : begin
        assign branch = 1;
        assign regDst = 0;
        assign aluSrc = 0;
        assign regWrite = 0;
        assign memWrite = 0;
        assign memToReg = 0;
        assign aluControl = 3;
        assign jType = 0;
        assign isJr = 0;     
        assign isJal = 0; 
      end
      // j
      6'b000010 : begin
        assign branch = 0;
        assign regDst = 0;
        assign aluSrc = 0;
        assign regWrite = 0;
        assign memWrite = 0;
        assign memToReg = 0;
        assign aluControl = 0;
        assign jType = 1;
        assign isJr = 0;    
        assign isJal = 0;  
      end
      // jal
      6'b000011 : begin
        assign branch = 0;
        assign regDst = 0;
        assign aluSrc = 0;
        assign regWrite = 1;
        assign memWrite = 0;
        assign memToReg = 0;
        assign aluControl = 0;
        assign jType = 1;
        assign isJr = 0;     
        assign isJal = 1; 
      end
    endcase
    #1
    $display("instruction: %b", instruction_memory_rd);
    $display("PCsrc: %b", PCsrc);
    $display("AluControl: %d", aluControl);
    $display("pc: %d pc_new %d", pc, pc_new);
    $display("AluResult: %d", aluResult);
  end

endmodule
