`include "../defines.v"

module csr_reg(
    input wire clk,
    input wire rst,

    input wire we_i,    //是否要写
    input wire[11:0]               waddr_i,  //要写的寄存器地址
	input wire[11:0]               raddr_i, //要读取的寄存器地址
	input wire[`RegBus]           data_i,  //要写入的数据

    input wire except_we_i,
    input wire[`RegBus] except_mcause_data_i,
    input wire[`RegBus] except_mepc_data_i,

    input wire[31:0]              excepttype_i,
	input wire[5:0]               int_i,
	input wire[`RegBus]           current_inst_addr_i,

    output reg[`RegBus] data_o, //读出的某个寄存器的值
    output reg[`RegBus] mstatus_o, // 异常原因
    output reg[`RegBus] mtvec_o, // 异常返回地址
    output reg[`RegBus] mscratch_o, // 状态
    output reg[`RegBus] mepc_o,
    output reg[`RegBus] mcause_o,
    output reg[`RegBus] satp_o,
    output reg[1:0]     mode    // 权限状态
);

    // write csr
    always @ (posedge clk) begin
        if(rst == `RstEnable) begin     //status，cause初值？？？？？？？？？？
            //init
            mstatus_o <= `ZeroWord;
            mtvec_o <= `ZeroWord;
            mscratch_o <= `ZeroWord;
            mepc_o <= `ZeroWord;
            mcause_o <= `ZeroWord;
            satp_o <= `ZeroWord;
            mode <= `MACHINE_MODE;
        end
        else begin
            if(we_i == `WriteEnable) begin
                case (waddr_i)
                    `CSR_REG_MSTATUS: begin     //status写？？？？？？？
                        mstatus_o[12:11] <= data_i[12:11];  
                    end  
                    `CSR_REG_MTVEC: begin
                        mtvec_o <= data_i;  
                    end
                    `CSR_REG_MSCRATCH: begin
                        mscratch_o <= data_i;  
                    end
                    `CSR_REG_MEPC: begin
                        mepc_o <= data_i;  
                    end
                    `CSR_REG_MCAUSE: begin
                        mcause_o <= data_i;
                    end
                    `CSR_REG_SATP: begin
                        satp_o <= data_i;
                    end
                endcase
            end
            if(excepttype_i != `ZeroWord) begin
                case (excepttype_i)
                    // mret
                    32'h00000008: begin
                        mode <= mstatus_o[12:11];
                    end
                    32'h00000004: begin
                        if(except_we_i == `WriteEnable) begin // 此时在ebreak，ecall，地址异常情况下才会写入
                             mcause_o <= except_mcause_data_i;
                             mepc_o <= except_mepc_data_i;
                        end
                        mode <= `MACHINE_MODE;
                    end
                    32'h0000000c: begin
                        mode <= `MACHINE_MODE;
                        if(except_we_i == `WriteEnable) begin // 此时在ebreak，ecall，地址异常情况下才会写入
                             mcause_o <= except_mcause_data_i;
                             mepc_o <= except_mepc_data_i;
                        end
                    end
                    32'h00000014: begin
                        mode <= `MACHINE_MODE;
                        if(except_we_i == `WriteEnable) begin // 此时在ebreak，ecall，地址异常情况下才会写入
                             mcause_o <= except_mcause_data_i;
                             mepc_o <= except_mepc_data_i;
                        end
                    end
                endcase
            end
        end
    end

    // read csr
    always @ (*) begin
        if(rst == `RstEnable) begin
            data_o <= `ZeroWord;
        end
        else begin
            data_o <= `ZeroWord;
            case (raddr_i)
                `CSR_REG_MSTATUS: begin
                    data_o <= mstatus_o;
                end
                `CSR_REG_MTVEC: begin
                    data_o <= mtvec_o;  
                end
                `CSR_REG_MSCRATCH: begin
                    data_o <= mscratch_o;  
                end
                `CSR_REG_MEPC: begin
                    data_o <= mepc_o;  
                end
                `CSR_REG_MCAUSE: begin
                    data_o <= mcause_o;  
                end
                `CSR_REG_SATP: begin
                    data_o <= satp_o;
                end
                default: begin
                end
            endcase
        end
    end

endmodule
