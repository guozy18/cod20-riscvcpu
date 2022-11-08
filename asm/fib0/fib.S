    .org 0x0
    .global _start
    .text

_start:
    ori t0, zero, 0x1   # t0 = 1 0
    ori t1, zero, 0x1   # t1 = 1 1
    ori s1, zero, 0x4   # s1 = 4 2
    lui t5, 0x80002 # 3
    addi t5, t5, 0x7fc # 4
    # ori t5, zero, 0x7fc # t5 = 0x7fc 3
    lui a0, 0x80002 # 0x80000000 0x00400000 5
    # addi a0, a0, 0x100 # 6
    # ori a0, zero, 0x100 # a0 = 0x100

1:
    add   t2, t0, t1    # t2 = t0+t1 7
    ori   t0, t1, 0x0   # t0 = t1 7
    ori   t1, t2, 0x0   # t1 = t2 8
    sw    t1, 0(a0) # 9
    add   a0, a0, s1    # a0 += 4 a

    beq   a0, t5, check # finished writing, start checking b
    beq   zero, zero, 1b # d

check:
    ori t0, zero, 0x1   # t0 = 1 e
    ori t1, zero, 0x1   # t1 = 1 f
    lui a0, 0x80002     # g
    # addi a0, a0, 0x100  # 10
    # ori a0, zero, 0x80000100 # a0 = 0x100

2:
    add   t2, t0, t1    # t2 = t0+t1 11
    ori   t0, t1, 0x0   # t0 = t1 12
    ori   t1, t2, 0x0   # t1 = t2 13
    lw    t3, 0(a0)     # 14
    beq   t1, t3, 3f    # good, continue 15
    beq   zero, zero, fail # 16
3:
    add   a0, a0, s1    # a0 += 4 17

    beq   a0, t5, succ  # finished checking 18
    beq   zero, zero, 2b # 19

succ:
    ori   t1, zero, 0x555 # t1 = 0x555 1a
    sw    t1, 0(a0)     # write a flag 1b
fail:
end:
    beq   zero, zero, end # 1d
