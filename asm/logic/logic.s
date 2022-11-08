	.org 0x0
.global _start
_start:
   # lui  t0,0x0101
   ori  t0,zero,0x0101
   ori  t0,t0,0x0101
   ori  t1,t0,0x0011        # t1 = t0 | 0x1100 = 0x01011101
   or   t0,t0,t1            # t0 = t0 | t1 = 0x01011101
   andi t2,t0,0x00fe        # t2 = t0 & 0x00fe = 0x00000000
   and  t0,t2,t0            # t0 = t2 & t0 = 0x00000000
   xori t3,t0,0x00ff        # t3 = t0 ^ 0xff00 = 0x0000ff00
   xor  t0,t3,t0            # t0 = t3 ^ t0 = 0x0000ff00
   # nor  t0,t3,t0            # t0 = t3 ~^ t0 = 0xffff00ff 
