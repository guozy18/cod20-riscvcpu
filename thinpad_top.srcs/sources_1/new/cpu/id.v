`include "../defines.v"

module id(

	input wire                    rst,
	input wire[`InstAddrBus]      pc_i,
	input wire[`InstBus]          inst_i,

    //处于执行阶段的指令要写入的目的寄存器信息
    input wire[`AluOpBus]         ex_aluop_i,
	input wire ex_wreg_i,
	input wire[`RegBus] ex_wdata_i,
	input wire[`RegAddrBus] ex_wd_i,
	
	//处于访存阶段的指令要写入的目的寄存器信息
	input wire mem_wreg_i,
	input wire[`RegBus] mem_wdata_i,
	input wire[`RegAddrBus] mem_wd_i,

	input wire[`RegBus]           reg1_data_i,
	input wire[`RegBus]           reg2_data_i,

	//送到regfile的信息
	output reg                    reg1_read_o,
	output reg                    reg2_read_o,     
	output reg[`RegAddrBus]       reg1_addr_o,
	output reg[`RegAddrBus]       reg2_addr_o, 	      
	
	//送到执行阶段的信息
	output reg[`AluOpBus]         aluop_o, //运算的子类型
	output reg[`AluSelBus]        alusel_o, //运算的类型
	output reg[`RegBus]           reg1_o,
	output reg[`RegBus]           reg2_o, 
    output wire[`InstBus]         inst_o, //当前指令
	output reg[`RegAddrBus]       wd_o, //目的寄存器地址
    output reg[`RegBus]           link_addr_o, //转移指令要保存的返回地址
    output wire[`RegBus]          current_inst_address_o, // 指令的PC值

    output reg                    next_inst_in_delayslot_o, // 延迟槽（暂停流水线，详情放到控制冲突的地方考虑）

    output reg                    branch_flag_o,    //是否发生跳转
    output reg[`RegBus]           branch_target_address_o,  //跳转地址

	output reg                    wreg_o, //是否有要写入的目的寄存器
    output wire stallreq,
    output wire stallreq_for_control,

    output wire[31:0]             excepttype_o //异常输出
);

    wire[6:0] opcode = inst_i[6:0];
    wire[4:0] rd = inst_i[11:7];
    wire[2:0] funct3 = inst_i[14:12];
    wire[4:0] rs1 = inst_i[19:15];
    wire[4:0] rs2 = inst_i[24:20];
    wire[6:0] funct7 = inst_i[31:25];

    wire[10:0] funct = { funct7[6:0], funct3[2:0] };
    wire[24:0] funct25 = inst_i[31:7];
    reg[`RegBus] imm;
    reg instvalid;
    wire[`RegBus] pc_plus_4;
    wire[`RegBus] branch_offset;
    wire[`RegBus] jump_offset;
    reg stallreq_for_reg1_loadrelate;
    reg stallreq_for_reg2_loadrelate;
    reg stallreq_for_jump_branch;
    wire pre_inst_is_load;

    reg excepttype_is_ecall; // 是否是系统调用异常ecall
    reg excepttype_is_mret; // 是否是异常返回指令mret
    reg excepttype_is_ebreak; // 是否是中断指令ebreak
    reg excepttype_is_sfence; // 清空tlb

    assign pc_plus_4 = pc_i + 4;
    assign branch_offset = inst_i[31] ? {19'b1111111111111111111,inst_i[31],inst_i[7],inst_i[30:25],inst_i[11:8],1'b0} : {19'b0,inst_i[31] ,inst_i[7], inst_i[30:25], inst_i[11:8],1'b0};
    assign jump_offset = inst_i[31] ? {8'hff,3'b111,inst_i[31],inst_i[19:12],inst_i[20],inst_i[30:21],1'b0} : {11'b0,inst_i[31],inst_i[19:12],inst_i[20],inst_i[30:21],1'b0};
    assign current_inst_address_o = pc_i;
    assign inst_o = inst_i;
    assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
    assign stallreq_for_control = stallreq_for_jump_branch;
    assign pre_inst_is_load = ((ex_aluop_i == `EXE_OPER_LW) ||
                               (ex_aluop_i == `EXE_OPER_LB)) ? 1'b1 : 1'b0;
    
    assign excepttype_o = {18'b0,excepttype_is_sfence, excepttype_is_ebreak, excepttype_is_mret , 1'b0 , instvalid, excepttype_is_ecall, 8'b0};
 
    /*  目前产生的传递给ID-EX信号： 
          运算类型 + 运算子类型；两个寄存器的数据内容； 目的寄存器的地址；是否要写入目的寄存器 ， PC信号
        
        待补充的信号：
          有关冲突处理的信号 + 暂停延迟的信号
    */

    always @ (*) begin
        if (rst == `RstEnable) begin
            aluop_o <= `EXE_OPER_NOP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
            branch_target_address_o <= `ZeroWord;
            link_addr_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            stallreq_for_jump_branch <= `NoStop;
            instvalid <= `InstInvalid;  // 默认是无效指令
            excepttype_is_ecall <= `False_v; // 默认没有系统调用异常
            excepttype_is_mret <= `False_v; // 默认不是eret指令
            excepttype_is_ebreak <= `False_v; // 默认不是ebreak指令
            excepttype_is_sfence <= `False_v;
        end else begin
            aluop_o <= `EXE_OPER_NOP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= rd;
			wreg_o <= `WriteDisable;	   
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= rs1;
			reg2_addr_o <= rs2;
            branch_target_address_o <= `ZeroWord;
            link_addr_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            stallreq_for_jump_branch <= `NoStop;
            instvalid <= `InstInvalid;  // 默认是无效指令
            excepttype_is_ecall <= `False_v; // 默认没有系统调用异常
            excepttype_is_mret <= `False_v; // 默认不是eret指令
            excepttype_is_ebreak <= `False_v; // 默认不是ebreak指令
            excepttype_is_sfence <= `False_v;
            imm <= `ZeroWord;	
            case (opcode)
                `EXE_TYPE_R: begin
                    case (funct3)
                        `EXE_FUNCT_ADD: begin
                            wreg_o <= `WriteEnable;
                            aluop_o <= `EXE_OPER_ADD;
                            alusel_o <= `EXE_RES_ARITHMETIC;
                            reg1_read_o <= 1'b1;
                            reg2_read_o <= 1'b1;
                            wd_o <= rd;
                            instvalid <= `InstValid;
                        end
                        `EXE_FUNCT_AND: begin
                            wreg_o <= `WriteEnable;
                            aluop_o <= `EXE_OPER_AND;
                            alusel_o <= `EXE_RES_LOGIC;
                            reg1_read_o <= 1'b1;
                            reg2_read_o <= 1'b1;
                            wd_o <= rd;
                            instvalid <= `InstValid;
                        end
                        `EXE_FUNCT_ORMINU: begin
                            case (funct7)
                                `EXE_FUNCT_ORXOR:begin
                                    // 此处定义为OR类型
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_OPER_OR;
                                    alusel_o <= `EXE_RES_LOGIC;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    wd_o <= rd;
                                    instvalid <= `InstValid;
                                end
                                `EXE_FUNCT_MINMINU:begin
                                    //此处解析为MINU型指令
                                    aluop_o <= `EXE_OPER_MINU;
                                    alusel_o <= `EXE_RES_MIN;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    wreg_o <= `WriteEnable;
                                    wd_o <= rd;
                                    instvalid <= `InstValid;
                                end
                            endcase
                        end
                        `EXE_FUNCT_XORMIN: begin
                            case (funct7)
                                `EXE_FUNCT_ORXOR:begin
                                    // 此处定义为XOR类型
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_OPER_XOR;
                                    alusel_o <= `EXE_RES_LOGIC;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid <= `InstValid;
                                    wd_o <= rd;
                                end
                                `EXE_FUNCT_MINMINU:begin
                                    //此处解析为MIN型指令
                                    aluop_o <= `EXE_OPER_MIN;
                                    alusel_o <= `EXE_RES_MIN;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    wreg_o <= `WriteEnable;
                                    wd_o <= rd;
                                    instvalid <= `InstValid;
                                end
                            endcase
                        end
                        default: begin
                        end
                    endcase
                end
                `EXE_TYPE_I: begin
                    case (funct3)
                        `EXE_FUNCT_ADDI: begin
                            wreg_o <= `WriteEnable;
                            aluop_o <= `EXE_OPER_ADDI;
                            alusel_o <= `EXE_RES_ARITHMETIC;
                            reg1_read_o <= 1'b1;
                            reg2_read_o <= 1'b0;
                            imm <= inst_i[31] ? {20'hfffff , inst_i[31:20]} : { 20'h00000, inst_i[31:20] };
                            wd_o <= rd;
                            instvalid <= `InstValid;
                        end
                        `EXE_FUNCT_ORI: begin
                            wreg_o <= `WriteEnable;
                            aluop_o <= `EXE_OPER_ORI;
                            alusel_o <= `EXE_RES_LOGIC;
                            reg1_read_o <= 1'b1;
                            reg2_read_o <= 1'b0;
                            imm <= inst_i[31] ? {20'hfffff , inst_i[31:20]} : { 20'h00000, inst_i[31:20] };
                            wd_o <= rd;
                            instvalid <= `InstValid;
                        end
                        `EXE_FUNCT_ANDI: begin
                            wreg_o <= `WriteEnable;
                            aluop_o <= `EXE_OPER_ANDI;
                            alusel_o <= `EXE_RES_LOGIC;
                            reg1_read_o <= 1'b1;
                            reg2_read_o <= 1'b0;
                            imm <= inst_i[31] ? {20'hfffff , inst_i[31:20]} : { 20'h00000, inst_i[31:20] };
                            wd_o <= rd;
                            instvalid <= `InstValid;
                        end
                        `EXE_FUNCT_SLLICTZ: begin
                            case (funct7)
                                `EXE_FUNCT_SLLI:begin
                                    wreg_o <= `WriteEnable;
                                    aluop_o <= `EXE_OPER_SLLI;
                                    alusel_o <= `EXE_RES_SHIFT;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b0;
                                    imm <= inst_i[24] ? {24'hffffff , 3'b111 , inst_i[24:20] } : { 27'b0, inst_i[24:20] };
                                    wd_o <= rd;
                                    instvalid <= `InstValid;
                                end
                                `EXE_FUNCT_CTZ:begin
                                    //此处解析为CTZ指令
                                    aluop_o <= `EXE_OPER_CTZ;
                                    alusel_o <= `EXE_RES_U;
                                    wreg_o <= `WriteEnable;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b0;
                                    imm <= 32'h00000000;
                                    wd_o <= rd;
                                    instvalid <= `InstValid;
                                end
                            endcase
                        end
                        `EXE_FUNCT_SRLI: begin
                            wreg_o <= `WriteEnable;
                            aluop_o <= `EXE_OPER_SRLI;
                            alusel_o <= `EXE_RES_SHIFT;
                            reg1_read_o <= 1'b1;
                            reg2_read_o <= 1'b0;
                            imm <= inst_i[24] ? {24'hffffff , 3'b111 , inst_i[24:20] } : { 27'b0, inst_i[24:20] };
                            wd_o <= rd;
                            instvalid <= `InstValid;
                        end
                        default: begin
                        end
                    endcase
                end
                `EXE_TYPE_S:begin
                    case (funct3)
                        `EXE_FUNCT_SB:begin
                            // 解析SB指令
                            aluop_o <= `EXE_OPER_SB;
                            alusel_o <= `EXE_RES_LOAD_STORE;
                            wreg_o <= `WriteDisable;
                            reg1_read_o <= 1'b1;
                            reg2_read_o <= 1'b1;
                            instvalid <= `InstValid;
                        end
                        `EXE_FUNCT_SW:begin
                            // 解析SW指令
                            aluop_o <= `EXE_OPER_SW;
                            alusel_o <= `EXE_RES_LOAD_STORE;
                            wreg_o <= `WriteDisable;
                            reg1_read_o <= 1'b1;
                            reg2_read_o <= 1'b1;
                            instvalid <= `InstValid;
                        end
                    endcase
                end
                `EXE_TYPE_B:begin
                    case (funct3)
                        `EXE_FUNCT_BEQ:begin
                            // 解析BEQ指令
                            aluop_o <= `EXE_OPER_BEQ;
                            alusel_o <= `EXE_RES_JUMP_BRANCH;
                            wreg_o <= `WriteDisable;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
                            instvalid <= `InstValid;
                            // 需要添加一个暂停指令，解析处为BEQ指令之后
                            if (reg1_o == reg2_o) begin
                                branch_target_address_o <= pc_i + branch_offset;
                                branch_flag_o <= `Branch;
                                stallreq_for_jump_branch <= `Stop;
                            end
                            instvalid <= `InstValid;
                        end
                        `EXE_FUNCT_BNE:begin
                            // 解析BNE指令
                            aluop_o <= `EXE_OPER_BNE;
                            alusel_o <= `EXE_RES_JUMP_BRANCH;
                            wreg_o <= `WriteDisable;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b1;
                            instvalid <= `InstValid;
                            // 需要添加一个暂停指令，解析处为BNE指令之后
                            if (reg1_o != reg2_o) begin
                                branch_target_address_o <= pc_i + branch_offset;
                                branch_flag_o <= `Branch;
                                stallreq_for_jump_branch <= `Stop;
                            end
                        end
                    endcase
                end
                `EXE_TYPE_L:begin
                    case (funct3)
                        `EXE_FUNCT_LB:begin
                            // 解析LB指令
                            aluop_o <= `EXE_OPER_LB;
                            alusel_o <= `EXE_RES_LOAD_STORE;
                            wreg_o <= `WriteEnable;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
                            wd_o <= rd;
                            instvalid <= `InstValid;
                        end
                        `EXE_FUNCT_LW:begin
                            // 解析LW指令
                            aluop_o <= `EXE_OPER_LW;
                            alusel_o <= `EXE_RES_LOAD_STORE;
                            wreg_o <= `WriteEnable;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
                            wd_o <= rd;
                            instvalid <= `InstValid;
                        end
                    endcase
                end
                `EXE_TYPE_LUI:begin
                    // 此处解析LUI指令
                    aluop_o <= `EXE_OPER_LUI;
                    alusel_o <= `EXE_RES_U;
                    wreg_o <= `WriteEnable;
                    reg1_read_o <= 1'b0; reg2_read_o <= 1'b0;
                    wd_o <= rd;
                    instvalid <= `InstValid;
                end
                `EXE_TYPE_JAL:begin
                    // 解析JAL指令
                    aluop_o <= `EXE_OPER_JAL;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= 1'b0; reg2_read_o <= 1'b0;
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;
                    link_addr_o <= pc_plus_4;
                    branch_target_address_o <= pc_i + jump_offset;
                    branch_flag_o <= `Branch;
                    stallreq_for_jump_branch <= `Stop;
                    instvalid <= `InstValid;

                end
                `EXE_TYPE_JALR:begin
                    // 解析JALR指令
                    aluop_o <= `EXE_OPER_JALR;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;
                    link_addr_o <= pc_plus_4;
                    branch_target_address_o <= (reg1_o + (inst_i[31] ? {20'hfffff , inst_i[31:20]} : { 20'h00000, inst_i[31:20] }))& (~1);
                    branch_flag_o <= `Branch;
                    stallreq_for_jump_branch <= `Stop;
                    instvalid <= `InstValid;  
                    // 此处寄存器可能发生一些问题从而产生异常
                end
                `EXE_TYPE_AUIPC:begin
                    // 解析AUIPC指令
                    aluop_o <= `EXE_OPER_AUIPC;
                    alusel_o <= `EXE_RES_U;
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;
                    reg1_read_o <= 1'b0; reg2_read_o <= 1'b0;
                    instvalid <= `InstValid; 
                end
                `EXE_TYPE_INTERRUPT:begin
                    case (funct3)
                        `EXE_FUNCT_CSRRC:begin
                            // 解析CSRRC指令
                            aluop_o <= `EXE_OPER_CSRRC;
                            alusel_o <= `EXE_RES_CSR;
                            wreg_o <= `WriteEnable;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
                            wd_o <= rd;
                            instvalid <= `InstValid;
                        end
                        `EXE_FUNCT_CSRRS:begin
                            // 解析CSRRS指令
                            aluop_o <= `EXE_OPER_CSRRS;
                            alusel_o <= `EXE_RES_CSR;
                            wreg_o <= `WriteEnable;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
                            wd_o <= rd;
                            instvalid <= `InstValid;
                        end
                        `EXE_FUNCT_CSRRW:begin
                            // 解析CSRRW指令
                            aluop_o <= `EXE_OPER_CSRRW;
                            alusel_o <= `EXE_RES_CSR;
                            instvalid <= `InstValid;
                            wreg_o <= `WriteEnable;
                            reg1_read_o <= 1'b1; reg2_read_o <= 1'b0;
                            wd_o <= rd;
                        end
                        `EXE_FUNCT_SYSCALL:begin
                            // 此处进一步判断三条指令中的一条
                            if(funct7 == `EXE_FUNCT_SFENCE) begin
                                aluop_o <= `EXE_OPER_SFENCE;
                                alusel_o <= `EXE_RES_INTERRUPT;
                                wreg_o <= `WriteDisable;
                                instvalid <= `InstValid;
                                reg1_read_o <= 1'b0; reg2_read_o <= 1'b0;
                                excepttype_is_sfence <= `True_v;
                            end else begin
                                case(funct25)
                                    `EXE_FUNCT_EBREAK:begin
                                        // EBREAK指令
                                        aluop_o <= `EXE_OPER_EBREAK;
                                        alusel_o <= `EXE_RES_INTERRUPT;
                                        wreg_o <= `WriteDisable;
                                        instvalid <= `InstValid;
                                        reg1_read_o <= 1'b0; reg2_read_o <= 1'b0;
                                        excepttype_is_ebreak <= `True_v;
                                    end
                                    `EXE_FUNCT_ECALL:begin
                                        // ECALL指令
                                        aluop_o <= `EXE_OPER_ECALL;
                                        alusel_o <= `EXE_RES_INTERRUPT;
                                        instvalid <= `InstValid;
                                        excepttype_is_ecall <= `True_v;
                                        wreg_o <= `WriteDisable;
                                        reg1_read_o <= 1'b0; reg2_read_o <= 1'b0;
                                    end
                                    `EXE_FUNCT_MRET:begin
                                        // MRET指令
                                        aluop_o <= `EXE_OPER_MRET;
                                        alusel_o <= `EXE_RES_INTERRUPT;
                                        instvalid <= `InstValid;
                                        excepttype_is_mret <= `True_v;
                                        wreg_o <= `WriteDisable;
                                        reg1_read_o <= 1'b0; reg2_read_o <= 1'b0;
                                    end
                                endcase
                            end
                            
                        end
                    endcase
                end
                default: begin
                end
            endcase
        end
    end

    always @ (*) begin
        stallreq_for_reg1_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;
        end else if (pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o && reg1_read_o == 1'b1) begin
            stallreq_for_reg1_loadrelate <= `Stop;
            reg1_o <= reg1_o;
        end else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg1_addr_o)) begin                       
			//reg1_o <= ex_wdata_i; 
            if(reg1_addr_o == 5'b0) begin
                reg1_o <= 32'b0 ;
            end else begin 
                reg1_o <= ex_wdata_i;
            end
		end else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg1_addr_o)) begin
			//reg1_o <= mem_wdata_i;
            if(reg1_addr_o == 5'b0) begin
                reg1_o <= 32'b0 ;
            end else begin
                reg1_o <= mem_wdata_i; 
            end
        end else if(reg1_read_o == 1'b1) begin
            reg1_o <= reg1_data_i;
        end else if(reg1_read_o == 1'b0) begin
            reg1_o <= imm;
        end else begin
            reg1_o <= `ZeroWord;
        end
	end
	
	always @ (*) begin
        stallreq_for_reg2_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
        end else if (pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o && reg2_read_o == 1'b1) begin
            stallreq_for_reg2_loadrelate <= `Stop;
            reg2_o <= reg2_o;
        end 
        else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg2_addr_o)) begin
			//reg2_o <= ex_wdata_i; 
            if(reg2_addr_o == 5'b0) begin
                reg2_o <= 32'b0 ;
            end else begin 
                reg2_o <= ex_wdata_i;
            end
		end else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg2_addr_o)) begin
			//reg2_o <= mem_wdata_i;	
            if(reg2_addr_o == 5'b0) begin
                reg2_o <= 32'b0 ;
            end else begin
                reg2_o <= mem_wdata_i; 
            end
        end else if(reg2_read_o == 1'b1) begin
            reg2_o <= reg2_data_i;
        end else if(reg2_read_o == 1'b0) begin
            reg2_o <= imm;
        end else begin
            reg2_o <= `ZeroWord;
        end
	end

endmodule
