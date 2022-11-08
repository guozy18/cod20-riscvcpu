.org 0x0
.global _start
.text

_start:
    lui t0, 0x80010
    ori s4, zero, 0x11
    sw  s4, 0x20(t0)

    csrr t3, mtvec
    sw  t3, 0x24(t0)

    la s0, EXCEPTION_HANDLER
    csrw mtvec, s0

    sw  s0, 0x20(t0)
    

    csrr t3, mtvec
    sw  t3, 0x28(t0)

    la s10, user
    csrw mepc, s10
    sw s10, 0x30(t0)
    csrr t3, mepc
    sw t3, 0x34(t0)
    li a0, 0x1800
    csrc mstatus, a0

    la ra, user_ret
    addi s5, zero, 0x1
    mret
    addi s5, s5, 0x1
    addi s5, s5, 0x1
    addi s5, s5, 0x1
    addi s5, s5, 0x1
    addi s5, s5, 0x1
    addi s5, s5, 0x1
    addi s5, s5, 0x1

    sw  s5, 0x18(t0)

EXCEPTION_HANDLER:
    csrrw sp, mscratch, sp

    sw s5, 0(t0)
    sw t2, 4(t0)
    sw s6, 8(t0)
    sw s7, 0xc(t0)
    mret
    ori t3, zero, 0x233
    sw  t3, 0x50(t0)
    j done

user:
    csrr t3, mtvec
    sw  t3, 0x1c(t0)
    ori s4, zero, 0x22
    sw  s4, 0x14(t0)
    ori t2, zero, 0x444
    csrr t3, mepc
    sw  t3, 0x38(t0)
    csrr t3, mcause
    sw  t3, 0x40(t0)
    auipc t3, 0x0
    sw t3, 0x54(t0)
    ecall
    csrr t3, mcause
    sw  t3, 0x44(t0)
    csrr t3, mepc
    sw  t3, 0x3c(t0)
    addi s6, zero, 0x1                 
    addi s6, s6, 0x1
    addi s6, s6, 0x1
    addi s6, s6, 0x1
    addi s6, s6, 0x1
    addi s6, s6, 0x1
    addi s6, s6, 0x1
    addi s6, s6, 0x1
user_ret:
    ori t2, zero, 0x555
    addi s7, zero, 0x77
    addi s5, s5, 0x20
    addi s5, s5, 0x1
    addi s5, s5, 0x1
    addi s5, s5, 0x1
    addi s5, s5, 0x1
    addi s5, s5, 0x1
    addi s5, s5, 0x1
    addi s5, s5, 0x1

    sw s5, 0(t0)
    sw t2, 4(t0)
    sw s6, 8(t0)
    sw s7, 0xc(t0)
done:
    addi t2, zero, 0x666
