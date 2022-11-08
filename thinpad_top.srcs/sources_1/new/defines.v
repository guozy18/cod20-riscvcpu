// constants
`define RstEnable 1'b1
`define RstDisable 1'b0
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0
`define ChipEnable 1'b1
`define ChipDisable 1'b0
`define InstValid 1'b0
`define InstInvalid 1'b1
`define Stop 1'b1
`define NoStop 1'b0
`define Branch 1'b1
`define NotBranch 1'b0
`define True_v 1'b1
`define False_v 1'b0

`define USER_MODE 2'b00
`define SUPERVISOR_MODE 2'b01
`define MACHINE_MODE 2'b11

`define VIRTUAL_MODE_F 2'b00
`define VIRTUAL_MODE_S 2'b01
`define PHYSICAL_MODE  2'b10

`define ZeroWord 32'h00000000
`define AluOpBus 4:0
`define AluSelBus 3:0
`define StartPC 32'h80000000

// instructions
`define EXE_TYPE_R 7'b0110011
`define EXE_TYPE_I 7'b0010011
`define EXE_TYPE_S 7'b0100011
`define EXE_TYPE_B 7'b1100011
`define EXE_TYPE_L 7'b0000011

`define EXE_TYPE_INTERRUPT 7'b1110011

`define EXE_TYPE_LUI 7'b0110111
`define EXE_TYPE_JAL 7'b1101111
`define EXE_TYPE_JALR 7'b1100111
`define EXE_TYPE_AUIPC 7'b0010111

// R
`define EXE_FUNCT_ADD  3'b000
`define EXE_FUNCT_AND  3'b111
`define EXE_FUNCT_ORMINU  3'b110
`define EXE_FUNCT_XORMIN  3'b100
`define EXE_FUNCT_ORXOR 7'b0000000
`define EXE_FUNCT_MINMINU 7'b0000101
`define EXE_FUNCT_SFENCE 7'b0001001

`define EXE_FUNCT_CSRRC 3'b011
`define EXE_FUNCT_CSRRS 3'b010
`define EXE_FUNCT_CSRRW 3'b001
`define EXE_FUNCT_SYSCALL 3'b000
`define EXE_FUNCT_EBREAK 25'b0000000000010000000000000
`define EXE_FUNCT_ECALL 25'b0000000000000000000000000
`define EXE_FUNCT_MRET 25'b0011000000100000000000000


`define EXE_FUNCT_ADDI 3'b000
`define EXE_FUNCT_ORI  3'b110
`define EXE_FUNCT_ANDI 3'b111
`define EXE_FUNCT_SRLI 3'b101
`define EXE_FUNCT_SLLICTZ 3'b001
`define EXE_FUNCT_SLLI 7'b0000000
`define EXE_FUNCT_CTZ  7'b0110000

`define EXE_FUNCT_SB 3'b000
`define EXE_FUNCT_SW 3'b010

`define EXE_FUNCT_BEQ 3'b000
`define EXE_FUNCT_BNE 3'b001

`define EXE_FUNCT_LB 3'b000
`define EXE_FUNCT_LW 3'b010


//inst_rom
`define InstAddrBus 31:0
`define InstBus 31:0
`define InstMemNum 131071
`define InstMemNumLog2 17
`define AluOpBus 4:0

// Regfile
`define RegAddrBus 4:0
`define RegBus 31:0
`define RegNum 32
`define RegNumLog2 5
`define NOPRegAddr 5'b00000

// 定义运算类型（总体类型）
`define EXE_RES_NOP 4'b0000         // 空指令
`define EXE_RES_LOGIC 4'b0001       // 逻辑指令
`define EXE_RES_SHIFT 4'b0010       // 移位指令
`define EXE_RES_U 4'b0011	        // U型指令，即Lui,AUIPC,CTZ指令
`define EXE_RES_ARITHMETIC 4'b0100	// 算术运算指令
`define EXE_RES_MIN 4'b0101         // MIN.MINU两条拓展指令
`define EXE_RES_JUMP_BRANCH 4'b0110 // 跳转指令
`define EXE_RES_LOAD_STORE 4'b0111  // 访存指令
`define EXE_RES_INTERRUPT 4'b1000   // 中断指令
`define EXE_RES_CSR 4'b1001         // CSR指令


// 定义运算子类型
`define EXE_OPER_NOP 5'b00000
`define EXE_OPER_ADD 5'b00001
`define EXE_OPER_AND 5'b00010
`define EXE_OPER_OR  5'b00011
`define EXE_OPER_XOR 5'b00100
`define EXE_OPER_MIN 5'b00101
`define EXE_OPER_MINU 5'b00110
`define EXE_OPER_ADDI 5'b00111
`define EXE_OPER_ANDI 5'b01000
`define EXE_OPER_ORI  5'b01001
`define EXE_OPER_SLLI 5'b01010
`define EXE_OPER_SRLI 5'b01011
`define EXE_OPER_CTZ  5'b01100
`define EXE_OPER_SB   5'b01101
`define EXE_OPER_SW   5'b01110
`define EXE_OPER_BEQ  5'b01111
`define EXE_OPER_BNE  5'b10000
`define EXE_OPER_LUI  5'b10001
`define EXE_OPER_JAL  5'b10010
`define EXE_OPER_JALR 5'b10011
`define EXE_OPER_LB   5'b10100
`define EXE_OPER_LW   5'b10101
`define EXE_OPER_AUIPC 5'b10110
`define EXE_OPER_CSRRC 5'b10111
`define EXE_OPER_CSRRS 5'b11000
`define EXE_OPER_CSRRW 5'b11001 
`define EXE_OPER_EBREAK 5'b11010 
`define EXE_OPER_ECALL 5'b11011 
`define EXE_OPER_MRET 5'b11100 //csr寄存器地址
`define EXE_OPER_SFENCE 5'b11101 // 异常

//machine mode
`define CSR_REG_MSTATUS 12'h300
`define CSR_REG_MTVEC 12'h305
`define CSR_REG_MSCRATCH 12'h340
`define CSR_REG_MEPC 12'h341
`define CSR_REG_MCAUSE 12'h342
`define CSR_REG_MTVAL 12'h343

//supervisor mode
`define CSR_REG_SATP 12'h180
