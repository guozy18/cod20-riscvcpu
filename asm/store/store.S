.org 0x0
.global _start
.text

_start:
    lui a0, 0x80000 
    addi a0, a0, 0x100 # 6
    ori t1, zero, 0x233 
    sw t1, 0(a0) # 23 A0 65 00
    lw t2, 0(a0)
    ori t1, zero, 0x233 
    ori t1, zero, 0x233 
    ori t1, zero, 0x233 
    ori t1, zero, 0x233 
    ori t1, zero, 0x233 
