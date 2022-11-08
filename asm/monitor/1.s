    .org 0x0
    .global _start
    

    .section .rodata
monitor_version:
    .asciz "MONITOR for RISC-V - initialized."
    .text
_start:
WELCOME:
    la s1, monitor_version          # 装入启动信息 0 and 1
    lb a0, 0(s1)
.Loop0:
    addi s1, s1, 0x1
    jal WRITE_SERIAL                # 调用串口写函数 3
    lb a0, 0(s1)
    bne a0, zero, .Loop0   

WRITE_SERIAL:                       # 写串口：将a0的低八位写入串口
    lui t0, 0x10000 # 6
.TESTW:
    lb t1, 5(t0)  # 查看串口状态 7
    andi t1, t1, 32    # 截取写状态位 8
    bne t1, zero, .WSERIAL          # 状态位非零可写进入写 9
    j .TESTW                        # 检测验证，忙等待 a
.WSERIAL:
    sb a0, 0(t0)  # 写入寄存器a0中的值 b
    jr ra
