`include "../defines.v"

module ctrl(
    input wire clk,
    input wire rst,

    input wire stallreq_from_id,
    input wire stallreq_from_ex,
    input wire stallreq_from_mem,
    input wire stallreq_from_control,

    input wire stall_for_virtual, //从MMU_TLB传来的控制信号，此时暂停流水线且下条指令不发生变化
    input wire stall_for_virtual_mem,

    output reg[`RegBus] new_pc, // 异常处理入口地址
    output reg flush,   // 是否清除流水线
    output reg[5:0] stall, // 暂停流水线控制信号

    input wire[31:0]    excepttype_i, // 来自MEM模块
    input wire[`RegBus] mtvec_i,   // 来自csr_reg的异常地址处理模块，同时清空流水线
    input wire[`RegBus] mepc_i     // 来自csr_reg的异常指令地址，eret时使用

);

always @ (*) begin

    if(rst == `RstEnable) begin
        stall <= 6'b000000;
        flush <= 1'b0;
        new_pc <= `ZeroWord;
    end else if(excepttype_i != `ZeroWord) begin    // 不为0，表示发生异常
        flush <= 1'b1;
        case(excepttype_i) 
            32'h00000004: begin // ecall
                new_pc <= mtvec_i;
            end
            32'h00000008: begin // mret
                new_pc <= mepc_i;
            end
            32'h0000000c: begin // ebreak
                new_pc <= mtvec_i;
            end
            32'h00000014: begin // 异常
                new_pc <= mtvec_i;
            end
        endcase
    end else if(stall_for_virtual == `Stop) begin // 此时标志着虚拟地址暂停流水线
        flush <= 1'b0;
        stall <= 6'b000011;
    end else if(stall_for_virtual_mem == `Stop) begin
        flush <= 1'b0;
        stall <= 6'b011111;
    end
    else if(stallreq_from_ex == `Stop) begin
        stall <= 6'b001111;
        flush <= 1'b0;
    end else if(stallreq_from_id == `Stop) begin
        stall <= 6'b000111;
        flush <= 1'b0;
    end else if(stallreq_from_mem == `Stop) begin
        stall <= 6'b000111;
        flush <= 1'b0;
    end else if(stallreq_from_control == `Stop) begin
        stall <= 6'b000011;
        flush <= 1'b0;
    end else begin
        stall <= 6'b000000; 
        flush <= 1'b0;
    end

end

endmodule