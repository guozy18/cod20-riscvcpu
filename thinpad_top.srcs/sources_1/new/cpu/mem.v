`include "../defines.v"

module mem(

	input wire rst,
	
	//来自执行阶段的信息	
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
	input wire[`RegBus]			  wdata_i,
	
	//送到回写阶段的信息
	output reg[`RegAddrBus]      wd_o,
	output reg                   wreg_o,
	output reg[`RegBus]		     wdata_o,

	//mem
	(* keep = "true" *) input wire[`AluOpBus] aluop_i,
	input wire[`RegBus] mem_addr_i,
	input wire[`RegBus] reg2_i,
	input wire[`RegBus] mem_data_i,
	
	output reg[`RegBus] mem_addr_o,
    output wire mem_we_o,
	// output wire uart_we_o,
    output reg[3:0] mem_sel_o,
    output reg[`RegBus] mem_data_o,
    output reg mem_ce_o,

	//异常相关
	input wire[31:0]	excepttype_i,
	(* keep = "true" *) output reg[31:0]    excepttype_o,
	input wire except_csr_reg_we_i,
	input wire[`RegBus] except_csr_mcause_data_i,
	input wire[`RegBus] except_csr_mepc_data_i,
	(* keep = "true" *) output reg except_csr_reg_we_o,
	(* keep = "true" *) output reg[`RegBus] except_csr_mcause_data_o,
	(* keep = "true" *) output reg[`RegBus] except_csr_mepc_data_o,

	//csr
	input wire csr_reg_we_i,
	input wire[11:0] csr_reg_write_addr_i,
	input wire[`RegBus] csr_reg_data_t_i,
	input wire[`RegBus] csr_reg_data_rs_i,

	output reg csr_reg_we_o,
	output reg[11:0] csr_reg_write_addr_o,
	output reg[`RegBus] csr_reg_data_o,

	(* keep = "true" *) input wire[1:0] mode, //代表当前所处的模式
	
	// tlb
	input wire addr_ready_i,
	input wire addr_error_i

);

	reg mem_we_flag;
	assign mem_we_o = mem_we_flag & addr_ready_i;

	always @ (*) begin
		if(rst == `RstEnable) begin
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
		    wdata_o <= `ZeroWord;
			mem_addr_o <= `ZeroWord;
			mem_we_flag <= `WriteDisable;
			mem_sel_o <= 4'b0000;
			mem_data_o <= `ZeroWord;		
			mem_ce_o <= `ChipDisable;
			csr_reg_we_o <= `WriteDisable;
			csr_reg_write_addr_o <= 12'h000;
			csr_reg_data_o <= `ZeroWord;
		end else begin
		    wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o <= wdata_i;
			mem_addr_o <= `ZeroWord;
			mem_we_flag <= `WriteDisable;
			mem_sel_o <= 4'b0000;
			mem_data_o <= `ZeroWord;		
			mem_ce_o <= `ChipDisable;
			csr_reg_we_o <= csr_reg_we_i;
			csr_reg_write_addr_o <= csr_reg_write_addr_i;
			case(aluop_i)
				`EXE_OPER_CSRRC: begin
					csr_reg_data_o <= csr_reg_data_t_i & (~csr_reg_data_rs_i);
				end
				`EXE_OPER_CSRRS: begin
					csr_reg_data_o <= csr_reg_data_t_i | csr_reg_data_rs_i;
				end
				`EXE_OPER_CSRRW: begin
					csr_reg_data_o <= csr_reg_data_rs_i;
				end
				`EXE_OPER_LB: begin
					mem_addr_o <= mem_addr_i;
					mem_we_flag <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b11: begin
							mem_sel_o <= 4'b0111;
							wdata_o <= {{24{mem_data_i[31]}},mem_data_i[31:24]};
						end
						2'b10: begin
							mem_sel_o <= 4'b1011;
							wdata_o <= {{24{mem_data_i[23]}},mem_data_i[23:16]};
						end
						2'b01: begin
							mem_sel_o <= 4'b1101;
							wdata_o <= {{24{mem_data_i[15]}},mem_data_i[15:8]};
						end
						2'b00: begin
							mem_sel_o <= 4'b1110;
							wdata_o <= {{24{mem_data_i[7]}},mem_data_i[7:0]};
						end
					endcase
				end
				`EXE_OPER_LW: begin
					mem_addr_o <= mem_addr_i;
					mem_we_flag <= `WriteDisable;
					wdata_o <= mem_data_i;
					mem_sel_o <= 4'b0000;		
					mem_ce_o <= `ChipEnable;
				end
				`EXE_OPER_SB: begin
					mem_addr_o <= mem_addr_i;
					mem_ce_o <= `ChipEnable;
					mem_we_flag <= `WriteEnable;
					if (mem_addr_i == 32'h10000000) begin
						mem_data_o <= {24'h0, reg2_i[7:0]};
						wdata_o <= mem_data_i;
					end
					else begin
						wdata_o <= mem_data_i;
						mem_data_o <= {reg2_i[7:0], reg2_i[7:0], reg2_i[7:0], reg2_i[7:0]};
						
						case (mem_addr_i[1:0])
							2'b11: begin
								mem_sel_o <= 4'b0111;
							end
							2'b10: begin
								mem_sel_o <= 4'b1011;
							end
							2'b01: begin
								mem_sel_o <= 4'b1101;
							end
							2'b00: begin
								mem_sel_o <= 4'b1110;
							end
						endcase
					end
					
				end
				`EXE_OPER_SW: begin
					mem_addr_o <= mem_addr_i;
                    mem_we_flag <= `WriteEnable;
                    mem_data_o <= reg2_i;
                    mem_ce_o <= `ChipEnable;
					mem_sel_o <= 4'b0000;
				end
			endcase
		end    //if
	end      //always
	
	always @ (*) begin
        if (rst == `RstEnable) begin
            excepttype_o <= `ZeroWord;
			except_csr_reg_we_o <= `WriteDisable;
			except_csr_mepc_data_o <= `ZeroWord;
			except_csr_mcause_data_o <= `ZeroWord;
        end else begin
            excepttype_o <= `ZeroWord;
			except_csr_reg_we_o <= `WriteDisable;
			except_csr_mepc_data_o <= `ZeroWord;
			except_csr_mcause_data_o <= `ZeroWord;
			case (aluop_i)
				`EXE_OPER_ECALL:begin
					if(mode == `USER_MODE) begin
						excepttype_o <= 32'h00000004; // ecall
						except_csr_reg_we_o <= except_csr_reg_we_i;
						except_csr_mcause_data_o <= except_csr_mcause_data_i;
						except_csr_mepc_data_o <= except_csr_mepc_data_i;	
					end
				end
				`EXE_OPER_EBREAK:begin
					if(mode == `USER_MODE) begin
						excepttype_o <= 32'h0000000c; // ebreak
						except_csr_reg_we_o <= except_csr_reg_we_i;
						except_csr_mcause_data_o <= except_csr_mcause_data_i;
						except_csr_mepc_data_o <= except_csr_mepc_data_i;
					end
				end
				`EXE_OPER_MRET:begin
					if(mode == `MACHINE_MODE) begin
						excepttype_o <= 32'h00000008; // mret
						except_csr_reg_we_o <= `WriteDisable;
						except_csr_mepc_data_o <= `ZeroWord;
						except_csr_mcause_data_o <= `ZeroWord;
					end
				end
				`EXE_OPER_LW,`EXE_OPER_SW,`EXE_OPER_LB,`EXE_OPER_SB:begin
					if(mode == `USER_MODE) begin
						if(addr_error_i == 1'b1) begin
							excepttype_o <= 32'h00000014; // 地址异常
							except_csr_reg_we_o <= except_csr_reg_we_i;
							except_csr_mcause_data_o <= {1'b0, 3'b000, 28'h1};
							except_csr_mepc_data_o <= except_csr_mepc_data_i;
						end
					end
				end
			endcase
        end
    end

endmodule