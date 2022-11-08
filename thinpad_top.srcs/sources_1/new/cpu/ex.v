`include "../defines.v"

module ex(

	input wire rst,
	
	//送到执行阶段的信息
	input wire[`AluOpBus]         aluop_i,
	input wire[`AluSelBus]        alusel_i,
	input wire[`RegBus]           reg1_i,
	input wire[`RegBus]           reg2_i,
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
	input wire[`RegBus] inst_i,
	input wire[`RegBus] current_inst_address_i,
	// 处于执行阶段的转移指令要保存的返回地址
	input wire[`RegBus] link_address_i,

	//执行的结果
	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	output reg[`RegBus]	          wdata_o,
	output wire[`RegBus] inst_o,
	output wire[`RegBus] current_inst_address_o,

    // for save & load
    output wire[`AluOpBus] aluop_o,
    output wire[`RegBus] mem_addr_o,
	output wire[`RegBus] reg2_o,

	//*
	//访存阶段是否要写csr
	input wire mem_csr_reg_we,
	input wire[11:0] mem_csr_reg_write_addr,
	input wire[`RegBus] mem_csr_reg_data,

	//回写阶段是否要写csr寄存器
	input wire wb_csr_reg_we,
	input wire[11:0] wb_csr_reg_write_addr,
	input wire[`RegBus] wb_csr_reg_data,

	//与csr相连，读取寄存器值
	input wire[`RegBus] csr_reg_data_i,
	output reg[11:0] csr_reg_read_addr_o,
	//*/

	//向下一级传递，用于写csr寄存器
	output reg csr_reg_we_o,
	output reg[11:0] csr_reg_write_addr_o,
	output reg[`RegBus] csr_reg_data_o,
	output reg[`RegBus] csr_reg_data_t_o,


    output wire stallreq,

	// 异常相关
	input wire[31:0] excepttype_i, // 译码阶段搜集到的异常信息
	output wire[31:0] excepttype_o,
	
	//向下一级传递，在异常阶段中，用于写csr寄存器
	//input wire[1:0] mode_i,
	output reg except_csr_reg_we_o,
	output reg[`RegBus] except_csr_mcause_data_o,
	output reg[`RegBus] except_csr_mepc_data_o,
	
	output wire sfence_vma_o
);

	assign aluop_o = aluop_i;
    assign mem_addr_o = ((aluop_i == `EXE_OPER_LW)||(aluop_i == `EXE_OPER_LB)) 
	    ? (reg1_i + (inst_i[31] ? {20'hfffff,inst_i[31:20]} : {20'h0,inst_i[31:20]}))
		: (reg1_i + (inst_i[31] ? {20'hfffff,inst_i[31:25],inst_i[11:7]} : {20'h0,inst_i[31:25],inst_i[11:7]} ));
	assign reg2_o = reg2_i;
	assign inst_o = inst_i;
	assign current_inst_address_o = current_inst_address_i;

	reg[`RegBus] logicout;
	reg[`RegBus] shiftres;
	wire[`RegBus] result_sum;
	reg[`RegBus] arithmetic;
	reg[`RegBus] u_result;
	wire reg1_lt_reg2;	//第一个操作数是否小于第二个
	reg[`RegBus] min_result;
	reg[`RegBus] csr_read_result;

	assign excepttype_o = excepttype_i;

	assign sfence_vma_o = excepttype_i[13];
	
    //aluop
	always @ (*) begin
		if(rst == `RstEnable) begin
			logicout <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_OPER_OR: begin
					logicout <= reg1_i | reg2_i;
				end
				`EXE_OPER_AND: begin
					logicout <= reg1_i & reg2_i;
				end
				`EXE_OPER_XOR: begin
					logicout <= reg1_i ^ reg2_i;
				end
				`EXE_OPER_ORI: begin
					logicout <= reg1_i | reg2_i;
				end
				`EXE_OPER_ANDI: begin
					logicout <= reg1_i & reg2_i;
				end                
				default: begin
					logicout <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always

	// shift
	always @ (*) begin
		if(rst == `RstEnable) begin
			shiftres <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_OPER_SLLI: begin
					shiftres <= reg1_i << reg2_i[4:0];
				end
				`EXE_OPER_SRLI: begin
					shiftres <= reg1_i >> reg2_i[4:0];
				end
				default: begin
					shiftres <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always

	// EXE_RES_ARITHMETIC
	assign result_sum = reg1_i + reg2_i;
	always @ (*) begin
		if(rst == `RstEnable) begin
			arithmetic <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_OPER_ADD: begin
					arithmetic <= result_sum;
				end
				`EXE_OPER_ADDI: begin
					arithmetic <= result_sum;
				end
				default: begin
					arithmetic <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always

	// EXE_RES_U
	always @ (*) begin
		if(rst == `RstEnable) begin
			u_result <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_OPER_AUIPC: begin
					u_result <= current_inst_address_i + {inst_i[31:12], 12'h000};
				end
				`EXE_OPER_LUI: begin
					u_result <= {inst_i[31:12], 12'h000};
				end
				`EXE_OPER_CTZ: begin
					u_result <= (reg1_i[0] ? 0 :
								reg1_i[1] ? 1 :
								reg1_i[2] ? 2 :
								reg1_i[3] ? 3 :
								reg1_i[4] ? 4 :
								reg1_i[5] ? 5 :
								reg1_i[6] ? 6 :
								reg1_i[7] ? 7 :
								reg1_i[8] ? 8 :
								reg1_i[9] ? 9 :
								reg1_i[10] ? 10 :
								reg1_i[11] ? 11 :
								reg1_i[12] ? 12 :
								reg1_i[13] ? 13 :
								reg1_i[14] ? 14 :
								reg1_i[15] ? 15 :
								reg1_i[16] ? 16 :
								reg1_i[17] ? 17 :
								reg1_i[18] ? 18 :
								reg1_i[19] ? 19 :
								reg1_i[20] ? 20 :
								reg1_i[21] ? 21 :
								reg1_i[22] ? 22 :
								reg1_i[23] ? 23 :
								reg1_i[24] ? 24 :
								reg1_i[25] ? 25 : 
								reg1_i[26] ? 26 :
								reg1_i[27] ? 27 :
								reg1_i[28] ? 28 :
								reg1_i[29] ? 29 :
								reg1_i[30] ? 30 :
								reg1_i[31] ? 31 : 32);
				end
				default: begin
					u_result <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always

	// EXE_RES_MIN
	assign reg1_lt_reg2 = ((aluop_i == `EXE_OPER_MIN)) ?
						((reg1_i[31] && !reg2_i[31]) ||
						(!reg1_i[31] && !reg2_i[31] && (reg1_i < reg2_i)) || 
						(reg1_i[31] && reg2_i[31] && (reg1_i < reg2_i)))
						: (reg1_i < reg2_i);
	always @ (*) begin
		case (aluop_i)
			`EXE_OPER_MIN: begin
				min_result <= reg1_lt_reg2 ? reg1_i : reg2_i;
			end
			`EXE_OPER_MINU: begin
				min_result <= reg1_lt_reg2 ? reg1_i : reg2_i;
			end
			default: begin
				min_result <= `ZeroWord;
			end
		endcase
	end

	//csr指令读
	always @ (*) begin
		if(rst == `RstEnable) begin
			csr_read_result <= `ZeroWord;
		end
		else begin
			csr_read_result <= `ZeroWord;
			csr_reg_data_t_o <= `ZeroWord;
			if (aluop_i == `EXE_OPER_CSRRC || aluop_i == `EXE_OPER_CSRRS || aluop_i == `EXE_OPER_CSRRW) begin
				csr_reg_read_addr_o <= inst_i[31:20];
				csr_read_result <= csr_reg_data_i;
				csr_reg_data_t_o <= csr_reg_data_i;
				//*
				if (mem_csr_reg_we == `WriteEnable && mem_csr_reg_write_addr == inst_i[31:20]) begin
					csr_read_result <= mem_csr_reg_data;  
					csr_reg_data_t_o <= mem_csr_reg_data;
				end 
				else if(wb_csr_reg_we == `WriteEnable && wb_csr_reg_write_addr == inst_i[31:20]) begin
					csr_read_result <= wb_csr_reg_data;  
					csr_reg_data_t_o <= wb_csr_reg_data;
				end  
				//*/
			end
		end
	end

	//csr指令写
	always @ (*) begin
		if(rst == `RstEnable) begin
			csr_reg_write_addr_o <= 12'h000;
			csr_reg_we_o <= `WriteDisable;
			csr_reg_data_o <= `ZeroWord;
		end  
		else begin
			csr_reg_write_addr_o <= 12'h000;
			csr_reg_we_o <= `WriteDisable;
			csr_reg_data_o <= `ZeroWord;
			if (aluop_i == `EXE_OPER_CSRRC || aluop_i == `EXE_OPER_CSRRS || aluop_i == `EXE_OPER_CSRRW) begin
				csr_reg_write_addr_o <= inst_i[31:20];
				csr_reg_we_o <= `WriteEnable;
				csr_reg_data_o <= reg1_i;
			end
		end
	end

	//两条异常指令
	always @ (*) begin
		if(rst == `RstEnable) begin
			except_csr_reg_we_o <= `WriteDisable;
			except_csr_mcause_data_o <= `ZeroWord;
			except_csr_mepc_data_o <= `ZeroWord;
		end  
		else begin
			except_csr_reg_we_o <= `WriteDisable;
			except_csr_mcause_data_o <= `ZeroWord;
			except_csr_mepc_data_o <= `ZeroWord;
			if (aluop_i == `EXE_OPER_EBREAK || aluop_i == `EXE_OPER_ECALL) begin
				if (aluop_i == `EXE_OPER_EBREAK) begin
					except_csr_reg_we_o <= `WriteEnable;
					except_csr_mepc_data_o <= current_inst_address_i;
					except_csr_mcause_data_o <= {1'b0, 3'b000, 28'h3};
				end
				else if (aluop_i == `EXE_OPER_ECALL) begin
					except_csr_reg_we_o <= `WriteEnable;
					except_csr_mepc_data_o <= current_inst_address_i;
					except_csr_mcause_data_o <= {1'b0, 3'b000, 28'h8};
				end
			end
		end
	end

    //alusel
    always @ (*) begin
        wd_o <= wd_i;
		wreg_o <= wreg_i;
        case ( alusel_i ) 
            `EXE_RES_LOGIC: begin
                wdata_o <= logicout;
            end
			`EXE_RES_SHIFT: begin
				wdata_o <= shiftres;
			end
			`EXE_RES_JUMP_BRANCH: begin
				wdata_o <= link_address_i;
			end
			`EXE_RES_ARITHMETIC: begin
				wdata_o <= arithmetic;
			end
			`EXE_RES_U : begin
				wdata_o <= u_result;
			end
			`EXE_RES_MIN: begin
				wdata_o <= min_result;
			end
			`EXE_RES_CSR: begin
				wdata_o <= csr_read_result;  
			end
            default: begin
                wdata_o <= `ZeroWord;
            end
        endcase
 	end

endmodule
