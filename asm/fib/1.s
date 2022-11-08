	.org 0x0
.global _start
_start:
    # 80100000 <_start>:
ori     t0,zero,1
ori     t1,zero,1
ori     s1,zero,4
lui     t5,0x80400
addi    t5,t5,2044 # 804007fc <__global_pointer$+0x2fef84>
lui     a0,0x80400
addi    a0,a0,256 # 80400100 <__global_pointer$+0x2fe888>
add     t2,t0,t1
ori     t0,t1,0
ori     t1,t2,0
sw      t1,0(a0)
add     a0,a0,s1
beq     a0,t5,0x80100038 # 0x80100038 # <check>
beqz    zero, 0x8010001c # <_start+0x1c>

    # 80100038 <check>:
ori     t0,zero,1
ori     t1,zero,1
lui     a0,0x80400
addi    a0,a0,256 # 80400100 <__global_pointer$+0x2fe888>
add     t2,t0,t1
ori     t0,t1,0
ori     t1,t2,0
lw      t3,0(a0)
beq     t1,t3,0x80100060 # <check+0x28>
beqz    zero,0x80100074 # <end>
add     a0,a0,s1
beq     a0,t5,0x8010006c # <succ>
beqz    zero, 0x80100048 # <check+0x10>

    # 8010006c <succ>:
ori     t1,zero,1365
sw      t1,0(a0)

    # 80100074 <end>:
ret
