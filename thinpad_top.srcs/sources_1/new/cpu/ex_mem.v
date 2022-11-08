`include "../defines.v"

module ex_mem(

	input wire clk,
	input wire rst,
	
    input wire[5:0] stall,
	
	//来自执行阶段的信息	
	input wire[`RegAddrBus]       ex_wd,
	input wire                    ex_wreg,
	input wire[`RegBus]			  ex_wdata, 	
	input wire[`AluOpBus] ex_aluop,
	input wire[`RegBus] ex_mem_addr,
	input wire[`RegBus] ex_reg2,
	input wire[`RegBus] ex_inst,
	input wire[`RegBus] ex_current_inst_address,
	
	//送到访存阶段的信息
	output reg[`RegAddrBus]      mem_wd,
	output reg                   mem_wreg,
	output reg[`RegBus]			 mem_wdata,
	output reg[`AluOpBus] mem_aluop,
	output reg[`RegBus] mem_mem_addr,
	output reg[`RegBus] mem_reg2,
	output reg[`RegBus] mem_inst,
	output reg[`RegBus] mem_current_inst_address,

	// 异常相关
	input wire 				flush,
	input wire[31:0] 		ex_excepttype,
	output reg[31:0]		mem_excepttype,
	input wire ex_except_csr_reg_we,
	input wire[31:0] ex_except_csr_mcause_data_i,
	input wire[31:0] ex_except_csr_mepc_data_i,
	output reg mem_except_csr_reg_we,
	output reg[31:0] mem_except_csr_mcause_data,
	output reg[31:0] mem_except_csr_mepc_data,
	
	input wire ex_csr_reg_we,
	input wire[11:0] ex_csr_reg_write_addr,
	input wire[`RegBus] ex_csr_reg_data_t,	//即ex的csr_result
	input wire[`RegBus] ex_csr_reg_data_rs, //即reg1_i

	output reg mem_csr_reg_we,
	output reg[11:0] mem_csr_reg_write_addr,
	output reg[`RegBus] mem_csr_reg_data_t,
	output reg[`RegBus] mem_csr_reg_data_rs
	
);


always @ (posedge clk) begin
	if(rst == `RstEnable) begin
		mem_wd <= `NOPRegAddr;
		mem_wreg <= `WriteDisable;
		mem_wdata <= `ZeroWord;	
		mem_aluop <= `EXE_OPER_NOP;
		mem_mem_addr <= `ZeroWord;
		mem_reg2 <= `ZeroWord;
		mem_inst <= `ZeroWord;
		mem_current_inst_address <= `ZeroWord;
		mem_excepttype <= `ZeroWord;
		mem_csr_reg_we <= `WriteDisable;
		mem_csr_reg_write_addr <= 12'h000;
		mem_csr_reg_data_t <= `ZeroWord;
		mem_csr_reg_data_rs <= `ZeroWord;
		mem_except_csr_reg_we <= `WriteDisable;
		mem_except_csr_mcause_data <= `ZeroWord;
		mem_except_csr_mepc_data <= `ZeroWord;
	end else if(flush == 1'b1) begin
		mem_wd <= `NOPRegAddr;
		mem_wreg <= `WriteDisable;
		mem_wdata <= `ZeroWord;	
		mem_aluop <= `EXE_OPER_NOP;
		mem_mem_addr <= `ZeroWord;
		mem_reg2 <= `ZeroWord;
		mem_inst <= `ZeroWord;
		mem_current_inst_address <= `ZeroWord;
		mem_excepttype <= `ZeroWord;
		mem_csr_reg_we <= `WriteDisable;
		mem_csr_reg_write_addr <= 12'h000;
		mem_csr_reg_data_t <= `ZeroWord;
		mem_csr_reg_data_rs <= `ZeroWord;
		mem_except_csr_reg_we <= `WriteDisable;
		mem_except_csr_mcause_data <= `ZeroWord;
		mem_except_csr_mepc_data <= `ZeroWord;
	end 
	else if(stall[3] == `Stop && stall[4] == `NoStop) begin
		mem_wd <= `NOPRegAddr;
		mem_wreg <= `WriteDisable;
		mem_wdata <= `ZeroWord;	
		mem_aluop <= `EXE_OPER_NOP;
		mem_mem_addr <= `ZeroWord;
		mem_reg2 <= `ZeroWord;
		mem_inst <= `ZeroWord;
		mem_current_inst_address <= `ZeroWord;
		mem_excepttype <= `ZeroWord;
		mem_csr_reg_we <= `WriteDisable;
		mem_csr_reg_write_addr <= 12'h000;
		mem_csr_reg_data_t <= `ZeroWord;
		mem_csr_reg_data_rs <= `ZeroWord;
		mem_except_csr_reg_we <= `WriteDisable;
		mem_except_csr_mcause_data <= `ZeroWord;
		mem_except_csr_mepc_data <= `ZeroWord;
	end 
	else if(stall[3] == `NoStop) begin
		mem_wd <= ex_wd;
		mem_wreg <= ex_wreg;
		mem_wdata <= ex_wdata;	
		mem_aluop <= ex_aluop;
		mem_mem_addr <= ex_mem_addr;
		mem_reg2 <= ex_reg2;		
		mem_inst <= ex_inst;
		mem_current_inst_address <= ex_current_inst_address;
		mem_excepttype <= ex_excepttype;
		mem_csr_reg_we <= ex_csr_reg_we;
		mem_csr_reg_write_addr <= ex_csr_reg_write_addr;
		mem_csr_reg_data_t <= ex_csr_reg_data_t;
		mem_csr_reg_data_rs <= ex_csr_reg_data_rs;
		mem_except_csr_reg_we <= ex_except_csr_reg_we;
		mem_except_csr_mcause_data <= ex_except_csr_mcause_data_i;
		mem_except_csr_mepc_data <= ex_except_csr_mepc_data_i;
	end    //if
end      //always
			

endmodule