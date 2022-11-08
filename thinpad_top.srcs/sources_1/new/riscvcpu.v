`include "defines.v"

module riscvcpu(

	input wire clk,
	input wire rst,
	
    input wire[`RegBus] if_data_i,
    output wire[`RegBus] if_addr_o,
    output wire if_sram_ce_o,
    output wire if_rom_ce_o,
    output wire if_serial_ce_o,
    output wire if_ce_o,

    input wire[`RegBus] mem_data_i,
    output wire[`RegBus] mem_addr_o,
    output wire[`RegBus] mem_data_o,
    output wire mem_we_o,
    output wire[3:0] mem_sel_o,
    output wire mem_sram_ce_o,
    output wire mem_rom_ce_o,
    output wire mem_serial_ce_o,
    output wire mem_ce_o
	
);

	wire[`InstAddrBus] pc;

	wire[`InstAddrBus] physical_pc;
	assign if_addr_o = physical_pc;
    wire[`InstAddrBus] virtual_addr;
    wire[`InstAddrBus] physical_addr;
	assign mem_addr_o = physical_addr;

	wire[`InstAddrBus] id_pc_i;
	wire[`InstBus] id_inst_i;
	
	//连接译码阶段ID模块的输出与ID/EX模块的输入
	(* dont_touch = "true" *) wire[`AluOpBus] id_aluop_o;
	wire[`AluSelBus] id_alusel_o;
	wire[`RegBus] id_reg1_o;
	wire[`RegBus] id_reg2_o;
	wire id_wreg_o;
	wire[`RegAddrBus] id_wd_o;
	(* keep = "true" *) wire[`RegBus] id_inst_o;
	wire[`RegBus] id_link_address_o;
	wire[`RegBus] id_current_inst_address_o;
	wire[`RegBus] id_excepttype_o;
	
	//连接ID/EX模块的输出与执行阶段EX模块的输入
	wire[`AluOpBus] ex_aluop_i;
	wire[`AluSelBus] ex_alusel_i;
	wire[`RegBus] ex_reg1_i;
	wire[`RegBus] ex_reg2_i;
	wire ex_wreg_i;
	wire[`RegAddrBus] ex_wd_i;
	wire[`RegBus] ex_link_address_i;
	wire[`RegBus] ex_inst_i;
	wire[`RegBus] ex_current_inst_address_i;
	wire[`RegBus] ex_excepttype_i;
	
	//连接执行阶段EX模块的输出与EX/MEM模块的输入
	wire ex_wreg_o;
	wire[`RegAddrBus] ex_wd_o;
	wire[`RegBus] ex_wdata_o;
	wire[`AluOpBus] ex_aluop_o;
	wire[`RegBus] ex_current_inst_address_o;
	wire[`RegBus] ex_mem_addr_o;
	wire[`RegBus] ex_reg2_o;
	wire mem_csr_reg_we_o;
	wire[11:0] mem_csr_reg_write_addr_o;
	wire[`RegBus] mem_csr_reg_data_o;
	(* keep = "true" *) wire wb_csr_reg_we_o;
	wire[11:0] wb_csr_reg_write_addr_o;
	wire[`RegBus] wb_csr_reg_data_o;
	(* dont_touch = "true" *) wire[`RegBus] csr_data_o;
	wire[11:0] csr_reg_read_addr_o;
	wire ex_csr_reg_we_i;
	wire[11:0] ex_csr_reg_write_addr_i;
	(* dont_touch = "true" *) wire[`RegBus] ex_csr_reg_data_rs_i;
	wire[`RegBus] ex_csr_reg_data_t_i;
	wire[`RegBus] ex_excepttype_o;
	(* keep = "true" *) wire[1:0] current_mode;
	wire ex_except_csr_reg_we_o;
	wire[`RegBus] ex_except_csr_mcause_data_o;
	wire[`RegBus] ex_except_csr_mepc_data_o;
	wire ex_sfence_vma_o;

	//连接EX/MEM模块的输出与访存阶段MEM模块的输入
	wire mem_wreg_i;
	wire[`RegAddrBus] mem_wd_i;
	wire[`RegBus] mem_wdata_i;
	(* keep = "true" *) wire[`AluOpBus] mem_aluop_i;
	wire[`RegBus] mem_mem_addr_i;
	wire[`RegBus] mem_reg2_i;
	wire[`RegBus] mem_current_inst_address_i;
	wire mem_csr_reg_we_i;
	wire[11:0] mem_csr_reg_write_addr_i;
	wire[`RegBus] mem_csr_reg_data_t_i;
	wire[`RegBus] mem_csr_reg_data_rs_i;
	wire[`RegBus] mem_excepttype_i;
	(* keep = "true" *) wire mem_except_csr_reg_we_i;
	(* keep = "true" *) wire[`RegBus] mem_except_csr_mcause_data_i;
	(* keep = "true" *) wire[`RegBus] mem_except_csr_mepc_data_i;

	wire mem_addr_ready_i;
	wire mem_addr_error_i;

	//连接访存阶段MEM模块的输出与MEM/WB模块的输入
	wire mem_wreg_o;
	wire[`RegAddrBus] mem_wd_o;
	wire[`RegBus] mem_wdata_o;
	(* keep = "true" *) wire mem_except_csr_reg_we_o;
	(* keep = "true" *) wire[`RegBus] mem_except_csr_mcause_data_o;
	(* keep = "true" *) wire[`RegBus] mem_except_csr_mepc_data_o;
	
	//连接MEM/WB模块的输出与回写阶段的输入	
	wire wb_wreg_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;
	wire wb_except_csr_reg_we_o;
	wire[`RegBus] wb_except_csr_mcause_data_o;
	wire[`RegBus] wb_except_csr_mepc_data_o;
	(* keep = "true" *) wire[`RegBus] wb_excepttype_o;
	
	//连接译码阶段ID模块与通用寄存器Regfile模块
	wire reg1_read;
	wire reg2_read;
	wire[`RegBus] reg1_data;
	wire[`RegBus] reg2_data;
	wire[`RegAddrBus] reg1_addr;
	wire[`RegAddrBus] reg2_addr;

  	//ctrl
  	wire[5:0] stall;
    wire stallreq_from_id;
    wire stallreq_from_ex;
	wire stallreq_from_control;
	(* keep = "true" *)wire[31:0] mem_excepttype_o;

	wire stall_for_virtual;
	wire stall_for_virtual_mem;

	// id <===> pc_reg
	wire id_branch_flag_o;
	wire[`RegBus] branch_target_address;


	// 中断
	wire flush;
	wire[`RegBus] new_pc;
	(* keep = "true" *) wire[`RegBus] csr_mstatus;
	wire[`RegBus] csr_mtvec;
	wire[`RegBus] csr_mscratch;
	(* dont_touch = "true" *) wire[`RegBus] csr_mepc;
	wire[`RegBus] csr_mcause;
	wire[`RegBus] csr_satp;


	// tlb
	wire virtual_pause_flag;

	ctrl _ctrl(
		.clk(clk),
		.rst(rst),

		.stallreq_from_id(stallreq_from_id),
		.stallreq_from_ex(stallreq_from_ex),
		.stallreq_from_mem(mem_ce_o),
		.stallreq_from_control(stallreq_from_control),

		//tlb
		.stall_for_virtual(stall_for_virtual),
		.stall_for_virtual_mem(stall_for_virtual_mem),

		.new_pc(new_pc),
		.flush(flush),
		.stall(stall),

		.mtvec_i(csr_mtvec),
		.mepc_i(csr_mepc),	
		.excepttype_i(mem_excepttype_o)
		//.cp0_epc_i(cp0_epc_i)
	);

  //pc_reg例化
	pc_reg pc_reg0(
		.clk(clk),
		.rst(rst),
		
		.pc(pc),

		.ce(if_ce_o),
		
		.stall(stall),

		.branch_flag_i(id_branch_flag_o),
		.branch_target_address_i(branch_target_address),

		.flush(flush),
		.new_pc(new_pc),

		.virtual_pause_flag(virtual_pause_flag)
	);

	// mmu for if
    mmu_tlb mmu_tlb0(
        .clk(clk),
        .rst(rst),
		.addr_i(pc),
		.addr_o(physical_pc),

        .sram_ce(if_sram_ce_o),
        .flash_ce(if_flash_ce_o),
        .rom_ce(if_rom_ce_o),
        .serial_ce(if_serial_ce_o),
        .vga_ce(if_vga_ce_o),
		
		// tlb
		.satp_i(csr_satp),
		.inst_data_i(if_data_i),
		.current_mode_i(current_mode),
		.stall_for_virtual(stall_for_virtual),
		.virtual_pause_flag(virtual_pause_flag),

		.sfence_vma_i(ex_sfence_vma_o)
    );

    //IF/ID模块例化
	if_id if_id0(
		.clk(clk),
		.rst(rst),
		.if_pc(pc),
		.if_inst(if_data_i),
		.id_pc(id_pc_i),
		.id_inst(id_inst_i),

		.flush(flush),

		.stall(stall) 	
	);
	
	//译码阶段ID模块
	id id0(
		.rst(rst),
		.pc_i(id_pc_i),
		.inst_i(id_inst_i),

		.reg1_data_i(reg1_data),
		.reg2_data_i(reg2_data),

        //处于执行阶段的指令要写入的目的寄存器信息
		.ex_aluop_i(ex_aluop_o),
		.ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_wd_i(ex_wd_o),

	  //处于访存阶段的指令要写入的目的寄存器信息
		.mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_wd_i(mem_wd_o),

		//送到regfile的信息
		.reg1_read_o(reg1_read),
		.reg2_read_o(reg2_read), 	  

		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr), 
	  
		//送到ID/EX模块的信息
		.aluop_o(id_aluop_o),
		.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),
		.reg2_o(id_reg2_o),
		.wd_o(id_wd_o),
		.wreg_o(id_wreg_o),

		.inst_o(id_inst_o),
		.link_addr_o(id_link_address_o),
		.current_inst_address_o(id_current_inst_address_o),

		.branch_flag_o(id_branch_flag_o),
		.branch_target_address_o(branch_target_address),

		.stallreq(stallreq_from_id),
		.stallreq_for_control(stallreq_from_control),

		.excepttype_o(id_excepttype_o)
	);

  //通用寄存器Regfile例化
	regfile regfile1(
		.clk (clk),
		.rst (rst),
		.we	(wb_wreg_i),
		.waddr (wb_wd_i),
		.wdata (wb_wdata_i),
		.re1 (reg1_read),
		.raddr1 (reg1_addr),
		.rdata1 (reg1_data),
		.re2 (reg2_read),
		.raddr2 (reg2_addr),
		.rdata2 (reg2_data)
	);

	//ID/EX模块
	id_ex id_ex0(
		.clk(clk),
		.rst(rst),
		
		//从译码阶段ID模块传递的信息
		.id_aluop(id_aluop_o),
		.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_wd(id_wd_o),
		.id_wreg(id_wreg_o),
		.id_inst(id_inst_o),
		.id_link_address(id_link_address_o),
		.id_current_inst_address(id_current_inst_address_o),
	
		//传递到执行阶段EX模块的信息
		.ex_aluop(ex_aluop_i),
		.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),
		.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),
		.ex_wreg(ex_wreg_i),
		.ex_inst(ex_inst_i),
		.ex_current_inst_address(ex_current_inst_address_i),
		.ex_link_address(ex_link_address_i),

		.flush(flush),
		.id_excepttype(id_excepttype_o),
		.ex_excepttype(ex_excepttype_i),
		
		.stall(stall)
	);		
	
	//EX模块
	ex ex0(
		.rst(rst),
	
		//送到执行阶段EX模块的信息
		.aluop_i(ex_aluop_i),
		.alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i),
		.reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i),
		.wreg_i(ex_wreg_i),

		.inst_i(ex_inst_i),
		.link_address_i(ex_link_address_i),
	 	.current_inst_address_i(ex_current_inst_address_i),

	  //EX模块的输出到EX/MEM模块信息
		.wd_o(ex_wd_o),
		.wreg_o(ex_wreg_o),
		.wdata_o(ex_wdata_o),
		.inst_o(ex_inst_o),
		.current_inst_address_o(ex_current_inst_address_o),

		.aluop_o(ex_aluop_o),
		.mem_addr_o(ex_mem_addr_o),
		.reg2_o(ex_reg2_o),

		.mem_csr_reg_we(mem_csr_reg_we_o),
		.mem_csr_reg_write_addr(mem_csr_reg_write_addr_o),
		.mem_csr_reg_data(mem_csr_reg_data_o),
		.wb_csr_reg_we(wb_csr_reg_we_o),
		.wb_csr_reg_write_addr(wb_csr_reg_write_addr_o),
		.wb_csr_reg_data(wb_csr_reg_data_o),
		.csr_reg_data_i(csr_data_o),
		.csr_reg_read_addr_o(csr_reg_read_addr_o),
		.csr_reg_we_o(ex_csr_reg_we_i),
		.csr_reg_write_addr_o(ex_csr_reg_write_addr_i),
		.csr_reg_data_o(ex_csr_reg_data_rs_i),
		.csr_reg_data_t_o(ex_csr_reg_data_t_i),
		.excepttype_i(ex_excepttype_i),
		.excepttype_o(ex_excepttype_o),

		//.mode_i(current_mode),
		.except_csr_reg_we_o(ex_except_csr_reg_we_o),
		.except_csr_mcause_data_o(ex_except_csr_mcause_data_o),
		.except_csr_mepc_data_o(ex_except_csr_mepc_data_o),

		.sfence_vma_o(ex_sfence_vma_o),

		.stallreq(stallreq_from_ex)
	);

  //EX/MEM模块
  ex_mem ex_mem0(
		.clk(clk),
		.rst(rst),
	  
		//来自执行阶段EX模块的信息	
		.ex_wd(ex_wd_o),
		.ex_wreg(ex_wreg_o),
		.ex_wdata(ex_wdata_o),
		.ex_aluop(ex_aluop_o),
		.ex_mem_addr(ex_mem_addr_o),
		.ex_reg2(ex_reg2_o),
		.ex_current_inst_address(ex_current_inst_address_o),
	
		//送到访存阶段MEM模块的信息
		.mem_wd(mem_wd_i),
		.mem_wreg(mem_wreg_i),
		.mem_wdata(mem_wdata_i),

		.mem_aluop(mem_aluop_i),
		.mem_mem_addr(mem_mem_addr_i),
		.mem_reg2(mem_reg2_i),
		.mem_current_inst_address(mem_current_inst_address_i),

		.ex_csr_reg_we(ex_csr_reg_we_i),
		.ex_csr_reg_write_addr(ex_csr_reg_write_addr_i),
		.ex_csr_reg_data_t(ex_csr_reg_data_t_i),
		.ex_csr_reg_data_rs(ex_csr_reg_data_rs_i),
		.mem_csr_reg_we(mem_csr_reg_we_i),
		.mem_csr_reg_write_addr(mem_csr_reg_write_addr_i),
		.mem_csr_reg_data_t(mem_csr_reg_data_t_i),
		.mem_csr_reg_data_rs(mem_csr_reg_data_rs_i),
		.flush(flush),
		.ex_excepttype(ex_excepttype_o),
		.mem_excepttype(mem_excepttype_i),
		.ex_except_csr_reg_we(ex_except_csr_reg_we_o),
		.ex_except_csr_mcause_data_i(ex_except_csr_mcause_data_o),
		.ex_except_csr_mepc_data_i(ex_except_csr_mepc_data_o),
		.mem_except_csr_reg_we(mem_except_csr_reg_we_i),
		.mem_except_csr_mcause_data(mem_except_csr_mcause_data_i),
		.mem_except_csr_mepc_data(mem_except_csr_mepc_data_i),

		.stall(stall)
	);
	
  //MEM模块例化
	mem mem0(
		.rst(rst),
	
		//来自EX/MEM模块的信息	
		.wd_i(mem_wd_i),
		.wreg_i(mem_wreg_i),
		.wdata_i(mem_wdata_i),
	  
		//送到MEM/WB模块的信息
		.wd_o(mem_wd_o),
		.wreg_o(mem_wreg_o),
		.wdata_o(mem_wdata_o),


		.mem_data_i(mem_data_i),

		.aluop_i(mem_aluop_i),
		.mem_addr_i(mem_mem_addr_i),
		.reg2_i(mem_reg2_i),

		// .mem_addr_o(mem_addr_o),
		.mem_addr_o(virtual_addr),
		.mem_we_o(mem_we_o),
		// .uart_we_o(uart_we_o),
		.mem_sel_o(mem_sel_o),
		.mem_data_o(mem_data_o),
		.mem_ce_o(mem_ce_o),

		.csr_reg_we_i(mem_csr_reg_we_i),
		.csr_reg_write_addr_i(mem_csr_reg_write_addr_i),
		.csr_reg_data_t_i(mem_csr_reg_data_t_i),
		.csr_reg_data_rs_i(mem_csr_reg_data_rs_i),
		.csr_reg_we_o(mem_csr_reg_we_o),
		.csr_reg_write_addr_o(mem_csr_reg_write_addr_o),
		.csr_reg_data_o(mem_csr_reg_data_o),

		.except_csr_reg_we_i(mem_except_csr_reg_we_i),
		.except_csr_mcause_data_i(mem_except_csr_mcause_data_i),
		.except_csr_mepc_data_i(mem_except_csr_mepc_data_i),
		.except_csr_reg_we_o(mem_except_csr_reg_we_o),
		.except_csr_mcause_data_o(mem_except_csr_mcause_data_o),
		.except_csr_mepc_data_o(mem_except_csr_mepc_data_o),


		.excepttype_i(mem_excepttype_i),
		.excepttype_o(mem_excepttype_o),
		.mode(current_mode),

		.addr_ready_i(mem_addr_ready_i),
		.addr_error_i(mem_addr_error_i)
	);

	// mmu for mem
	mmu_tlb mmu_tlb1(
        .clk(clk),
        .rst(rst),
        // .addr_i(mem_addr_o),
		.addr_i(virtual_addr),
		.addr_o(physical_addr),
        .sram_ce(mem_sram_ce_o),
        .flash_ce(mem_flash_ce_o),
        .rom_ce(mem_rom_ce_o),
        .serial_ce(mem_serial_ce_o),
        .vga_ce(mem_vga_ce_o),

		// tlb
		.satp_i(csr_satp),
		.inst_data_i(mem_data_i),
		.current_mode_i(current_mode),
		.stall_for_virtual_mem(stall_for_virtual_mem),

		.addr_ready(mem_addr_ready_i),
		.addr_error(mem_addr_error_i),

		.sfence_vma_i(ex_sfence_vma_o)
    );

  //MEM/WB模块
	mem_wb mem_wb0(
		.clk(clk),
		.rst(rst),

		//来自访存阶段MEM模块的信息	
		.mem_wd(mem_wd_o),
		.mem_wreg(mem_wreg_o),
		.mem_wdata(mem_wdata_o),

		.mem_excepttype(mem_excepttype_o),
	
		//送到回写阶段的信息
		.wb_wd(wb_wd_i),
		.wb_wreg(wb_wreg_i),
		.wb_wdata(wb_wdata_i),

		.wb_excepttype(wb_excepttype_o),

		.flush(flush),
		.mem_csr_reg_we(mem_csr_reg_we_o),
		.mem_csr_reg_write_addr(mem_csr_reg_write_addr_o),
		.mem_csr_reg_data(mem_csr_reg_data_o),
		.wb_csr_reg_we(wb_csr_reg_we_o),
		.wb_csr_reg_write_addr(wb_csr_reg_write_addr_o),
		.wb_csr_reg_data(wb_csr_reg_data_o),

		.stall(stall)				       	
	);

	csr_reg csr_reg0(
		.clk(clk),
		.rst(rst),
		.we_i(wb_csr_reg_we_o),
		.waddr_i(wb_csr_reg_write_addr_o),
		.raddr_i(csr_reg_read_addr_o),
		.data_i(wb_csr_reg_data_o),
		.excepttype_i(mem_excepttype_o),
		.data_o(csr_data_o),
		.mstatus_o(csr_mstatus),
		.mtvec_o(csr_mtvec),
		.mscratch_o(csr_mscratch),
		.mepc_o(csr_mepc),
		.mcause_o(csr_mcause),
		.except_we_i(mem_except_csr_reg_we_o),
		.except_mcause_data_i(mem_except_csr_mcause_data_o),
		.except_mepc_data_i(mem_except_csr_mepc_data_o),
		.mode(current_mode),

		.satp_o(csr_satp)
	);

endmodule
