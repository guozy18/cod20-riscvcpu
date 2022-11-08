.org 0x0
.global _start
.text

_start:
    ori a0, zero, 0x23   # t0 = 1 0
    lui t0, 0x10000
    sb	a0,0(t0)

.TESTR:
    lb t1, 5(t0)
    andi t1, t1, 1
    bnez t1,.RSERIAL
    j .TESTR

.RSERIAL:
    lb	a1,0(t0)
    j .TESTR
