
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	88013103          	ld	sp,-1920(sp) # 80008880 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	ff070713          	addi	a4,a4,-16 # 80009040 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	afe78793          	addi	a5,a5,-1282 # 80005b60 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e0278793          	addi	a5,a5,-510 # 80000eae <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  timerinit();
    800000d6:	00000097          	auipc	ra,0x0
    800000da:	f46080e7          	jalr	-186(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000de:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e6:	30200073          	mret
}
    800000ea:	60a2                	ld	ra,8(sp)
    800000ec:	6402                	ld	s0,0(sp)
    800000ee:	0141                	addi	sp,sp,16
    800000f0:	8082                	ret

00000000800000f2 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f2:	715d                	addi	sp,sp,-80
    800000f4:	e486                	sd	ra,72(sp)
    800000f6:	e0a2                	sd	s0,64(sp)
    800000f8:	fc26                	sd	s1,56(sp)
    800000fa:	f84a                	sd	s2,48(sp)
    800000fc:	f44e                	sd	s3,40(sp)
    800000fe:	f052                	sd	s4,32(sp)
    80000100:	ec56                	sd	s5,24(sp)
    80000102:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000104:	04c05763          	blez	a2,80000152 <consolewrite+0x60>
    80000108:	8a2a                	mv	s4,a0
    8000010a:	84ae                	mv	s1,a1
    8000010c:	89b2                	mv	s3,a2
    8000010e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000110:	5afd                	li	s5,-1
    80000112:	4685                	li	a3,1
    80000114:	8626                	mv	a2,s1
    80000116:	85d2                	mv	a1,s4
    80000118:	fbf40513          	addi	a0,s0,-65
    8000011c:	00002097          	auipc	ra,0x2
    80000120:	362080e7          	jalr	866(ra) # 8000247e <either_copyin>
    80000124:	01550d63          	beq	a0,s5,8000013e <consolewrite+0x4c>
      break;
    uartputc(c);
    80000128:	fbf44503          	lbu	a0,-65(s0)
    8000012c:	00000097          	auipc	ra,0x0
    80000130:	77e080e7          	jalr	1918(ra) # 800008aa <uartputc>
  for(i = 0; i < n; i++){
    80000134:	2905                	addiw	s2,s2,1
    80000136:	0485                	addi	s1,s1,1
    80000138:	fd299de3          	bne	s3,s2,80000112 <consolewrite+0x20>
    8000013c:	894e                	mv	s2,s3
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4c>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aaa                	mv	s5,a0
    80000174:	8a2e                	mv	s4,a1
    80000176:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	ff448493          	addi	s1,s1,-12 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	08490913          	addi	s2,s2,132 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00002097          	auipc	ra,0x2
    800001b6:	80e080e7          	jalr	-2034(ra) # 800019c0 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	ec2080e7          	jalr	-318(ra) # 80002084 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00002097          	auipc	ra,0x2
    80000202:	22a080e7          	jalr	554(ra) # 80002428 <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00011517          	auipc	a0,0x11
    80000216:	f6e50513          	addi	a0,a0,-146 # 80011180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00011717          	auipc	a4,0x11
    80000262:	faf72d23          	sw	a5,-70(a4) # 80011218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	560080e7          	jalr	1376(ra) # 800007d8 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54e080e7          	jalr	1358(ra) # 800007d8 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	542080e7          	jalr	1346(ra) # 800007d8 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	538080e7          	jalr	1336(ra) # 800007d8 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00011517          	auipc	a0,0x11
    800002bc:	ec850513          	addi	a0,a0,-312 # 80011180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00002097          	auipc	ra,0x2
    800002e2:	1f6080e7          	jalr	502(ra) # 800024d4 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00011717          	auipc	a4,0x11
    8000030e:	e7670713          	addi	a4,a4,-394 # 80011180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00011797          	auipc	a5,0x11
    80000338:	e4c78793          	addi	a5,a5,-436 # 80011180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00011797          	auipc	a5,0x11
    80000366:	eb67a783          	lw	a5,-330(a5) # 80011218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80011180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00011717          	auipc	a4,0x11
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80011180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00011797          	auipc	a5,0x11
    80000402:	d8278793          	addi	a5,a5,-638 # 80011180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dee50513          	addi	a0,a0,-530 # 80011218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	dde080e7          	jalr	-546(ra) # 80002210 <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00008597          	auipc	a1,0x8
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80008010 <etext+0x10>
    8000044c:	00011517          	auipc	a0,0x11
    80000450:	d3450513          	addi	a0,a0,-716 # 80011180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32c080e7          	jalr	812(ra) # 80000788 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00021797          	auipc	a5,0x21
    80000468:	eb478793          	addi	a5,a5,-332 # 80021318 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7c70713          	addi	a4,a4,-900 # 800000f2 <consolewrite>
    8000047e:	ef98                	sd	a4,24(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054763          	bltz	a0,80000524 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00008617          	auipc	a2,0x8
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80008040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088c63          	beqz	a7,800004ea <printint+0x62>
    buf[i++] = '-';
    800004d6:	fe070793          	addi	a5,a4,-32
    800004da:	00878733          	add	a4,a5,s0
    800004de:	02d00793          	li	a5,45
    800004e2:	fef70823          	sb	a5,-16(a4)
    800004e6:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004ea:	02e05763          	blez	a4,80000518 <printint+0x90>
    800004ee:	fd040793          	addi	a5,s0,-48
    800004f2:	00e784b3          	add	s1,a5,a4
    800004f6:	fff78913          	addi	s2,a5,-1
    800004fa:	993a                	add	s2,s2,a4
    800004fc:	377d                	addiw	a4,a4,-1
    800004fe:	1702                	slli	a4,a4,0x20
    80000500:	9301                	srli	a4,a4,0x20
    80000502:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000506:	fff4c503          	lbu	a0,-1(s1)
    8000050a:	00000097          	auipc	ra,0x0
    8000050e:	d5e080e7          	jalr	-674(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000512:	14fd                	addi	s1,s1,-1
    80000514:	ff2499e3          	bne	s1,s2,80000506 <printint+0x7e>
}
    80000518:	70a2                	ld	ra,40(sp)
    8000051a:	7402                	ld	s0,32(sp)
    8000051c:	64e2                	ld	s1,24(sp)
    8000051e:	6942                	ld	s2,16(sp)
    80000520:	6145                	addi	sp,sp,48
    80000522:	8082                	ret
    x = -xx;
    80000524:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000528:	4885                	li	a7,1
    x = -xx;
    8000052a:	bf95                	j	8000049e <printint+0x16>

000000008000052c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052c:	1101                	addi	sp,sp,-32
    8000052e:	ec06                	sd	ra,24(sp)
    80000530:	e822                	sd	s0,16(sp)
    80000532:	e426                	sd	s1,8(sp)
    80000534:	1000                	addi	s0,sp,32
    80000536:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000538:	00011797          	auipc	a5,0x11
    8000053c:	d007a423          	sw	zero,-760(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000540:	00008517          	auipc	a0,0x8
    80000544:	ad850513          	addi	a0,a0,-1320 # 80008018 <etext+0x18>
    80000548:	00000097          	auipc	ra,0x0
    8000054c:	02e080e7          	jalr	46(ra) # 80000576 <printf>
  printf(s);
    80000550:	8526                	mv	a0,s1
    80000552:	00000097          	auipc	ra,0x0
    80000556:	024080e7          	jalr	36(ra) # 80000576 <printf>
  printf("\n");
    8000055a:	00008517          	auipc	a0,0x8
    8000055e:	b6e50513          	addi	a0,a0,-1170 # 800080c8 <digits+0x88>
    80000562:	00000097          	auipc	ra,0x0
    80000566:	014080e7          	jalr	20(ra) # 80000576 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000056a:	4785                	li	a5,1
    8000056c:	00009717          	auipc	a4,0x9
    80000570:	a8f72a23          	sw	a5,-1388(a4) # 80009000 <panicked>
  for(;;)
    80000574:	a001                	j	80000574 <panic+0x48>

0000000080000576 <printf>:
{
    80000576:	7131                	addi	sp,sp,-192
    80000578:	fc86                	sd	ra,120(sp)
    8000057a:	f8a2                	sd	s0,112(sp)
    8000057c:	f4a6                	sd	s1,104(sp)
    8000057e:	f0ca                	sd	s2,96(sp)
    80000580:	ecce                	sd	s3,88(sp)
    80000582:	e8d2                	sd	s4,80(sp)
    80000584:	e4d6                	sd	s5,72(sp)
    80000586:	e0da                	sd	s6,64(sp)
    80000588:	fc5e                	sd	s7,56(sp)
    8000058a:	f862                	sd	s8,48(sp)
    8000058c:	f466                	sd	s9,40(sp)
    8000058e:	f06a                	sd	s10,32(sp)
    80000590:	ec6e                	sd	s11,24(sp)
    80000592:	0100                	addi	s0,sp,128
    80000594:	8a2a                	mv	s4,a0
    80000596:	e40c                	sd	a1,8(s0)
    80000598:	e810                	sd	a2,16(s0)
    8000059a:	ec14                	sd	a3,24(s0)
    8000059c:	f018                	sd	a4,32(s0)
    8000059e:	f41c                	sd	a5,40(s0)
    800005a0:	03043823          	sd	a6,48(s0)
    800005a4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a8:	00011d97          	auipc	s11,0x11
    800005ac:	c98dad83          	lw	s11,-872(s11) # 80011240 <pr+0x18>
  if(locking)
    800005b0:	020d9b63          	bnez	s11,800005e6 <printf+0x70>
  if (fmt == 0)
    800005b4:	040a0263          	beqz	s4,800005f8 <printf+0x82>
  va_start(ap, fmt);
    800005b8:	00840793          	addi	a5,s0,8
    800005bc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c0:	000a4503          	lbu	a0,0(s4)
    800005c4:	14050f63          	beqz	a0,80000722 <printf+0x1ac>
    800005c8:	4981                	li	s3,0
    if(c != '%'){
    800005ca:	02500a93          	li	s5,37
    switch(c){
    800005ce:	07000b93          	li	s7,112
  consputc('x');
    800005d2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d4:	00008b17          	auipc	s6,0x8
    800005d8:	a6cb0b13          	addi	s6,s6,-1428 # 80008040 <digits>
    switch(c){
    800005dc:	07300c93          	li	s9,115
    800005e0:	06400c13          	li	s8,100
    800005e4:	a82d                	j	8000061e <printf+0xa8>
    acquire(&pr.lock);
    800005e6:	00011517          	auipc	a0,0x11
    800005ea:	c4250513          	addi	a0,a0,-958 # 80011228 <pr>
    800005ee:	00000097          	auipc	ra,0x0
    800005f2:	5d4080e7          	jalr	1492(ra) # 80000bc2 <acquire>
    800005f6:	bf7d                	j	800005b4 <printf+0x3e>
    panic("null fmt");
    800005f8:	00008517          	auipc	a0,0x8
    800005fc:	a3050513          	addi	a0,a0,-1488 # 80008028 <etext+0x28>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	f2c080e7          	jalr	-212(ra) # 8000052c <panic>
      consputc(c);
    80000608:	00000097          	auipc	ra,0x0
    8000060c:	c60080e7          	jalr	-928(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000610:	2985                	addiw	s3,s3,1
    80000612:	013a07b3          	add	a5,s4,s3
    80000616:	0007c503          	lbu	a0,0(a5)
    8000061a:	10050463          	beqz	a0,80000722 <printf+0x1ac>
    if(c != '%'){
    8000061e:	ff5515e3          	bne	a0,s5,80000608 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c783          	lbu	a5,0(a5)
    8000062c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000630:	cbed                	beqz	a5,80000722 <printf+0x1ac>
    switch(c){
    80000632:	05778a63          	beq	a5,s7,80000686 <printf+0x110>
    80000636:	02fbf663          	bgeu	s7,a5,80000662 <printf+0xec>
    8000063a:	09978863          	beq	a5,s9,800006ca <printf+0x154>
    8000063e:	07800713          	li	a4,120
    80000642:	0ce79563          	bne	a5,a4,8000070c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000646:	f8843783          	ld	a5,-120(s0)
    8000064a:	00878713          	addi	a4,a5,8
    8000064e:	f8e43423          	sd	a4,-120(s0)
    80000652:	4605                	li	a2,1
    80000654:	85ea                	mv	a1,s10
    80000656:	4388                	lw	a0,0(a5)
    80000658:	00000097          	auipc	ra,0x0
    8000065c:	e30080e7          	jalr	-464(ra) # 80000488 <printint>
      break;
    80000660:	bf45                	j	80000610 <printf+0x9a>
    switch(c){
    80000662:	09578f63          	beq	a5,s5,80000700 <printf+0x18a>
    80000666:	0b879363          	bne	a5,s8,8000070c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000066a:	f8843783          	ld	a5,-120(s0)
    8000066e:	00878713          	addi	a4,a5,8
    80000672:	f8e43423          	sd	a4,-120(s0)
    80000676:	4605                	li	a2,1
    80000678:	45a9                	li	a1,10
    8000067a:	4388                	lw	a0,0(a5)
    8000067c:	00000097          	auipc	ra,0x0
    80000680:	e0c080e7          	jalr	-500(ra) # 80000488 <printint>
      break;
    80000684:	b771                	j	80000610 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000696:	03000513          	li	a0,48
    8000069a:	00000097          	auipc	ra,0x0
    8000069e:	bce080e7          	jalr	-1074(ra) # 80000268 <consputc>
  consputc('x');
    800006a2:	07800513          	li	a0,120
    800006a6:	00000097          	auipc	ra,0x0
    800006aa:	bc2080e7          	jalr	-1086(ra) # 80000268 <consputc>
    800006ae:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006b0:	03c95793          	srli	a5,s2,0x3c
    800006b4:	97da                	add	a5,a5,s6
    800006b6:	0007c503          	lbu	a0,0(a5)
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bae080e7          	jalr	-1106(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c2:	0912                	slli	s2,s2,0x4
    800006c4:	34fd                	addiw	s1,s1,-1
    800006c6:	f4ed                	bnez	s1,800006b0 <printf+0x13a>
    800006c8:	b7a1                	j	80000610 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006ca:	f8843783          	ld	a5,-120(s0)
    800006ce:	00878713          	addi	a4,a5,8
    800006d2:	f8e43423          	sd	a4,-120(s0)
    800006d6:	6384                	ld	s1,0(a5)
    800006d8:	cc89                	beqz	s1,800006f2 <printf+0x17c>
      for(; *s; s++)
    800006da:	0004c503          	lbu	a0,0(s1)
    800006de:	d90d                	beqz	a0,80000610 <printf+0x9a>
        consputc(*s);
    800006e0:	00000097          	auipc	ra,0x0
    800006e4:	b88080e7          	jalr	-1144(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e8:	0485                	addi	s1,s1,1
    800006ea:	0004c503          	lbu	a0,0(s1)
    800006ee:	f96d                	bnez	a0,800006e0 <printf+0x16a>
    800006f0:	b705                	j	80000610 <printf+0x9a>
        s = "(null)";
    800006f2:	00008497          	auipc	s1,0x8
    800006f6:	92e48493          	addi	s1,s1,-1746 # 80008020 <etext+0x20>
      for(; *s; s++)
    800006fa:	02800513          	li	a0,40
    800006fe:	b7cd                	j	800006e0 <printf+0x16a>
      consputc('%');
    80000700:	8556                	mv	a0,s5
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b66080e7          	jalr	-1178(ra) # 80000268 <consputc>
      break;
    8000070a:	b719                	j	80000610 <printf+0x9a>
      consputc('%');
    8000070c:	8556                	mv	a0,s5
    8000070e:	00000097          	auipc	ra,0x0
    80000712:	b5a080e7          	jalr	-1190(ra) # 80000268 <consputc>
      consputc(c);
    80000716:	8526                	mv	a0,s1
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b50080e7          	jalr	-1200(ra) # 80000268 <consputc>
      break;
    80000720:	bdc5                	j	80000610 <printf+0x9a>
  if(locking)
    80000722:	020d9163          	bnez	s11,80000744 <printf+0x1ce>
}
    80000726:	70e6                	ld	ra,120(sp)
    80000728:	7446                	ld	s0,112(sp)
    8000072a:	74a6                	ld	s1,104(sp)
    8000072c:	7906                	ld	s2,96(sp)
    8000072e:	69e6                	ld	s3,88(sp)
    80000730:	6a46                	ld	s4,80(sp)
    80000732:	6aa6                	ld	s5,72(sp)
    80000734:	6b06                	ld	s6,64(sp)
    80000736:	7be2                	ld	s7,56(sp)
    80000738:	7c42                	ld	s8,48(sp)
    8000073a:	7ca2                	ld	s9,40(sp)
    8000073c:	7d02                	ld	s10,32(sp)
    8000073e:	6de2                	ld	s11,24(sp)
    80000740:	6129                	addi	sp,sp,192
    80000742:	8082                	ret
    release(&pr.lock);
    80000744:	00011517          	auipc	a0,0x11
    80000748:	ae450513          	addi	a0,a0,-1308 # 80011228 <pr>
    8000074c:	00000097          	auipc	ra,0x0
    80000750:	52a080e7          	jalr	1322(ra) # 80000c76 <release>
}
    80000754:	bfc9                	j	80000726 <printf+0x1b0>

0000000080000756 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000756:	1101                	addi	sp,sp,-32
    80000758:	ec06                	sd	ra,24(sp)
    8000075a:	e822                	sd	s0,16(sp)
    8000075c:	e426                	sd	s1,8(sp)
    8000075e:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000760:	00011497          	auipc	s1,0x11
    80000764:	ac848493          	addi	s1,s1,-1336 # 80011228 <pr>
    80000768:	00008597          	auipc	a1,0x8
    8000076c:	8d058593          	addi	a1,a1,-1840 # 80008038 <etext+0x38>
    80000770:	8526                	mv	a0,s1
    80000772:	00000097          	auipc	ra,0x0
    80000776:	3c0080e7          	jalr	960(ra) # 80000b32 <initlock>
  pr.locking = 1;
    8000077a:	4785                	li	a5,1
    8000077c:	cc9c                	sw	a5,24(s1)
}
    8000077e:	60e2                	ld	ra,24(sp)
    80000780:	6442                	ld	s0,16(sp)
    80000782:	64a2                	ld	s1,8(sp)
    80000784:	6105                	addi	sp,sp,32
    80000786:	8082                	ret

0000000080000788 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000788:	1141                	addi	sp,sp,-16
    8000078a:	e406                	sd	ra,8(sp)
    8000078c:	e022                	sd	s0,0(sp)
    8000078e:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000790:	100007b7          	lui	a5,0x10000
    80000794:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000798:	f8000713          	li	a4,-128
    8000079c:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007a0:	470d                	li	a4,3
    800007a2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007aa:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ae:	469d                	li	a3,7
    800007b0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b8:	00008597          	auipc	a1,0x8
    800007bc:	8a058593          	addi	a1,a1,-1888 # 80008058 <digits+0x18>
    800007c0:	00011517          	auipc	a0,0x11
    800007c4:	a8850513          	addi	a0,a0,-1400 # 80011248 <uart_tx_lock>
    800007c8:	00000097          	auipc	ra,0x0
    800007cc:	36a080e7          	jalr	874(ra) # 80000b32 <initlock>
}
    800007d0:	60a2                	ld	ra,8(sp)
    800007d2:	6402                	ld	s0,0(sp)
    800007d4:	0141                	addi	sp,sp,16
    800007d6:	8082                	ret

00000000800007d8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d8:	1101                	addi	sp,sp,-32
    800007da:	ec06                	sd	ra,24(sp)
    800007dc:	e822                	sd	s0,16(sp)
    800007de:	e426                	sd	s1,8(sp)
    800007e0:	1000                	addi	s0,sp,32
    800007e2:	84aa                	mv	s1,a0
  push_off();
    800007e4:	00000097          	auipc	ra,0x0
    800007e8:	392080e7          	jalr	914(ra) # 80000b76 <push_off>

  if(panicked){
    800007ec:	00009797          	auipc	a5,0x9
    800007f0:	8147a783          	lw	a5,-2028(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f4:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f8:	c391                	beqz	a5,800007fc <uartputc_sync+0x24>
    for(;;)
    800007fa:	a001                	j	800007fa <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fc:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000800:	0207f793          	andi	a5,a5,32
    80000804:	dfe5                	beqz	a5,800007fc <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000806:	0ff4f513          	zext.b	a0,s1
    8000080a:	100007b7          	lui	a5,0x10000
    8000080e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000812:	00000097          	auipc	ra,0x0
    80000816:	404080e7          	jalr	1028(ra) # 80000c16 <pop_off>
}
    8000081a:	60e2                	ld	ra,24(sp)
    8000081c:	6442                	ld	s0,16(sp)
    8000081e:	64a2                	ld	s1,8(sp)
    80000820:	6105                	addi	sp,sp,32
    80000822:	8082                	ret

0000000080000824 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000824:	00008797          	auipc	a5,0x8
    80000828:	7e47b783          	ld	a5,2020(a5) # 80009008 <uart_tx_r>
    8000082c:	00008717          	auipc	a4,0x8
    80000830:	7e473703          	ld	a4,2020(a4) # 80009010 <uart_tx_w>
    80000834:	06f70a63          	beq	a4,a5,800008a8 <uartstart+0x84>
{
    80000838:	7139                	addi	sp,sp,-64
    8000083a:	fc06                	sd	ra,56(sp)
    8000083c:	f822                	sd	s0,48(sp)
    8000083e:	f426                	sd	s1,40(sp)
    80000840:	f04a                	sd	s2,32(sp)
    80000842:	ec4e                	sd	s3,24(sp)
    80000844:	e852                	sd	s4,16(sp)
    80000846:	e456                	sd	s5,8(sp)
    80000848:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000084a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084e:	00011a17          	auipc	s4,0x11
    80000852:	9faa0a13          	addi	s4,s4,-1542 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000856:	00008497          	auipc	s1,0x8
    8000085a:	7b248493          	addi	s1,s1,1970 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085e:	00008997          	auipc	s3,0x8
    80000862:	7b298993          	addi	s3,s3,1970 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000086a:	02077713          	andi	a4,a4,32
    8000086e:	c705                	beqz	a4,80000896 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	01f7f713          	andi	a4,a5,31
    80000874:	9752                	add	a4,a4,s4
    80000876:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000087a:	0785                	addi	a5,a5,1
    8000087c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087e:	8526                	mv	a0,s1
    80000880:	00002097          	auipc	ra,0x2
    80000884:	990080e7          	jalr	-1648(ra) # 80002210 <wakeup>
    
    WriteReg(THR, c);
    80000888:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088c:	609c                	ld	a5,0(s1)
    8000088e:	0009b703          	ld	a4,0(s3)
    80000892:	fcf71ae3          	bne	a4,a5,80000866 <uartstart+0x42>
  }
}
    80000896:	70e2                	ld	ra,56(sp)
    80000898:	7442                	ld	s0,48(sp)
    8000089a:	74a2                	ld	s1,40(sp)
    8000089c:	7902                	ld	s2,32(sp)
    8000089e:	69e2                	ld	s3,24(sp)
    800008a0:	6a42                	ld	s4,16(sp)
    800008a2:	6aa2                	ld	s5,8(sp)
    800008a4:	6121                	addi	sp,sp,64
    800008a6:	8082                	ret
    800008a8:	8082                	ret

00000000800008aa <uartputc>:
{
    800008aa:	7179                	addi	sp,sp,-48
    800008ac:	f406                	sd	ra,40(sp)
    800008ae:	f022                	sd	s0,32(sp)
    800008b0:	ec26                	sd	s1,24(sp)
    800008b2:	e84a                	sd	s2,16(sp)
    800008b4:	e44e                	sd	s3,8(sp)
    800008b6:	e052                	sd	s4,0(sp)
    800008b8:	1800                	addi	s0,sp,48
    800008ba:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008bc:	00011517          	auipc	a0,0x11
    800008c0:	98c50513          	addi	a0,a0,-1652 # 80011248 <uart_tx_lock>
    800008c4:	00000097          	auipc	ra,0x0
    800008c8:	2fe080e7          	jalr	766(ra) # 80000bc2 <acquire>
  if(panicked){
    800008cc:	00008797          	auipc	a5,0x8
    800008d0:	7347a783          	lw	a5,1844(a5) # 80009000 <panicked>
    800008d4:	c391                	beqz	a5,800008d8 <uartputc+0x2e>
    for(;;)
    800008d6:	a001                	j	800008d6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d8:	00008717          	auipc	a4,0x8
    800008dc:	73873703          	ld	a4,1848(a4) # 80009010 <uart_tx_w>
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	7287b783          	ld	a5,1832(a5) # 80009008 <uart_tx_r>
    800008e8:	02078793          	addi	a5,a5,32
    800008ec:	02e79b63          	bne	a5,a4,80000922 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008f0:	00011997          	auipc	s3,0x11
    800008f4:	95898993          	addi	s3,s3,-1704 # 80011248 <uart_tx_lock>
    800008f8:	00008497          	auipc	s1,0x8
    800008fc:	71048493          	addi	s1,s1,1808 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000900:	00008917          	auipc	s2,0x8
    80000904:	71090913          	addi	s2,s2,1808 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000908:	85ce                	mv	a1,s3
    8000090a:	8526                	mv	a0,s1
    8000090c:	00001097          	auipc	ra,0x1
    80000910:	778080e7          	jalr	1912(ra) # 80002084 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000914:	00093703          	ld	a4,0(s2)
    80000918:	609c                	ld	a5,0(s1)
    8000091a:	02078793          	addi	a5,a5,32
    8000091e:	fee785e3          	beq	a5,a4,80000908 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000922:	00011497          	auipc	s1,0x11
    80000926:	92648493          	addi	s1,s1,-1754 # 80011248 <uart_tx_lock>
    8000092a:	01f77793          	andi	a5,a4,31
    8000092e:	97a6                	add	a5,a5,s1
    80000930:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000934:	0705                	addi	a4,a4,1
    80000936:	00008797          	auipc	a5,0x8
    8000093a:	6ce7bd23          	sd	a4,1754(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000093e:	00000097          	auipc	ra,0x0
    80000942:	ee6080e7          	jalr	-282(ra) # 80000824 <uartstart>
      release(&uart_tx_lock);
    80000946:	8526                	mv	a0,s1
    80000948:	00000097          	auipc	ra,0x0
    8000094c:	32e080e7          	jalr	814(ra) # 80000c76 <release>
}
    80000950:	70a2                	ld	ra,40(sp)
    80000952:	7402                	ld	s0,32(sp)
    80000954:	64e2                	ld	s1,24(sp)
    80000956:	6942                	ld	s2,16(sp)
    80000958:	69a2                	ld	s3,8(sp)
    8000095a:	6a02                	ld	s4,0(sp)
    8000095c:	6145                	addi	sp,sp,48
    8000095e:	8082                	ret

0000000080000960 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000960:	1141                	addi	sp,sp,-16
    80000962:	e422                	sd	s0,8(sp)
    80000964:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000966:	100007b7          	lui	a5,0x10000
    8000096a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096e:	8b85                	andi	a5,a5,1
    80000970:	cb81                	beqz	a5,80000980 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000972:	100007b7          	lui	a5,0x10000
    80000976:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000097a:	6422                	ld	s0,8(sp)
    8000097c:	0141                	addi	sp,sp,16
    8000097e:	8082                	ret
    return -1;
    80000980:	557d                	li	a0,-1
    80000982:	bfe5                	j	8000097a <uartgetc+0x1a>

0000000080000984 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000984:	1101                	addi	sp,sp,-32
    80000986:	ec06                	sd	ra,24(sp)
    80000988:	e822                	sd	s0,16(sp)
    8000098a:	e426                	sd	s1,8(sp)
    8000098c:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000098e:	54fd                	li	s1,-1
    80000990:	a029                	j	8000099a <uartintr+0x16>
      break;
    consoleintr(c);
    80000992:	00000097          	auipc	ra,0x0
    80000996:	918080e7          	jalr	-1768(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099a:	00000097          	auipc	ra,0x0
    8000099e:	fc6080e7          	jalr	-58(ra) # 80000960 <uartgetc>
    if(c == -1)
    800009a2:	fe9518e3          	bne	a0,s1,80000992 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a6:	00011497          	auipc	s1,0x11
    800009aa:	8a248493          	addi	s1,s1,-1886 # 80011248 <uart_tx_lock>
    800009ae:	8526                	mv	a0,s1
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	212080e7          	jalr	530(ra) # 80000bc2 <acquire>
  uartstart();
    800009b8:	00000097          	auipc	ra,0x0
    800009bc:	e6c080e7          	jalr	-404(ra) # 80000824 <uartstart>
  release(&uart_tx_lock);
    800009c0:	8526                	mv	a0,s1
    800009c2:	00000097          	auipc	ra,0x0
    800009c6:	2b4080e7          	jalr	692(ra) # 80000c76 <release>
}
    800009ca:	60e2                	ld	ra,24(sp)
    800009cc:	6442                	ld	s0,16(sp)
    800009ce:	64a2                	ld	s1,8(sp)
    800009d0:	6105                	addi	sp,sp,32
    800009d2:	8082                	ret

00000000800009d4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	e04a                	sd	s2,0(sp)
    800009de:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009e0:	03451793          	slli	a5,a0,0x34
    800009e4:	ebb9                	bnez	a5,80000a3a <kfree+0x66>
    800009e6:	84aa                	mv	s1,a0
    800009e8:	00025797          	auipc	a5,0x25
    800009ec:	61878793          	addi	a5,a5,1560 # 80026000 <end>
    800009f0:	04f56563          	bltu	a0,a5,80000a3a <kfree+0x66>
    800009f4:	47c5                	li	a5,17
    800009f6:	07ee                	slli	a5,a5,0x1b
    800009f8:	04f57163          	bgeu	a0,a5,80000a3a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fc:	6605                	lui	a2,0x1
    800009fe:	4585                	li	a1,1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	2be080e7          	jalr	702(ra) # 80000cbe <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a08:	00011917          	auipc	s2,0x11
    80000a0c:	87890913          	addi	s2,s2,-1928 # 80011280 <kmem>
    80000a10:	854a                	mv	a0,s2
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	1b0080e7          	jalr	432(ra) # 80000bc2 <acquire>
  r->next = kmem.freelist;
    80000a1a:	01893783          	ld	a5,24(s2)
    80000a1e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a20:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	250080e7          	jalr	592(ra) # 80000c76 <release>
}
    80000a2e:	60e2                	ld	ra,24(sp)
    80000a30:	6442                	ld	s0,16(sp)
    80000a32:	64a2                	ld	s1,8(sp)
    80000a34:	6902                	ld	s2,0(sp)
    80000a36:	6105                	addi	sp,sp,32
    80000a38:	8082                	ret
    panic("kfree");
    80000a3a:	00007517          	auipc	a0,0x7
    80000a3e:	62650513          	addi	a0,a0,1574 # 80008060 <digits+0x20>
    80000a42:	00000097          	auipc	ra,0x0
    80000a46:	aea080e7          	jalr	-1302(ra) # 8000052c <panic>

0000000080000a4a <freerange>:
{
    80000a4a:	7179                	addi	sp,sp,-48
    80000a4c:	f406                	sd	ra,40(sp)
    80000a4e:	f022                	sd	s0,32(sp)
    80000a50:	ec26                	sd	s1,24(sp)
    80000a52:	e84a                	sd	s2,16(sp)
    80000a54:	e44e                	sd	s3,8(sp)
    80000a56:	e052                	sd	s4,0(sp)
    80000a58:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a5a:	6785                	lui	a5,0x1
    80000a5c:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a60:	00e504b3          	add	s1,a0,a4
    80000a64:	777d                	lui	a4,0xfffff
    80000a66:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a68:	94be                	add	s1,s1,a5
    80000a6a:	0095ee63          	bltu	a1,s1,80000a86 <freerange+0x3c>
    80000a6e:	892e                	mv	s2,a1
    kfree(p);
    80000a70:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a72:	6985                	lui	s3,0x1
    kfree(p);
    80000a74:	01448533          	add	a0,s1,s4
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	f5c080e7          	jalr	-164(ra) # 800009d4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	94ce                	add	s1,s1,s3
    80000a82:	fe9979e3          	bgeu	s2,s1,80000a74 <freerange+0x2a>
}
    80000a86:	70a2                	ld	ra,40(sp)
    80000a88:	7402                	ld	s0,32(sp)
    80000a8a:	64e2                	ld	s1,24(sp)
    80000a8c:	6942                	ld	s2,16(sp)
    80000a8e:	69a2                	ld	s3,8(sp)
    80000a90:	6a02                	ld	s4,0(sp)
    80000a92:	6145                	addi	sp,sp,48
    80000a94:	8082                	ret

0000000080000a96 <kinit>:
{
    80000a96:	1141                	addi	sp,sp,-16
    80000a98:	e406                	sd	ra,8(sp)
    80000a9a:	e022                	sd	s0,0(sp)
    80000a9c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a9e:	00007597          	auipc	a1,0x7
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80008068 <digits+0x28>
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80011280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	00025517          	auipc	a0,0x25
    80000abe:	54650513          	addi	a0,a0,1350 # 80026000 <end>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	f88080e7          	jalr	-120(ra) # 80000a4a <freerange>
}
    80000aca:	60a2                	ld	ra,8(sp)
    80000acc:	6402                	ld	s0,0(sp)
    80000ace:	0141                	addi	sp,sp,16
    80000ad0:	8082                	ret

0000000080000ad2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ad2:	1101                	addi	sp,sp,-32
    80000ad4:	ec06                	sd	ra,24(sp)
    80000ad6:	e822                	sd	s0,16(sp)
    80000ad8:	e426                	sd	s1,8(sp)
    80000ada:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000adc:	00010497          	auipc	s1,0x10
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80011280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00010517          	auipc	a0,0x10
    80000af8:	78c50513          	addi	a0,a0,1932 # 80011280 <kmem>
    80000afc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	178080e7          	jalr	376(ra) # 80000c76 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1b2080e7          	jalr	434(ra) # 80000cbe <memset>
  return (void*)r;
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
  release(&kmem.lock);
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
  if(r)
    80000b30:	b7d5                	j	80000b14 <kalloc+0x42>

0000000080000b32 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b32:	1141                	addi	sp,sp,-16
    80000b34:	e422                	sd	s0,8(sp)
    80000b36:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b38:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b3a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b3e:	00053823          	sd	zero,16(a0)
}
    80000b42:	6422                	ld	s0,8(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b48:	411c                	lw	a5,0(a0)
    80000b4a:	e399                	bnez	a5,80000b50 <holding+0x8>
    80000b4c:	4501                	li	a0,0
  return r;
}
    80000b4e:	8082                	ret
{
    80000b50:	1101                	addi	sp,sp,-32
    80000b52:	ec06                	sd	ra,24(sp)
    80000b54:	e822                	sd	s0,16(sp)
    80000b56:	e426                	sd	s1,8(sp)
    80000b58:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b5a:	6904                	ld	s1,16(a0)
    80000b5c:	00001097          	auipc	ra,0x1
    80000b60:	e48080e7          	jalr	-440(ra) # 800019a4 <mycpu>
    80000b64:	40a48533          	sub	a0,s1,a0
    80000b68:	00153513          	seqz	a0,a0
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret

0000000080000b76 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b80:	100024f3          	csrr	s1,sstatus
    80000b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b8a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b8e:	00001097          	auipc	ra,0x1
    80000b92:	e16080e7          	jalr	-490(ra) # 800019a4 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	e0a080e7          	jalr	-502(ra) # 800019a4 <mycpu>
    80000ba2:	5d3c                	lw	a5,120(a0)
    80000ba4:	2785                	addiw	a5,a5,1
    80000ba6:	dd3c                	sw	a5,120(a0)
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret
    mycpu()->intena = old;
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	df2080e7          	jalr	-526(ra) # 800019a4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bba:	8085                	srli	s1,s1,0x1
    80000bbc:	8885                	andi	s1,s1,1
    80000bbe:	dd64                	sw	s1,124(a0)
    80000bc0:	bfe9                	j	80000b9a <push_off+0x24>

0000000080000bc2 <acquire>:
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
    80000bcc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	fa8080e7          	jalr	-88(ra) # 80000b76 <push_off>
  if(holding(lk))
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk))
    80000be2:	e115                	bnez	a0,80000c06 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	87ba                	mv	a5,a4
    80000be6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bea:	2781                	sext.w	a5,a5
    80000bec:	ffe5                	bnez	a5,80000be4 <acquire+0x22>
  __sync_synchronize();
    80000bee:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	db2080e7          	jalr	-590(ra) # 800019a4 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00007517          	auipc	a0,0x7
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80008070 <digits+0x30>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	91e080e7          	jalr	-1762(ra) # 8000052c <panic>

0000000080000c16 <pop_off>:

void
pop_off(void)
{
    80000c16:	1141                	addi	sp,sp,-16
    80000c18:	e406                	sd	ra,8(sp)
    80000c1a:	e022                	sd	s0,0(sp)
    80000c1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	d86080e7          	jalr	-634(ra) # 800019a4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c2c:	e78d                	bnez	a5,80000c56 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	02f05b63          	blez	a5,80000c66 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c34:	37fd                	addiw	a5,a5,-1
    80000c36:	0007871b          	sext.w	a4,a5
    80000c3a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c3c:	eb09                	bnez	a4,80000c4e <pop_off+0x38>
    80000c3e:	5d7c                	lw	a5,124(a0)
    80000c40:	c799                	beqz	a5,80000c4e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c4e:	60a2                	ld	ra,8(sp)
    80000c50:	6402                	ld	s0,0(sp)
    80000c52:	0141                	addi	sp,sp,16
    80000c54:	8082                	ret
    panic("pop_off - interruptible");
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	42250513          	addi	a0,a0,1058 # 80008078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8ce080e7          	jalr	-1842(ra) # 8000052c <panic>
    panic("pop_off");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8be080e7          	jalr	-1858(ra) # 8000052c <panic>

0000000080000c76 <release>:
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
    80000c80:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	ec6080e7          	jalr	-314(ra) # 80000b48 <holding>
    80000c8a:	c115                	beqz	a0,80000cae <release+0x38>
  lk->cpu = 0;
    80000c8c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c94:	0f50000f          	fence	iorw,ow
    80000c98:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f7a080e7          	jalr	-134(ra) # 80000c16 <pop_off>
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    panic("release");
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80008098 <digits+0x58>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	876080e7          	jalr	-1930(ra) # 8000052c <panic>

0000000080000cbe <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cbe:	1141                	addi	sp,sp,-16
    80000cc0:	e422                	sd	s0,8(sp)
    80000cc2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cc4:	ca19                	beqz	a2,80000cda <memset+0x1c>
    80000cc6:	87aa                	mv	a5,a0
    80000cc8:	1602                	slli	a2,a2,0x20
    80000cca:	9201                	srli	a2,a2,0x20
    80000ccc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cd0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cd4:	0785                	addi	a5,a5,1
    80000cd6:	fee79de3          	bne	a5,a4,80000cd0 <memset+0x12>
  }
  return dst;
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ce6:	ca05                	beqz	a2,80000d16 <memcmp+0x36>
    80000ce8:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cec:	1682                	slli	a3,a3,0x20
    80000cee:	9281                	srli	a3,a3,0x20
    80000cf0:	0685                	addi	a3,a3,1
    80000cf2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cf4:	00054783          	lbu	a5,0(a0)
    80000cf8:	0005c703          	lbu	a4,0(a1)
    80000cfc:	00e79863          	bne	a5,a4,80000d0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d00:	0505                	addi	a0,a0,1
    80000d02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d04:	fed518e3          	bne	a0,a3,80000cf4 <memcmp+0x14>
  }

  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	a019                	j	80000d10 <memcmp+0x30>
      return *s1 - *s2;
    80000d0c:	40e7853b          	subw	a0,a5,a4
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	bfe5                	j	80000d10 <memcmp+0x30>

0000000080000d1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d20:	02a5e563          	bltu	a1,a0,80000d4a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	ce11                	beqz	a2,80000d44 <memmove+0x2a>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96ae                	add	a3,a3,a1
    80000d32:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d34:	0585                	addi	a1,a1,1
    80000d36:	0785                	addi	a5,a5,1
    80000d38:	fff5c703          	lbu	a4,-1(a1)
    80000d3c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d40:	fed59ae3          	bne	a1,a3,80000d34 <memmove+0x1a>

  return dst;
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  if(s < d && s + n > d){
    80000d4a:	02061713          	slli	a4,a2,0x20
    80000d4e:	9301                	srli	a4,a4,0x20
    80000d50:	00e587b3          	add	a5,a1,a4
    80000d54:	fcf578e3          	bgeu	a0,a5,80000d24 <memmove+0xa>
    d += n;
    80000d58:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d5a:	fff6069b          	addiw	a3,a2,-1
    80000d5e:	d27d                	beqz	a2,80000d44 <memmove+0x2a>
    80000d60:	02069613          	slli	a2,a3,0x20
    80000d64:	9201                	srli	a2,a2,0x20
    80000d66:	fff64613          	not	a2,a2
    80000d6a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d6c:	17fd                	addi	a5,a5,-1
    80000d6e:	177d                	addi	a4,a4,-1 # ffffffffffffefff <end+0xffffffff7ffd8fff>
    80000d70:	0007c683          	lbu	a3,0(a5)
    80000d74:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d78:	fef61ae3          	bne	a2,a5,80000d6c <memmove+0x52>
    80000d7c:	b7e1                	j	80000d44 <memmove+0x2a>

0000000080000d7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	f94080e7          	jalr	-108(ra) # 80000d1a <memmove>
}
    80000d8e:	60a2                	ld	ra,8(sp)
    80000d90:	6402                	ld	s0,0(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d9c:	ce11                	beqz	a2,80000db8 <strncmp+0x22>
    80000d9e:	00054783          	lbu	a5,0(a0)
    80000da2:	cf89                	beqz	a5,80000dbc <strncmp+0x26>
    80000da4:	0005c703          	lbu	a4,0(a1)
    80000da8:	00f71a63          	bne	a4,a5,80000dbc <strncmp+0x26>
    n--, p++, q++;
    80000dac:	367d                	addiw	a2,a2,-1
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db2:	f675                	bnez	a2,80000d9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	a809                	j	80000dc8 <strncmp+0x32>
    80000db8:	4501                	li	a0,0
    80000dba:	a039                	j	80000dc8 <strncmp+0x32>
  if(n == 0)
    80000dbc:	ca09                	beqz	a2,80000dce <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dbe:	00054503          	lbu	a0,0(a0)
    80000dc2:	0005c783          	lbu	a5,0(a1)
    80000dc6:	9d1d                	subw	a0,a0,a5
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	bfe5                	j	80000dc8 <strncmp+0x32>

0000000080000dd2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dd8:	872a                	mv	a4,a0
    80000dda:	8832                	mv	a6,a2
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	01005963          	blez	a6,80000df0 <strncpy+0x1e>
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	fef70fa3          	sb	a5,-1(a4)
    80000dec:	0585                	addi	a1,a1,1
    80000dee:	f7f5                	bnez	a5,80000dda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df0:	86ba                	mv	a3,a4
    80000df2:	00c05c63          	blez	a2,80000e0a <strncpy+0x38>
    *s++ = 0;
    80000df6:	0685                	addi	a3,a3,1
    80000df8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000dfc:	40d707bb          	subw	a5,a4,a3
    80000e00:	37fd                	addiw	a5,a5,-1
    80000e02:	010787bb          	addw	a5,a5,a6
    80000e06:	fef048e3          	bgtz	a5,80000df6 <strncpy+0x24>
  return os;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e16:	02c05363          	blez	a2,80000e3c <safestrcpy+0x2c>
    80000e1a:	fff6069b          	addiw	a3,a2,-1
    80000e1e:	1682                	slli	a3,a3,0x20
    80000e20:	9281                	srli	a3,a3,0x20
    80000e22:	96ae                	add	a3,a3,a1
    80000e24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e26:	00d58963          	beq	a1,a3,80000e38 <safestrcpy+0x28>
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fff5c703          	lbu	a4,-1(a1)
    80000e32:	fee78fa3          	sb	a4,-1(a5)
    80000e36:	fb65                	bnez	a4,80000e26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3c:	6422                	ld	s0,8(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret

0000000080000e42 <strlen>:

int
strlen(const char *s)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e48:	00054783          	lbu	a5,0(a0)
    80000e4c:	cf91                	beqz	a5,80000e68 <strlen+0x26>
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	87aa                	mv	a5,a0
    80000e52:	4685                	li	a3,1
    80000e54:	9e89                	subw	a3,a3,a0
    80000e56:	00f6853b          	addw	a0,a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	fb7d                	bnez	a4,80000e56 <strlen+0x14>
    ;
  return n;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strlen+0x20>

0000000080000e6c <strcat>:

char* 
strcat(char* destination, const char* source)
{
    80000e6c:	1101                	addi	sp,sp,-32
    80000e6e:	ec06                	sd	ra,24(sp)
    80000e70:	e822                	sd	s0,16(sp)
    80000e72:	e426                	sd	s1,8(sp)
    80000e74:	e04a                	sd	s2,0(sp)
    80000e76:	1000                	addi	s0,sp,32
    80000e78:	892a                	mv	s2,a0
    80000e7a:	84ae                	mv	s1,a1
  char* ptr = destination + strlen(destination);
    80000e7c:	00000097          	auipc	ra,0x0
    80000e80:	fc6080e7          	jalr	-58(ra) # 80000e42 <strlen>
    80000e84:	00a907b3          	add	a5,s2,a0

  while (*source != '\0')
    80000e88:	0004c703          	lbu	a4,0(s1)
    80000e8c:	cb01                	beqz	a4,80000e9c <strcat+0x30>
    *ptr++ = *source++;
    80000e8e:	0485                	addi	s1,s1,1
    80000e90:	0785                	addi	a5,a5,1
    80000e92:	fee78fa3          	sb	a4,-1(a5)
  while (*source != '\0')
    80000e96:	0004c703          	lbu	a4,0(s1)
    80000e9a:	fb75                	bnez	a4,80000e8e <strcat+0x22>

  *ptr = '\0';
    80000e9c:	00078023          	sb	zero,0(a5)

  return destination;
}
    80000ea0:	854a                	mv	a0,s2
    80000ea2:	60e2                	ld	ra,24(sp)
    80000ea4:	6442                	ld	s0,16(sp)
    80000ea6:	64a2                	ld	s1,8(sp)
    80000ea8:	6902                	ld	s2,0(sp)
    80000eaa:	6105                	addi	sp,sp,32
    80000eac:	8082                	ret

0000000080000eae <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000eae:	1141                	addi	sp,sp,-16
    80000eb0:	e406                	sd	ra,8(sp)
    80000eb2:	e022                	sd	s0,0(sp)
    80000eb4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eb6:	00001097          	auipc	ra,0x1
    80000eba:	ade080e7          	jalr	-1314(ra) # 80001994 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ebe:	00008717          	auipc	a4,0x8
    80000ec2:	15a70713          	addi	a4,a4,346 # 80009018 <started>
  if(cpuid() == 0){
    80000ec6:	c139                	beqz	a0,80000f0c <main+0x5e>
    while(started == 0)
    80000ec8:	431c                	lw	a5,0(a4)
    80000eca:	2781                	sext.w	a5,a5
    80000ecc:	dff5                	beqz	a5,80000ec8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ece:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ed2:	00001097          	auipc	ra,0x1
    80000ed6:	ac2080e7          	jalr	-1342(ra) # 80001994 <cpuid>
    80000eda:	85aa                	mv	a1,a0
    80000edc:	00007517          	auipc	a0,0x7
    80000ee0:	1dc50513          	addi	a0,a0,476 # 800080b8 <digits+0x78>
    80000ee4:	fffff097          	auipc	ra,0xfffff
    80000ee8:	692080e7          	jalr	1682(ra) # 80000576 <printf>
    kvminithart();    // turn on paging
    80000eec:	00000097          	auipc	ra,0x0
    80000ef0:	0d8080e7          	jalr	216(ra) # 80000fc4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ef4:	00001097          	auipc	ra,0x1
    80000ef8:	722080e7          	jalr	1826(ra) # 80002616 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000efc:	00005097          	auipc	ra,0x5
    80000f00:	ca4080e7          	jalr	-860(ra) # 80005ba0 <plicinithart>
  }

  scheduler();        
    80000f04:	00001097          	auipc	ra,0x1
    80000f08:	fce080e7          	jalr	-50(ra) # 80001ed2 <scheduler>
    consoleinit();
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	530080e7          	jalr	1328(ra) # 8000043c <consoleinit>
    printfinit();
    80000f14:	00000097          	auipc	ra,0x0
    80000f18:	842080e7          	jalr	-1982(ra) # 80000756 <printfinit>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	652080e7          	jalr	1618(ra) # 80000576 <printf>
    printf("xv6 kernel is booting\n");
    80000f2c:	00007517          	auipc	a0,0x7
    80000f30:	17450513          	addi	a0,a0,372 # 800080a0 <digits+0x60>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	642080e7          	jalr	1602(ra) # 80000576 <printf>
    printf("\n");
    80000f3c:	00007517          	auipc	a0,0x7
    80000f40:	18c50513          	addi	a0,a0,396 # 800080c8 <digits+0x88>
    80000f44:	fffff097          	auipc	ra,0xfffff
    80000f48:	632080e7          	jalr	1586(ra) # 80000576 <printf>
    kinit();         // physical page allocator
    80000f4c:	00000097          	auipc	ra,0x0
    80000f50:	b4a080e7          	jalr	-1206(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f54:	00000097          	auipc	ra,0x0
    80000f58:	310080e7          	jalr	784(ra) # 80001264 <kvminit>
    kvminithart();   // turn on paging
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	068080e7          	jalr	104(ra) # 80000fc4 <kvminithart>
    procinit();      // process table
    80000f64:	00001097          	auipc	ra,0x1
    80000f68:	980080e7          	jalr	-1664(ra) # 800018e4 <procinit>
    trapinit();      // trap vectors
    80000f6c:	00001097          	auipc	ra,0x1
    80000f70:	682080e7          	jalr	1666(ra) # 800025ee <trapinit>
    trapinithart();  // install kernel trap vector
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	6a2080e7          	jalr	1698(ra) # 80002616 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f7c:	00005097          	auipc	ra,0x5
    80000f80:	c0e080e7          	jalr	-1010(ra) # 80005b8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	c1c080e7          	jalr	-996(ra) # 80005ba0 <plicinithart>
    binit();         // buffer cache
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	dcc080e7          	jalr	-564(ra) # 80002d58 <binit>
    iinit();         // inode cache
    80000f94:	00002097          	auipc	ra,0x2
    80000f98:	45a080e7          	jalr	1114(ra) # 800033ee <iinit>
    fileinit();      // file table
    80000f9c:	00003097          	auipc	ra,0x3
    80000fa0:	40c080e7          	jalr	1036(ra) # 800043a8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa4:	00005097          	auipc	ra,0x5
    80000fa8:	d1c080e7          	jalr	-740(ra) # 80005cc0 <virtio_disk_init>
    userinit();      // first user process
    80000fac:	00001097          	auipc	ra,0x1
    80000fb0:	cec080e7          	jalr	-788(ra) # 80001c98 <userinit>
    __sync_synchronize();
    80000fb4:	0ff0000f          	fence
    started = 1;
    80000fb8:	4785                	li	a5,1
    80000fba:	00008717          	auipc	a4,0x8
    80000fbe:	04f72f23          	sw	a5,94(a4) # 80009018 <started>
    80000fc2:	b789                	j	80000f04 <main+0x56>

0000000080000fc4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fc4:	1141                	addi	sp,sp,-16
    80000fc6:	e422                	sd	s0,8(sp)
    80000fc8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fca:	00008797          	auipc	a5,0x8
    80000fce:	0567b783          	ld	a5,86(a5) # 80009020 <kernel_pagetable>
    80000fd2:	83b1                	srli	a5,a5,0xc
    80000fd4:	577d                	li	a4,-1
    80000fd6:	177e                	slli	a4,a4,0x3f
    80000fd8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fda:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fde:	12000073          	sfence.vma
  sfence_vma();
}
    80000fe2:	6422                	ld	s0,8(sp)
    80000fe4:	0141                	addi	sp,sp,16
    80000fe6:	8082                	ret

0000000080000fe8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fe8:	7139                	addi	sp,sp,-64
    80000fea:	fc06                	sd	ra,56(sp)
    80000fec:	f822                	sd	s0,48(sp)
    80000fee:	f426                	sd	s1,40(sp)
    80000ff0:	f04a                	sd	s2,32(sp)
    80000ff2:	ec4e                	sd	s3,24(sp)
    80000ff4:	e852                	sd	s4,16(sp)
    80000ff6:	e456                	sd	s5,8(sp)
    80000ff8:	e05a                	sd	s6,0(sp)
    80000ffa:	0080                	addi	s0,sp,64
    80000ffc:	84aa                	mv	s1,a0
    80000ffe:	89ae                	mv	s3,a1
    80001000:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001002:	57fd                	li	a5,-1
    80001004:	83e9                	srli	a5,a5,0x1a
    80001006:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001008:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000100a:	04b7f263          	bgeu	a5,a1,8000104e <walk+0x66>
    panic("walk");
    8000100e:	00007517          	auipc	a0,0x7
    80001012:	0c250513          	addi	a0,a0,194 # 800080d0 <digits+0x90>
    80001016:	fffff097          	auipc	ra,0xfffff
    8000101a:	516080e7          	jalr	1302(ra) # 8000052c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000101e:	060a8663          	beqz	s5,8000108a <walk+0xa2>
    80001022:	00000097          	auipc	ra,0x0
    80001026:	ab0080e7          	jalr	-1360(ra) # 80000ad2 <kalloc>
    8000102a:	84aa                	mv	s1,a0
    8000102c:	c529                	beqz	a0,80001076 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000102e:	6605                	lui	a2,0x1
    80001030:	4581                	li	a1,0
    80001032:	00000097          	auipc	ra,0x0
    80001036:	c8c080e7          	jalr	-884(ra) # 80000cbe <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000103a:	00c4d793          	srli	a5,s1,0xc
    8000103e:	07aa                	slli	a5,a5,0xa
    80001040:	0017e793          	ori	a5,a5,1
    80001044:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001048:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8ff7>
    8000104a:	036a0063          	beq	s4,s6,8000106a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000104e:	0149d933          	srl	s2,s3,s4
    80001052:	1ff97913          	andi	s2,s2,511
    80001056:	090e                	slli	s2,s2,0x3
    80001058:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000105a:	00093483          	ld	s1,0(s2)
    8000105e:	0014f793          	andi	a5,s1,1
    80001062:	dfd5                	beqz	a5,8000101e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001064:	80a9                	srli	s1,s1,0xa
    80001066:	04b2                	slli	s1,s1,0xc
    80001068:	b7c5                	j	80001048 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000106a:	00c9d513          	srli	a0,s3,0xc
    8000106e:	1ff57513          	andi	a0,a0,511
    80001072:	050e                	slli	a0,a0,0x3
    80001074:	9526                	add	a0,a0,s1
}
    80001076:	70e2                	ld	ra,56(sp)
    80001078:	7442                	ld	s0,48(sp)
    8000107a:	74a2                	ld	s1,40(sp)
    8000107c:	7902                	ld	s2,32(sp)
    8000107e:	69e2                	ld	s3,24(sp)
    80001080:	6a42                	ld	s4,16(sp)
    80001082:	6aa2                	ld	s5,8(sp)
    80001084:	6b02                	ld	s6,0(sp)
    80001086:	6121                	addi	sp,sp,64
    80001088:	8082                	ret
        return 0;
    8000108a:	4501                	li	a0,0
    8000108c:	b7ed                	j	80001076 <walk+0x8e>

000000008000108e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000108e:	57fd                	li	a5,-1
    80001090:	83e9                	srli	a5,a5,0x1a
    80001092:	00b7f463          	bgeu	a5,a1,8000109a <walkaddr+0xc>
    return 0;
    80001096:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001098:	8082                	ret
{
    8000109a:	1141                	addi	sp,sp,-16
    8000109c:	e406                	sd	ra,8(sp)
    8000109e:	e022                	sd	s0,0(sp)
    800010a0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010a2:	4601                	li	a2,0
    800010a4:	00000097          	auipc	ra,0x0
    800010a8:	f44080e7          	jalr	-188(ra) # 80000fe8 <walk>
  if(pte == 0)
    800010ac:	c105                	beqz	a0,800010cc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010ae:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010b0:	0117f693          	andi	a3,a5,17
    800010b4:	4745                	li	a4,17
    return 0;
    800010b6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010b8:	00e68663          	beq	a3,a4,800010c4 <walkaddr+0x36>
}
    800010bc:	60a2                	ld	ra,8(sp)
    800010be:	6402                	ld	s0,0(sp)
    800010c0:	0141                	addi	sp,sp,16
    800010c2:	8082                	ret
  pa = PTE2PA(*pte);
    800010c4:	83a9                	srli	a5,a5,0xa
    800010c6:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010ca:	bfcd                	j	800010bc <walkaddr+0x2e>
    return 0;
    800010cc:	4501                	li	a0,0
    800010ce:	b7fd                	j	800010bc <walkaddr+0x2e>

00000000800010d0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010d0:	715d                	addi	sp,sp,-80
    800010d2:	e486                	sd	ra,72(sp)
    800010d4:	e0a2                	sd	s0,64(sp)
    800010d6:	fc26                	sd	s1,56(sp)
    800010d8:	f84a                	sd	s2,48(sp)
    800010da:	f44e                	sd	s3,40(sp)
    800010dc:	f052                	sd	s4,32(sp)
    800010de:	ec56                	sd	s5,24(sp)
    800010e0:	e85a                	sd	s6,16(sp)
    800010e2:	e45e                	sd	s7,8(sp)
    800010e4:	0880                	addi	s0,sp,80
    800010e6:	8aaa                	mv	s5,a0
    800010e8:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010ea:	777d                	lui	a4,0xfffff
    800010ec:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010f0:	fff60993          	addi	s3,a2,-1 # fff <_entry-0x7ffff001>
    800010f4:	99ae                	add	s3,s3,a1
    800010f6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010fa:	893e                	mv	s2,a5
    800010fc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001100:	6b85                	lui	s7,0x1
    80001102:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001106:	4605                	li	a2,1
    80001108:	85ca                	mv	a1,s2
    8000110a:	8556                	mv	a0,s5
    8000110c:	00000097          	auipc	ra,0x0
    80001110:	edc080e7          	jalr	-292(ra) # 80000fe8 <walk>
    80001114:	c51d                	beqz	a0,80001142 <mappages+0x72>
    if(*pte & PTE_V)
    80001116:	611c                	ld	a5,0(a0)
    80001118:	8b85                	andi	a5,a5,1
    8000111a:	ef81                	bnez	a5,80001132 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000111c:	80b1                	srli	s1,s1,0xc
    8000111e:	04aa                	slli	s1,s1,0xa
    80001120:	0164e4b3          	or	s1,s1,s6
    80001124:	0014e493          	ori	s1,s1,1
    80001128:	e104                	sd	s1,0(a0)
    if(a == last)
    8000112a:	03390863          	beq	s2,s3,8000115a <mappages+0x8a>
    a += PGSIZE;
    8000112e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001130:	bfc9                	j	80001102 <mappages+0x32>
      panic("remap");
    80001132:	00007517          	auipc	a0,0x7
    80001136:	fa650513          	addi	a0,a0,-90 # 800080d8 <digits+0x98>
    8000113a:	fffff097          	auipc	ra,0xfffff
    8000113e:	3f2080e7          	jalr	1010(ra) # 8000052c <panic>
      return -1;
    80001142:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret
  return 0;
    8000115a:	4501                	li	a0,0
    8000115c:	b7e5                	j	80001144 <mappages+0x74>

000000008000115e <kvmmap>:
{
    8000115e:	1141                	addi	sp,sp,-16
    80001160:	e406                	sd	ra,8(sp)
    80001162:	e022                	sd	s0,0(sp)
    80001164:	0800                	addi	s0,sp,16
    80001166:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001168:	86b2                	mv	a3,a2
    8000116a:	863e                	mv	a2,a5
    8000116c:	00000097          	auipc	ra,0x0
    80001170:	f64080e7          	jalr	-156(ra) # 800010d0 <mappages>
    80001174:	e509                	bnez	a0,8000117e <kvmmap+0x20>
}
    80001176:	60a2                	ld	ra,8(sp)
    80001178:	6402                	ld	s0,0(sp)
    8000117a:	0141                	addi	sp,sp,16
    8000117c:	8082                	ret
    panic("kvmmap");
    8000117e:	00007517          	auipc	a0,0x7
    80001182:	f6250513          	addi	a0,a0,-158 # 800080e0 <digits+0xa0>
    80001186:	fffff097          	auipc	ra,0xfffff
    8000118a:	3a6080e7          	jalr	934(ra) # 8000052c <panic>

000000008000118e <kvmmake>:
{
    8000118e:	1101                	addi	sp,sp,-32
    80001190:	ec06                	sd	ra,24(sp)
    80001192:	e822                	sd	s0,16(sp)
    80001194:	e426                	sd	s1,8(sp)
    80001196:	e04a                	sd	s2,0(sp)
    80001198:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	938080e7          	jalr	-1736(ra) # 80000ad2 <kalloc>
    800011a2:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a4:	6605                	lui	a2,0x1
    800011a6:	4581                	li	a1,0
    800011a8:	00000097          	auipc	ra,0x0
    800011ac:	b16080e7          	jalr	-1258(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011b0:	4719                	li	a4,6
    800011b2:	6685                	lui	a3,0x1
    800011b4:	10000637          	lui	a2,0x10000
    800011b8:	100005b7          	lui	a1,0x10000
    800011bc:	8526                	mv	a0,s1
    800011be:	00000097          	auipc	ra,0x0
    800011c2:	fa0080e7          	jalr	-96(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c6:	4719                	li	a4,6
    800011c8:	6685                	lui	a3,0x1
    800011ca:	10001637          	lui	a2,0x10001
    800011ce:	100015b7          	lui	a1,0x10001
    800011d2:	8526                	mv	a0,s1
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	f8a080e7          	jalr	-118(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011dc:	4719                	li	a4,6
    800011de:	004006b7          	lui	a3,0x400
    800011e2:	0c000637          	lui	a2,0xc000
    800011e6:	0c0005b7          	lui	a1,0xc000
    800011ea:	8526                	mv	a0,s1
    800011ec:	00000097          	auipc	ra,0x0
    800011f0:	f72080e7          	jalr	-142(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f4:	00007917          	auipc	s2,0x7
    800011f8:	e0c90913          	addi	s2,s2,-500 # 80008000 <etext>
    800011fc:	4729                	li	a4,10
    800011fe:	80007697          	auipc	a3,0x80007
    80001202:	e0268693          	addi	a3,a3,-510 # 8000 <_entry-0x7fff8000>
    80001206:	4605                	li	a2,1
    80001208:	067e                	slli	a2,a2,0x1f
    8000120a:	85b2                	mv	a1,a2
    8000120c:	8526                	mv	a0,s1
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f50080e7          	jalr	-176(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001216:	4719                	li	a4,6
    80001218:	46c5                	li	a3,17
    8000121a:	06ee                	slli	a3,a3,0x1b
    8000121c:	412686b3          	sub	a3,a3,s2
    80001220:	864a                	mv	a2,s2
    80001222:	85ca                	mv	a1,s2
    80001224:	8526                	mv	a0,s1
    80001226:	00000097          	auipc	ra,0x0
    8000122a:	f38080e7          	jalr	-200(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122e:	4729                	li	a4,10
    80001230:	6685                	lui	a3,0x1
    80001232:	00006617          	auipc	a2,0x6
    80001236:	dce60613          	addi	a2,a2,-562 # 80007000 <_trampoline>
    8000123a:	040005b7          	lui	a1,0x4000
    8000123e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001240:	05b2                	slli	a1,a1,0xc
    80001242:	8526                	mv	a0,s1
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f1a080e7          	jalr	-230(ra) # 8000115e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000124c:	8526                	mv	a0,s1
    8000124e:	00000097          	auipc	ra,0x0
    80001252:	600080e7          	jalr	1536(ra) # 8000184e <proc_mapstacks>
}
    80001256:	8526                	mv	a0,s1
    80001258:	60e2                	ld	ra,24(sp)
    8000125a:	6442                	ld	s0,16(sp)
    8000125c:	64a2                	ld	s1,8(sp)
    8000125e:	6902                	ld	s2,0(sp)
    80001260:	6105                	addi	sp,sp,32
    80001262:	8082                	ret

0000000080001264 <kvminit>:
{
    80001264:	1141                	addi	sp,sp,-16
    80001266:	e406                	sd	ra,8(sp)
    80001268:	e022                	sd	s0,0(sp)
    8000126a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f22080e7          	jalr	-222(ra) # 8000118e <kvmmake>
    80001274:	00008797          	auipc	a5,0x8
    80001278:	daa7b623          	sd	a0,-596(a5) # 80009020 <kernel_pagetable>
}
    8000127c:	60a2                	ld	ra,8(sp)
    8000127e:	6402                	ld	s0,0(sp)
    80001280:	0141                	addi	sp,sp,16
    80001282:	8082                	ret

0000000080001284 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001284:	715d                	addi	sp,sp,-80
    80001286:	e486                	sd	ra,72(sp)
    80001288:	e0a2                	sd	s0,64(sp)
    8000128a:	fc26                	sd	s1,56(sp)
    8000128c:	f84a                	sd	s2,48(sp)
    8000128e:	f44e                	sd	s3,40(sp)
    80001290:	f052                	sd	s4,32(sp)
    80001292:	ec56                	sd	s5,24(sp)
    80001294:	e85a                	sd	s6,16(sp)
    80001296:	e45e                	sd	s7,8(sp)
    80001298:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000129a:	03459793          	slli	a5,a1,0x34
    8000129e:	e795                	bnez	a5,800012ca <uvmunmap+0x46>
    800012a0:	8a2a                	mv	s4,a0
    800012a2:	892e                	mv	s2,a1
    800012a4:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a6:	0632                	slli	a2,a2,0xc
    800012a8:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ac:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ae:	6b05                	lui	s6,0x1
    800012b0:	0735e263          	bltu	a1,s3,80001314 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b4:	60a6                	ld	ra,72(sp)
    800012b6:	6406                	ld	s0,64(sp)
    800012b8:	74e2                	ld	s1,56(sp)
    800012ba:	7942                	ld	s2,48(sp)
    800012bc:	79a2                	ld	s3,40(sp)
    800012be:	7a02                	ld	s4,32(sp)
    800012c0:	6ae2                	ld	s5,24(sp)
    800012c2:	6b42                	ld	s6,16(sp)
    800012c4:	6ba2                	ld	s7,8(sp)
    800012c6:	6161                	addi	sp,sp,80
    800012c8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e1e50513          	addi	a0,a0,-482 # 800080e8 <digits+0xa8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	25a080e7          	jalr	602(ra) # 8000052c <panic>
      panic("uvmunmap: walk");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e2650513          	addi	a0,a0,-474 # 80008100 <digits+0xc0>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	24a080e7          	jalr	586(ra) # 8000052c <panic>
      panic("uvmunmap: not mapped");
    800012ea:	00007517          	auipc	a0,0x7
    800012ee:	e2650513          	addi	a0,a0,-474 # 80008110 <digits+0xd0>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	23a080e7          	jalr	570(ra) # 8000052c <panic>
      panic("uvmunmap: not a leaf");
    800012fa:	00007517          	auipc	a0,0x7
    800012fe:	e2e50513          	addi	a0,a0,-466 # 80008128 <digits+0xe8>
    80001302:	fffff097          	auipc	ra,0xfffff
    80001306:	22a080e7          	jalr	554(ra) # 8000052c <panic>
    *pte = 0;
    8000130a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130e:	995a                	add	s2,s2,s6
    80001310:	fb3972e3          	bgeu	s2,s3,800012b4 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001314:	4601                	li	a2,0
    80001316:	85ca                	mv	a1,s2
    80001318:	8552                	mv	a0,s4
    8000131a:	00000097          	auipc	ra,0x0
    8000131e:	cce080e7          	jalr	-818(ra) # 80000fe8 <walk>
    80001322:	84aa                	mv	s1,a0
    80001324:	d95d                	beqz	a0,800012da <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001326:	6108                	ld	a0,0(a0)
    80001328:	00157793          	andi	a5,a0,1
    8000132c:	dfdd                	beqz	a5,800012ea <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132e:	3ff57793          	andi	a5,a0,1023
    80001332:	fd7784e3          	beq	a5,s7,800012fa <uvmunmap+0x76>
    if(do_free){
    80001336:	fc0a8ae3          	beqz	s5,8000130a <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000133a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000133c:	0532                	slli	a0,a0,0xc
    8000133e:	fffff097          	auipc	ra,0xfffff
    80001342:	696080e7          	jalr	1686(ra) # 800009d4 <kfree>
    80001346:	b7d1                	j	8000130a <uvmunmap+0x86>

0000000080001348 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001348:	1101                	addi	sp,sp,-32
    8000134a:	ec06                	sd	ra,24(sp)
    8000134c:	e822                	sd	s0,16(sp)
    8000134e:	e426                	sd	s1,8(sp)
    80001350:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001352:	fffff097          	auipc	ra,0xfffff
    80001356:	780080e7          	jalr	1920(ra) # 80000ad2 <kalloc>
    8000135a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000135c:	c519                	beqz	a0,8000136a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135e:	6605                	lui	a2,0x1
    80001360:	4581                	li	a1,0
    80001362:	00000097          	auipc	ra,0x0
    80001366:	95c080e7          	jalr	-1700(ra) # 80000cbe <memset>
  return pagetable;
}
    8000136a:	8526                	mv	a0,s1
    8000136c:	60e2                	ld	ra,24(sp)
    8000136e:	6442                	ld	s0,16(sp)
    80001370:	64a2                	ld	s1,8(sp)
    80001372:	6105                	addi	sp,sp,32
    80001374:	8082                	ret

0000000080001376 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001376:	7179                	addi	sp,sp,-48
    80001378:	f406                	sd	ra,40(sp)
    8000137a:	f022                	sd	s0,32(sp)
    8000137c:	ec26                	sd	s1,24(sp)
    8000137e:	e84a                	sd	s2,16(sp)
    80001380:	e44e                	sd	s3,8(sp)
    80001382:	e052                	sd	s4,0(sp)
    80001384:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001386:	6785                	lui	a5,0x1
    80001388:	04f67863          	bgeu	a2,a5,800013d8 <uvminit+0x62>
    8000138c:	8a2a                	mv	s4,a0
    8000138e:	89ae                	mv	s3,a1
    80001390:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001392:	fffff097          	auipc	ra,0xfffff
    80001396:	740080e7          	jalr	1856(ra) # 80000ad2 <kalloc>
    8000139a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000139c:	6605                	lui	a2,0x1
    8000139e:	4581                	li	a1,0
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	91e080e7          	jalr	-1762(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a8:	4779                	li	a4,30
    800013aa:	86ca                	mv	a3,s2
    800013ac:	6605                	lui	a2,0x1
    800013ae:	4581                	li	a1,0
    800013b0:	8552                	mv	a0,s4
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	d1e080e7          	jalr	-738(ra) # 800010d0 <mappages>
  memmove(mem, src, sz);
    800013ba:	8626                	mv	a2,s1
    800013bc:	85ce                	mv	a1,s3
    800013be:	854a                	mv	a0,s2
    800013c0:	00000097          	auipc	ra,0x0
    800013c4:	95a080e7          	jalr	-1702(ra) # 80000d1a <memmove>
}
    800013c8:	70a2                	ld	ra,40(sp)
    800013ca:	7402                	ld	s0,32(sp)
    800013cc:	64e2                	ld	s1,24(sp)
    800013ce:	6942                	ld	s2,16(sp)
    800013d0:	69a2                	ld	s3,8(sp)
    800013d2:	6a02                	ld	s4,0(sp)
    800013d4:	6145                	addi	sp,sp,48
    800013d6:	8082                	ret
    panic("inituvm: more than a page");
    800013d8:	00007517          	auipc	a0,0x7
    800013dc:	d6850513          	addi	a0,a0,-664 # 80008140 <digits+0x100>
    800013e0:	fffff097          	auipc	ra,0xfffff
    800013e4:	14c080e7          	jalr	332(ra) # 8000052c <panic>

00000000800013e8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e8:	1101                	addi	sp,sp,-32
    800013ea:	ec06                	sd	ra,24(sp)
    800013ec:	e822                	sd	s0,16(sp)
    800013ee:	e426                	sd	s1,8(sp)
    800013f0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013f2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f4:	00b67d63          	bgeu	a2,a1,8000140e <uvmdealloc+0x26>
    800013f8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013fa:	6785                	lui	a5,0x1
    800013fc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013fe:	00f60733          	add	a4,a2,a5
    80001402:	76fd                	lui	a3,0xfffff
    80001404:	8f75                	and	a4,a4,a3
    80001406:	97ae                	add	a5,a5,a1
    80001408:	8ff5                	and	a5,a5,a3
    8000140a:	00f76863          	bltu	a4,a5,8000141a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140e:	8526                	mv	a0,s1
    80001410:	60e2                	ld	ra,24(sp)
    80001412:	6442                	ld	s0,16(sp)
    80001414:	64a2                	ld	s1,8(sp)
    80001416:	6105                	addi	sp,sp,32
    80001418:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000141a:	8f99                	sub	a5,a5,a4
    8000141c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141e:	4685                	li	a3,1
    80001420:	0007861b          	sext.w	a2,a5
    80001424:	85ba                	mv	a1,a4
    80001426:	00000097          	auipc	ra,0x0
    8000142a:	e5e080e7          	jalr	-418(ra) # 80001284 <uvmunmap>
    8000142e:	b7c5                	j	8000140e <uvmdealloc+0x26>

0000000080001430 <uvmalloc>:
  if(newsz < oldsz)
    80001430:	0ab66163          	bltu	a2,a1,800014d2 <uvmalloc+0xa2>
{
    80001434:	7139                	addi	sp,sp,-64
    80001436:	fc06                	sd	ra,56(sp)
    80001438:	f822                	sd	s0,48(sp)
    8000143a:	f426                	sd	s1,40(sp)
    8000143c:	f04a                	sd	s2,32(sp)
    8000143e:	ec4e                	sd	s3,24(sp)
    80001440:	e852                	sd	s4,16(sp)
    80001442:	e456                	sd	s5,8(sp)
    80001444:	0080                	addi	s0,sp,64
    80001446:	8aaa                	mv	s5,a0
    80001448:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000144a:	6785                	lui	a5,0x1
    8000144c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000144e:	95be                	add	a1,a1,a5
    80001450:	77fd                	lui	a5,0xfffff
    80001452:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001456:	08c9f063          	bgeu	s3,a2,800014d6 <uvmalloc+0xa6>
    8000145a:	894e                	mv	s2,s3
    mem = kalloc();
    8000145c:	fffff097          	auipc	ra,0xfffff
    80001460:	676080e7          	jalr	1654(ra) # 80000ad2 <kalloc>
    80001464:	84aa                	mv	s1,a0
    if(mem == 0){
    80001466:	c51d                	beqz	a0,80001494 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001468:	6605                	lui	a2,0x1
    8000146a:	4581                	li	a1,0
    8000146c:	00000097          	auipc	ra,0x0
    80001470:	852080e7          	jalr	-1966(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001474:	4779                	li	a4,30
    80001476:	86a6                	mv	a3,s1
    80001478:	6605                	lui	a2,0x1
    8000147a:	85ca                	mv	a1,s2
    8000147c:	8556                	mv	a0,s5
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	c52080e7          	jalr	-942(ra) # 800010d0 <mappages>
    80001486:	e905                	bnez	a0,800014b6 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001488:	6785                	lui	a5,0x1
    8000148a:	993e                	add	s2,s2,a5
    8000148c:	fd4968e3          	bltu	s2,s4,8000145c <uvmalloc+0x2c>
  return newsz;
    80001490:	8552                	mv	a0,s4
    80001492:	a809                	j	800014a4 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001494:	864e                	mv	a2,s3
    80001496:	85ca                	mv	a1,s2
    80001498:	8556                	mv	a0,s5
    8000149a:	00000097          	auipc	ra,0x0
    8000149e:	f4e080e7          	jalr	-178(ra) # 800013e8 <uvmdealloc>
      return 0;
    800014a2:	4501                	li	a0,0
}
    800014a4:	70e2                	ld	ra,56(sp)
    800014a6:	7442                	ld	s0,48(sp)
    800014a8:	74a2                	ld	s1,40(sp)
    800014aa:	7902                	ld	s2,32(sp)
    800014ac:	69e2                	ld	s3,24(sp)
    800014ae:	6a42                	ld	s4,16(sp)
    800014b0:	6aa2                	ld	s5,8(sp)
    800014b2:	6121                	addi	sp,sp,64
    800014b4:	8082                	ret
      kfree(mem);
    800014b6:	8526                	mv	a0,s1
    800014b8:	fffff097          	auipc	ra,0xfffff
    800014bc:	51c080e7          	jalr	1308(ra) # 800009d4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c0:	864e                	mv	a2,s3
    800014c2:	85ca                	mv	a1,s2
    800014c4:	8556                	mv	a0,s5
    800014c6:	00000097          	auipc	ra,0x0
    800014ca:	f22080e7          	jalr	-222(ra) # 800013e8 <uvmdealloc>
      return 0;
    800014ce:	4501                	li	a0,0
    800014d0:	bfd1                	j	800014a4 <uvmalloc+0x74>
    return oldsz;
    800014d2:	852e                	mv	a0,a1
}
    800014d4:	8082                	ret
  return newsz;
    800014d6:	8532                	mv	a0,a2
    800014d8:	b7f1                	j	800014a4 <uvmalloc+0x74>

00000000800014da <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014da:	7179                	addi	sp,sp,-48
    800014dc:	f406                	sd	ra,40(sp)
    800014de:	f022                	sd	s0,32(sp)
    800014e0:	ec26                	sd	s1,24(sp)
    800014e2:	e84a                	sd	s2,16(sp)
    800014e4:	e44e                	sd	s3,8(sp)
    800014e6:	e052                	sd	s4,0(sp)
    800014e8:	1800                	addi	s0,sp,48
    800014ea:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ec:	84aa                	mv	s1,a0
    800014ee:	6905                	lui	s2,0x1
    800014f0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f2:	4985                	li	s3,1
    800014f4:	a829                	j	8000150e <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f6:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014f8:	00c79513          	slli	a0,a5,0xc
    800014fc:	00000097          	auipc	ra,0x0
    80001500:	fde080e7          	jalr	-34(ra) # 800014da <freewalk>
      pagetable[i] = 0;
    80001504:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001508:	04a1                	addi	s1,s1,8
    8000150a:	03248163          	beq	s1,s2,8000152c <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000150e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001510:	00f7f713          	andi	a4,a5,15
    80001514:	ff3701e3          	beq	a4,s3,800014f6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001518:	8b85                	andi	a5,a5,1
    8000151a:	d7fd                	beqz	a5,80001508 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000151c:	00007517          	auipc	a0,0x7
    80001520:	c4450513          	addi	a0,a0,-956 # 80008160 <digits+0x120>
    80001524:	fffff097          	auipc	ra,0xfffff
    80001528:	008080e7          	jalr	8(ra) # 8000052c <panic>
    }
  }
  kfree((void*)pagetable);
    8000152c:	8552                	mv	a0,s4
    8000152e:	fffff097          	auipc	ra,0xfffff
    80001532:	4a6080e7          	jalr	1190(ra) # 800009d4 <kfree>
}
    80001536:	70a2                	ld	ra,40(sp)
    80001538:	7402                	ld	s0,32(sp)
    8000153a:	64e2                	ld	s1,24(sp)
    8000153c:	6942                	ld	s2,16(sp)
    8000153e:	69a2                	ld	s3,8(sp)
    80001540:	6a02                	ld	s4,0(sp)
    80001542:	6145                	addi	sp,sp,48
    80001544:	8082                	ret

0000000080001546 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001546:	1101                	addi	sp,sp,-32
    80001548:	ec06                	sd	ra,24(sp)
    8000154a:	e822                	sd	s0,16(sp)
    8000154c:	e426                	sd	s1,8(sp)
    8000154e:	1000                	addi	s0,sp,32
    80001550:	84aa                	mv	s1,a0
  if(sz > 0)
    80001552:	e999                	bnez	a1,80001568 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001554:	8526                	mv	a0,s1
    80001556:	00000097          	auipc	ra,0x0
    8000155a:	f84080e7          	jalr	-124(ra) # 800014da <freewalk>
}
    8000155e:	60e2                	ld	ra,24(sp)
    80001560:	6442                	ld	s0,16(sp)
    80001562:	64a2                	ld	s1,8(sp)
    80001564:	6105                	addi	sp,sp,32
    80001566:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001568:	6785                	lui	a5,0x1
    8000156a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000156c:	95be                	add	a1,a1,a5
    8000156e:	4685                	li	a3,1
    80001570:	00c5d613          	srli	a2,a1,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0e080e7          	jalr	-754(ra) # 80001284 <uvmunmap>
    8000157e:	bfd9                	j	80001554 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a42080e7          	jalr	-1470(ra) # 80000fe8 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	50e080e7          	jalr	1294(ra) # 80000ad2 <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	746080e7          	jalr	1862(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	aea080e7          	jalr	-1302(ra) # 800010d0 <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b7650513          	addi	a0,a0,-1162 # 80008170 <digits+0x130>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f2a080e7          	jalr	-214(ra) # 8000052c <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b8650513          	addi	a0,a0,-1146 # 80008190 <digits+0x150>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f1a080e7          	jalr	-230(ra) # 8000052c <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3b8080e7          	jalr	952(ra) # 800009d4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c56080e7          	jalr	-938(ra) # 80001284 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	98c080e7          	jalr	-1652(ra) # 80000fe8 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b3c50513          	addi	a0,a0,-1220 # 800081b0 <digits+0x170>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	eb0080e7          	jalr	-336(ra) # 8000052c <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	662080e7          	jalr	1634(ra) # 80000d1a <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9b8080e7          	jalr	-1608(ra) # 8000108e <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	caa5                	beqz	a3,80001780 <copyin+0x70>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a01d                	j	8000175c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	018505b3          	add	a1,a0,s8
    8000173c:	0004861b          	sext.w	a2,s1
    80001740:	412585b3          	sub	a1,a1,s2
    80001744:	8552                	mv	a0,s4
    80001746:	fffff097          	auipc	ra,0xfffff
    8000174a:	5d4080e7          	jalr	1492(ra) # 80000d1a <memmove>

    len -= n;
    8000174e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001752:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001754:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001758:	02098263          	beqz	s3,8000177c <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000175c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001760:	85ca                	mv	a1,s2
    80001762:	855a                	mv	a0,s6
    80001764:	00000097          	auipc	ra,0x0
    80001768:	92a080e7          	jalr	-1750(ra) # 8000108e <walkaddr>
    if(pa0 == 0)
    8000176c:	cd01                	beqz	a0,80001784 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000176e:	418904b3          	sub	s1,s2,s8
    80001772:	94d6                	add	s1,s1,s5
    80001774:	fc99f2e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001778:	84ce                	mv	s1,s3
    8000177a:	bf7d                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177c:	4501                	li	a0,0
    8000177e:	a021                	j	80001786 <copyin+0x76>
    80001780:	4501                	li	a0,0
}
    80001782:	8082                	ret
      return -1;
    80001784:	557d                	li	a0,-1
}
    80001786:	60a6                	ld	ra,72(sp)
    80001788:	6406                	ld	s0,64(sp)
    8000178a:	74e2                	ld	s1,56(sp)
    8000178c:	7942                	ld	s2,48(sp)
    8000178e:	79a2                	ld	s3,40(sp)
    80001790:	7a02                	ld	s4,32(sp)
    80001792:	6ae2                	ld	s5,24(sp)
    80001794:	6b42                	ld	s6,16(sp)
    80001796:	6ba2                	ld	s7,8(sp)
    80001798:	6c02                	ld	s8,0(sp)
    8000179a:	6161                	addi	sp,sp,80
    8000179c:	8082                	ret

000000008000179e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179e:	c2dd                	beqz	a3,80001844 <copyinstr+0xa6>
{
    800017a0:	715d                	addi	sp,sp,-80
    800017a2:	e486                	sd	ra,72(sp)
    800017a4:	e0a2                	sd	s0,64(sp)
    800017a6:	fc26                	sd	s1,56(sp)
    800017a8:	f84a                	sd	s2,48(sp)
    800017aa:	f44e                	sd	s3,40(sp)
    800017ac:	f052                	sd	s4,32(sp)
    800017ae:	ec56                	sd	s5,24(sp)
    800017b0:	e85a                	sd	s6,16(sp)
    800017b2:	e45e                	sd	s7,8(sp)
    800017b4:	0880                	addi	s0,sp,80
    800017b6:	8a2a                	mv	s4,a0
    800017b8:	8b2e                	mv	s6,a1
    800017ba:	8bb2                	mv	s7,a2
    800017bc:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017be:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017c0:	6985                	lui	s3,0x1
    800017c2:	a02d                	j	800017ec <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ca:	37fd                	addiw	a5,a5,-1
    800017cc:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	89a080e7          	jalr	-1894(ra) # 8000108e <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017fe:	417906b3          	sub	a3,s2,s7
    80001802:	96ce                	add	a3,a3,s3
    80001804:	00d4f363          	bgeu	s1,a3,8000180a <copyinstr+0x6c>
    80001808:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	daf9                	beqz	a3,800017e6 <copyinstr+0x48>
    80001812:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001814:	41650633          	sub	a2,a0,s6
    80001818:	fff48593          	addi	a1,s1,-1
    8000181c:	95da                	add	a1,a1,s6
    while(n > 0){
    8000181e:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001828:	df51                	beqz	a4,800017c4 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	fed796e3          	bne	a5,a3,80001820 <copyinstr+0x82>
      dst++;
    80001838:	8b3e                	mv	s6,a5
    8000183a:	b775                	j	800017e6 <copyinstr+0x48>
    8000183c:	4781                	li	a5,0
    8000183e:	b771                	j	800017ca <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x32>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	37fd                	addiw	a5,a5,-1
    80001848:	0007851b          	sext.w	a0,a5
}
    8000184c:	8082                	ret

000000008000184e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000184e:	7139                	addi	sp,sp,-64
    80001850:	fc06                	sd	ra,56(sp)
    80001852:	f822                	sd	s0,48(sp)
    80001854:	f426                	sd	s1,40(sp)
    80001856:	f04a                	sd	s2,32(sp)
    80001858:	ec4e                	sd	s3,24(sp)
    8000185a:	e852                	sd	s4,16(sp)
    8000185c:	e456                	sd	s5,8(sp)
    8000185e:	e05a                	sd	s6,0(sp)
    80001860:	0080                	addi	s0,sp,64
    80001862:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001864:	00010497          	auipc	s1,0x10
    80001868:	e6c48493          	addi	s1,s1,-404 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000186c:	8b26                	mv	s6,s1
    8000186e:	00006a97          	auipc	s5,0x6
    80001872:	792a8a93          	addi	s5,s5,1938 # 80008000 <etext>
    80001876:	04000937          	lui	s2,0x4000
    8000187a:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000187c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000187e:	00016a17          	auipc	s4,0x16
    80001882:	852a0a13          	addi	s4,s4,-1966 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001886:	fffff097          	auipc	ra,0xfffff
    8000188a:	24c080e7          	jalr	588(ra) # 80000ad2 <kalloc>
    8000188e:	862a                	mv	a2,a0
    if(pa == 0)
    80001890:	c131                	beqz	a0,800018d4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001892:	416485b3          	sub	a1,s1,s6
    80001896:	858d                	srai	a1,a1,0x3
    80001898:	000ab783          	ld	a5,0(s5)
    8000189c:	02f585b3          	mul	a1,a1,a5
    800018a0:	2585                	addiw	a1,a1,1
    800018a2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a6:	4719                	li	a4,6
    800018a8:	6685                	lui	a3,0x1
    800018aa:	40b905b3          	sub	a1,s2,a1
    800018ae:	854e                	mv	a0,s3
    800018b0:	00000097          	auipc	ra,0x0
    800018b4:	8ae080e7          	jalr	-1874(ra) # 8000115e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b8:	16848493          	addi	s1,s1,360
    800018bc:	fd4495e3          	bne	s1,s4,80001886 <proc_mapstacks+0x38>
  }
}
    800018c0:	70e2                	ld	ra,56(sp)
    800018c2:	7442                	ld	s0,48(sp)
    800018c4:	74a2                	ld	s1,40(sp)
    800018c6:	7902                	ld	s2,32(sp)
    800018c8:	69e2                	ld	s3,24(sp)
    800018ca:	6a42                	ld	s4,16(sp)
    800018cc:	6aa2                	ld	s5,8(sp)
    800018ce:	6b02                	ld	s6,0(sp)
    800018d0:	6121                	addi	sp,sp,64
    800018d2:	8082                	ret
      panic("kalloc");
    800018d4:	00007517          	auipc	a0,0x7
    800018d8:	8ec50513          	addi	a0,a0,-1812 # 800081c0 <digits+0x180>
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	c50080e7          	jalr	-944(ra) # 8000052c <panic>

00000000800018e4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018e4:	7139                	addi	sp,sp,-64
    800018e6:	fc06                	sd	ra,56(sp)
    800018e8:	f822                	sd	s0,48(sp)
    800018ea:	f426                	sd	s1,40(sp)
    800018ec:	f04a                	sd	s2,32(sp)
    800018ee:	ec4e                	sd	s3,24(sp)
    800018f0:	e852                	sd	s4,16(sp)
    800018f2:	e456                	sd	s5,8(sp)
    800018f4:	e05a                	sd	s6,0(sp)
    800018f6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8d058593          	addi	a1,a1,-1840 # 800081c8 <digits+0x188>
    80001900:	00010517          	auipc	a0,0x10
    80001904:	9a050513          	addi	a0,a0,-1632 # 800112a0 <pid_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	22a080e7          	jalr	554(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001910:	00007597          	auipc	a1,0x7
    80001914:	8c058593          	addi	a1,a1,-1856 # 800081d0 <digits+0x190>
    80001918:	00010517          	auipc	a0,0x10
    8000191c:	9a050513          	addi	a0,a0,-1632 # 800112b8 <wait_lock>
    80001920:	fffff097          	auipc	ra,0xfffff
    80001924:	212080e7          	jalr	530(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001928:	00010497          	auipc	s1,0x10
    8000192c:	da848493          	addi	s1,s1,-600 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001930:	00007b17          	auipc	s6,0x7
    80001934:	8b0b0b13          	addi	s6,s6,-1872 # 800081e0 <digits+0x1a0>
      p->kstack = KSTACK((int) (p - proc));
    80001938:	8aa6                	mv	s5,s1
    8000193a:	00006a17          	auipc	s4,0x6
    8000193e:	6c6a0a13          	addi	s4,s4,1734 # 80008000 <etext>
    80001942:	04000937          	lui	s2,0x4000
    80001946:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001948:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194a:	00015997          	auipc	s3,0x15
    8000194e:	78698993          	addi	s3,s3,1926 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001952:	85da                	mv	a1,s6
    80001954:	8526                	mv	a0,s1
    80001956:	fffff097          	auipc	ra,0xfffff
    8000195a:	1dc080e7          	jalr	476(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000195e:	415487b3          	sub	a5,s1,s5
    80001962:	878d                	srai	a5,a5,0x3
    80001964:	000a3703          	ld	a4,0(s4)
    80001968:	02e787b3          	mul	a5,a5,a4
    8000196c:	2785                	addiw	a5,a5,1
    8000196e:	00d7979b          	slliw	a5,a5,0xd
    80001972:	40f907b3          	sub	a5,s2,a5
    80001976:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001978:	16848493          	addi	s1,s1,360
    8000197c:	fd349be3          	bne	s1,s3,80001952 <procinit+0x6e>
  }
}
    80001980:	70e2                	ld	ra,56(sp)
    80001982:	7442                	ld	s0,48(sp)
    80001984:	74a2                	ld	s1,40(sp)
    80001986:	7902                	ld	s2,32(sp)
    80001988:	69e2                	ld	s3,24(sp)
    8000198a:	6a42                	ld	s4,16(sp)
    8000198c:	6aa2                	ld	s5,8(sp)
    8000198e:	6b02                	ld	s6,0(sp)
    80001990:	6121                	addi	sp,sp,64
    80001992:	8082                	ret

0000000080001994 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000199a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000199c:	2501                	sext.w	a0,a0
    8000199e:	6422                	ld	s0,8(sp)
    800019a0:	0141                	addi	sp,sp,16
    800019a2:	8082                	ret

00000000800019a4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019a4:	1141                	addi	sp,sp,-16
    800019a6:	e422                	sd	s0,8(sp)
    800019a8:	0800                	addi	s0,sp,16
    800019aa:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019ac:	2781                	sext.w	a5,a5
    800019ae:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b0:	00010517          	auipc	a0,0x10
    800019b4:	92050513          	addi	a0,a0,-1760 # 800112d0 <cpus>
    800019b8:	953e                	add	a0,a0,a5
    800019ba:	6422                	ld	s0,8(sp)
    800019bc:	0141                	addi	sp,sp,16
    800019be:	8082                	ret

00000000800019c0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019c0:	1101                	addi	sp,sp,-32
    800019c2:	ec06                	sd	ra,24(sp)
    800019c4:	e822                	sd	s0,16(sp)
    800019c6:	e426                	sd	s1,8(sp)
    800019c8:	1000                	addi	s0,sp,32
  push_off();
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	1ac080e7          	jalr	428(ra) # 80000b76 <push_off>
    800019d2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019d4:	2781                	sext.w	a5,a5
    800019d6:	079e                	slli	a5,a5,0x7
    800019d8:	00010717          	auipc	a4,0x10
    800019dc:	8c870713          	addi	a4,a4,-1848 # 800112a0 <pid_lock>
    800019e0:	97ba                	add	a5,a5,a4
    800019e2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019e4:	fffff097          	auipc	ra,0xfffff
    800019e8:	232080e7          	jalr	562(ra) # 80000c16 <pop_off>
  return p;
}
    800019ec:	8526                	mv	a0,s1
    800019ee:	60e2                	ld	ra,24(sp)
    800019f0:	6442                	ld	s0,16(sp)
    800019f2:	64a2                	ld	s1,8(sp)
    800019f4:	6105                	addi	sp,sp,32
    800019f6:	8082                	ret

00000000800019f8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019f8:	1141                	addi	sp,sp,-16
    800019fa:	e406                	sd	ra,8(sp)
    800019fc:	e022                	sd	s0,0(sp)
    800019fe:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a00:	00000097          	auipc	ra,0x0
    80001a04:	fc0080e7          	jalr	-64(ra) # 800019c0 <myproc>
    80001a08:	fffff097          	auipc	ra,0xfffff
    80001a0c:	26e080e7          	jalr	622(ra) # 80000c76 <release>

  if (first) {
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	e207a783          	lw	a5,-480(a5) # 80008830 <first.1>
    80001a18:	eb89                	bnez	a5,80001a2a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a1a:	00001097          	auipc	ra,0x1
    80001a1e:	c14080e7          	jalr	-1004(ra) # 8000262e <usertrapret>
}
    80001a22:	60a2                	ld	ra,8(sp)
    80001a24:	6402                	ld	s0,0(sp)
    80001a26:	0141                	addi	sp,sp,16
    80001a28:	8082                	ret
    first = 0;
    80001a2a:	00007797          	auipc	a5,0x7
    80001a2e:	e007a323          	sw	zero,-506(a5) # 80008830 <first.1>
    fsinit(ROOTDEV);
    80001a32:	4505                	li	a0,1
    80001a34:	00002097          	auipc	ra,0x2
    80001a38:	93a080e7          	jalr	-1734(ra) # 8000336e <fsinit>
    80001a3c:	bff9                	j	80001a1a <forkret+0x22>

0000000080001a3e <allocpid>:
allocpid() {
    80001a3e:	1101                	addi	sp,sp,-32
    80001a40:	ec06                	sd	ra,24(sp)
    80001a42:	e822                	sd	s0,16(sp)
    80001a44:	e426                	sd	s1,8(sp)
    80001a46:	e04a                	sd	s2,0(sp)
    80001a48:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a4a:	00010917          	auipc	s2,0x10
    80001a4e:	85690913          	addi	s2,s2,-1962 # 800112a0 <pid_lock>
    80001a52:	854a                	mv	a0,s2
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	16e080e7          	jalr	366(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a5c:	00007797          	auipc	a5,0x7
    80001a60:	dd878793          	addi	a5,a5,-552 # 80008834 <nextpid>
    80001a64:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a66:	0014871b          	addiw	a4,s1,1
    80001a6a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a6c:	854a                	mv	a0,s2
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	208080e7          	jalr	520(ra) # 80000c76 <release>
}
    80001a76:	8526                	mv	a0,s1
    80001a78:	60e2                	ld	ra,24(sp)
    80001a7a:	6442                	ld	s0,16(sp)
    80001a7c:	64a2                	ld	s1,8(sp)
    80001a7e:	6902                	ld	s2,0(sp)
    80001a80:	6105                	addi	sp,sp,32
    80001a82:	8082                	ret

0000000080001a84 <proc_pagetable>:
{
    80001a84:	1101                	addi	sp,sp,-32
    80001a86:	ec06                	sd	ra,24(sp)
    80001a88:	e822                	sd	s0,16(sp)
    80001a8a:	e426                	sd	s1,8(sp)
    80001a8c:	e04a                	sd	s2,0(sp)
    80001a8e:	1000                	addi	s0,sp,32
    80001a90:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a92:	00000097          	auipc	ra,0x0
    80001a96:	8b6080e7          	jalr	-1866(ra) # 80001348 <uvmcreate>
    80001a9a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a9c:	c121                	beqz	a0,80001adc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a9e:	4729                	li	a4,10
    80001aa0:	00005697          	auipc	a3,0x5
    80001aa4:	56068693          	addi	a3,a3,1376 # 80007000 <_trampoline>
    80001aa8:	6605                	lui	a2,0x1
    80001aaa:	040005b7          	lui	a1,0x4000
    80001aae:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ab0:	05b2                	slli	a1,a1,0xc
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	61e080e7          	jalr	1566(ra) # 800010d0 <mappages>
    80001aba:	02054863          	bltz	a0,80001aea <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001abe:	4719                	li	a4,6
    80001ac0:	05893683          	ld	a3,88(s2)
    80001ac4:	6605                	lui	a2,0x1
    80001ac6:	020005b7          	lui	a1,0x2000
    80001aca:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001acc:	05b6                	slli	a1,a1,0xd
    80001ace:	8526                	mv	a0,s1
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	600080e7          	jalr	1536(ra) # 800010d0 <mappages>
    80001ad8:	02054163          	bltz	a0,80001afa <proc_pagetable+0x76>
}
    80001adc:	8526                	mv	a0,s1
    80001ade:	60e2                	ld	ra,24(sp)
    80001ae0:	6442                	ld	s0,16(sp)
    80001ae2:	64a2                	ld	s1,8(sp)
    80001ae4:	6902                	ld	s2,0(sp)
    80001ae6:	6105                	addi	sp,sp,32
    80001ae8:	8082                	ret
    uvmfree(pagetable, 0);
    80001aea:	4581                	li	a1,0
    80001aec:	8526                	mv	a0,s1
    80001aee:	00000097          	auipc	ra,0x0
    80001af2:	a58080e7          	jalr	-1448(ra) # 80001546 <uvmfree>
    return 0;
    80001af6:	4481                	li	s1,0
    80001af8:	b7d5                	j	80001adc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001afa:	4681                	li	a3,0
    80001afc:	4605                	li	a2,1
    80001afe:	040005b7          	lui	a1,0x4000
    80001b02:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b04:	05b2                	slli	a1,a1,0xc
    80001b06:	8526                	mv	a0,s1
    80001b08:	fffff097          	auipc	ra,0xfffff
    80001b0c:	77c080e7          	jalr	1916(ra) # 80001284 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b10:	4581                	li	a1,0
    80001b12:	8526                	mv	a0,s1
    80001b14:	00000097          	auipc	ra,0x0
    80001b18:	a32080e7          	jalr	-1486(ra) # 80001546 <uvmfree>
    return 0;
    80001b1c:	4481                	li	s1,0
    80001b1e:	bf7d                	j	80001adc <proc_pagetable+0x58>

0000000080001b20 <proc_freepagetable>:
{
    80001b20:	1101                	addi	sp,sp,-32
    80001b22:	ec06                	sd	ra,24(sp)
    80001b24:	e822                	sd	s0,16(sp)
    80001b26:	e426                	sd	s1,8(sp)
    80001b28:	e04a                	sd	s2,0(sp)
    80001b2a:	1000                	addi	s0,sp,32
    80001b2c:	84aa                	mv	s1,a0
    80001b2e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	040005b7          	lui	a1,0x4000
    80001b38:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b3a:	05b2                	slli	a1,a1,0xc
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	748080e7          	jalr	1864(ra) # 80001284 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b44:	4681                	li	a3,0
    80001b46:	4605                	li	a2,1
    80001b48:	020005b7          	lui	a1,0x2000
    80001b4c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b4e:	05b6                	slli	a1,a1,0xd
    80001b50:	8526                	mv	a0,s1
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	732080e7          	jalr	1842(ra) # 80001284 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b5a:	85ca                	mv	a1,s2
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	00000097          	auipc	ra,0x0
    80001b62:	9e8080e7          	jalr	-1560(ra) # 80001546 <uvmfree>
}
    80001b66:	60e2                	ld	ra,24(sp)
    80001b68:	6442                	ld	s0,16(sp)
    80001b6a:	64a2                	ld	s1,8(sp)
    80001b6c:	6902                	ld	s2,0(sp)
    80001b6e:	6105                	addi	sp,sp,32
    80001b70:	8082                	ret

0000000080001b72 <freeproc>:
{
    80001b72:	1101                	addi	sp,sp,-32
    80001b74:	ec06                	sd	ra,24(sp)
    80001b76:	e822                	sd	s0,16(sp)
    80001b78:	e426                	sd	s1,8(sp)
    80001b7a:	1000                	addi	s0,sp,32
    80001b7c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b7e:	6d28                	ld	a0,88(a0)
    80001b80:	c509                	beqz	a0,80001b8a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	e52080e7          	jalr	-430(ra) # 800009d4 <kfree>
  p->trapframe = 0;
    80001b8a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b8e:	68a8                	ld	a0,80(s1)
    80001b90:	c511                	beqz	a0,80001b9c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b92:	64ac                	ld	a1,72(s1)
    80001b94:	00000097          	auipc	ra,0x0
    80001b98:	f8c080e7          	jalr	-116(ra) # 80001b20 <proc_freepagetable>
  p->pagetable = 0;
    80001b9c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ba0:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ba4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ba8:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bac:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bb0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bb4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bb8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bbc:	0004ac23          	sw	zero,24(s1)
}
    80001bc0:	60e2                	ld	ra,24(sp)
    80001bc2:	6442                	ld	s0,16(sp)
    80001bc4:	64a2                	ld	s1,8(sp)
    80001bc6:	6105                	addi	sp,sp,32
    80001bc8:	8082                	ret

0000000080001bca <allocproc>:
{
    80001bca:	1101                	addi	sp,sp,-32
    80001bcc:	ec06                	sd	ra,24(sp)
    80001bce:	e822                	sd	s0,16(sp)
    80001bd0:	e426                	sd	s1,8(sp)
    80001bd2:	e04a                	sd	s2,0(sp)
    80001bd4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd6:	00010497          	auipc	s1,0x10
    80001bda:	afa48493          	addi	s1,s1,-1286 # 800116d0 <proc>
    80001bde:	00015917          	auipc	s2,0x15
    80001be2:	4f290913          	addi	s2,s2,1266 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001be6:	8526                	mv	a0,s1
    80001be8:	fffff097          	auipc	ra,0xfffff
    80001bec:	fda080e7          	jalr	-38(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001bf0:	4c9c                	lw	a5,24(s1)
    80001bf2:	cf81                	beqz	a5,80001c0a <allocproc+0x40>
      release(&p->lock);
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	080080e7          	jalr	128(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bfe:	16848493          	addi	s1,s1,360
    80001c02:	ff2492e3          	bne	s1,s2,80001be6 <allocproc+0x1c>
  return 0;
    80001c06:	4481                	li	s1,0
    80001c08:	a889                	j	80001c5a <allocproc+0x90>
  p->pid = allocpid();
    80001c0a:	00000097          	auipc	ra,0x0
    80001c0e:	e34080e7          	jalr	-460(ra) # 80001a3e <allocpid>
    80001c12:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c14:	4785                	li	a5,1
    80001c16:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	eba080e7          	jalr	-326(ra) # 80000ad2 <kalloc>
    80001c20:	892a                	mv	s2,a0
    80001c22:	eca8                	sd	a0,88(s1)
    80001c24:	c131                	beqz	a0,80001c68 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	e5c080e7          	jalr	-420(ra) # 80001a84 <proc_pagetable>
    80001c30:	892a                	mv	s2,a0
    80001c32:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c34:	c531                	beqz	a0,80001c80 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c36:	07000613          	li	a2,112
    80001c3a:	4581                	li	a1,0
    80001c3c:	06048513          	addi	a0,s1,96
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	07e080e7          	jalr	126(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c48:	00000797          	auipc	a5,0x0
    80001c4c:	db078793          	addi	a5,a5,-592 # 800019f8 <forkret>
    80001c50:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c52:	60bc                	ld	a5,64(s1)
    80001c54:	6705                	lui	a4,0x1
    80001c56:	97ba                	add	a5,a5,a4
    80001c58:	f4bc                	sd	a5,104(s1)
}
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6902                	ld	s2,0(sp)
    80001c64:	6105                	addi	sp,sp,32
    80001c66:	8082                	ret
    freeproc(p);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	00000097          	auipc	ra,0x0
    80001c6e:	f08080e7          	jalr	-248(ra) # 80001b72 <freeproc>
    release(&p->lock);
    80001c72:	8526                	mv	a0,s1
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	002080e7          	jalr	2(ra) # 80000c76 <release>
    return 0;
    80001c7c:	84ca                	mv	s1,s2
    80001c7e:	bff1                	j	80001c5a <allocproc+0x90>
    freeproc(p);
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	ef0080e7          	jalr	-272(ra) # 80001b72 <freeproc>
    release(&p->lock);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	fea080e7          	jalr	-22(ra) # 80000c76 <release>
    return 0;
    80001c94:	84ca                	mv	s1,s2
    80001c96:	b7d1                	j	80001c5a <allocproc+0x90>

0000000080001c98 <userinit>:
{
    80001c98:	1101                	addi	sp,sp,-32
    80001c9a:	ec06                	sd	ra,24(sp)
    80001c9c:	e822                	sd	s0,16(sp)
    80001c9e:	e426                	sd	s1,8(sp)
    80001ca0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	f28080e7          	jalr	-216(ra) # 80001bca <allocproc>
    80001caa:	84aa                	mv	s1,a0
  initproc = p;
    80001cac:	00007797          	auipc	a5,0x7
    80001cb0:	36a7be23          	sd	a0,892(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb4:	03400613          	li	a2,52
    80001cb8:	00007597          	auipc	a1,0x7
    80001cbc:	b8858593          	addi	a1,a1,-1144 # 80008840 <initcode>
    80001cc0:	6928                	ld	a0,80(a0)
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	6b4080e7          	jalr	1716(ra) # 80001376 <uvminit>
  p->sz = PGSIZE;
    80001cca:	6785                	lui	a5,0x1
    80001ccc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cce:	6cb8                	ld	a4,88(s1)
    80001cd0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd8:	4641                	li	a2,16
    80001cda:	00006597          	auipc	a1,0x6
    80001cde:	50e58593          	addi	a1,a1,1294 # 800081e8 <digits+0x1a8>
    80001ce2:	15848513          	addi	a0,s1,344
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	12a080e7          	jalr	298(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001cee:	00006517          	auipc	a0,0x6
    80001cf2:	50a50513          	addi	a0,a0,1290 # 800081f8 <digits+0x1b8>
    80001cf6:	00002097          	auipc	ra,0x2
    80001cfa:	0ae080e7          	jalr	174(ra) # 80003da4 <namei>
    80001cfe:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d02:	478d                	li	a5,3
    80001d04:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	f6e080e7          	jalr	-146(ra) # 80000c76 <release>
}
    80001d10:	60e2                	ld	ra,24(sp)
    80001d12:	6442                	ld	s0,16(sp)
    80001d14:	64a2                	ld	s1,8(sp)
    80001d16:	6105                	addi	sp,sp,32
    80001d18:	8082                	ret

0000000080001d1a <growproc>:
{
    80001d1a:	1101                	addi	sp,sp,-32
    80001d1c:	ec06                	sd	ra,24(sp)
    80001d1e:	e822                	sd	s0,16(sp)
    80001d20:	e426                	sd	s1,8(sp)
    80001d22:	e04a                	sd	s2,0(sp)
    80001d24:	1000                	addi	s0,sp,32
    80001d26:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	c98080e7          	jalr	-872(ra) # 800019c0 <myproc>
    80001d30:	892a                	mv	s2,a0
  sz = p->sz;
    80001d32:	652c                	ld	a1,72(a0)
    80001d34:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d38:	00904f63          	bgtz	s1,80001d56 <growproc+0x3c>
  } else if(n < 0){
    80001d3c:	0204cd63          	bltz	s1,80001d76 <growproc+0x5c>
  p->sz = sz;
    80001d40:	1782                	slli	a5,a5,0x20
    80001d42:	9381                	srli	a5,a5,0x20
    80001d44:	04f93423          	sd	a5,72(s2)
  return 0;
    80001d48:	4501                	li	a0,0
}
    80001d4a:	60e2                	ld	ra,24(sp)
    80001d4c:	6442                	ld	s0,16(sp)
    80001d4e:	64a2                	ld	s1,8(sp)
    80001d50:	6902                	ld	s2,0(sp)
    80001d52:	6105                	addi	sp,sp,32
    80001d54:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d56:	00f4863b          	addw	a2,s1,a5
    80001d5a:	1602                	slli	a2,a2,0x20
    80001d5c:	9201                	srli	a2,a2,0x20
    80001d5e:	1582                	slli	a1,a1,0x20
    80001d60:	9181                	srli	a1,a1,0x20
    80001d62:	6928                	ld	a0,80(a0)
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	6cc080e7          	jalr	1740(ra) # 80001430 <uvmalloc>
    80001d6c:	0005079b          	sext.w	a5,a0
    80001d70:	fbe1                	bnez	a5,80001d40 <growproc+0x26>
      return -1;
    80001d72:	557d                	li	a0,-1
    80001d74:	bfd9                	j	80001d4a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d76:	00f4863b          	addw	a2,s1,a5
    80001d7a:	1602                	slli	a2,a2,0x20
    80001d7c:	9201                	srli	a2,a2,0x20
    80001d7e:	1582                	slli	a1,a1,0x20
    80001d80:	9181                	srli	a1,a1,0x20
    80001d82:	6928                	ld	a0,80(a0)
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	664080e7          	jalr	1636(ra) # 800013e8 <uvmdealloc>
    80001d8c:	0005079b          	sext.w	a5,a0
    80001d90:	bf45                	j	80001d40 <growproc+0x26>

0000000080001d92 <fork>:
{
    80001d92:	7139                	addi	sp,sp,-64
    80001d94:	fc06                	sd	ra,56(sp)
    80001d96:	f822                	sd	s0,48(sp)
    80001d98:	f426                	sd	s1,40(sp)
    80001d9a:	f04a                	sd	s2,32(sp)
    80001d9c:	ec4e                	sd	s3,24(sp)
    80001d9e:	e852                	sd	s4,16(sp)
    80001da0:	e456                	sd	s5,8(sp)
    80001da2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001da4:	00000097          	auipc	ra,0x0
    80001da8:	c1c080e7          	jalr	-996(ra) # 800019c0 <myproc>
    80001dac:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	e1c080e7          	jalr	-484(ra) # 80001bca <allocproc>
    80001db6:	10050c63          	beqz	a0,80001ece <fork+0x13c>
    80001dba:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dbc:	048ab603          	ld	a2,72(s5)
    80001dc0:	692c                	ld	a1,80(a0)
    80001dc2:	050ab503          	ld	a0,80(s5)
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	7ba080e7          	jalr	1978(ra) # 80001580 <uvmcopy>
    80001dce:	04054863          	bltz	a0,80001e1e <fork+0x8c>
  np->sz = p->sz;
    80001dd2:	048ab783          	ld	a5,72(s5)
    80001dd6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dda:	058ab683          	ld	a3,88(s5)
    80001dde:	87b6                	mv	a5,a3
    80001de0:	058a3703          	ld	a4,88(s4)
    80001de4:	12068693          	addi	a3,a3,288
    80001de8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dec:	6788                	ld	a0,8(a5)
    80001dee:	6b8c                	ld	a1,16(a5)
    80001df0:	6f90                	ld	a2,24(a5)
    80001df2:	01073023          	sd	a6,0(a4)
    80001df6:	e708                	sd	a0,8(a4)
    80001df8:	eb0c                	sd	a1,16(a4)
    80001dfa:	ef10                	sd	a2,24(a4)
    80001dfc:	02078793          	addi	a5,a5,32
    80001e00:	02070713          	addi	a4,a4,32
    80001e04:	fed792e3          	bne	a5,a3,80001de8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e08:	058a3783          	ld	a5,88(s4)
    80001e0c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e10:	0d0a8493          	addi	s1,s5,208
    80001e14:	0d0a0913          	addi	s2,s4,208
    80001e18:	150a8993          	addi	s3,s5,336
    80001e1c:	a00d                	j	80001e3e <fork+0xac>
    freeproc(np);
    80001e1e:	8552                	mv	a0,s4
    80001e20:	00000097          	auipc	ra,0x0
    80001e24:	d52080e7          	jalr	-686(ra) # 80001b72 <freeproc>
    release(&np->lock);
    80001e28:	8552                	mv	a0,s4
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	e4c080e7          	jalr	-436(ra) # 80000c76 <release>
    return -1;
    80001e32:	597d                	li	s2,-1
    80001e34:	a059                	j	80001eba <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e36:	04a1                	addi	s1,s1,8
    80001e38:	0921                	addi	s2,s2,8
    80001e3a:	01348b63          	beq	s1,s3,80001e50 <fork+0xbe>
    if(p->ofile[i])
    80001e3e:	6088                	ld	a0,0(s1)
    80001e40:	d97d                	beqz	a0,80001e36 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e42:	00002097          	auipc	ra,0x2
    80001e46:	5f8080e7          	jalr	1528(ra) # 8000443a <filedup>
    80001e4a:	00a93023          	sd	a0,0(s2)
    80001e4e:	b7e5                	j	80001e36 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e50:	150ab503          	ld	a0,336(s5)
    80001e54:	00001097          	auipc	ra,0x1
    80001e58:	756080e7          	jalr	1878(ra) # 800035aa <idup>
    80001e5c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e60:	4641                	li	a2,16
    80001e62:	158a8593          	addi	a1,s5,344
    80001e66:	158a0513          	addi	a0,s4,344
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	fa6080e7          	jalr	-90(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e72:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e76:	8552                	mv	a0,s4
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	dfe080e7          	jalr	-514(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e80:	0000f497          	auipc	s1,0xf
    80001e84:	43848493          	addi	s1,s1,1080 # 800112b8 <wait_lock>
    80001e88:	8526                	mv	a0,s1
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	d38080e7          	jalr	-712(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001e92:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e96:	8526                	mv	a0,s1
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	dde080e7          	jalr	-546(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001ea0:	8552                	mv	a0,s4
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	d20080e7          	jalr	-736(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001eaa:	478d                	li	a5,3
    80001eac:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001eb0:	8552                	mv	a0,s4
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	dc4080e7          	jalr	-572(ra) # 80000c76 <release>
}
    80001eba:	854a                	mv	a0,s2
    80001ebc:	70e2                	ld	ra,56(sp)
    80001ebe:	7442                	ld	s0,48(sp)
    80001ec0:	74a2                	ld	s1,40(sp)
    80001ec2:	7902                	ld	s2,32(sp)
    80001ec4:	69e2                	ld	s3,24(sp)
    80001ec6:	6a42                	ld	s4,16(sp)
    80001ec8:	6aa2                	ld	s5,8(sp)
    80001eca:	6121                	addi	sp,sp,64
    80001ecc:	8082                	ret
    return -1;
    80001ece:	597d                	li	s2,-1
    80001ed0:	b7ed                	j	80001eba <fork+0x128>

0000000080001ed2 <scheduler>:
{
    80001ed2:	7139                	addi	sp,sp,-64
    80001ed4:	fc06                	sd	ra,56(sp)
    80001ed6:	f822                	sd	s0,48(sp)
    80001ed8:	f426                	sd	s1,40(sp)
    80001eda:	f04a                	sd	s2,32(sp)
    80001edc:	ec4e                	sd	s3,24(sp)
    80001ede:	e852                	sd	s4,16(sp)
    80001ee0:	e456                	sd	s5,8(sp)
    80001ee2:	e05a                	sd	s6,0(sp)
    80001ee4:	0080                	addi	s0,sp,64
    80001ee6:	8792                	mv	a5,tp
  int id = r_tp();
    80001ee8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eea:	00779a93          	slli	s5,a5,0x7
    80001eee:	0000f717          	auipc	a4,0xf
    80001ef2:	3b270713          	addi	a4,a4,946 # 800112a0 <pid_lock>
    80001ef6:	9756                	add	a4,a4,s5
    80001ef8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001efc:	0000f717          	auipc	a4,0xf
    80001f00:	3dc70713          	addi	a4,a4,988 # 800112d8 <cpus+0x8>
    80001f04:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f06:	498d                	li	s3,3
        p->state = RUNNING;
    80001f08:	4b11                	li	s6,4
        c->proc = p;
    80001f0a:	079e                	slli	a5,a5,0x7
    80001f0c:	0000fa17          	auipc	s4,0xf
    80001f10:	394a0a13          	addi	s4,s4,916 # 800112a0 <pid_lock>
    80001f14:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f16:	00015917          	auipc	s2,0x15
    80001f1a:	1ba90913          	addi	s2,s2,442 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f22:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f26:	10079073          	csrw	sstatus,a5
    80001f2a:	0000f497          	auipc	s1,0xf
    80001f2e:	7a648493          	addi	s1,s1,1958 # 800116d0 <proc>
    80001f32:	a811                	j	80001f46 <scheduler+0x74>
      release(&p->lock);
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	d40080e7          	jalr	-704(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f3e:	16848493          	addi	s1,s1,360
    80001f42:	fd248ee3          	beq	s1,s2,80001f1e <scheduler+0x4c>
      acquire(&p->lock);
    80001f46:	8526                	mv	a0,s1
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	c7a080e7          	jalr	-902(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001f50:	4c9c                	lw	a5,24(s1)
    80001f52:	ff3791e3          	bne	a5,s3,80001f34 <scheduler+0x62>
        p->state = RUNNING;
    80001f56:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f5a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f5e:	06048593          	addi	a1,s1,96
    80001f62:	8556                	mv	a0,s5
    80001f64:	00000097          	auipc	ra,0x0
    80001f68:	620080e7          	jalr	1568(ra) # 80002584 <swtch>
        c->proc = 0;
    80001f6c:	020a3823          	sd	zero,48(s4)
    80001f70:	b7d1                	j	80001f34 <scheduler+0x62>

0000000080001f72 <sched>:
{
    80001f72:	7179                	addi	sp,sp,-48
    80001f74:	f406                	sd	ra,40(sp)
    80001f76:	f022                	sd	s0,32(sp)
    80001f78:	ec26                	sd	s1,24(sp)
    80001f7a:	e84a                	sd	s2,16(sp)
    80001f7c:	e44e                	sd	s3,8(sp)
    80001f7e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f80:	00000097          	auipc	ra,0x0
    80001f84:	a40080e7          	jalr	-1472(ra) # 800019c0 <myproc>
    80001f88:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	bbe080e7          	jalr	-1090(ra) # 80000b48 <holding>
    80001f92:	c93d                	beqz	a0,80002008 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f94:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f96:	2781                	sext.w	a5,a5
    80001f98:	079e                	slli	a5,a5,0x7
    80001f9a:	0000f717          	auipc	a4,0xf
    80001f9e:	30670713          	addi	a4,a4,774 # 800112a0 <pid_lock>
    80001fa2:	97ba                	add	a5,a5,a4
    80001fa4:	0a87a703          	lw	a4,168(a5)
    80001fa8:	4785                	li	a5,1
    80001faa:	06f71763          	bne	a4,a5,80002018 <sched+0xa6>
  if(p->state == RUNNING)
    80001fae:	4c98                	lw	a4,24(s1)
    80001fb0:	4791                	li	a5,4
    80001fb2:	06f70b63          	beq	a4,a5,80002028 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fb6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fba:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fbc:	efb5                	bnez	a5,80002038 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fbe:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fc0:	0000f917          	auipc	s2,0xf
    80001fc4:	2e090913          	addi	s2,s2,736 # 800112a0 <pid_lock>
    80001fc8:	2781                	sext.w	a5,a5
    80001fca:	079e                	slli	a5,a5,0x7
    80001fcc:	97ca                	add	a5,a5,s2
    80001fce:	0ac7a983          	lw	s3,172(a5)
    80001fd2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fd4:	2781                	sext.w	a5,a5
    80001fd6:	079e                	slli	a5,a5,0x7
    80001fd8:	0000f597          	auipc	a1,0xf
    80001fdc:	30058593          	addi	a1,a1,768 # 800112d8 <cpus+0x8>
    80001fe0:	95be                	add	a1,a1,a5
    80001fe2:	06048513          	addi	a0,s1,96
    80001fe6:	00000097          	auipc	ra,0x0
    80001fea:	59e080e7          	jalr	1438(ra) # 80002584 <swtch>
    80001fee:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001ff0:	2781                	sext.w	a5,a5
    80001ff2:	079e                	slli	a5,a5,0x7
    80001ff4:	993e                	add	s2,s2,a5
    80001ff6:	0b392623          	sw	s3,172(s2)
}
    80001ffa:	70a2                	ld	ra,40(sp)
    80001ffc:	7402                	ld	s0,32(sp)
    80001ffe:	64e2                	ld	s1,24(sp)
    80002000:	6942                	ld	s2,16(sp)
    80002002:	69a2                	ld	s3,8(sp)
    80002004:	6145                	addi	sp,sp,48
    80002006:	8082                	ret
    panic("sched p->lock");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	1f850513          	addi	a0,a0,504 # 80008200 <digits+0x1c0>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	51c080e7          	jalr	1308(ra) # 8000052c <panic>
    panic("sched locks");
    80002018:	00006517          	auipc	a0,0x6
    8000201c:	1f850513          	addi	a0,a0,504 # 80008210 <digits+0x1d0>
    80002020:	ffffe097          	auipc	ra,0xffffe
    80002024:	50c080e7          	jalr	1292(ra) # 8000052c <panic>
    panic("sched running");
    80002028:	00006517          	auipc	a0,0x6
    8000202c:	1f850513          	addi	a0,a0,504 # 80008220 <digits+0x1e0>
    80002030:	ffffe097          	auipc	ra,0xffffe
    80002034:	4fc080e7          	jalr	1276(ra) # 8000052c <panic>
    panic("sched interruptible");
    80002038:	00006517          	auipc	a0,0x6
    8000203c:	1f850513          	addi	a0,a0,504 # 80008230 <digits+0x1f0>
    80002040:	ffffe097          	auipc	ra,0xffffe
    80002044:	4ec080e7          	jalr	1260(ra) # 8000052c <panic>

0000000080002048 <yield>:
{
    80002048:	1101                	addi	sp,sp,-32
    8000204a:	ec06                	sd	ra,24(sp)
    8000204c:	e822                	sd	s0,16(sp)
    8000204e:	e426                	sd	s1,8(sp)
    80002050:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002052:	00000097          	auipc	ra,0x0
    80002056:	96e080e7          	jalr	-1682(ra) # 800019c0 <myproc>
    8000205a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	b66080e7          	jalr	-1178(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80002064:	478d                	li	a5,3
    80002066:	cc9c                	sw	a5,24(s1)
  sched();
    80002068:	00000097          	auipc	ra,0x0
    8000206c:	f0a080e7          	jalr	-246(ra) # 80001f72 <sched>
  release(&p->lock);
    80002070:	8526                	mv	a0,s1
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	c04080e7          	jalr	-1020(ra) # 80000c76 <release>
}
    8000207a:	60e2                	ld	ra,24(sp)
    8000207c:	6442                	ld	s0,16(sp)
    8000207e:	64a2                	ld	s1,8(sp)
    80002080:	6105                	addi	sp,sp,32
    80002082:	8082                	ret

0000000080002084 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002084:	7179                	addi	sp,sp,-48
    80002086:	f406                	sd	ra,40(sp)
    80002088:	f022                	sd	s0,32(sp)
    8000208a:	ec26                	sd	s1,24(sp)
    8000208c:	e84a                	sd	s2,16(sp)
    8000208e:	e44e                	sd	s3,8(sp)
    80002090:	1800                	addi	s0,sp,48
    80002092:	89aa                	mv	s3,a0
    80002094:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002096:	00000097          	auipc	ra,0x0
    8000209a:	92a080e7          	jalr	-1750(ra) # 800019c0 <myproc>
    8000209e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	b22080e7          	jalr	-1246(ra) # 80000bc2 <acquire>
  release(lk);
    800020a8:	854a                	mv	a0,s2
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	bcc080e7          	jalr	-1076(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    800020b2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020b6:	4789                	li	a5,2
    800020b8:	cc9c                	sw	a5,24(s1)

  sched();
    800020ba:	00000097          	auipc	ra,0x0
    800020be:	eb8080e7          	jalr	-328(ra) # 80001f72 <sched>

  // Tidy up.
  p->chan = 0;
    800020c2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020c6:	8526                	mv	a0,s1
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	bae080e7          	jalr	-1106(ra) # 80000c76 <release>
  acquire(lk);
    800020d0:	854a                	mv	a0,s2
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	af0080e7          	jalr	-1296(ra) # 80000bc2 <acquire>
}
    800020da:	70a2                	ld	ra,40(sp)
    800020dc:	7402                	ld	s0,32(sp)
    800020de:	64e2                	ld	s1,24(sp)
    800020e0:	6942                	ld	s2,16(sp)
    800020e2:	69a2                	ld	s3,8(sp)
    800020e4:	6145                	addi	sp,sp,48
    800020e6:	8082                	ret

00000000800020e8 <wait>:
{
    800020e8:	715d                	addi	sp,sp,-80
    800020ea:	e486                	sd	ra,72(sp)
    800020ec:	e0a2                	sd	s0,64(sp)
    800020ee:	fc26                	sd	s1,56(sp)
    800020f0:	f84a                	sd	s2,48(sp)
    800020f2:	f44e                	sd	s3,40(sp)
    800020f4:	f052                	sd	s4,32(sp)
    800020f6:	ec56                	sd	s5,24(sp)
    800020f8:	e85a                	sd	s6,16(sp)
    800020fa:	e45e                	sd	s7,8(sp)
    800020fc:	e062                	sd	s8,0(sp)
    800020fe:	0880                	addi	s0,sp,80
    80002100:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002102:	00000097          	auipc	ra,0x0
    80002106:	8be080e7          	jalr	-1858(ra) # 800019c0 <myproc>
    8000210a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000210c:	0000f517          	auipc	a0,0xf
    80002110:	1ac50513          	addi	a0,a0,428 # 800112b8 <wait_lock>
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	aae080e7          	jalr	-1362(ra) # 80000bc2 <acquire>
    havekids = 0;
    8000211c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000211e:	4a15                	li	s4,5
        havekids = 1;
    80002120:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002122:	00015997          	auipc	s3,0x15
    80002126:	fae98993          	addi	s3,s3,-82 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000212a:	0000fc17          	auipc	s8,0xf
    8000212e:	18ec0c13          	addi	s8,s8,398 # 800112b8 <wait_lock>
    havekids = 0;
    80002132:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002134:	0000f497          	auipc	s1,0xf
    80002138:	59c48493          	addi	s1,s1,1436 # 800116d0 <proc>
    8000213c:	a0bd                	j	800021aa <wait+0xc2>
          pid = np->pid;
    8000213e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002142:	000b0e63          	beqz	s6,8000215e <wait+0x76>
    80002146:	4691                	li	a3,4
    80002148:	02c48613          	addi	a2,s1,44
    8000214c:	85da                	mv	a1,s6
    8000214e:	05093503          	ld	a0,80(s2)
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	532080e7          	jalr	1330(ra) # 80001684 <copyout>
    8000215a:	02054563          	bltz	a0,80002184 <wait+0x9c>
          freeproc(np);
    8000215e:	8526                	mv	a0,s1
    80002160:	00000097          	auipc	ra,0x0
    80002164:	a12080e7          	jalr	-1518(ra) # 80001b72 <freeproc>
          release(&np->lock);
    80002168:	8526                	mv	a0,s1
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	b0c080e7          	jalr	-1268(ra) # 80000c76 <release>
          release(&wait_lock);
    80002172:	0000f517          	auipc	a0,0xf
    80002176:	14650513          	addi	a0,a0,326 # 800112b8 <wait_lock>
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	afc080e7          	jalr	-1284(ra) # 80000c76 <release>
          return pid;
    80002182:	a09d                	j	800021e8 <wait+0x100>
            release(&np->lock);
    80002184:	8526                	mv	a0,s1
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	af0080e7          	jalr	-1296(ra) # 80000c76 <release>
            release(&wait_lock);
    8000218e:	0000f517          	auipc	a0,0xf
    80002192:	12a50513          	addi	a0,a0,298 # 800112b8 <wait_lock>
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	ae0080e7          	jalr	-1312(ra) # 80000c76 <release>
            return -1;
    8000219e:	59fd                	li	s3,-1
    800021a0:	a0a1                	j	800021e8 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021a2:	16848493          	addi	s1,s1,360
    800021a6:	03348463          	beq	s1,s3,800021ce <wait+0xe6>
      if(np->parent == p){
    800021aa:	7c9c                	ld	a5,56(s1)
    800021ac:	ff279be3          	bne	a5,s2,800021a2 <wait+0xba>
        acquire(&np->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	a10080e7          	jalr	-1520(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800021ba:	4c9c                	lw	a5,24(s1)
    800021bc:	f94781e3          	beq	a5,s4,8000213e <wait+0x56>
        release(&np->lock);
    800021c0:	8526                	mv	a0,s1
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	ab4080e7          	jalr	-1356(ra) # 80000c76 <release>
        havekids = 1;
    800021ca:	8756                	mv	a4,s5
    800021cc:	bfd9                	j	800021a2 <wait+0xba>
    if(!havekids || p->killed){
    800021ce:	c701                	beqz	a4,800021d6 <wait+0xee>
    800021d0:	02892783          	lw	a5,40(s2)
    800021d4:	c79d                	beqz	a5,80002202 <wait+0x11a>
      release(&wait_lock);
    800021d6:	0000f517          	auipc	a0,0xf
    800021da:	0e250513          	addi	a0,a0,226 # 800112b8 <wait_lock>
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	a98080e7          	jalr	-1384(ra) # 80000c76 <release>
      return -1;
    800021e6:	59fd                	li	s3,-1
}
    800021e8:	854e                	mv	a0,s3
    800021ea:	60a6                	ld	ra,72(sp)
    800021ec:	6406                	ld	s0,64(sp)
    800021ee:	74e2                	ld	s1,56(sp)
    800021f0:	7942                	ld	s2,48(sp)
    800021f2:	79a2                	ld	s3,40(sp)
    800021f4:	7a02                	ld	s4,32(sp)
    800021f6:	6ae2                	ld	s5,24(sp)
    800021f8:	6b42                	ld	s6,16(sp)
    800021fa:	6ba2                	ld	s7,8(sp)
    800021fc:	6c02                	ld	s8,0(sp)
    800021fe:	6161                	addi	sp,sp,80
    80002200:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002202:	85e2                	mv	a1,s8
    80002204:	854a                	mv	a0,s2
    80002206:	00000097          	auipc	ra,0x0
    8000220a:	e7e080e7          	jalr	-386(ra) # 80002084 <sleep>
    havekids = 0;
    8000220e:	b715                	j	80002132 <wait+0x4a>

0000000080002210 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002210:	7139                	addi	sp,sp,-64
    80002212:	fc06                	sd	ra,56(sp)
    80002214:	f822                	sd	s0,48(sp)
    80002216:	f426                	sd	s1,40(sp)
    80002218:	f04a                	sd	s2,32(sp)
    8000221a:	ec4e                	sd	s3,24(sp)
    8000221c:	e852                	sd	s4,16(sp)
    8000221e:	e456                	sd	s5,8(sp)
    80002220:	0080                	addi	s0,sp,64
    80002222:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002224:	0000f497          	auipc	s1,0xf
    80002228:	4ac48493          	addi	s1,s1,1196 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000222c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000222e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002230:	00015917          	auipc	s2,0x15
    80002234:	ea090913          	addi	s2,s2,-352 # 800170d0 <tickslock>
    80002238:	a811                	j	8000224c <wakeup+0x3c>
      }
      release(&p->lock);
    8000223a:	8526                	mv	a0,s1
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	a3a080e7          	jalr	-1478(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002244:	16848493          	addi	s1,s1,360
    80002248:	03248663          	beq	s1,s2,80002274 <wakeup+0x64>
    if(p != myproc()){
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	774080e7          	jalr	1908(ra) # 800019c0 <myproc>
    80002254:	fea488e3          	beq	s1,a0,80002244 <wakeup+0x34>
      acquire(&p->lock);
    80002258:	8526                	mv	a0,s1
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	968080e7          	jalr	-1688(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002262:	4c9c                	lw	a5,24(s1)
    80002264:	fd379be3          	bne	a5,s3,8000223a <wakeup+0x2a>
    80002268:	709c                	ld	a5,32(s1)
    8000226a:	fd4798e3          	bne	a5,s4,8000223a <wakeup+0x2a>
        p->state = RUNNABLE;
    8000226e:	0154ac23          	sw	s5,24(s1)
    80002272:	b7e1                	j	8000223a <wakeup+0x2a>
    }
  }
}
    80002274:	70e2                	ld	ra,56(sp)
    80002276:	7442                	ld	s0,48(sp)
    80002278:	74a2                	ld	s1,40(sp)
    8000227a:	7902                	ld	s2,32(sp)
    8000227c:	69e2                	ld	s3,24(sp)
    8000227e:	6a42                	ld	s4,16(sp)
    80002280:	6aa2                	ld	s5,8(sp)
    80002282:	6121                	addi	sp,sp,64
    80002284:	8082                	ret

0000000080002286 <reparent>:
{
    80002286:	7179                	addi	sp,sp,-48
    80002288:	f406                	sd	ra,40(sp)
    8000228a:	f022                	sd	s0,32(sp)
    8000228c:	ec26                	sd	s1,24(sp)
    8000228e:	e84a                	sd	s2,16(sp)
    80002290:	e44e                	sd	s3,8(sp)
    80002292:	e052                	sd	s4,0(sp)
    80002294:	1800                	addi	s0,sp,48
    80002296:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002298:	0000f497          	auipc	s1,0xf
    8000229c:	43848493          	addi	s1,s1,1080 # 800116d0 <proc>
      pp->parent = initproc;
    800022a0:	00007a17          	auipc	s4,0x7
    800022a4:	d88a0a13          	addi	s4,s4,-632 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022a8:	00015997          	auipc	s3,0x15
    800022ac:	e2898993          	addi	s3,s3,-472 # 800170d0 <tickslock>
    800022b0:	a029                	j	800022ba <reparent+0x34>
    800022b2:	16848493          	addi	s1,s1,360
    800022b6:	01348d63          	beq	s1,s3,800022d0 <reparent+0x4a>
    if(pp->parent == p){
    800022ba:	7c9c                	ld	a5,56(s1)
    800022bc:	ff279be3          	bne	a5,s2,800022b2 <reparent+0x2c>
      pp->parent = initproc;
    800022c0:	000a3503          	ld	a0,0(s4)
    800022c4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	f4a080e7          	jalr	-182(ra) # 80002210 <wakeup>
    800022ce:	b7d5                	j	800022b2 <reparent+0x2c>
}
    800022d0:	70a2                	ld	ra,40(sp)
    800022d2:	7402                	ld	s0,32(sp)
    800022d4:	64e2                	ld	s1,24(sp)
    800022d6:	6942                	ld	s2,16(sp)
    800022d8:	69a2                	ld	s3,8(sp)
    800022da:	6a02                	ld	s4,0(sp)
    800022dc:	6145                	addi	sp,sp,48
    800022de:	8082                	ret

00000000800022e0 <exit>:
{
    800022e0:	7179                	addi	sp,sp,-48
    800022e2:	f406                	sd	ra,40(sp)
    800022e4:	f022                	sd	s0,32(sp)
    800022e6:	ec26                	sd	s1,24(sp)
    800022e8:	e84a                	sd	s2,16(sp)
    800022ea:	e44e                	sd	s3,8(sp)
    800022ec:	e052                	sd	s4,0(sp)
    800022ee:	1800                	addi	s0,sp,48
    800022f0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	6ce080e7          	jalr	1742(ra) # 800019c0 <myproc>
    800022fa:	89aa                	mv	s3,a0
  if(p == initproc)
    800022fc:	00007797          	auipc	a5,0x7
    80002300:	d2c7b783          	ld	a5,-724(a5) # 80009028 <initproc>
    80002304:	0d050493          	addi	s1,a0,208
    80002308:	15050913          	addi	s2,a0,336
    8000230c:	02a79363          	bne	a5,a0,80002332 <exit+0x52>
    panic("init exiting");
    80002310:	00006517          	auipc	a0,0x6
    80002314:	f3850513          	addi	a0,a0,-200 # 80008248 <digits+0x208>
    80002318:	ffffe097          	auipc	ra,0xffffe
    8000231c:	214080e7          	jalr	532(ra) # 8000052c <panic>
      fileclose(f);
    80002320:	00002097          	auipc	ra,0x2
    80002324:	16c080e7          	jalr	364(ra) # 8000448c <fileclose>
      p->ofile[fd] = 0;
    80002328:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000232c:	04a1                	addi	s1,s1,8
    8000232e:	01248563          	beq	s1,s2,80002338 <exit+0x58>
    if(p->ofile[fd]){
    80002332:	6088                	ld	a0,0(s1)
    80002334:	f575                	bnez	a0,80002320 <exit+0x40>
    80002336:	bfdd                	j	8000232c <exit+0x4c>
  begin_op();
    80002338:	00002097          	auipc	ra,0x2
    8000233c:	c8c080e7          	jalr	-884(ra) # 80003fc4 <begin_op>
  iput(p->cwd);
    80002340:	1509b503          	ld	a0,336(s3)
    80002344:	00001097          	auipc	ra,0x1
    80002348:	45e080e7          	jalr	1118(ra) # 800037a2 <iput>
  end_op();
    8000234c:	00002097          	auipc	ra,0x2
    80002350:	cf6080e7          	jalr	-778(ra) # 80004042 <end_op>
  p->cwd = 0;
    80002354:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002358:	0000f497          	auipc	s1,0xf
    8000235c:	f6048493          	addi	s1,s1,-160 # 800112b8 <wait_lock>
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	860080e7          	jalr	-1952(ra) # 80000bc2 <acquire>
  reparent(p);
    8000236a:	854e                	mv	a0,s3
    8000236c:	00000097          	auipc	ra,0x0
    80002370:	f1a080e7          	jalr	-230(ra) # 80002286 <reparent>
  wakeup(p->parent);
    80002374:	0389b503          	ld	a0,56(s3)
    80002378:	00000097          	auipc	ra,0x0
    8000237c:	e98080e7          	jalr	-360(ra) # 80002210 <wakeup>
  acquire(&p->lock);
    80002380:	854e                	mv	a0,s3
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	840080e7          	jalr	-1984(ra) # 80000bc2 <acquire>
  p->xstate = status;
    8000238a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000238e:	4795                	li	a5,5
    80002390:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002394:	8526                	mv	a0,s1
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	8e0080e7          	jalr	-1824(ra) # 80000c76 <release>
  sched();
    8000239e:	00000097          	auipc	ra,0x0
    800023a2:	bd4080e7          	jalr	-1068(ra) # 80001f72 <sched>
  panic("zombie exit");
    800023a6:	00006517          	auipc	a0,0x6
    800023aa:	eb250513          	addi	a0,a0,-334 # 80008258 <digits+0x218>
    800023ae:	ffffe097          	auipc	ra,0xffffe
    800023b2:	17e080e7          	jalr	382(ra) # 8000052c <panic>

00000000800023b6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023b6:	7179                	addi	sp,sp,-48
    800023b8:	f406                	sd	ra,40(sp)
    800023ba:	f022                	sd	s0,32(sp)
    800023bc:	ec26                	sd	s1,24(sp)
    800023be:	e84a                	sd	s2,16(sp)
    800023c0:	e44e                	sd	s3,8(sp)
    800023c2:	1800                	addi	s0,sp,48
    800023c4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023c6:	0000f497          	auipc	s1,0xf
    800023ca:	30a48493          	addi	s1,s1,778 # 800116d0 <proc>
    800023ce:	00015997          	auipc	s3,0x15
    800023d2:	d0298993          	addi	s3,s3,-766 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023d6:	8526                	mv	a0,s1
    800023d8:	ffffe097          	auipc	ra,0xffffe
    800023dc:	7ea080e7          	jalr	2026(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    800023e0:	589c                	lw	a5,48(s1)
    800023e2:	01278d63          	beq	a5,s2,800023fc <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023e6:	8526                	mv	a0,s1
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	88e080e7          	jalr	-1906(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023f0:	16848493          	addi	s1,s1,360
    800023f4:	ff3491e3          	bne	s1,s3,800023d6 <kill+0x20>
  }
  return -1;
    800023f8:	557d                	li	a0,-1
    800023fa:	a829                	j	80002414 <kill+0x5e>
      p->killed = 1;
    800023fc:	4785                	li	a5,1
    800023fe:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002400:	4c98                	lw	a4,24(s1)
    80002402:	4789                	li	a5,2
    80002404:	00f70f63          	beq	a4,a5,80002422 <kill+0x6c>
      release(&p->lock);
    80002408:	8526                	mv	a0,s1
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	86c080e7          	jalr	-1940(ra) # 80000c76 <release>
      return 0;
    80002412:	4501                	li	a0,0
}
    80002414:	70a2                	ld	ra,40(sp)
    80002416:	7402                	ld	s0,32(sp)
    80002418:	64e2                	ld	s1,24(sp)
    8000241a:	6942                	ld	s2,16(sp)
    8000241c:	69a2                	ld	s3,8(sp)
    8000241e:	6145                	addi	sp,sp,48
    80002420:	8082                	ret
        p->state = RUNNABLE;
    80002422:	478d                	li	a5,3
    80002424:	cc9c                	sw	a5,24(s1)
    80002426:	b7cd                	j	80002408 <kill+0x52>

0000000080002428 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002428:	7179                	addi	sp,sp,-48
    8000242a:	f406                	sd	ra,40(sp)
    8000242c:	f022                	sd	s0,32(sp)
    8000242e:	ec26                	sd	s1,24(sp)
    80002430:	e84a                	sd	s2,16(sp)
    80002432:	e44e                	sd	s3,8(sp)
    80002434:	e052                	sd	s4,0(sp)
    80002436:	1800                	addi	s0,sp,48
    80002438:	84aa                	mv	s1,a0
    8000243a:	892e                	mv	s2,a1
    8000243c:	89b2                	mv	s3,a2
    8000243e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	580080e7          	jalr	1408(ra) # 800019c0 <myproc>
  if(user_dst){
    80002448:	c08d                	beqz	s1,8000246a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000244a:	86d2                	mv	a3,s4
    8000244c:	864e                	mv	a2,s3
    8000244e:	85ca                	mv	a1,s2
    80002450:	6928                	ld	a0,80(a0)
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	232080e7          	jalr	562(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000245a:	70a2                	ld	ra,40(sp)
    8000245c:	7402                	ld	s0,32(sp)
    8000245e:	64e2                	ld	s1,24(sp)
    80002460:	6942                	ld	s2,16(sp)
    80002462:	69a2                	ld	s3,8(sp)
    80002464:	6a02                	ld	s4,0(sp)
    80002466:	6145                	addi	sp,sp,48
    80002468:	8082                	ret
    memmove((char *)dst, src, len);
    8000246a:	000a061b          	sext.w	a2,s4
    8000246e:	85ce                	mv	a1,s3
    80002470:	854a                	mv	a0,s2
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	8a8080e7          	jalr	-1880(ra) # 80000d1a <memmove>
    return 0;
    8000247a:	8526                	mv	a0,s1
    8000247c:	bff9                	j	8000245a <either_copyout+0x32>

000000008000247e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000247e:	7179                	addi	sp,sp,-48
    80002480:	f406                	sd	ra,40(sp)
    80002482:	f022                	sd	s0,32(sp)
    80002484:	ec26                	sd	s1,24(sp)
    80002486:	e84a                	sd	s2,16(sp)
    80002488:	e44e                	sd	s3,8(sp)
    8000248a:	e052                	sd	s4,0(sp)
    8000248c:	1800                	addi	s0,sp,48
    8000248e:	892a                	mv	s2,a0
    80002490:	84ae                	mv	s1,a1
    80002492:	89b2                	mv	s3,a2
    80002494:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	52a080e7          	jalr	1322(ra) # 800019c0 <myproc>
  if(user_src){
    8000249e:	c08d                	beqz	s1,800024c0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024a0:	86d2                	mv	a3,s4
    800024a2:	864e                	mv	a2,s3
    800024a4:	85ca                	mv	a1,s2
    800024a6:	6928                	ld	a0,80(a0)
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	268080e7          	jalr	616(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024b0:	70a2                	ld	ra,40(sp)
    800024b2:	7402                	ld	s0,32(sp)
    800024b4:	64e2                	ld	s1,24(sp)
    800024b6:	6942                	ld	s2,16(sp)
    800024b8:	69a2                	ld	s3,8(sp)
    800024ba:	6a02                	ld	s4,0(sp)
    800024bc:	6145                	addi	sp,sp,48
    800024be:	8082                	ret
    memmove(dst, (char*)src, len);
    800024c0:	000a061b          	sext.w	a2,s4
    800024c4:	85ce                	mv	a1,s3
    800024c6:	854a                	mv	a0,s2
    800024c8:	fffff097          	auipc	ra,0xfffff
    800024cc:	852080e7          	jalr	-1966(ra) # 80000d1a <memmove>
    return 0;
    800024d0:	8526                	mv	a0,s1
    800024d2:	bff9                	j	800024b0 <either_copyin+0x32>

00000000800024d4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024d4:	715d                	addi	sp,sp,-80
    800024d6:	e486                	sd	ra,72(sp)
    800024d8:	e0a2                	sd	s0,64(sp)
    800024da:	fc26                	sd	s1,56(sp)
    800024dc:	f84a                	sd	s2,48(sp)
    800024de:	f44e                	sd	s3,40(sp)
    800024e0:	f052                	sd	s4,32(sp)
    800024e2:	ec56                	sd	s5,24(sp)
    800024e4:	e85a                	sd	s6,16(sp)
    800024e6:	e45e                	sd	s7,8(sp)
    800024e8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024ea:	00006517          	auipc	a0,0x6
    800024ee:	bde50513          	addi	a0,a0,-1058 # 800080c8 <digits+0x88>
    800024f2:	ffffe097          	auipc	ra,0xffffe
    800024f6:	084080e7          	jalr	132(ra) # 80000576 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024fa:	0000f497          	auipc	s1,0xf
    800024fe:	32e48493          	addi	s1,s1,814 # 80011828 <proc+0x158>
    80002502:	00015917          	auipc	s2,0x15
    80002506:	d2690913          	addi	s2,s2,-730 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000250a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000250c:	00006997          	auipc	s3,0x6
    80002510:	d5c98993          	addi	s3,s3,-676 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002514:	00006a97          	auipc	s5,0x6
    80002518:	d5ca8a93          	addi	s5,s5,-676 # 80008270 <digits+0x230>
    printf("\n");
    8000251c:	00006a17          	auipc	s4,0x6
    80002520:	baca0a13          	addi	s4,s4,-1108 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002524:	00006b97          	auipc	s7,0x6
    80002528:	d84b8b93          	addi	s7,s7,-636 # 800082a8 <states.0>
    8000252c:	a00d                	j	8000254e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000252e:	ed86a583          	lw	a1,-296(a3)
    80002532:	8556                	mv	a0,s5
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	042080e7          	jalr	66(ra) # 80000576 <printf>
    printf("\n");
    8000253c:	8552                	mv	a0,s4
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	038080e7          	jalr	56(ra) # 80000576 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002546:	16848493          	addi	s1,s1,360
    8000254a:	03248263          	beq	s1,s2,8000256e <procdump+0x9a>
    if(p->state == UNUSED)
    8000254e:	86a6                	mv	a3,s1
    80002550:	ec04a783          	lw	a5,-320(s1)
    80002554:	dbed                	beqz	a5,80002546 <procdump+0x72>
      state = "???";
    80002556:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002558:	fcfb6be3          	bltu	s6,a5,8000252e <procdump+0x5a>
    8000255c:	02079713          	slli	a4,a5,0x20
    80002560:	01d75793          	srli	a5,a4,0x1d
    80002564:	97de                	add	a5,a5,s7
    80002566:	6390                	ld	a2,0(a5)
    80002568:	f279                	bnez	a2,8000252e <procdump+0x5a>
      state = "???";
    8000256a:	864e                	mv	a2,s3
    8000256c:	b7c9                	j	8000252e <procdump+0x5a>
  }
}
    8000256e:	60a6                	ld	ra,72(sp)
    80002570:	6406                	ld	s0,64(sp)
    80002572:	74e2                	ld	s1,56(sp)
    80002574:	7942                	ld	s2,48(sp)
    80002576:	79a2                	ld	s3,40(sp)
    80002578:	7a02                	ld	s4,32(sp)
    8000257a:	6ae2                	ld	s5,24(sp)
    8000257c:	6b42                	ld	s6,16(sp)
    8000257e:	6ba2                	ld	s7,8(sp)
    80002580:	6161                	addi	sp,sp,80
    80002582:	8082                	ret

0000000080002584 <swtch>:
    80002584:	00153023          	sd	ra,0(a0)
    80002588:	00253423          	sd	sp,8(a0)
    8000258c:	e900                	sd	s0,16(a0)
    8000258e:	ed04                	sd	s1,24(a0)
    80002590:	03253023          	sd	s2,32(a0)
    80002594:	03353423          	sd	s3,40(a0)
    80002598:	03453823          	sd	s4,48(a0)
    8000259c:	03553c23          	sd	s5,56(a0)
    800025a0:	05653023          	sd	s6,64(a0)
    800025a4:	05753423          	sd	s7,72(a0)
    800025a8:	05853823          	sd	s8,80(a0)
    800025ac:	05953c23          	sd	s9,88(a0)
    800025b0:	07a53023          	sd	s10,96(a0)
    800025b4:	07b53423          	sd	s11,104(a0)
    800025b8:	0005b083          	ld	ra,0(a1)
    800025bc:	0085b103          	ld	sp,8(a1)
    800025c0:	6980                	ld	s0,16(a1)
    800025c2:	6d84                	ld	s1,24(a1)
    800025c4:	0205b903          	ld	s2,32(a1)
    800025c8:	0285b983          	ld	s3,40(a1)
    800025cc:	0305ba03          	ld	s4,48(a1)
    800025d0:	0385ba83          	ld	s5,56(a1)
    800025d4:	0405bb03          	ld	s6,64(a1)
    800025d8:	0485bb83          	ld	s7,72(a1)
    800025dc:	0505bc03          	ld	s8,80(a1)
    800025e0:	0585bc83          	ld	s9,88(a1)
    800025e4:	0605bd03          	ld	s10,96(a1)
    800025e8:	0685bd83          	ld	s11,104(a1)
    800025ec:	8082                	ret

00000000800025ee <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025ee:	1141                	addi	sp,sp,-16
    800025f0:	e406                	sd	ra,8(sp)
    800025f2:	e022                	sd	s0,0(sp)
    800025f4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025f6:	00006597          	auipc	a1,0x6
    800025fa:	ce258593          	addi	a1,a1,-798 # 800082d8 <states.0+0x30>
    800025fe:	00015517          	auipc	a0,0x15
    80002602:	ad250513          	addi	a0,a0,-1326 # 800170d0 <tickslock>
    80002606:	ffffe097          	auipc	ra,0xffffe
    8000260a:	52c080e7          	jalr	1324(ra) # 80000b32 <initlock>
}
    8000260e:	60a2                	ld	ra,8(sp)
    80002610:	6402                	ld	s0,0(sp)
    80002612:	0141                	addi	sp,sp,16
    80002614:	8082                	ret

0000000080002616 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002616:	1141                	addi	sp,sp,-16
    80002618:	e422                	sd	s0,8(sp)
    8000261a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000261c:	00003797          	auipc	a5,0x3
    80002620:	4b478793          	addi	a5,a5,1204 # 80005ad0 <kernelvec>
    80002624:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002628:	6422                	ld	s0,8(sp)
    8000262a:	0141                	addi	sp,sp,16
    8000262c:	8082                	ret

000000008000262e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000262e:	1141                	addi	sp,sp,-16
    80002630:	e406                	sd	ra,8(sp)
    80002632:	e022                	sd	s0,0(sp)
    80002634:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002636:	fffff097          	auipc	ra,0xfffff
    8000263a:	38a080e7          	jalr	906(ra) # 800019c0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000263e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002642:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002644:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002648:	00005697          	auipc	a3,0x5
    8000264c:	9b868693          	addi	a3,a3,-1608 # 80007000 <_trampoline>
    80002650:	00005717          	auipc	a4,0x5
    80002654:	9b070713          	addi	a4,a4,-1616 # 80007000 <_trampoline>
    80002658:	8f15                	sub	a4,a4,a3
    8000265a:	040007b7          	lui	a5,0x4000
    8000265e:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002660:	07b2                	slli	a5,a5,0xc
    80002662:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002664:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002668:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000266a:	18002673          	csrr	a2,satp
    8000266e:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002670:	6d30                	ld	a2,88(a0)
    80002672:	6138                	ld	a4,64(a0)
    80002674:	6585                	lui	a1,0x1
    80002676:	972e                	add	a4,a4,a1
    80002678:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000267a:	6d38                	ld	a4,88(a0)
    8000267c:	00000617          	auipc	a2,0x0
    80002680:	13860613          	addi	a2,a2,312 # 800027b4 <usertrap>
    80002684:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002686:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002688:	8612                	mv	a2,tp
    8000268a:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000268c:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002690:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002694:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002698:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000269c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000269e:	6f18                	ld	a4,24(a4)
    800026a0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026a4:	692c                	ld	a1,80(a0)
    800026a6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026a8:	00005717          	auipc	a4,0x5
    800026ac:	9e870713          	addi	a4,a4,-1560 # 80007090 <userret>
    800026b0:	8f15                	sub	a4,a4,a3
    800026b2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026b4:	577d                	li	a4,-1
    800026b6:	177e                	slli	a4,a4,0x3f
    800026b8:	8dd9                	or	a1,a1,a4
    800026ba:	02000537          	lui	a0,0x2000
    800026be:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800026c0:	0536                	slli	a0,a0,0xd
    800026c2:	9782                	jalr	a5
}
    800026c4:	60a2                	ld	ra,8(sp)
    800026c6:	6402                	ld	s0,0(sp)
    800026c8:	0141                	addi	sp,sp,16
    800026ca:	8082                	ret

00000000800026cc <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026cc:	1101                	addi	sp,sp,-32
    800026ce:	ec06                	sd	ra,24(sp)
    800026d0:	e822                	sd	s0,16(sp)
    800026d2:	e426                	sd	s1,8(sp)
    800026d4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026d6:	00015497          	auipc	s1,0x15
    800026da:	9fa48493          	addi	s1,s1,-1542 # 800170d0 <tickslock>
    800026de:	8526                	mv	a0,s1
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	4e2080e7          	jalr	1250(ra) # 80000bc2 <acquire>
  ticks++;
    800026e8:	00007517          	auipc	a0,0x7
    800026ec:	94850513          	addi	a0,a0,-1720 # 80009030 <ticks>
    800026f0:	411c                	lw	a5,0(a0)
    800026f2:	2785                	addiw	a5,a5,1
    800026f4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026f6:	00000097          	auipc	ra,0x0
    800026fa:	b1a080e7          	jalr	-1254(ra) # 80002210 <wakeup>
  release(&tickslock);
    800026fe:	8526                	mv	a0,s1
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	576080e7          	jalr	1398(ra) # 80000c76 <release>
}
    80002708:	60e2                	ld	ra,24(sp)
    8000270a:	6442                	ld	s0,16(sp)
    8000270c:	64a2                	ld	s1,8(sp)
    8000270e:	6105                	addi	sp,sp,32
    80002710:	8082                	ret

0000000080002712 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002712:	1101                	addi	sp,sp,-32
    80002714:	ec06                	sd	ra,24(sp)
    80002716:	e822                	sd	s0,16(sp)
    80002718:	e426                	sd	s1,8(sp)
    8000271a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000271c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002720:	00074d63          	bltz	a4,8000273a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002724:	57fd                	li	a5,-1
    80002726:	17fe                	slli	a5,a5,0x3f
    80002728:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000272a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000272c:	06f70363          	beq	a4,a5,80002792 <devintr+0x80>
  }
}
    80002730:	60e2                	ld	ra,24(sp)
    80002732:	6442                	ld	s0,16(sp)
    80002734:	64a2                	ld	s1,8(sp)
    80002736:	6105                	addi	sp,sp,32
    80002738:	8082                	ret
     (scause & 0xff) == 9){
    8000273a:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    8000273e:	46a5                	li	a3,9
    80002740:	fed792e3          	bne	a5,a3,80002724 <devintr+0x12>
    int irq = plic_claim();
    80002744:	00003097          	auipc	ra,0x3
    80002748:	494080e7          	jalr	1172(ra) # 80005bd8 <plic_claim>
    8000274c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000274e:	47a9                	li	a5,10
    80002750:	02f50763          	beq	a0,a5,8000277e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002754:	4785                	li	a5,1
    80002756:	02f50963          	beq	a0,a5,80002788 <devintr+0x76>
    return 1;
    8000275a:	4505                	li	a0,1
    } else if(irq){
    8000275c:	d8f1                	beqz	s1,80002730 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000275e:	85a6                	mv	a1,s1
    80002760:	00006517          	auipc	a0,0x6
    80002764:	b8050513          	addi	a0,a0,-1152 # 800082e0 <states.0+0x38>
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	e0e080e7          	jalr	-498(ra) # 80000576 <printf>
      plic_complete(irq);
    80002770:	8526                	mv	a0,s1
    80002772:	00003097          	auipc	ra,0x3
    80002776:	48a080e7          	jalr	1162(ra) # 80005bfc <plic_complete>
    return 1;
    8000277a:	4505                	li	a0,1
    8000277c:	bf55                	j	80002730 <devintr+0x1e>
      uartintr();
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	206080e7          	jalr	518(ra) # 80000984 <uartintr>
    80002786:	b7ed                	j	80002770 <devintr+0x5e>
      virtio_disk_intr();
    80002788:	00004097          	auipc	ra,0x4
    8000278c:	900080e7          	jalr	-1792(ra) # 80006088 <virtio_disk_intr>
    80002790:	b7c5                	j	80002770 <devintr+0x5e>
    if(cpuid() == 0){
    80002792:	fffff097          	auipc	ra,0xfffff
    80002796:	202080e7          	jalr	514(ra) # 80001994 <cpuid>
    8000279a:	c901                	beqz	a0,800027aa <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000279c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027a0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027a2:	14479073          	csrw	sip,a5
    return 2;
    800027a6:	4509                	li	a0,2
    800027a8:	b761                	j	80002730 <devintr+0x1e>
      clockintr();
    800027aa:	00000097          	auipc	ra,0x0
    800027ae:	f22080e7          	jalr	-222(ra) # 800026cc <clockintr>
    800027b2:	b7ed                	j	8000279c <devintr+0x8a>

00000000800027b4 <usertrap>:
{
    800027b4:	1101                	addi	sp,sp,-32
    800027b6:	ec06                	sd	ra,24(sp)
    800027b8:	e822                	sd	s0,16(sp)
    800027ba:	e426                	sd	s1,8(sp)
    800027bc:	e04a                	sd	s2,0(sp)
    800027be:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027c0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027c4:	1007f793          	andi	a5,a5,256
    800027c8:	e3ad                	bnez	a5,8000282a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027ca:	00003797          	auipc	a5,0x3
    800027ce:	30678793          	addi	a5,a5,774 # 80005ad0 <kernelvec>
    800027d2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027d6:	fffff097          	auipc	ra,0xfffff
    800027da:	1ea080e7          	jalr	490(ra) # 800019c0 <myproc>
    800027de:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027e0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027e2:	14102773          	csrr	a4,sepc
    800027e6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027ec:	47a1                	li	a5,8
    800027ee:	04f71c63          	bne	a4,a5,80002846 <usertrap+0x92>
    if(p->killed)
    800027f2:	551c                	lw	a5,40(a0)
    800027f4:	e3b9                	bnez	a5,8000283a <usertrap+0x86>
    p->trapframe->epc += 4;
    800027f6:	6cb8                	ld	a4,88(s1)
    800027f8:	6f1c                	ld	a5,24(a4)
    800027fa:	0791                	addi	a5,a5,4
    800027fc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027fe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002802:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002806:	10079073          	csrw	sstatus,a5
    syscall();
    8000280a:	00000097          	auipc	ra,0x0
    8000280e:	2e0080e7          	jalr	736(ra) # 80002aea <syscall>
  if(p->killed)
    80002812:	549c                	lw	a5,40(s1)
    80002814:	ebc1                	bnez	a5,800028a4 <usertrap+0xf0>
  usertrapret();
    80002816:	00000097          	auipc	ra,0x0
    8000281a:	e18080e7          	jalr	-488(ra) # 8000262e <usertrapret>
}
    8000281e:	60e2                	ld	ra,24(sp)
    80002820:	6442                	ld	s0,16(sp)
    80002822:	64a2                	ld	s1,8(sp)
    80002824:	6902                	ld	s2,0(sp)
    80002826:	6105                	addi	sp,sp,32
    80002828:	8082                	ret
    panic("usertrap: not from user mode");
    8000282a:	00006517          	auipc	a0,0x6
    8000282e:	ad650513          	addi	a0,a0,-1322 # 80008300 <states.0+0x58>
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	cfa080e7          	jalr	-774(ra) # 8000052c <panic>
      exit(-1);
    8000283a:	557d                	li	a0,-1
    8000283c:	00000097          	auipc	ra,0x0
    80002840:	aa4080e7          	jalr	-1372(ra) # 800022e0 <exit>
    80002844:	bf4d                	j	800027f6 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002846:	00000097          	auipc	ra,0x0
    8000284a:	ecc080e7          	jalr	-308(ra) # 80002712 <devintr>
    8000284e:	892a                	mv	s2,a0
    80002850:	c501                	beqz	a0,80002858 <usertrap+0xa4>
  if(p->killed)
    80002852:	549c                	lw	a5,40(s1)
    80002854:	c3a1                	beqz	a5,80002894 <usertrap+0xe0>
    80002856:	a815                	j	8000288a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002858:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000285c:	5890                	lw	a2,48(s1)
    8000285e:	00006517          	auipc	a0,0x6
    80002862:	ac250513          	addi	a0,a0,-1342 # 80008320 <states.0+0x78>
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	d10080e7          	jalr	-752(ra) # 80000576 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000286e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002872:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002876:	00006517          	auipc	a0,0x6
    8000287a:	ada50513          	addi	a0,a0,-1318 # 80008350 <states.0+0xa8>
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	cf8080e7          	jalr	-776(ra) # 80000576 <printf>
    p->killed = 1;
    80002886:	4785                	li	a5,1
    80002888:	d49c                	sw	a5,40(s1)
    exit(-1);
    8000288a:	557d                	li	a0,-1
    8000288c:	00000097          	auipc	ra,0x0
    80002890:	a54080e7          	jalr	-1452(ra) # 800022e0 <exit>
  if(which_dev == 2)
    80002894:	4789                	li	a5,2
    80002896:	f8f910e3          	bne	s2,a5,80002816 <usertrap+0x62>
    yield();
    8000289a:	fffff097          	auipc	ra,0xfffff
    8000289e:	7ae080e7          	jalr	1966(ra) # 80002048 <yield>
    800028a2:	bf95                	j	80002816 <usertrap+0x62>
  int which_dev = 0;
    800028a4:	4901                	li	s2,0
    800028a6:	b7d5                	j	8000288a <usertrap+0xd6>

00000000800028a8 <kerneltrap>:
{
    800028a8:	7179                	addi	sp,sp,-48
    800028aa:	f406                	sd	ra,40(sp)
    800028ac:	f022                	sd	s0,32(sp)
    800028ae:	ec26                	sd	s1,24(sp)
    800028b0:	e84a                	sd	s2,16(sp)
    800028b2:	e44e                	sd	s3,8(sp)
    800028b4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ba:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028be:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028c2:	1004f793          	andi	a5,s1,256
    800028c6:	cb85                	beqz	a5,800028f6 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028cc:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028ce:	ef85                	bnez	a5,80002906 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028d0:	00000097          	auipc	ra,0x0
    800028d4:	e42080e7          	jalr	-446(ra) # 80002712 <devintr>
    800028d8:	cd1d                	beqz	a0,80002916 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028da:	4789                	li	a5,2
    800028dc:	06f50a63          	beq	a0,a5,80002950 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028e0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028e4:	10049073          	csrw	sstatus,s1
}
    800028e8:	70a2                	ld	ra,40(sp)
    800028ea:	7402                	ld	s0,32(sp)
    800028ec:	64e2                	ld	s1,24(sp)
    800028ee:	6942                	ld	s2,16(sp)
    800028f0:	69a2                	ld	s3,8(sp)
    800028f2:	6145                	addi	sp,sp,48
    800028f4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028f6:	00006517          	auipc	a0,0x6
    800028fa:	a7a50513          	addi	a0,a0,-1414 # 80008370 <states.0+0xc8>
    800028fe:	ffffe097          	auipc	ra,0xffffe
    80002902:	c2e080e7          	jalr	-978(ra) # 8000052c <panic>
    panic("kerneltrap: interrupts enabled");
    80002906:	00006517          	auipc	a0,0x6
    8000290a:	a9250513          	addi	a0,a0,-1390 # 80008398 <states.0+0xf0>
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	c1e080e7          	jalr	-994(ra) # 8000052c <panic>
    printf("scause %p\n", scause);
    80002916:	85ce                	mv	a1,s3
    80002918:	00006517          	auipc	a0,0x6
    8000291c:	aa050513          	addi	a0,a0,-1376 # 800083b8 <states.0+0x110>
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	c56080e7          	jalr	-938(ra) # 80000576 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002928:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000292c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002930:	00006517          	auipc	a0,0x6
    80002934:	a9850513          	addi	a0,a0,-1384 # 800083c8 <states.0+0x120>
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	c3e080e7          	jalr	-962(ra) # 80000576 <printf>
    panic("kerneltrap");
    80002940:	00006517          	auipc	a0,0x6
    80002944:	aa050513          	addi	a0,a0,-1376 # 800083e0 <states.0+0x138>
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	be4080e7          	jalr	-1052(ra) # 8000052c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002950:	fffff097          	auipc	ra,0xfffff
    80002954:	070080e7          	jalr	112(ra) # 800019c0 <myproc>
    80002958:	d541                	beqz	a0,800028e0 <kerneltrap+0x38>
    8000295a:	fffff097          	auipc	ra,0xfffff
    8000295e:	066080e7          	jalr	102(ra) # 800019c0 <myproc>
    80002962:	4d18                	lw	a4,24(a0)
    80002964:	4791                	li	a5,4
    80002966:	f6f71de3          	bne	a4,a5,800028e0 <kerneltrap+0x38>
    yield();
    8000296a:	fffff097          	auipc	ra,0xfffff
    8000296e:	6de080e7          	jalr	1758(ra) # 80002048 <yield>
    80002972:	b7bd                	j	800028e0 <kerneltrap+0x38>

0000000080002974 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002974:	1101                	addi	sp,sp,-32
    80002976:	ec06                	sd	ra,24(sp)
    80002978:	e822                	sd	s0,16(sp)
    8000297a:	e426                	sd	s1,8(sp)
    8000297c:	1000                	addi	s0,sp,32
    8000297e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002980:	fffff097          	auipc	ra,0xfffff
    80002984:	040080e7          	jalr	64(ra) # 800019c0 <myproc>
  switch (n) {
    80002988:	4795                	li	a5,5
    8000298a:	0497e163          	bltu	a5,s1,800029cc <argraw+0x58>
    8000298e:	048a                	slli	s1,s1,0x2
    80002990:	00006717          	auipc	a4,0x6
    80002994:	a8870713          	addi	a4,a4,-1400 # 80008418 <states.0+0x170>
    80002998:	94ba                	add	s1,s1,a4
    8000299a:	409c                	lw	a5,0(s1)
    8000299c:	97ba                	add	a5,a5,a4
    8000299e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029a0:	6d3c                	ld	a5,88(a0)
    800029a2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029a4:	60e2                	ld	ra,24(sp)
    800029a6:	6442                	ld	s0,16(sp)
    800029a8:	64a2                	ld	s1,8(sp)
    800029aa:	6105                	addi	sp,sp,32
    800029ac:	8082                	ret
    return p->trapframe->a1;
    800029ae:	6d3c                	ld	a5,88(a0)
    800029b0:	7fa8                	ld	a0,120(a5)
    800029b2:	bfcd                	j	800029a4 <argraw+0x30>
    return p->trapframe->a2;
    800029b4:	6d3c                	ld	a5,88(a0)
    800029b6:	63c8                	ld	a0,128(a5)
    800029b8:	b7f5                	j	800029a4 <argraw+0x30>
    return p->trapframe->a3;
    800029ba:	6d3c                	ld	a5,88(a0)
    800029bc:	67c8                	ld	a0,136(a5)
    800029be:	b7dd                	j	800029a4 <argraw+0x30>
    return p->trapframe->a4;
    800029c0:	6d3c                	ld	a5,88(a0)
    800029c2:	6bc8                	ld	a0,144(a5)
    800029c4:	b7c5                	j	800029a4 <argraw+0x30>
    return p->trapframe->a5;
    800029c6:	6d3c                	ld	a5,88(a0)
    800029c8:	6fc8                	ld	a0,152(a5)
    800029ca:	bfe9                	j	800029a4 <argraw+0x30>
  panic("argraw");
    800029cc:	00006517          	auipc	a0,0x6
    800029d0:	a2450513          	addi	a0,a0,-1500 # 800083f0 <states.0+0x148>
    800029d4:	ffffe097          	auipc	ra,0xffffe
    800029d8:	b58080e7          	jalr	-1192(ra) # 8000052c <panic>

00000000800029dc <fetchaddr>:
{
    800029dc:	1101                	addi	sp,sp,-32
    800029de:	ec06                	sd	ra,24(sp)
    800029e0:	e822                	sd	s0,16(sp)
    800029e2:	e426                	sd	s1,8(sp)
    800029e4:	e04a                	sd	s2,0(sp)
    800029e6:	1000                	addi	s0,sp,32
    800029e8:	84aa                	mv	s1,a0
    800029ea:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029ec:	fffff097          	auipc	ra,0xfffff
    800029f0:	fd4080e7          	jalr	-44(ra) # 800019c0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029f4:	653c                	ld	a5,72(a0)
    800029f6:	02f4f863          	bgeu	s1,a5,80002a26 <fetchaddr+0x4a>
    800029fa:	00848713          	addi	a4,s1,8
    800029fe:	02e7e663          	bltu	a5,a4,80002a2a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a02:	46a1                	li	a3,8
    80002a04:	8626                	mv	a2,s1
    80002a06:	85ca                	mv	a1,s2
    80002a08:	6928                	ld	a0,80(a0)
    80002a0a:	fffff097          	auipc	ra,0xfffff
    80002a0e:	d06080e7          	jalr	-762(ra) # 80001710 <copyin>
    80002a12:	00a03533          	snez	a0,a0
    80002a16:	40a00533          	neg	a0,a0
}
    80002a1a:	60e2                	ld	ra,24(sp)
    80002a1c:	6442                	ld	s0,16(sp)
    80002a1e:	64a2                	ld	s1,8(sp)
    80002a20:	6902                	ld	s2,0(sp)
    80002a22:	6105                	addi	sp,sp,32
    80002a24:	8082                	ret
    return -1;
    80002a26:	557d                	li	a0,-1
    80002a28:	bfcd                	j	80002a1a <fetchaddr+0x3e>
    80002a2a:	557d                	li	a0,-1
    80002a2c:	b7fd                	j	80002a1a <fetchaddr+0x3e>

0000000080002a2e <fetchstr>:
{
    80002a2e:	7179                	addi	sp,sp,-48
    80002a30:	f406                	sd	ra,40(sp)
    80002a32:	f022                	sd	s0,32(sp)
    80002a34:	ec26                	sd	s1,24(sp)
    80002a36:	e84a                	sd	s2,16(sp)
    80002a38:	e44e                	sd	s3,8(sp)
    80002a3a:	1800                	addi	s0,sp,48
    80002a3c:	892a                	mv	s2,a0
    80002a3e:	84ae                	mv	s1,a1
    80002a40:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a42:	fffff097          	auipc	ra,0xfffff
    80002a46:	f7e080e7          	jalr	-130(ra) # 800019c0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a4a:	86ce                	mv	a3,s3
    80002a4c:	864a                	mv	a2,s2
    80002a4e:	85a6                	mv	a1,s1
    80002a50:	6928                	ld	a0,80(a0)
    80002a52:	fffff097          	auipc	ra,0xfffff
    80002a56:	d4c080e7          	jalr	-692(ra) # 8000179e <copyinstr>
  if(err < 0)
    80002a5a:	00054763          	bltz	a0,80002a68 <fetchstr+0x3a>
  return strlen(buf);
    80002a5e:	8526                	mv	a0,s1
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	3e2080e7          	jalr	994(ra) # 80000e42 <strlen>
}
    80002a68:	70a2                	ld	ra,40(sp)
    80002a6a:	7402                	ld	s0,32(sp)
    80002a6c:	64e2                	ld	s1,24(sp)
    80002a6e:	6942                	ld	s2,16(sp)
    80002a70:	69a2                	ld	s3,8(sp)
    80002a72:	6145                	addi	sp,sp,48
    80002a74:	8082                	ret

0000000080002a76 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a76:	1101                	addi	sp,sp,-32
    80002a78:	ec06                	sd	ra,24(sp)
    80002a7a:	e822                	sd	s0,16(sp)
    80002a7c:	e426                	sd	s1,8(sp)
    80002a7e:	1000                	addi	s0,sp,32
    80002a80:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a82:	00000097          	auipc	ra,0x0
    80002a86:	ef2080e7          	jalr	-270(ra) # 80002974 <argraw>
    80002a8a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a8c:	4501                	li	a0,0
    80002a8e:	60e2                	ld	ra,24(sp)
    80002a90:	6442                	ld	s0,16(sp)
    80002a92:	64a2                	ld	s1,8(sp)
    80002a94:	6105                	addi	sp,sp,32
    80002a96:	8082                	ret

0000000080002a98 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a98:	1101                	addi	sp,sp,-32
    80002a9a:	ec06                	sd	ra,24(sp)
    80002a9c:	e822                	sd	s0,16(sp)
    80002a9e:	e426                	sd	s1,8(sp)
    80002aa0:	1000                	addi	s0,sp,32
    80002aa2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aa4:	00000097          	auipc	ra,0x0
    80002aa8:	ed0080e7          	jalr	-304(ra) # 80002974 <argraw>
    80002aac:	e088                	sd	a0,0(s1)
  return 0;
}
    80002aae:	4501                	li	a0,0
    80002ab0:	60e2                	ld	ra,24(sp)
    80002ab2:	6442                	ld	s0,16(sp)
    80002ab4:	64a2                	ld	s1,8(sp)
    80002ab6:	6105                	addi	sp,sp,32
    80002ab8:	8082                	ret

0000000080002aba <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002aba:	1101                	addi	sp,sp,-32
    80002abc:	ec06                	sd	ra,24(sp)
    80002abe:	e822                	sd	s0,16(sp)
    80002ac0:	e426                	sd	s1,8(sp)
    80002ac2:	e04a                	sd	s2,0(sp)
    80002ac4:	1000                	addi	s0,sp,32
    80002ac6:	84ae                	mv	s1,a1
    80002ac8:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002aca:	00000097          	auipc	ra,0x0
    80002ace:	eaa080e7          	jalr	-342(ra) # 80002974 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ad2:	864a                	mv	a2,s2
    80002ad4:	85a6                	mv	a1,s1
    80002ad6:	00000097          	auipc	ra,0x0
    80002ada:	f58080e7          	jalr	-168(ra) # 80002a2e <fetchstr>
}
    80002ade:	60e2                	ld	ra,24(sp)
    80002ae0:	6442                	ld	s0,16(sp)
    80002ae2:	64a2                	ld	s1,8(sp)
    80002ae4:	6902                	ld	s2,0(sp)
    80002ae6:	6105                	addi	sp,sp,32
    80002ae8:	8082                	ret

0000000080002aea <syscall>:
[SYS_symlink]   sys_symlink,
};

void
syscall(void)
{
    80002aea:	1101                	addi	sp,sp,-32
    80002aec:	ec06                	sd	ra,24(sp)
    80002aee:	e822                	sd	s0,16(sp)
    80002af0:	e426                	sd	s1,8(sp)
    80002af2:	e04a                	sd	s2,0(sp)
    80002af4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	eca080e7          	jalr	-310(ra) # 800019c0 <myproc>
    80002afe:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b00:	05853903          	ld	s2,88(a0)
    80002b04:	0a893783          	ld	a5,168(s2)
    80002b08:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b0c:	37fd                	addiw	a5,a5,-1
    80002b0e:	4755                	li	a4,21
    80002b10:	00f76f63          	bltu	a4,a5,80002b2e <syscall+0x44>
    80002b14:	00369713          	slli	a4,a3,0x3
    80002b18:	00006797          	auipc	a5,0x6
    80002b1c:	91878793          	addi	a5,a5,-1768 # 80008430 <syscalls>
    80002b20:	97ba                	add	a5,a5,a4
    80002b22:	639c                	ld	a5,0(a5)
    80002b24:	c789                	beqz	a5,80002b2e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b26:	9782                	jalr	a5
    80002b28:	06a93823          	sd	a0,112(s2)
    80002b2c:	a839                	j	80002b4a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b2e:	15848613          	addi	a2,s1,344
    80002b32:	588c                	lw	a1,48(s1)
    80002b34:	00006517          	auipc	a0,0x6
    80002b38:	8c450513          	addi	a0,a0,-1852 # 800083f8 <states.0+0x150>
    80002b3c:	ffffe097          	auipc	ra,0xffffe
    80002b40:	a3a080e7          	jalr	-1478(ra) # 80000576 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b44:	6cbc                	ld	a5,88(s1)
    80002b46:	577d                	li	a4,-1
    80002b48:	fbb8                	sd	a4,112(a5)
  }
}
    80002b4a:	60e2                	ld	ra,24(sp)
    80002b4c:	6442                	ld	s0,16(sp)
    80002b4e:	64a2                	ld	s1,8(sp)
    80002b50:	6902                	ld	s2,0(sp)
    80002b52:	6105                	addi	sp,sp,32
    80002b54:	8082                	ret

0000000080002b56 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b56:	1101                	addi	sp,sp,-32
    80002b58:	ec06                	sd	ra,24(sp)
    80002b5a:	e822                	sd	s0,16(sp)
    80002b5c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b5e:	fec40593          	addi	a1,s0,-20
    80002b62:	4501                	li	a0,0
    80002b64:	00000097          	auipc	ra,0x0
    80002b68:	f12080e7          	jalr	-238(ra) # 80002a76 <argint>
    return -1;
    80002b6c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b6e:	00054963          	bltz	a0,80002b80 <sys_exit+0x2a>
  exit(n);
    80002b72:	fec42503          	lw	a0,-20(s0)
    80002b76:	fffff097          	auipc	ra,0xfffff
    80002b7a:	76a080e7          	jalr	1898(ra) # 800022e0 <exit>
  return 0;  // not reached
    80002b7e:	4781                	li	a5,0
}
    80002b80:	853e                	mv	a0,a5
    80002b82:	60e2                	ld	ra,24(sp)
    80002b84:	6442                	ld	s0,16(sp)
    80002b86:	6105                	addi	sp,sp,32
    80002b88:	8082                	ret

0000000080002b8a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b8a:	1141                	addi	sp,sp,-16
    80002b8c:	e406                	sd	ra,8(sp)
    80002b8e:	e022                	sd	s0,0(sp)
    80002b90:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	e2e080e7          	jalr	-466(ra) # 800019c0 <myproc>
}
    80002b9a:	5908                	lw	a0,48(a0)
    80002b9c:	60a2                	ld	ra,8(sp)
    80002b9e:	6402                	ld	s0,0(sp)
    80002ba0:	0141                	addi	sp,sp,16
    80002ba2:	8082                	ret

0000000080002ba4 <sys_fork>:

uint64
sys_fork(void)
{
    80002ba4:	1141                	addi	sp,sp,-16
    80002ba6:	e406                	sd	ra,8(sp)
    80002ba8:	e022                	sd	s0,0(sp)
    80002baa:	0800                	addi	s0,sp,16
  return fork();
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	1e6080e7          	jalr	486(ra) # 80001d92 <fork>
}
    80002bb4:	60a2                	ld	ra,8(sp)
    80002bb6:	6402                	ld	s0,0(sp)
    80002bb8:	0141                	addi	sp,sp,16
    80002bba:	8082                	ret

0000000080002bbc <sys_wait>:

uint64
sys_wait(void)
{
    80002bbc:	1101                	addi	sp,sp,-32
    80002bbe:	ec06                	sd	ra,24(sp)
    80002bc0:	e822                	sd	s0,16(sp)
    80002bc2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002bc4:	fe840593          	addi	a1,s0,-24
    80002bc8:	4501                	li	a0,0
    80002bca:	00000097          	auipc	ra,0x0
    80002bce:	ece080e7          	jalr	-306(ra) # 80002a98 <argaddr>
    80002bd2:	87aa                	mv	a5,a0
    return -1;
    80002bd4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bd6:	0007c863          	bltz	a5,80002be6 <sys_wait+0x2a>
  return wait(p);
    80002bda:	fe843503          	ld	a0,-24(s0)
    80002bde:	fffff097          	auipc	ra,0xfffff
    80002be2:	50a080e7          	jalr	1290(ra) # 800020e8 <wait>
}
    80002be6:	60e2                	ld	ra,24(sp)
    80002be8:	6442                	ld	s0,16(sp)
    80002bea:	6105                	addi	sp,sp,32
    80002bec:	8082                	ret

0000000080002bee <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002bee:	7179                	addi	sp,sp,-48
    80002bf0:	f406                	sd	ra,40(sp)
    80002bf2:	f022                	sd	s0,32(sp)
    80002bf4:	ec26                	sd	s1,24(sp)
    80002bf6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002bf8:	fdc40593          	addi	a1,s0,-36
    80002bfc:	4501                	li	a0,0
    80002bfe:	00000097          	auipc	ra,0x0
    80002c02:	e78080e7          	jalr	-392(ra) # 80002a76 <argint>
    80002c06:	87aa                	mv	a5,a0
    return -1;
    80002c08:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002c0a:	0207c063          	bltz	a5,80002c2a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002c0e:	fffff097          	auipc	ra,0xfffff
    80002c12:	db2080e7          	jalr	-590(ra) # 800019c0 <myproc>
    80002c16:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c18:	fdc42503          	lw	a0,-36(s0)
    80002c1c:	fffff097          	auipc	ra,0xfffff
    80002c20:	0fe080e7          	jalr	254(ra) # 80001d1a <growproc>
    80002c24:	00054863          	bltz	a0,80002c34 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002c28:	8526                	mv	a0,s1
}
    80002c2a:	70a2                	ld	ra,40(sp)
    80002c2c:	7402                	ld	s0,32(sp)
    80002c2e:	64e2                	ld	s1,24(sp)
    80002c30:	6145                	addi	sp,sp,48
    80002c32:	8082                	ret
    return -1;
    80002c34:	557d                	li	a0,-1
    80002c36:	bfd5                	j	80002c2a <sys_sbrk+0x3c>

0000000080002c38 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c38:	7139                	addi	sp,sp,-64
    80002c3a:	fc06                	sd	ra,56(sp)
    80002c3c:	f822                	sd	s0,48(sp)
    80002c3e:	f426                	sd	s1,40(sp)
    80002c40:	f04a                	sd	s2,32(sp)
    80002c42:	ec4e                	sd	s3,24(sp)
    80002c44:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c46:	fcc40593          	addi	a1,s0,-52
    80002c4a:	4501                	li	a0,0
    80002c4c:	00000097          	auipc	ra,0x0
    80002c50:	e2a080e7          	jalr	-470(ra) # 80002a76 <argint>
    return -1;
    80002c54:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c56:	06054563          	bltz	a0,80002cc0 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c5a:	00014517          	auipc	a0,0x14
    80002c5e:	47650513          	addi	a0,a0,1142 # 800170d0 <tickslock>
    80002c62:	ffffe097          	auipc	ra,0xffffe
    80002c66:	f60080e7          	jalr	-160(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002c6a:	00006917          	auipc	s2,0x6
    80002c6e:	3c692903          	lw	s2,966(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002c72:	fcc42783          	lw	a5,-52(s0)
    80002c76:	cf85                	beqz	a5,80002cae <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c78:	00014997          	auipc	s3,0x14
    80002c7c:	45898993          	addi	s3,s3,1112 # 800170d0 <tickslock>
    80002c80:	00006497          	auipc	s1,0x6
    80002c84:	3b048493          	addi	s1,s1,944 # 80009030 <ticks>
    if(myproc()->killed){
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	d38080e7          	jalr	-712(ra) # 800019c0 <myproc>
    80002c90:	551c                	lw	a5,40(a0)
    80002c92:	ef9d                	bnez	a5,80002cd0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002c94:	85ce                	mv	a1,s3
    80002c96:	8526                	mv	a0,s1
    80002c98:	fffff097          	auipc	ra,0xfffff
    80002c9c:	3ec080e7          	jalr	1004(ra) # 80002084 <sleep>
  while(ticks - ticks0 < n){
    80002ca0:	409c                	lw	a5,0(s1)
    80002ca2:	412787bb          	subw	a5,a5,s2
    80002ca6:	fcc42703          	lw	a4,-52(s0)
    80002caa:	fce7efe3          	bltu	a5,a4,80002c88 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002cae:	00014517          	auipc	a0,0x14
    80002cb2:	42250513          	addi	a0,a0,1058 # 800170d0 <tickslock>
    80002cb6:	ffffe097          	auipc	ra,0xffffe
    80002cba:	fc0080e7          	jalr	-64(ra) # 80000c76 <release>
  return 0;
    80002cbe:	4781                	li	a5,0
}
    80002cc0:	853e                	mv	a0,a5
    80002cc2:	70e2                	ld	ra,56(sp)
    80002cc4:	7442                	ld	s0,48(sp)
    80002cc6:	74a2                	ld	s1,40(sp)
    80002cc8:	7902                	ld	s2,32(sp)
    80002cca:	69e2                	ld	s3,24(sp)
    80002ccc:	6121                	addi	sp,sp,64
    80002cce:	8082                	ret
      release(&tickslock);
    80002cd0:	00014517          	auipc	a0,0x14
    80002cd4:	40050513          	addi	a0,a0,1024 # 800170d0 <tickslock>
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	f9e080e7          	jalr	-98(ra) # 80000c76 <release>
      return -1;
    80002ce0:	57fd                	li	a5,-1
    80002ce2:	bff9                	j	80002cc0 <sys_sleep+0x88>

0000000080002ce4 <sys_kill>:

uint64
sys_kill(void)
{
    80002ce4:	1101                	addi	sp,sp,-32
    80002ce6:	ec06                	sd	ra,24(sp)
    80002ce8:	e822                	sd	s0,16(sp)
    80002cea:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002cec:	fec40593          	addi	a1,s0,-20
    80002cf0:	4501                	li	a0,0
    80002cf2:	00000097          	auipc	ra,0x0
    80002cf6:	d84080e7          	jalr	-636(ra) # 80002a76 <argint>
    80002cfa:	87aa                	mv	a5,a0
    return -1;
    80002cfc:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002cfe:	0007c863          	bltz	a5,80002d0e <sys_kill+0x2a>
  return kill(pid);
    80002d02:	fec42503          	lw	a0,-20(s0)
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	6b0080e7          	jalr	1712(ra) # 800023b6 <kill>
}
    80002d0e:	60e2                	ld	ra,24(sp)
    80002d10:	6442                	ld	s0,16(sp)
    80002d12:	6105                	addi	sp,sp,32
    80002d14:	8082                	ret

0000000080002d16 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d16:	1101                	addi	sp,sp,-32
    80002d18:	ec06                	sd	ra,24(sp)
    80002d1a:	e822                	sd	s0,16(sp)
    80002d1c:	e426                	sd	s1,8(sp)
    80002d1e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d20:	00014517          	auipc	a0,0x14
    80002d24:	3b050513          	addi	a0,a0,944 # 800170d0 <tickslock>
    80002d28:	ffffe097          	auipc	ra,0xffffe
    80002d2c:	e9a080e7          	jalr	-358(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002d30:	00006497          	auipc	s1,0x6
    80002d34:	3004a483          	lw	s1,768(s1) # 80009030 <ticks>
  release(&tickslock);
    80002d38:	00014517          	auipc	a0,0x14
    80002d3c:	39850513          	addi	a0,a0,920 # 800170d0 <tickslock>
    80002d40:	ffffe097          	auipc	ra,0xffffe
    80002d44:	f36080e7          	jalr	-202(ra) # 80000c76 <release>
  return xticks;
}
    80002d48:	02049513          	slli	a0,s1,0x20
    80002d4c:	9101                	srli	a0,a0,0x20
    80002d4e:	60e2                	ld	ra,24(sp)
    80002d50:	6442                	ld	s0,16(sp)
    80002d52:	64a2                	ld	s1,8(sp)
    80002d54:	6105                	addi	sp,sp,32
    80002d56:	8082                	ret

0000000080002d58 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d58:	7179                	addi	sp,sp,-48
    80002d5a:	f406                	sd	ra,40(sp)
    80002d5c:	f022                	sd	s0,32(sp)
    80002d5e:	ec26                	sd	s1,24(sp)
    80002d60:	e84a                	sd	s2,16(sp)
    80002d62:	e44e                	sd	s3,8(sp)
    80002d64:	e052                	sd	s4,0(sp)
    80002d66:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d68:	00005597          	auipc	a1,0x5
    80002d6c:	78058593          	addi	a1,a1,1920 # 800084e8 <syscalls+0xb8>
    80002d70:	00014517          	auipc	a0,0x14
    80002d74:	37850513          	addi	a0,a0,888 # 800170e8 <bcache>
    80002d78:	ffffe097          	auipc	ra,0xffffe
    80002d7c:	dba080e7          	jalr	-582(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d80:	0001c797          	auipc	a5,0x1c
    80002d84:	36878793          	addi	a5,a5,872 # 8001f0e8 <bcache+0x8000>
    80002d88:	0001c717          	auipc	a4,0x1c
    80002d8c:	5c870713          	addi	a4,a4,1480 # 8001f350 <bcache+0x8268>
    80002d90:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002d94:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002d98:	00014497          	auipc	s1,0x14
    80002d9c:	36848493          	addi	s1,s1,872 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002da0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002da2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002da4:	00005a17          	auipc	s4,0x5
    80002da8:	74ca0a13          	addi	s4,s4,1868 # 800084f0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002dac:	2b893783          	ld	a5,696(s2)
    80002db0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002db2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002db6:	85d2                	mv	a1,s4
    80002db8:	01048513          	addi	a0,s1,16
    80002dbc:	00001097          	auipc	ra,0x1
    80002dc0:	4c2080e7          	jalr	1218(ra) # 8000427e <initsleeplock>
    bcache.head.next->prev = b;
    80002dc4:	2b893783          	ld	a5,696(s2)
    80002dc8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002dca:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dce:	45848493          	addi	s1,s1,1112
    80002dd2:	fd349de3          	bne	s1,s3,80002dac <binit+0x54>
  }
}
    80002dd6:	70a2                	ld	ra,40(sp)
    80002dd8:	7402                	ld	s0,32(sp)
    80002dda:	64e2                	ld	s1,24(sp)
    80002ddc:	6942                	ld	s2,16(sp)
    80002dde:	69a2                	ld	s3,8(sp)
    80002de0:	6a02                	ld	s4,0(sp)
    80002de2:	6145                	addi	sp,sp,48
    80002de4:	8082                	ret

0000000080002de6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002de6:	7179                	addi	sp,sp,-48
    80002de8:	f406                	sd	ra,40(sp)
    80002dea:	f022                	sd	s0,32(sp)
    80002dec:	ec26                	sd	s1,24(sp)
    80002dee:	e84a                	sd	s2,16(sp)
    80002df0:	e44e                	sd	s3,8(sp)
    80002df2:	1800                	addi	s0,sp,48
    80002df4:	892a                	mv	s2,a0
    80002df6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002df8:	00014517          	auipc	a0,0x14
    80002dfc:	2f050513          	addi	a0,a0,752 # 800170e8 <bcache>
    80002e00:	ffffe097          	auipc	ra,0xffffe
    80002e04:	dc2080e7          	jalr	-574(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e08:	0001c497          	auipc	s1,0x1c
    80002e0c:	5984b483          	ld	s1,1432(s1) # 8001f3a0 <bcache+0x82b8>
    80002e10:	0001c797          	auipc	a5,0x1c
    80002e14:	54078793          	addi	a5,a5,1344 # 8001f350 <bcache+0x8268>
    80002e18:	02f48f63          	beq	s1,a5,80002e56 <bread+0x70>
    80002e1c:	873e                	mv	a4,a5
    80002e1e:	a021                	j	80002e26 <bread+0x40>
    80002e20:	68a4                	ld	s1,80(s1)
    80002e22:	02e48a63          	beq	s1,a4,80002e56 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e26:	449c                	lw	a5,8(s1)
    80002e28:	ff279ce3          	bne	a5,s2,80002e20 <bread+0x3a>
    80002e2c:	44dc                	lw	a5,12(s1)
    80002e2e:	ff3799e3          	bne	a5,s3,80002e20 <bread+0x3a>
      b->refcnt++;
    80002e32:	40bc                	lw	a5,64(s1)
    80002e34:	2785                	addiw	a5,a5,1
    80002e36:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e38:	00014517          	auipc	a0,0x14
    80002e3c:	2b050513          	addi	a0,a0,688 # 800170e8 <bcache>
    80002e40:	ffffe097          	auipc	ra,0xffffe
    80002e44:	e36080e7          	jalr	-458(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002e48:	01048513          	addi	a0,s1,16
    80002e4c:	00001097          	auipc	ra,0x1
    80002e50:	46c080e7          	jalr	1132(ra) # 800042b8 <acquiresleep>
      return b;
    80002e54:	a8b9                	j	80002eb2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e56:	0001c497          	auipc	s1,0x1c
    80002e5a:	5424b483          	ld	s1,1346(s1) # 8001f398 <bcache+0x82b0>
    80002e5e:	0001c797          	auipc	a5,0x1c
    80002e62:	4f278793          	addi	a5,a5,1266 # 8001f350 <bcache+0x8268>
    80002e66:	00f48863          	beq	s1,a5,80002e76 <bread+0x90>
    80002e6a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e6c:	40bc                	lw	a5,64(s1)
    80002e6e:	cf81                	beqz	a5,80002e86 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e70:	64a4                	ld	s1,72(s1)
    80002e72:	fee49de3          	bne	s1,a4,80002e6c <bread+0x86>
  panic("bget: no buffers");
    80002e76:	00005517          	auipc	a0,0x5
    80002e7a:	68250513          	addi	a0,a0,1666 # 800084f8 <syscalls+0xc8>
    80002e7e:	ffffd097          	auipc	ra,0xffffd
    80002e82:	6ae080e7          	jalr	1710(ra) # 8000052c <panic>
      b->dev = dev;
    80002e86:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002e8a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002e8e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002e92:	4785                	li	a5,1
    80002e94:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e96:	00014517          	auipc	a0,0x14
    80002e9a:	25250513          	addi	a0,a0,594 # 800170e8 <bcache>
    80002e9e:	ffffe097          	auipc	ra,0xffffe
    80002ea2:	dd8080e7          	jalr	-552(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002ea6:	01048513          	addi	a0,s1,16
    80002eaa:	00001097          	auipc	ra,0x1
    80002eae:	40e080e7          	jalr	1038(ra) # 800042b8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002eb2:	409c                	lw	a5,0(s1)
    80002eb4:	cb89                	beqz	a5,80002ec6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002eb6:	8526                	mv	a0,s1
    80002eb8:	70a2                	ld	ra,40(sp)
    80002eba:	7402                	ld	s0,32(sp)
    80002ebc:	64e2                	ld	s1,24(sp)
    80002ebe:	6942                	ld	s2,16(sp)
    80002ec0:	69a2                	ld	s3,8(sp)
    80002ec2:	6145                	addi	sp,sp,48
    80002ec4:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ec6:	4581                	li	a1,0
    80002ec8:	8526                	mv	a0,s1
    80002eca:	00003097          	auipc	ra,0x3
    80002ece:	f38080e7          	jalr	-200(ra) # 80005e02 <virtio_disk_rw>
    b->valid = 1;
    80002ed2:	4785                	li	a5,1
    80002ed4:	c09c                	sw	a5,0(s1)
  return b;
    80002ed6:	b7c5                	j	80002eb6 <bread+0xd0>

0000000080002ed8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ed8:	1101                	addi	sp,sp,-32
    80002eda:	ec06                	sd	ra,24(sp)
    80002edc:	e822                	sd	s0,16(sp)
    80002ede:	e426                	sd	s1,8(sp)
    80002ee0:	1000                	addi	s0,sp,32
    80002ee2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ee4:	0541                	addi	a0,a0,16
    80002ee6:	00001097          	auipc	ra,0x1
    80002eea:	46c080e7          	jalr	1132(ra) # 80004352 <holdingsleep>
    80002eee:	cd01                	beqz	a0,80002f06 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002ef0:	4585                	li	a1,1
    80002ef2:	8526                	mv	a0,s1
    80002ef4:	00003097          	auipc	ra,0x3
    80002ef8:	f0e080e7          	jalr	-242(ra) # 80005e02 <virtio_disk_rw>
}
    80002efc:	60e2                	ld	ra,24(sp)
    80002efe:	6442                	ld	s0,16(sp)
    80002f00:	64a2                	ld	s1,8(sp)
    80002f02:	6105                	addi	sp,sp,32
    80002f04:	8082                	ret
    panic("bwrite");
    80002f06:	00005517          	auipc	a0,0x5
    80002f0a:	60a50513          	addi	a0,a0,1546 # 80008510 <syscalls+0xe0>
    80002f0e:	ffffd097          	auipc	ra,0xffffd
    80002f12:	61e080e7          	jalr	1566(ra) # 8000052c <panic>

0000000080002f16 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f16:	1101                	addi	sp,sp,-32
    80002f18:	ec06                	sd	ra,24(sp)
    80002f1a:	e822                	sd	s0,16(sp)
    80002f1c:	e426                	sd	s1,8(sp)
    80002f1e:	e04a                	sd	s2,0(sp)
    80002f20:	1000                	addi	s0,sp,32
    80002f22:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f24:	01050913          	addi	s2,a0,16
    80002f28:	854a                	mv	a0,s2
    80002f2a:	00001097          	auipc	ra,0x1
    80002f2e:	428080e7          	jalr	1064(ra) # 80004352 <holdingsleep>
    80002f32:	c92d                	beqz	a0,80002fa4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f34:	854a                	mv	a0,s2
    80002f36:	00001097          	auipc	ra,0x1
    80002f3a:	3d8080e7          	jalr	984(ra) # 8000430e <releasesleep>

  acquire(&bcache.lock);
    80002f3e:	00014517          	auipc	a0,0x14
    80002f42:	1aa50513          	addi	a0,a0,426 # 800170e8 <bcache>
    80002f46:	ffffe097          	auipc	ra,0xffffe
    80002f4a:	c7c080e7          	jalr	-900(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80002f4e:	40bc                	lw	a5,64(s1)
    80002f50:	37fd                	addiw	a5,a5,-1
    80002f52:	0007871b          	sext.w	a4,a5
    80002f56:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f58:	eb05                	bnez	a4,80002f88 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f5a:	68bc                	ld	a5,80(s1)
    80002f5c:	64b8                	ld	a4,72(s1)
    80002f5e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f60:	64bc                	ld	a5,72(s1)
    80002f62:	68b8                	ld	a4,80(s1)
    80002f64:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f66:	0001c797          	auipc	a5,0x1c
    80002f6a:	18278793          	addi	a5,a5,386 # 8001f0e8 <bcache+0x8000>
    80002f6e:	2b87b703          	ld	a4,696(a5)
    80002f72:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f74:	0001c717          	auipc	a4,0x1c
    80002f78:	3dc70713          	addi	a4,a4,988 # 8001f350 <bcache+0x8268>
    80002f7c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f7e:	2b87b703          	ld	a4,696(a5)
    80002f82:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f84:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002f88:	00014517          	auipc	a0,0x14
    80002f8c:	16050513          	addi	a0,a0,352 # 800170e8 <bcache>
    80002f90:	ffffe097          	auipc	ra,0xffffe
    80002f94:	ce6080e7          	jalr	-794(ra) # 80000c76 <release>
}
    80002f98:	60e2                	ld	ra,24(sp)
    80002f9a:	6442                	ld	s0,16(sp)
    80002f9c:	64a2                	ld	s1,8(sp)
    80002f9e:	6902                	ld	s2,0(sp)
    80002fa0:	6105                	addi	sp,sp,32
    80002fa2:	8082                	ret
    panic("brelse");
    80002fa4:	00005517          	auipc	a0,0x5
    80002fa8:	57450513          	addi	a0,a0,1396 # 80008518 <syscalls+0xe8>
    80002fac:	ffffd097          	auipc	ra,0xffffd
    80002fb0:	580080e7          	jalr	1408(ra) # 8000052c <panic>

0000000080002fb4 <bpin>:

void
bpin(struct buf *b) {
    80002fb4:	1101                	addi	sp,sp,-32
    80002fb6:	ec06                	sd	ra,24(sp)
    80002fb8:	e822                	sd	s0,16(sp)
    80002fba:	e426                	sd	s1,8(sp)
    80002fbc:	1000                	addi	s0,sp,32
    80002fbe:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fc0:	00014517          	auipc	a0,0x14
    80002fc4:	12850513          	addi	a0,a0,296 # 800170e8 <bcache>
    80002fc8:	ffffe097          	auipc	ra,0xffffe
    80002fcc:	bfa080e7          	jalr	-1030(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80002fd0:	40bc                	lw	a5,64(s1)
    80002fd2:	2785                	addiw	a5,a5,1
    80002fd4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fd6:	00014517          	auipc	a0,0x14
    80002fda:	11250513          	addi	a0,a0,274 # 800170e8 <bcache>
    80002fde:	ffffe097          	auipc	ra,0xffffe
    80002fe2:	c98080e7          	jalr	-872(ra) # 80000c76 <release>
}
    80002fe6:	60e2                	ld	ra,24(sp)
    80002fe8:	6442                	ld	s0,16(sp)
    80002fea:	64a2                	ld	s1,8(sp)
    80002fec:	6105                	addi	sp,sp,32
    80002fee:	8082                	ret

0000000080002ff0 <bunpin>:

void
bunpin(struct buf *b) {
    80002ff0:	1101                	addi	sp,sp,-32
    80002ff2:	ec06                	sd	ra,24(sp)
    80002ff4:	e822                	sd	s0,16(sp)
    80002ff6:	e426                	sd	s1,8(sp)
    80002ff8:	1000                	addi	s0,sp,32
    80002ffa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002ffc:	00014517          	auipc	a0,0x14
    80003000:	0ec50513          	addi	a0,a0,236 # 800170e8 <bcache>
    80003004:	ffffe097          	auipc	ra,0xffffe
    80003008:	bbe080e7          	jalr	-1090(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000300c:	40bc                	lw	a5,64(s1)
    8000300e:	37fd                	addiw	a5,a5,-1
    80003010:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003012:	00014517          	auipc	a0,0x14
    80003016:	0d650513          	addi	a0,a0,214 # 800170e8 <bcache>
    8000301a:	ffffe097          	auipc	ra,0xffffe
    8000301e:	c5c080e7          	jalr	-932(ra) # 80000c76 <release>
}
    80003022:	60e2                	ld	ra,24(sp)
    80003024:	6442                	ld	s0,16(sp)
    80003026:	64a2                	ld	s1,8(sp)
    80003028:	6105                	addi	sp,sp,32
    8000302a:	8082                	ret

000000008000302c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000302c:	1101                	addi	sp,sp,-32
    8000302e:	ec06                	sd	ra,24(sp)
    80003030:	e822                	sd	s0,16(sp)
    80003032:	e426                	sd	s1,8(sp)
    80003034:	e04a                	sd	s2,0(sp)
    80003036:	1000                	addi	s0,sp,32
    80003038:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000303a:	00d5d59b          	srliw	a1,a1,0xd
    8000303e:	0001c797          	auipc	a5,0x1c
    80003042:	7867a783          	lw	a5,1926(a5) # 8001f7c4 <sb+0x1c>
    80003046:	9dbd                	addw	a1,a1,a5
    80003048:	00000097          	auipc	ra,0x0
    8000304c:	d9e080e7          	jalr	-610(ra) # 80002de6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003050:	0074f713          	andi	a4,s1,7
    80003054:	4785                	li	a5,1
    80003056:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000305a:	14ce                	slli	s1,s1,0x33
    8000305c:	90d9                	srli	s1,s1,0x36
    8000305e:	00950733          	add	a4,a0,s1
    80003062:	05874703          	lbu	a4,88(a4)
    80003066:	00e7f6b3          	and	a3,a5,a4
    8000306a:	c69d                	beqz	a3,80003098 <bfree+0x6c>
    8000306c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000306e:	94aa                	add	s1,s1,a0
    80003070:	fff7c793          	not	a5,a5
    80003074:	8f7d                	and	a4,a4,a5
    80003076:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000307a:	00001097          	auipc	ra,0x1
    8000307e:	120080e7          	jalr	288(ra) # 8000419a <log_write>
  brelse(bp);
    80003082:	854a                	mv	a0,s2
    80003084:	00000097          	auipc	ra,0x0
    80003088:	e92080e7          	jalr	-366(ra) # 80002f16 <brelse>
}
    8000308c:	60e2                	ld	ra,24(sp)
    8000308e:	6442                	ld	s0,16(sp)
    80003090:	64a2                	ld	s1,8(sp)
    80003092:	6902                	ld	s2,0(sp)
    80003094:	6105                	addi	sp,sp,32
    80003096:	8082                	ret
    panic("freeing free block");
    80003098:	00005517          	auipc	a0,0x5
    8000309c:	48850513          	addi	a0,a0,1160 # 80008520 <syscalls+0xf0>
    800030a0:	ffffd097          	auipc	ra,0xffffd
    800030a4:	48c080e7          	jalr	1164(ra) # 8000052c <panic>

00000000800030a8 <balloc>:
{
    800030a8:	711d                	addi	sp,sp,-96
    800030aa:	ec86                	sd	ra,88(sp)
    800030ac:	e8a2                	sd	s0,80(sp)
    800030ae:	e4a6                	sd	s1,72(sp)
    800030b0:	e0ca                	sd	s2,64(sp)
    800030b2:	fc4e                	sd	s3,56(sp)
    800030b4:	f852                	sd	s4,48(sp)
    800030b6:	f456                	sd	s5,40(sp)
    800030b8:	f05a                	sd	s6,32(sp)
    800030ba:	ec5e                	sd	s7,24(sp)
    800030bc:	e862                	sd	s8,16(sp)
    800030be:	e466                	sd	s9,8(sp)
    800030c0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030c2:	0001c797          	auipc	a5,0x1c
    800030c6:	6ea7a783          	lw	a5,1770(a5) # 8001f7ac <sb+0x4>
    800030ca:	cbc1                	beqz	a5,8000315a <balloc+0xb2>
    800030cc:	8baa                	mv	s7,a0
    800030ce:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030d0:	0001cb17          	auipc	s6,0x1c
    800030d4:	6d8b0b13          	addi	s6,s6,1752 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030d8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030da:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030dc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030de:	6c89                	lui	s9,0x2
    800030e0:	a831                	j	800030fc <balloc+0x54>
    brelse(bp);
    800030e2:	854a                	mv	a0,s2
    800030e4:	00000097          	auipc	ra,0x0
    800030e8:	e32080e7          	jalr	-462(ra) # 80002f16 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800030ec:	015c87bb          	addw	a5,s9,s5
    800030f0:	00078a9b          	sext.w	s5,a5
    800030f4:	004b2703          	lw	a4,4(s6)
    800030f8:	06eaf163          	bgeu	s5,a4,8000315a <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    800030fc:	41fad79b          	sraiw	a5,s5,0x1f
    80003100:	0137d79b          	srliw	a5,a5,0x13
    80003104:	015787bb          	addw	a5,a5,s5
    80003108:	40d7d79b          	sraiw	a5,a5,0xd
    8000310c:	01cb2583          	lw	a1,28(s6)
    80003110:	9dbd                	addw	a1,a1,a5
    80003112:	855e                	mv	a0,s7
    80003114:	00000097          	auipc	ra,0x0
    80003118:	cd2080e7          	jalr	-814(ra) # 80002de6 <bread>
    8000311c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000311e:	004b2503          	lw	a0,4(s6)
    80003122:	000a849b          	sext.w	s1,s5
    80003126:	8762                	mv	a4,s8
    80003128:	faa4fde3          	bgeu	s1,a0,800030e2 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000312c:	00777693          	andi	a3,a4,7
    80003130:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003134:	41f7579b          	sraiw	a5,a4,0x1f
    80003138:	01d7d79b          	srliw	a5,a5,0x1d
    8000313c:	9fb9                	addw	a5,a5,a4
    8000313e:	4037d79b          	sraiw	a5,a5,0x3
    80003142:	00f90633          	add	a2,s2,a5
    80003146:	05864603          	lbu	a2,88(a2)
    8000314a:	00c6f5b3          	and	a1,a3,a2
    8000314e:	cd91                	beqz	a1,8000316a <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003150:	2705                	addiw	a4,a4,1
    80003152:	2485                	addiw	s1,s1,1
    80003154:	fd471ae3          	bne	a4,s4,80003128 <balloc+0x80>
    80003158:	b769                	j	800030e2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000315a:	00005517          	auipc	a0,0x5
    8000315e:	3de50513          	addi	a0,a0,990 # 80008538 <syscalls+0x108>
    80003162:	ffffd097          	auipc	ra,0xffffd
    80003166:	3ca080e7          	jalr	970(ra) # 8000052c <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000316a:	97ca                	add	a5,a5,s2
    8000316c:	8e55                	or	a2,a2,a3
    8000316e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003172:	854a                	mv	a0,s2
    80003174:	00001097          	auipc	ra,0x1
    80003178:	026080e7          	jalr	38(ra) # 8000419a <log_write>
        brelse(bp);
    8000317c:	854a                	mv	a0,s2
    8000317e:	00000097          	auipc	ra,0x0
    80003182:	d98080e7          	jalr	-616(ra) # 80002f16 <brelse>
  bp = bread(dev, bno);
    80003186:	85a6                	mv	a1,s1
    80003188:	855e                	mv	a0,s7
    8000318a:	00000097          	auipc	ra,0x0
    8000318e:	c5c080e7          	jalr	-932(ra) # 80002de6 <bread>
    80003192:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003194:	40000613          	li	a2,1024
    80003198:	4581                	li	a1,0
    8000319a:	05850513          	addi	a0,a0,88
    8000319e:	ffffe097          	auipc	ra,0xffffe
    800031a2:	b20080e7          	jalr	-1248(ra) # 80000cbe <memset>
  log_write(bp);
    800031a6:	854a                	mv	a0,s2
    800031a8:	00001097          	auipc	ra,0x1
    800031ac:	ff2080e7          	jalr	-14(ra) # 8000419a <log_write>
  brelse(bp);
    800031b0:	854a                	mv	a0,s2
    800031b2:	00000097          	auipc	ra,0x0
    800031b6:	d64080e7          	jalr	-668(ra) # 80002f16 <brelse>
}
    800031ba:	8526                	mv	a0,s1
    800031bc:	60e6                	ld	ra,88(sp)
    800031be:	6446                	ld	s0,80(sp)
    800031c0:	64a6                	ld	s1,72(sp)
    800031c2:	6906                	ld	s2,64(sp)
    800031c4:	79e2                	ld	s3,56(sp)
    800031c6:	7a42                	ld	s4,48(sp)
    800031c8:	7aa2                	ld	s5,40(sp)
    800031ca:	7b02                	ld	s6,32(sp)
    800031cc:	6be2                	ld	s7,24(sp)
    800031ce:	6c42                	ld	s8,16(sp)
    800031d0:	6ca2                	ld	s9,8(sp)
    800031d2:	6125                	addi	sp,sp,96
    800031d4:	8082                	ret

00000000800031d6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800031d6:	7179                	addi	sp,sp,-48
    800031d8:	f406                	sd	ra,40(sp)
    800031da:	f022                	sd	s0,32(sp)
    800031dc:	ec26                	sd	s1,24(sp)
    800031de:	e84a                	sd	s2,16(sp)
    800031e0:	e44e                	sd	s3,8(sp)
    800031e2:	e052                	sd	s4,0(sp)
    800031e4:	1800                	addi	s0,sp,48
    800031e6:	892a                	mv	s2,a0
  // You should modify bmap(),
  // so that it can handle doubly indrect inode.
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800031e8:	47ad                	li	a5,11
    800031ea:	04b7fe63          	bgeu	a5,a1,80003246 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800031ee:	ff45849b          	addiw	s1,a1,-12
    800031f2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800031f6:	0ff00793          	li	a5,255
    800031fa:	0ae7e463          	bltu	a5,a4,800032a2 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800031fe:	08052583          	lw	a1,128(a0)
    80003202:	c5b5                	beqz	a1,8000326e <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003204:	00092503          	lw	a0,0(s2)
    80003208:	00000097          	auipc	ra,0x0
    8000320c:	bde080e7          	jalr	-1058(ra) # 80002de6 <bread>
    80003210:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003212:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003216:	02049713          	slli	a4,s1,0x20
    8000321a:	01e75593          	srli	a1,a4,0x1e
    8000321e:	00b784b3          	add	s1,a5,a1
    80003222:	0004a983          	lw	s3,0(s1)
    80003226:	04098e63          	beqz	s3,80003282 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000322a:	8552                	mv	a0,s4
    8000322c:	00000097          	auipc	ra,0x0
    80003230:	cea080e7          	jalr	-790(ra) # 80002f16 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003234:	854e                	mv	a0,s3
    80003236:	70a2                	ld	ra,40(sp)
    80003238:	7402                	ld	s0,32(sp)
    8000323a:	64e2                	ld	s1,24(sp)
    8000323c:	6942                	ld	s2,16(sp)
    8000323e:	69a2                	ld	s3,8(sp)
    80003240:	6a02                	ld	s4,0(sp)
    80003242:	6145                	addi	sp,sp,48
    80003244:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003246:	02059793          	slli	a5,a1,0x20
    8000324a:	01e7d593          	srli	a1,a5,0x1e
    8000324e:	00b504b3          	add	s1,a0,a1
    80003252:	0504a983          	lw	s3,80(s1)
    80003256:	fc099fe3          	bnez	s3,80003234 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000325a:	4108                	lw	a0,0(a0)
    8000325c:	00000097          	auipc	ra,0x0
    80003260:	e4c080e7          	jalr	-436(ra) # 800030a8 <balloc>
    80003264:	0005099b          	sext.w	s3,a0
    80003268:	0534a823          	sw	s3,80(s1)
    8000326c:	b7e1                	j	80003234 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000326e:	4108                	lw	a0,0(a0)
    80003270:	00000097          	auipc	ra,0x0
    80003274:	e38080e7          	jalr	-456(ra) # 800030a8 <balloc>
    80003278:	0005059b          	sext.w	a1,a0
    8000327c:	08b92023          	sw	a1,128(s2)
    80003280:	b751                	j	80003204 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003282:	00092503          	lw	a0,0(s2)
    80003286:	00000097          	auipc	ra,0x0
    8000328a:	e22080e7          	jalr	-478(ra) # 800030a8 <balloc>
    8000328e:	0005099b          	sext.w	s3,a0
    80003292:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003296:	8552                	mv	a0,s4
    80003298:	00001097          	auipc	ra,0x1
    8000329c:	f02080e7          	jalr	-254(ra) # 8000419a <log_write>
    800032a0:	b769                	j	8000322a <bmap+0x54>
  panic("bmap: out of range");
    800032a2:	00005517          	auipc	a0,0x5
    800032a6:	2ae50513          	addi	a0,a0,686 # 80008550 <syscalls+0x120>
    800032aa:	ffffd097          	auipc	ra,0xffffd
    800032ae:	282080e7          	jalr	642(ra) # 8000052c <panic>

00000000800032b2 <iget>:
{
    800032b2:	7179                	addi	sp,sp,-48
    800032b4:	f406                	sd	ra,40(sp)
    800032b6:	f022                	sd	s0,32(sp)
    800032b8:	ec26                	sd	s1,24(sp)
    800032ba:	e84a                	sd	s2,16(sp)
    800032bc:	e44e                	sd	s3,8(sp)
    800032be:	e052                	sd	s4,0(sp)
    800032c0:	1800                	addi	s0,sp,48
    800032c2:	89aa                	mv	s3,a0
    800032c4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800032c6:	0001c517          	auipc	a0,0x1c
    800032ca:	50250513          	addi	a0,a0,1282 # 8001f7c8 <itable>
    800032ce:	ffffe097          	auipc	ra,0xffffe
    800032d2:	8f4080e7          	jalr	-1804(ra) # 80000bc2 <acquire>
  empty = 0;
    800032d6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800032d8:	0001c497          	auipc	s1,0x1c
    800032dc:	50848493          	addi	s1,s1,1288 # 8001f7e0 <itable+0x18>
    800032e0:	0001e697          	auipc	a3,0x1e
    800032e4:	f9068693          	addi	a3,a3,-112 # 80021270 <log>
    800032e8:	a039                	j	800032f6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800032ea:	02090b63          	beqz	s2,80003320 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800032ee:	08848493          	addi	s1,s1,136
    800032f2:	02d48a63          	beq	s1,a3,80003326 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800032f6:	449c                	lw	a5,8(s1)
    800032f8:	fef059e3          	blez	a5,800032ea <iget+0x38>
    800032fc:	4098                	lw	a4,0(s1)
    800032fe:	ff3716e3          	bne	a4,s3,800032ea <iget+0x38>
    80003302:	40d8                	lw	a4,4(s1)
    80003304:	ff4713e3          	bne	a4,s4,800032ea <iget+0x38>
      ip->ref++;
    80003308:	2785                	addiw	a5,a5,1
    8000330a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000330c:	0001c517          	auipc	a0,0x1c
    80003310:	4bc50513          	addi	a0,a0,1212 # 8001f7c8 <itable>
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	962080e7          	jalr	-1694(ra) # 80000c76 <release>
      return ip;
    8000331c:	8926                	mv	s2,s1
    8000331e:	a03d                	j	8000334c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003320:	f7f9                	bnez	a5,800032ee <iget+0x3c>
    80003322:	8926                	mv	s2,s1
    80003324:	b7e9                	j	800032ee <iget+0x3c>
  if(empty == 0)
    80003326:	02090c63          	beqz	s2,8000335e <iget+0xac>
  ip->dev = dev;
    8000332a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000332e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003332:	4785                	li	a5,1
    80003334:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003338:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000333c:	0001c517          	auipc	a0,0x1c
    80003340:	48c50513          	addi	a0,a0,1164 # 8001f7c8 <itable>
    80003344:	ffffe097          	auipc	ra,0xffffe
    80003348:	932080e7          	jalr	-1742(ra) # 80000c76 <release>
}
    8000334c:	854a                	mv	a0,s2
    8000334e:	70a2                	ld	ra,40(sp)
    80003350:	7402                	ld	s0,32(sp)
    80003352:	64e2                	ld	s1,24(sp)
    80003354:	6942                	ld	s2,16(sp)
    80003356:	69a2                	ld	s3,8(sp)
    80003358:	6a02                	ld	s4,0(sp)
    8000335a:	6145                	addi	sp,sp,48
    8000335c:	8082                	ret
    panic("iget: no inodes");
    8000335e:	00005517          	auipc	a0,0x5
    80003362:	20a50513          	addi	a0,a0,522 # 80008568 <syscalls+0x138>
    80003366:	ffffd097          	auipc	ra,0xffffd
    8000336a:	1c6080e7          	jalr	454(ra) # 8000052c <panic>

000000008000336e <fsinit>:
fsinit(int dev) {
    8000336e:	7179                	addi	sp,sp,-48
    80003370:	f406                	sd	ra,40(sp)
    80003372:	f022                	sd	s0,32(sp)
    80003374:	ec26                	sd	s1,24(sp)
    80003376:	e84a                	sd	s2,16(sp)
    80003378:	e44e                	sd	s3,8(sp)
    8000337a:	1800                	addi	s0,sp,48
    8000337c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000337e:	4585                	li	a1,1
    80003380:	00000097          	auipc	ra,0x0
    80003384:	a66080e7          	jalr	-1434(ra) # 80002de6 <bread>
    80003388:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000338a:	0001c997          	auipc	s3,0x1c
    8000338e:	41e98993          	addi	s3,s3,1054 # 8001f7a8 <sb>
    80003392:	02000613          	li	a2,32
    80003396:	05850593          	addi	a1,a0,88
    8000339a:	854e                	mv	a0,s3
    8000339c:	ffffe097          	auipc	ra,0xffffe
    800033a0:	97e080e7          	jalr	-1666(ra) # 80000d1a <memmove>
  brelse(bp);
    800033a4:	8526                	mv	a0,s1
    800033a6:	00000097          	auipc	ra,0x0
    800033aa:	b70080e7          	jalr	-1168(ra) # 80002f16 <brelse>
  if(sb.magic != FSMAGIC)
    800033ae:	0009a703          	lw	a4,0(s3)
    800033b2:	102037b7          	lui	a5,0x10203
    800033b6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033ba:	02f71263          	bne	a4,a5,800033de <fsinit+0x70>
  initlog(dev, &sb);
    800033be:	0001c597          	auipc	a1,0x1c
    800033c2:	3ea58593          	addi	a1,a1,1002 # 8001f7a8 <sb>
    800033c6:	854a                	mv	a0,s2
    800033c8:	00001097          	auipc	ra,0x1
    800033cc:	b56080e7          	jalr	-1194(ra) # 80003f1e <initlog>
}
    800033d0:	70a2                	ld	ra,40(sp)
    800033d2:	7402                	ld	s0,32(sp)
    800033d4:	64e2                	ld	s1,24(sp)
    800033d6:	6942                	ld	s2,16(sp)
    800033d8:	69a2                	ld	s3,8(sp)
    800033da:	6145                	addi	sp,sp,48
    800033dc:	8082                	ret
    panic("invalid file system");
    800033de:	00005517          	auipc	a0,0x5
    800033e2:	19a50513          	addi	a0,a0,410 # 80008578 <syscalls+0x148>
    800033e6:	ffffd097          	auipc	ra,0xffffd
    800033ea:	146080e7          	jalr	326(ra) # 8000052c <panic>

00000000800033ee <iinit>:
{
    800033ee:	7179                	addi	sp,sp,-48
    800033f0:	f406                	sd	ra,40(sp)
    800033f2:	f022                	sd	s0,32(sp)
    800033f4:	ec26                	sd	s1,24(sp)
    800033f6:	e84a                	sd	s2,16(sp)
    800033f8:	e44e                	sd	s3,8(sp)
    800033fa:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800033fc:	00005597          	auipc	a1,0x5
    80003400:	19458593          	addi	a1,a1,404 # 80008590 <syscalls+0x160>
    80003404:	0001c517          	auipc	a0,0x1c
    80003408:	3c450513          	addi	a0,a0,964 # 8001f7c8 <itable>
    8000340c:	ffffd097          	auipc	ra,0xffffd
    80003410:	726080e7          	jalr	1830(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003414:	0001c497          	auipc	s1,0x1c
    80003418:	3dc48493          	addi	s1,s1,988 # 8001f7f0 <itable+0x28>
    8000341c:	0001e997          	auipc	s3,0x1e
    80003420:	e6498993          	addi	s3,s3,-412 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003424:	00005917          	auipc	s2,0x5
    80003428:	17490913          	addi	s2,s2,372 # 80008598 <syscalls+0x168>
    8000342c:	85ca                	mv	a1,s2
    8000342e:	8526                	mv	a0,s1
    80003430:	00001097          	auipc	ra,0x1
    80003434:	e4e080e7          	jalr	-434(ra) # 8000427e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003438:	08848493          	addi	s1,s1,136
    8000343c:	ff3498e3          	bne	s1,s3,8000342c <iinit+0x3e>
}
    80003440:	70a2                	ld	ra,40(sp)
    80003442:	7402                	ld	s0,32(sp)
    80003444:	64e2                	ld	s1,24(sp)
    80003446:	6942                	ld	s2,16(sp)
    80003448:	69a2                	ld	s3,8(sp)
    8000344a:	6145                	addi	sp,sp,48
    8000344c:	8082                	ret

000000008000344e <ialloc>:
{
    8000344e:	715d                	addi	sp,sp,-80
    80003450:	e486                	sd	ra,72(sp)
    80003452:	e0a2                	sd	s0,64(sp)
    80003454:	fc26                	sd	s1,56(sp)
    80003456:	f84a                	sd	s2,48(sp)
    80003458:	f44e                	sd	s3,40(sp)
    8000345a:	f052                	sd	s4,32(sp)
    8000345c:	ec56                	sd	s5,24(sp)
    8000345e:	e85a                	sd	s6,16(sp)
    80003460:	e45e                	sd	s7,8(sp)
    80003462:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003464:	0001c717          	auipc	a4,0x1c
    80003468:	35072703          	lw	a4,848(a4) # 8001f7b4 <sb+0xc>
    8000346c:	4785                	li	a5,1
    8000346e:	04e7fa63          	bgeu	a5,a4,800034c2 <ialloc+0x74>
    80003472:	8aaa                	mv	s5,a0
    80003474:	8bae                	mv	s7,a1
    80003476:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003478:	0001ca17          	auipc	s4,0x1c
    8000347c:	330a0a13          	addi	s4,s4,816 # 8001f7a8 <sb>
    80003480:	00048b1b          	sext.w	s6,s1
    80003484:	0044d593          	srli	a1,s1,0x4
    80003488:	018a2783          	lw	a5,24(s4)
    8000348c:	9dbd                	addw	a1,a1,a5
    8000348e:	8556                	mv	a0,s5
    80003490:	00000097          	auipc	ra,0x0
    80003494:	956080e7          	jalr	-1706(ra) # 80002de6 <bread>
    80003498:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000349a:	05850993          	addi	s3,a0,88
    8000349e:	00f4f793          	andi	a5,s1,15
    800034a2:	079a                	slli	a5,a5,0x6
    800034a4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034a6:	00099783          	lh	a5,0(s3)
    800034aa:	c785                	beqz	a5,800034d2 <ialloc+0x84>
    brelse(bp);
    800034ac:	00000097          	auipc	ra,0x0
    800034b0:	a6a080e7          	jalr	-1430(ra) # 80002f16 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034b4:	0485                	addi	s1,s1,1
    800034b6:	00ca2703          	lw	a4,12(s4)
    800034ba:	0004879b          	sext.w	a5,s1
    800034be:	fce7e1e3          	bltu	a5,a4,80003480 <ialloc+0x32>
  panic("ialloc: no inodes");
    800034c2:	00005517          	auipc	a0,0x5
    800034c6:	0de50513          	addi	a0,a0,222 # 800085a0 <syscalls+0x170>
    800034ca:	ffffd097          	auipc	ra,0xffffd
    800034ce:	062080e7          	jalr	98(ra) # 8000052c <panic>
      memset(dip, 0, sizeof(*dip));
    800034d2:	04000613          	li	a2,64
    800034d6:	4581                	li	a1,0
    800034d8:	854e                	mv	a0,s3
    800034da:	ffffd097          	auipc	ra,0xffffd
    800034de:	7e4080e7          	jalr	2020(ra) # 80000cbe <memset>
      dip->type = type;
    800034e2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800034e6:	854a                	mv	a0,s2
    800034e8:	00001097          	auipc	ra,0x1
    800034ec:	cb2080e7          	jalr	-846(ra) # 8000419a <log_write>
      brelse(bp);
    800034f0:	854a                	mv	a0,s2
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	a24080e7          	jalr	-1500(ra) # 80002f16 <brelse>
      return iget(dev, inum);
    800034fa:	85da                	mv	a1,s6
    800034fc:	8556                	mv	a0,s5
    800034fe:	00000097          	auipc	ra,0x0
    80003502:	db4080e7          	jalr	-588(ra) # 800032b2 <iget>
}
    80003506:	60a6                	ld	ra,72(sp)
    80003508:	6406                	ld	s0,64(sp)
    8000350a:	74e2                	ld	s1,56(sp)
    8000350c:	7942                	ld	s2,48(sp)
    8000350e:	79a2                	ld	s3,40(sp)
    80003510:	7a02                	ld	s4,32(sp)
    80003512:	6ae2                	ld	s5,24(sp)
    80003514:	6b42                	ld	s6,16(sp)
    80003516:	6ba2                	ld	s7,8(sp)
    80003518:	6161                	addi	sp,sp,80
    8000351a:	8082                	ret

000000008000351c <iupdate>:
{
    8000351c:	1101                	addi	sp,sp,-32
    8000351e:	ec06                	sd	ra,24(sp)
    80003520:	e822                	sd	s0,16(sp)
    80003522:	e426                	sd	s1,8(sp)
    80003524:	e04a                	sd	s2,0(sp)
    80003526:	1000                	addi	s0,sp,32
    80003528:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000352a:	415c                	lw	a5,4(a0)
    8000352c:	0047d79b          	srliw	a5,a5,0x4
    80003530:	0001c597          	auipc	a1,0x1c
    80003534:	2905a583          	lw	a1,656(a1) # 8001f7c0 <sb+0x18>
    80003538:	9dbd                	addw	a1,a1,a5
    8000353a:	4108                	lw	a0,0(a0)
    8000353c:	00000097          	auipc	ra,0x0
    80003540:	8aa080e7          	jalr	-1878(ra) # 80002de6 <bread>
    80003544:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003546:	05850793          	addi	a5,a0,88
    8000354a:	40d8                	lw	a4,4(s1)
    8000354c:	8b3d                	andi	a4,a4,15
    8000354e:	071a                	slli	a4,a4,0x6
    80003550:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003552:	04449703          	lh	a4,68(s1)
    80003556:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000355a:	04649703          	lh	a4,70(s1)
    8000355e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003562:	04849703          	lh	a4,72(s1)
    80003566:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000356a:	04a49703          	lh	a4,74(s1)
    8000356e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003572:	44f8                	lw	a4,76(s1)
    80003574:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003576:	03400613          	li	a2,52
    8000357a:	05048593          	addi	a1,s1,80
    8000357e:	00c78513          	addi	a0,a5,12
    80003582:	ffffd097          	auipc	ra,0xffffd
    80003586:	798080e7          	jalr	1944(ra) # 80000d1a <memmove>
  log_write(bp);
    8000358a:	854a                	mv	a0,s2
    8000358c:	00001097          	auipc	ra,0x1
    80003590:	c0e080e7          	jalr	-1010(ra) # 8000419a <log_write>
  brelse(bp);
    80003594:	854a                	mv	a0,s2
    80003596:	00000097          	auipc	ra,0x0
    8000359a:	980080e7          	jalr	-1664(ra) # 80002f16 <brelse>
}
    8000359e:	60e2                	ld	ra,24(sp)
    800035a0:	6442                	ld	s0,16(sp)
    800035a2:	64a2                	ld	s1,8(sp)
    800035a4:	6902                	ld	s2,0(sp)
    800035a6:	6105                	addi	sp,sp,32
    800035a8:	8082                	ret

00000000800035aa <idup>:
{
    800035aa:	1101                	addi	sp,sp,-32
    800035ac:	ec06                	sd	ra,24(sp)
    800035ae:	e822                	sd	s0,16(sp)
    800035b0:	e426                	sd	s1,8(sp)
    800035b2:	1000                	addi	s0,sp,32
    800035b4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800035b6:	0001c517          	auipc	a0,0x1c
    800035ba:	21250513          	addi	a0,a0,530 # 8001f7c8 <itable>
    800035be:	ffffd097          	auipc	ra,0xffffd
    800035c2:	604080e7          	jalr	1540(ra) # 80000bc2 <acquire>
  ip->ref++;
    800035c6:	449c                	lw	a5,8(s1)
    800035c8:	2785                	addiw	a5,a5,1
    800035ca:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800035cc:	0001c517          	auipc	a0,0x1c
    800035d0:	1fc50513          	addi	a0,a0,508 # 8001f7c8 <itable>
    800035d4:	ffffd097          	auipc	ra,0xffffd
    800035d8:	6a2080e7          	jalr	1698(ra) # 80000c76 <release>
}
    800035dc:	8526                	mv	a0,s1
    800035de:	60e2                	ld	ra,24(sp)
    800035e0:	6442                	ld	s0,16(sp)
    800035e2:	64a2                	ld	s1,8(sp)
    800035e4:	6105                	addi	sp,sp,32
    800035e6:	8082                	ret

00000000800035e8 <ilock>:
{
    800035e8:	1101                	addi	sp,sp,-32
    800035ea:	ec06                	sd	ra,24(sp)
    800035ec:	e822                	sd	s0,16(sp)
    800035ee:	e426                	sd	s1,8(sp)
    800035f0:	e04a                	sd	s2,0(sp)
    800035f2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800035f4:	c115                	beqz	a0,80003618 <ilock+0x30>
    800035f6:	84aa                	mv	s1,a0
    800035f8:	451c                	lw	a5,8(a0)
    800035fa:	00f05f63          	blez	a5,80003618 <ilock+0x30>
  acquiresleep(&ip->lock);
    800035fe:	0541                	addi	a0,a0,16
    80003600:	00001097          	auipc	ra,0x1
    80003604:	cb8080e7          	jalr	-840(ra) # 800042b8 <acquiresleep>
  if(ip->valid == 0){
    80003608:	40bc                	lw	a5,64(s1)
    8000360a:	cf99                	beqz	a5,80003628 <ilock+0x40>
}
    8000360c:	60e2                	ld	ra,24(sp)
    8000360e:	6442                	ld	s0,16(sp)
    80003610:	64a2                	ld	s1,8(sp)
    80003612:	6902                	ld	s2,0(sp)
    80003614:	6105                	addi	sp,sp,32
    80003616:	8082                	ret
    panic("ilock");
    80003618:	00005517          	auipc	a0,0x5
    8000361c:	fa050513          	addi	a0,a0,-96 # 800085b8 <syscalls+0x188>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	f0c080e7          	jalr	-244(ra) # 8000052c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003628:	40dc                	lw	a5,4(s1)
    8000362a:	0047d79b          	srliw	a5,a5,0x4
    8000362e:	0001c597          	auipc	a1,0x1c
    80003632:	1925a583          	lw	a1,402(a1) # 8001f7c0 <sb+0x18>
    80003636:	9dbd                	addw	a1,a1,a5
    80003638:	4088                	lw	a0,0(s1)
    8000363a:	fffff097          	auipc	ra,0xfffff
    8000363e:	7ac080e7          	jalr	1964(ra) # 80002de6 <bread>
    80003642:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003644:	05850593          	addi	a1,a0,88
    80003648:	40dc                	lw	a5,4(s1)
    8000364a:	8bbd                	andi	a5,a5,15
    8000364c:	079a                	slli	a5,a5,0x6
    8000364e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003650:	00059783          	lh	a5,0(a1)
    80003654:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003658:	00259783          	lh	a5,2(a1)
    8000365c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003660:	00459783          	lh	a5,4(a1)
    80003664:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003668:	00659783          	lh	a5,6(a1)
    8000366c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003670:	459c                	lw	a5,8(a1)
    80003672:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003674:	03400613          	li	a2,52
    80003678:	05b1                	addi	a1,a1,12
    8000367a:	05048513          	addi	a0,s1,80
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	69c080e7          	jalr	1692(ra) # 80000d1a <memmove>
    brelse(bp);
    80003686:	854a                	mv	a0,s2
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	88e080e7          	jalr	-1906(ra) # 80002f16 <brelse>
    ip->valid = 1;
    80003690:	4785                	li	a5,1
    80003692:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003694:	04449783          	lh	a5,68(s1)
    80003698:	fbb5                	bnez	a5,8000360c <ilock+0x24>
      panic("ilock: no type");
    8000369a:	00005517          	auipc	a0,0x5
    8000369e:	f2650513          	addi	a0,a0,-218 # 800085c0 <syscalls+0x190>
    800036a2:	ffffd097          	auipc	ra,0xffffd
    800036a6:	e8a080e7          	jalr	-374(ra) # 8000052c <panic>

00000000800036aa <iunlock>:
{
    800036aa:	1101                	addi	sp,sp,-32
    800036ac:	ec06                	sd	ra,24(sp)
    800036ae:	e822                	sd	s0,16(sp)
    800036b0:	e426                	sd	s1,8(sp)
    800036b2:	e04a                	sd	s2,0(sp)
    800036b4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036b6:	c905                	beqz	a0,800036e6 <iunlock+0x3c>
    800036b8:	84aa                	mv	s1,a0
    800036ba:	01050913          	addi	s2,a0,16
    800036be:	854a                	mv	a0,s2
    800036c0:	00001097          	auipc	ra,0x1
    800036c4:	c92080e7          	jalr	-878(ra) # 80004352 <holdingsleep>
    800036c8:	cd19                	beqz	a0,800036e6 <iunlock+0x3c>
    800036ca:	449c                	lw	a5,8(s1)
    800036cc:	00f05d63          	blez	a5,800036e6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800036d0:	854a                	mv	a0,s2
    800036d2:	00001097          	auipc	ra,0x1
    800036d6:	c3c080e7          	jalr	-964(ra) # 8000430e <releasesleep>
}
    800036da:	60e2                	ld	ra,24(sp)
    800036dc:	6442                	ld	s0,16(sp)
    800036de:	64a2                	ld	s1,8(sp)
    800036e0:	6902                	ld	s2,0(sp)
    800036e2:	6105                	addi	sp,sp,32
    800036e4:	8082                	ret
    panic("iunlock");
    800036e6:	00005517          	auipc	a0,0x5
    800036ea:	eea50513          	addi	a0,a0,-278 # 800085d0 <syscalls+0x1a0>
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	e3e080e7          	jalr	-450(ra) # 8000052c <panic>

00000000800036f6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800036f6:	7179                	addi	sp,sp,-48
    800036f8:	f406                	sd	ra,40(sp)
    800036fa:	f022                	sd	s0,32(sp)
    800036fc:	ec26                	sd	s1,24(sp)
    800036fe:	e84a                	sd	s2,16(sp)
    80003700:	e44e                	sd	s3,8(sp)
    80003702:	e052                	sd	s4,0(sp)
    80003704:	1800                	addi	s0,sp,48
    80003706:	89aa                	mv	s3,a0
  // so that it can handle doubly indrect inode.
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003708:	05050493          	addi	s1,a0,80
    8000370c:	08050913          	addi	s2,a0,128
    80003710:	a021                	j	80003718 <itrunc+0x22>
    80003712:	0491                	addi	s1,s1,4
    80003714:	01248d63          	beq	s1,s2,8000372e <itrunc+0x38>
    if(ip->addrs[i]){
    80003718:	408c                	lw	a1,0(s1)
    8000371a:	dde5                	beqz	a1,80003712 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000371c:	0009a503          	lw	a0,0(s3)
    80003720:	00000097          	auipc	ra,0x0
    80003724:	90c080e7          	jalr	-1780(ra) # 8000302c <bfree>
      ip->addrs[i] = 0;
    80003728:	0004a023          	sw	zero,0(s1)
    8000372c:	b7dd                	j	80003712 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000372e:	0809a583          	lw	a1,128(s3)
    80003732:	e185                	bnez	a1,80003752 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003734:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003738:	854e                	mv	a0,s3
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	de2080e7          	jalr	-542(ra) # 8000351c <iupdate>
}
    80003742:	70a2                	ld	ra,40(sp)
    80003744:	7402                	ld	s0,32(sp)
    80003746:	64e2                	ld	s1,24(sp)
    80003748:	6942                	ld	s2,16(sp)
    8000374a:	69a2                	ld	s3,8(sp)
    8000374c:	6a02                	ld	s4,0(sp)
    8000374e:	6145                	addi	sp,sp,48
    80003750:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003752:	0009a503          	lw	a0,0(s3)
    80003756:	fffff097          	auipc	ra,0xfffff
    8000375a:	690080e7          	jalr	1680(ra) # 80002de6 <bread>
    8000375e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003760:	05850493          	addi	s1,a0,88
    80003764:	45850913          	addi	s2,a0,1112
    80003768:	a021                	j	80003770 <itrunc+0x7a>
    8000376a:	0491                	addi	s1,s1,4
    8000376c:	01248b63          	beq	s1,s2,80003782 <itrunc+0x8c>
      if(a[j])
    80003770:	408c                	lw	a1,0(s1)
    80003772:	dde5                	beqz	a1,8000376a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003774:	0009a503          	lw	a0,0(s3)
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	8b4080e7          	jalr	-1868(ra) # 8000302c <bfree>
    80003780:	b7ed                	j	8000376a <itrunc+0x74>
    brelse(bp);
    80003782:	8552                	mv	a0,s4
    80003784:	fffff097          	auipc	ra,0xfffff
    80003788:	792080e7          	jalr	1938(ra) # 80002f16 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000378c:	0809a583          	lw	a1,128(s3)
    80003790:	0009a503          	lw	a0,0(s3)
    80003794:	00000097          	auipc	ra,0x0
    80003798:	898080e7          	jalr	-1896(ra) # 8000302c <bfree>
    ip->addrs[NDIRECT] = 0;
    8000379c:	0809a023          	sw	zero,128(s3)
    800037a0:	bf51                	j	80003734 <itrunc+0x3e>

00000000800037a2 <iput>:
{
    800037a2:	1101                	addi	sp,sp,-32
    800037a4:	ec06                	sd	ra,24(sp)
    800037a6:	e822                	sd	s0,16(sp)
    800037a8:	e426                	sd	s1,8(sp)
    800037aa:	e04a                	sd	s2,0(sp)
    800037ac:	1000                	addi	s0,sp,32
    800037ae:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037b0:	0001c517          	auipc	a0,0x1c
    800037b4:	01850513          	addi	a0,a0,24 # 8001f7c8 <itable>
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	40a080e7          	jalr	1034(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037c0:	4498                	lw	a4,8(s1)
    800037c2:	4785                	li	a5,1
    800037c4:	02f70363          	beq	a4,a5,800037ea <iput+0x48>
  ip->ref--;
    800037c8:	449c                	lw	a5,8(s1)
    800037ca:	37fd                	addiw	a5,a5,-1
    800037cc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037ce:	0001c517          	auipc	a0,0x1c
    800037d2:	ffa50513          	addi	a0,a0,-6 # 8001f7c8 <itable>
    800037d6:	ffffd097          	auipc	ra,0xffffd
    800037da:	4a0080e7          	jalr	1184(ra) # 80000c76 <release>
}
    800037de:	60e2                	ld	ra,24(sp)
    800037e0:	6442                	ld	s0,16(sp)
    800037e2:	64a2                	ld	s1,8(sp)
    800037e4:	6902                	ld	s2,0(sp)
    800037e6:	6105                	addi	sp,sp,32
    800037e8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037ea:	40bc                	lw	a5,64(s1)
    800037ec:	dff1                	beqz	a5,800037c8 <iput+0x26>
    800037ee:	04a49783          	lh	a5,74(s1)
    800037f2:	fbf9                	bnez	a5,800037c8 <iput+0x26>
    acquiresleep(&ip->lock);
    800037f4:	01048913          	addi	s2,s1,16
    800037f8:	854a                	mv	a0,s2
    800037fa:	00001097          	auipc	ra,0x1
    800037fe:	abe080e7          	jalr	-1346(ra) # 800042b8 <acquiresleep>
    release(&itable.lock);
    80003802:	0001c517          	auipc	a0,0x1c
    80003806:	fc650513          	addi	a0,a0,-58 # 8001f7c8 <itable>
    8000380a:	ffffd097          	auipc	ra,0xffffd
    8000380e:	46c080e7          	jalr	1132(ra) # 80000c76 <release>
    itrunc(ip);
    80003812:	8526                	mv	a0,s1
    80003814:	00000097          	auipc	ra,0x0
    80003818:	ee2080e7          	jalr	-286(ra) # 800036f6 <itrunc>
    ip->type = 0;
    8000381c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003820:	8526                	mv	a0,s1
    80003822:	00000097          	auipc	ra,0x0
    80003826:	cfa080e7          	jalr	-774(ra) # 8000351c <iupdate>
    ip->valid = 0;
    8000382a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000382e:	854a                	mv	a0,s2
    80003830:	00001097          	auipc	ra,0x1
    80003834:	ade080e7          	jalr	-1314(ra) # 8000430e <releasesleep>
    acquire(&itable.lock);
    80003838:	0001c517          	auipc	a0,0x1c
    8000383c:	f9050513          	addi	a0,a0,-112 # 8001f7c8 <itable>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	382080e7          	jalr	898(ra) # 80000bc2 <acquire>
    80003848:	b741                	j	800037c8 <iput+0x26>

000000008000384a <iunlockput>:
{
    8000384a:	1101                	addi	sp,sp,-32
    8000384c:	ec06                	sd	ra,24(sp)
    8000384e:	e822                	sd	s0,16(sp)
    80003850:	e426                	sd	s1,8(sp)
    80003852:	1000                	addi	s0,sp,32
    80003854:	84aa                	mv	s1,a0
  iunlock(ip);
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	e54080e7          	jalr	-428(ra) # 800036aa <iunlock>
  iput(ip);
    8000385e:	8526                	mv	a0,s1
    80003860:	00000097          	auipc	ra,0x0
    80003864:	f42080e7          	jalr	-190(ra) # 800037a2 <iput>
}
    80003868:	60e2                	ld	ra,24(sp)
    8000386a:	6442                	ld	s0,16(sp)
    8000386c:	64a2                	ld	s1,8(sp)
    8000386e:	6105                	addi	sp,sp,32
    80003870:	8082                	ret

0000000080003872 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003872:	1141                	addi	sp,sp,-16
    80003874:	e422                	sd	s0,8(sp)
    80003876:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003878:	411c                	lw	a5,0(a0)
    8000387a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000387c:	415c                	lw	a5,4(a0)
    8000387e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003880:	04451783          	lh	a5,68(a0)
    80003884:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003888:	04a51783          	lh	a5,74(a0)
    8000388c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003890:	04c56783          	lwu	a5,76(a0)
    80003894:	e99c                	sd	a5,16(a1)
}
    80003896:	6422                	ld	s0,8(sp)
    80003898:	0141                	addi	sp,sp,16
    8000389a:	8082                	ret

000000008000389c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000389c:	457c                	lw	a5,76(a0)
    8000389e:	0ed7e963          	bltu	a5,a3,80003990 <readi+0xf4>
{
    800038a2:	7159                	addi	sp,sp,-112
    800038a4:	f486                	sd	ra,104(sp)
    800038a6:	f0a2                	sd	s0,96(sp)
    800038a8:	eca6                	sd	s1,88(sp)
    800038aa:	e8ca                	sd	s2,80(sp)
    800038ac:	e4ce                	sd	s3,72(sp)
    800038ae:	e0d2                	sd	s4,64(sp)
    800038b0:	fc56                	sd	s5,56(sp)
    800038b2:	f85a                	sd	s6,48(sp)
    800038b4:	f45e                	sd	s7,40(sp)
    800038b6:	f062                	sd	s8,32(sp)
    800038b8:	ec66                	sd	s9,24(sp)
    800038ba:	e86a                	sd	s10,16(sp)
    800038bc:	e46e                	sd	s11,8(sp)
    800038be:	1880                	addi	s0,sp,112
    800038c0:	8baa                	mv	s7,a0
    800038c2:	8c2e                	mv	s8,a1
    800038c4:	8ab2                	mv	s5,a2
    800038c6:	84b6                	mv	s1,a3
    800038c8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800038ca:	9f35                	addw	a4,a4,a3
    return 0;
    800038cc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800038ce:	0ad76063          	bltu	a4,a3,8000396e <readi+0xd2>
  if(off + n > ip->size)
    800038d2:	00e7f463          	bgeu	a5,a4,800038da <readi+0x3e>
    n = ip->size - off;
    800038d6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038da:	0a0b0963          	beqz	s6,8000398c <readi+0xf0>
    800038de:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800038e0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800038e4:	5cfd                	li	s9,-1
    800038e6:	a82d                	j	80003920 <readi+0x84>
    800038e8:	020a1d93          	slli	s11,s4,0x20
    800038ec:	020ddd93          	srli	s11,s11,0x20
    800038f0:	05890613          	addi	a2,s2,88
    800038f4:	86ee                	mv	a3,s11
    800038f6:	963a                	add	a2,a2,a4
    800038f8:	85d6                	mv	a1,s5
    800038fa:	8562                	mv	a0,s8
    800038fc:	fffff097          	auipc	ra,0xfffff
    80003900:	b2c080e7          	jalr	-1236(ra) # 80002428 <either_copyout>
    80003904:	05950d63          	beq	a0,s9,8000395e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003908:	854a                	mv	a0,s2
    8000390a:	fffff097          	auipc	ra,0xfffff
    8000390e:	60c080e7          	jalr	1548(ra) # 80002f16 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003912:	013a09bb          	addw	s3,s4,s3
    80003916:	009a04bb          	addw	s1,s4,s1
    8000391a:	9aee                	add	s5,s5,s11
    8000391c:	0569f763          	bgeu	s3,s6,8000396a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003920:	000ba903          	lw	s2,0(s7)
    80003924:	00a4d59b          	srliw	a1,s1,0xa
    80003928:	855e                	mv	a0,s7
    8000392a:	00000097          	auipc	ra,0x0
    8000392e:	8ac080e7          	jalr	-1876(ra) # 800031d6 <bmap>
    80003932:	0005059b          	sext.w	a1,a0
    80003936:	854a                	mv	a0,s2
    80003938:	fffff097          	auipc	ra,0xfffff
    8000393c:	4ae080e7          	jalr	1198(ra) # 80002de6 <bread>
    80003940:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003942:	3ff4f713          	andi	a4,s1,1023
    80003946:	40ed07bb          	subw	a5,s10,a4
    8000394a:	413b06bb          	subw	a3,s6,s3
    8000394e:	8a3e                	mv	s4,a5
    80003950:	2781                	sext.w	a5,a5
    80003952:	0006861b          	sext.w	a2,a3
    80003956:	f8f679e3          	bgeu	a2,a5,800038e8 <readi+0x4c>
    8000395a:	8a36                	mv	s4,a3
    8000395c:	b771                	j	800038e8 <readi+0x4c>
      brelse(bp);
    8000395e:	854a                	mv	a0,s2
    80003960:	fffff097          	auipc	ra,0xfffff
    80003964:	5b6080e7          	jalr	1462(ra) # 80002f16 <brelse>
      tot = -1;
    80003968:	59fd                	li	s3,-1
  }
  return tot;
    8000396a:	0009851b          	sext.w	a0,s3
}
    8000396e:	70a6                	ld	ra,104(sp)
    80003970:	7406                	ld	s0,96(sp)
    80003972:	64e6                	ld	s1,88(sp)
    80003974:	6946                	ld	s2,80(sp)
    80003976:	69a6                	ld	s3,72(sp)
    80003978:	6a06                	ld	s4,64(sp)
    8000397a:	7ae2                	ld	s5,56(sp)
    8000397c:	7b42                	ld	s6,48(sp)
    8000397e:	7ba2                	ld	s7,40(sp)
    80003980:	7c02                	ld	s8,32(sp)
    80003982:	6ce2                	ld	s9,24(sp)
    80003984:	6d42                	ld	s10,16(sp)
    80003986:	6da2                	ld	s11,8(sp)
    80003988:	6165                	addi	sp,sp,112
    8000398a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000398c:	89da                	mv	s3,s6
    8000398e:	bff1                	j	8000396a <readi+0xce>
    return 0;
    80003990:	4501                	li	a0,0
}
    80003992:	8082                	ret

0000000080003994 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003994:	457c                	lw	a5,76(a0)
    80003996:	10d7e863          	bltu	a5,a3,80003aa6 <writei+0x112>
{
    8000399a:	7159                	addi	sp,sp,-112
    8000399c:	f486                	sd	ra,104(sp)
    8000399e:	f0a2                	sd	s0,96(sp)
    800039a0:	eca6                	sd	s1,88(sp)
    800039a2:	e8ca                	sd	s2,80(sp)
    800039a4:	e4ce                	sd	s3,72(sp)
    800039a6:	e0d2                	sd	s4,64(sp)
    800039a8:	fc56                	sd	s5,56(sp)
    800039aa:	f85a                	sd	s6,48(sp)
    800039ac:	f45e                	sd	s7,40(sp)
    800039ae:	f062                	sd	s8,32(sp)
    800039b0:	ec66                	sd	s9,24(sp)
    800039b2:	e86a                	sd	s10,16(sp)
    800039b4:	e46e                	sd	s11,8(sp)
    800039b6:	1880                	addi	s0,sp,112
    800039b8:	8b2a                	mv	s6,a0
    800039ba:	8c2e                	mv	s8,a1
    800039bc:	8ab2                	mv	s5,a2
    800039be:	8936                	mv	s2,a3
    800039c0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800039c2:	00e687bb          	addw	a5,a3,a4
    800039c6:	0ed7e263          	bltu	a5,a3,80003aaa <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800039ca:	00043737          	lui	a4,0x43
    800039ce:	0ef76063          	bltu	a4,a5,80003aae <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039d2:	0c0b8863          	beqz	s7,80003aa2 <writei+0x10e>
    800039d6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039d8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800039dc:	5cfd                	li	s9,-1
    800039de:	a091                	j	80003a22 <writei+0x8e>
    800039e0:	02099d93          	slli	s11,s3,0x20
    800039e4:	020ddd93          	srli	s11,s11,0x20
    800039e8:	05848513          	addi	a0,s1,88
    800039ec:	86ee                	mv	a3,s11
    800039ee:	8656                	mv	a2,s5
    800039f0:	85e2                	mv	a1,s8
    800039f2:	953a                	add	a0,a0,a4
    800039f4:	fffff097          	auipc	ra,0xfffff
    800039f8:	a8a080e7          	jalr	-1398(ra) # 8000247e <either_copyin>
    800039fc:	07950263          	beq	a0,s9,80003a60 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a00:	8526                	mv	a0,s1
    80003a02:	00000097          	auipc	ra,0x0
    80003a06:	798080e7          	jalr	1944(ra) # 8000419a <log_write>
    brelse(bp);
    80003a0a:	8526                	mv	a0,s1
    80003a0c:	fffff097          	auipc	ra,0xfffff
    80003a10:	50a080e7          	jalr	1290(ra) # 80002f16 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a14:	01498a3b          	addw	s4,s3,s4
    80003a18:	0129893b          	addw	s2,s3,s2
    80003a1c:	9aee                	add	s5,s5,s11
    80003a1e:	057a7663          	bgeu	s4,s7,80003a6a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a22:	000b2483          	lw	s1,0(s6)
    80003a26:	00a9559b          	srliw	a1,s2,0xa
    80003a2a:	855a                	mv	a0,s6
    80003a2c:	fffff097          	auipc	ra,0xfffff
    80003a30:	7aa080e7          	jalr	1962(ra) # 800031d6 <bmap>
    80003a34:	0005059b          	sext.w	a1,a0
    80003a38:	8526                	mv	a0,s1
    80003a3a:	fffff097          	auipc	ra,0xfffff
    80003a3e:	3ac080e7          	jalr	940(ra) # 80002de6 <bread>
    80003a42:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a44:	3ff97713          	andi	a4,s2,1023
    80003a48:	40ed07bb          	subw	a5,s10,a4
    80003a4c:	414b86bb          	subw	a3,s7,s4
    80003a50:	89be                	mv	s3,a5
    80003a52:	2781                	sext.w	a5,a5
    80003a54:	0006861b          	sext.w	a2,a3
    80003a58:	f8f674e3          	bgeu	a2,a5,800039e0 <writei+0x4c>
    80003a5c:	89b6                	mv	s3,a3
    80003a5e:	b749                	j	800039e0 <writei+0x4c>
      brelse(bp);
    80003a60:	8526                	mv	a0,s1
    80003a62:	fffff097          	auipc	ra,0xfffff
    80003a66:	4b4080e7          	jalr	1204(ra) # 80002f16 <brelse>
  }

  if(off > ip->size)
    80003a6a:	04cb2783          	lw	a5,76(s6)
    80003a6e:	0127f463          	bgeu	a5,s2,80003a76 <writei+0xe2>
    ip->size = off;
    80003a72:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003a76:	855a                	mv	a0,s6
    80003a78:	00000097          	auipc	ra,0x0
    80003a7c:	aa4080e7          	jalr	-1372(ra) # 8000351c <iupdate>

  return tot;
    80003a80:	000a051b          	sext.w	a0,s4
}
    80003a84:	70a6                	ld	ra,104(sp)
    80003a86:	7406                	ld	s0,96(sp)
    80003a88:	64e6                	ld	s1,88(sp)
    80003a8a:	6946                	ld	s2,80(sp)
    80003a8c:	69a6                	ld	s3,72(sp)
    80003a8e:	6a06                	ld	s4,64(sp)
    80003a90:	7ae2                	ld	s5,56(sp)
    80003a92:	7b42                	ld	s6,48(sp)
    80003a94:	7ba2                	ld	s7,40(sp)
    80003a96:	7c02                	ld	s8,32(sp)
    80003a98:	6ce2                	ld	s9,24(sp)
    80003a9a:	6d42                	ld	s10,16(sp)
    80003a9c:	6da2                	ld	s11,8(sp)
    80003a9e:	6165                	addi	sp,sp,112
    80003aa0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aa2:	8a5e                	mv	s4,s7
    80003aa4:	bfc9                	j	80003a76 <writei+0xe2>
    return -1;
    80003aa6:	557d                	li	a0,-1
}
    80003aa8:	8082                	ret
    return -1;
    80003aaa:	557d                	li	a0,-1
    80003aac:	bfe1                	j	80003a84 <writei+0xf0>
    return -1;
    80003aae:	557d                	li	a0,-1
    80003ab0:	bfd1                	j	80003a84 <writei+0xf0>

0000000080003ab2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ab2:	1141                	addi	sp,sp,-16
    80003ab4:	e406                	sd	ra,8(sp)
    80003ab6:	e022                	sd	s0,0(sp)
    80003ab8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003aba:	4639                	li	a2,14
    80003abc:	ffffd097          	auipc	ra,0xffffd
    80003ac0:	2da080e7          	jalr	730(ra) # 80000d96 <strncmp>
}
    80003ac4:	60a2                	ld	ra,8(sp)
    80003ac6:	6402                	ld	s0,0(sp)
    80003ac8:	0141                	addi	sp,sp,16
    80003aca:	8082                	ret

0000000080003acc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003acc:	7139                	addi	sp,sp,-64
    80003ace:	fc06                	sd	ra,56(sp)
    80003ad0:	f822                	sd	s0,48(sp)
    80003ad2:	f426                	sd	s1,40(sp)
    80003ad4:	f04a                	sd	s2,32(sp)
    80003ad6:	ec4e                	sd	s3,24(sp)
    80003ad8:	e852                	sd	s4,16(sp)
    80003ada:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003adc:	04451703          	lh	a4,68(a0)
    80003ae0:	4785                	li	a5,1
    80003ae2:	00f71a63          	bne	a4,a5,80003af6 <dirlookup+0x2a>
    80003ae6:	892a                	mv	s2,a0
    80003ae8:	89ae                	mv	s3,a1
    80003aea:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003aec:	457c                	lw	a5,76(a0)
    80003aee:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003af0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003af2:	e79d                	bnez	a5,80003b20 <dirlookup+0x54>
    80003af4:	a8a5                	j	80003b6c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003af6:	00005517          	auipc	a0,0x5
    80003afa:	ae250513          	addi	a0,a0,-1310 # 800085d8 <syscalls+0x1a8>
    80003afe:	ffffd097          	auipc	ra,0xffffd
    80003b02:	a2e080e7          	jalr	-1490(ra) # 8000052c <panic>
      panic("dirlookup read");
    80003b06:	00005517          	auipc	a0,0x5
    80003b0a:	aea50513          	addi	a0,a0,-1302 # 800085f0 <syscalls+0x1c0>
    80003b0e:	ffffd097          	auipc	ra,0xffffd
    80003b12:	a1e080e7          	jalr	-1506(ra) # 8000052c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b16:	24c1                	addiw	s1,s1,16
    80003b18:	04c92783          	lw	a5,76(s2)
    80003b1c:	04f4f763          	bgeu	s1,a5,80003b6a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b20:	4741                	li	a4,16
    80003b22:	86a6                	mv	a3,s1
    80003b24:	fc040613          	addi	a2,s0,-64
    80003b28:	4581                	li	a1,0
    80003b2a:	854a                	mv	a0,s2
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	d70080e7          	jalr	-656(ra) # 8000389c <readi>
    80003b34:	47c1                	li	a5,16
    80003b36:	fcf518e3          	bne	a0,a5,80003b06 <dirlookup+0x3a>
    if(de.inum == 0)
    80003b3a:	fc045783          	lhu	a5,-64(s0)
    80003b3e:	dfe1                	beqz	a5,80003b16 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b40:	fc240593          	addi	a1,s0,-62
    80003b44:	854e                	mv	a0,s3
    80003b46:	00000097          	auipc	ra,0x0
    80003b4a:	f6c080e7          	jalr	-148(ra) # 80003ab2 <namecmp>
    80003b4e:	f561                	bnez	a0,80003b16 <dirlookup+0x4a>
      if(poff)
    80003b50:	000a0463          	beqz	s4,80003b58 <dirlookup+0x8c>
        *poff = off;
    80003b54:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b58:	fc045583          	lhu	a1,-64(s0)
    80003b5c:	00092503          	lw	a0,0(s2)
    80003b60:	fffff097          	auipc	ra,0xfffff
    80003b64:	752080e7          	jalr	1874(ra) # 800032b2 <iget>
    80003b68:	a011                	j	80003b6c <dirlookup+0xa0>
  return 0;
    80003b6a:	4501                	li	a0,0
}
    80003b6c:	70e2                	ld	ra,56(sp)
    80003b6e:	7442                	ld	s0,48(sp)
    80003b70:	74a2                	ld	s1,40(sp)
    80003b72:	7902                	ld	s2,32(sp)
    80003b74:	69e2                	ld	s3,24(sp)
    80003b76:	6a42                	ld	s4,16(sp)
    80003b78:	6121                	addi	sp,sp,64
    80003b7a:	8082                	ret

0000000080003b7c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003b7c:	711d                	addi	sp,sp,-96
    80003b7e:	ec86                	sd	ra,88(sp)
    80003b80:	e8a2                	sd	s0,80(sp)
    80003b82:	e4a6                	sd	s1,72(sp)
    80003b84:	e0ca                	sd	s2,64(sp)
    80003b86:	fc4e                	sd	s3,56(sp)
    80003b88:	f852                	sd	s4,48(sp)
    80003b8a:	f456                	sd	s5,40(sp)
    80003b8c:	f05a                	sd	s6,32(sp)
    80003b8e:	ec5e                	sd	s7,24(sp)
    80003b90:	e862                	sd	s8,16(sp)
    80003b92:	e466                	sd	s9,8(sp)
    80003b94:	e06a                	sd	s10,0(sp)
    80003b96:	1080                	addi	s0,sp,96
    80003b98:	84aa                	mv	s1,a0
    80003b9a:	8b2e                	mv	s6,a1
    80003b9c:	8ab2                	mv	s5,a2
  // TODO: Symbolic Link to Directories
  // Modify this function to deal with symbolic links to directories.
  struct inode *ip, *next;
  
  if(*path == '/')
    80003b9e:	00054703          	lbu	a4,0(a0)
    80003ba2:	02f00793          	li	a5,47
    80003ba6:	02f70363          	beq	a4,a5,80003bcc <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003baa:	ffffe097          	auipc	ra,0xffffe
    80003bae:	e16080e7          	jalr	-490(ra) # 800019c0 <myproc>
    80003bb2:	15053503          	ld	a0,336(a0)
    80003bb6:	00000097          	auipc	ra,0x0
    80003bba:	9f4080e7          	jalr	-1548(ra) # 800035aa <idup>
    80003bbe:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003bc0:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003bc4:	4cb5                	li	s9,13
  len = path - s;
    80003bc6:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003bc8:	4c05                	li	s8,1
    80003bca:	a87d                	j	80003c88 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003bcc:	4585                	li	a1,1
    80003bce:	4505                	li	a0,1
    80003bd0:	fffff097          	auipc	ra,0xfffff
    80003bd4:	6e2080e7          	jalr	1762(ra) # 800032b2 <iget>
    80003bd8:	8a2a                	mv	s4,a0
    80003bda:	b7dd                	j	80003bc0 <namex+0x44>
      iunlockput(ip);
    80003bdc:	8552                	mv	a0,s4
    80003bde:	00000097          	auipc	ra,0x0
    80003be2:	c6c080e7          	jalr	-916(ra) # 8000384a <iunlockput>
      return 0;
    80003be6:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003be8:	8552                	mv	a0,s4
    80003bea:	60e6                	ld	ra,88(sp)
    80003bec:	6446                	ld	s0,80(sp)
    80003bee:	64a6                	ld	s1,72(sp)
    80003bf0:	6906                	ld	s2,64(sp)
    80003bf2:	79e2                	ld	s3,56(sp)
    80003bf4:	7a42                	ld	s4,48(sp)
    80003bf6:	7aa2                	ld	s5,40(sp)
    80003bf8:	7b02                	ld	s6,32(sp)
    80003bfa:	6be2                	ld	s7,24(sp)
    80003bfc:	6c42                	ld	s8,16(sp)
    80003bfe:	6ca2                	ld	s9,8(sp)
    80003c00:	6d02                	ld	s10,0(sp)
    80003c02:	6125                	addi	sp,sp,96
    80003c04:	8082                	ret
      iunlock(ip);
    80003c06:	8552                	mv	a0,s4
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	aa2080e7          	jalr	-1374(ra) # 800036aa <iunlock>
      return ip;
    80003c10:	bfe1                	j	80003be8 <namex+0x6c>
      iunlockput(ip);
    80003c12:	8552                	mv	a0,s4
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	c36080e7          	jalr	-970(ra) # 8000384a <iunlockput>
      return 0;
    80003c1c:	8a4e                	mv	s4,s3
    80003c1e:	b7e9                	j	80003be8 <namex+0x6c>
  len = path - s;
    80003c20:	40998633          	sub	a2,s3,s1
    80003c24:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003c28:	09acd863          	bge	s9,s10,80003cb8 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003c2c:	4639                	li	a2,14
    80003c2e:	85a6                	mv	a1,s1
    80003c30:	8556                	mv	a0,s5
    80003c32:	ffffd097          	auipc	ra,0xffffd
    80003c36:	0e8080e7          	jalr	232(ra) # 80000d1a <memmove>
    80003c3a:	84ce                	mv	s1,s3
  while(*path == '/')
    80003c3c:	0004c783          	lbu	a5,0(s1)
    80003c40:	01279763          	bne	a5,s2,80003c4e <namex+0xd2>
    path++;
    80003c44:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c46:	0004c783          	lbu	a5,0(s1)
    80003c4a:	ff278de3          	beq	a5,s2,80003c44 <namex+0xc8>
    ilock(ip);
    80003c4e:	8552                	mv	a0,s4
    80003c50:	00000097          	auipc	ra,0x0
    80003c54:	998080e7          	jalr	-1640(ra) # 800035e8 <ilock>
    if(ip->type != T_DIR){
    80003c58:	044a1783          	lh	a5,68(s4)
    80003c5c:	f98790e3          	bne	a5,s8,80003bdc <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003c60:	000b0563          	beqz	s6,80003c6a <namex+0xee>
    80003c64:	0004c783          	lbu	a5,0(s1)
    80003c68:	dfd9                	beqz	a5,80003c06 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c6a:	865e                	mv	a2,s7
    80003c6c:	85d6                	mv	a1,s5
    80003c6e:	8552                	mv	a0,s4
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	e5c080e7          	jalr	-420(ra) # 80003acc <dirlookup>
    80003c78:	89aa                	mv	s3,a0
    80003c7a:	dd41                	beqz	a0,80003c12 <namex+0x96>
    iunlockput(ip);
    80003c7c:	8552                	mv	a0,s4
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	bcc080e7          	jalr	-1076(ra) # 8000384a <iunlockput>
    ip = next;
    80003c86:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003c88:	0004c783          	lbu	a5,0(s1)
    80003c8c:	01279763          	bne	a5,s2,80003c9a <namex+0x11e>
    path++;
    80003c90:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c92:	0004c783          	lbu	a5,0(s1)
    80003c96:	ff278de3          	beq	a5,s2,80003c90 <namex+0x114>
  if(*path == 0)
    80003c9a:	cb9d                	beqz	a5,80003cd0 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003c9c:	0004c783          	lbu	a5,0(s1)
    80003ca0:	89a6                	mv	s3,s1
  len = path - s;
    80003ca2:	8d5e                	mv	s10,s7
    80003ca4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ca6:	01278963          	beq	a5,s2,80003cb8 <namex+0x13c>
    80003caa:	dbbd                	beqz	a5,80003c20 <namex+0xa4>
    path++;
    80003cac:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003cae:	0009c783          	lbu	a5,0(s3)
    80003cb2:	ff279ce3          	bne	a5,s2,80003caa <namex+0x12e>
    80003cb6:	b7ad                	j	80003c20 <namex+0xa4>
    memmove(name, s, len);
    80003cb8:	2601                	sext.w	a2,a2
    80003cba:	85a6                	mv	a1,s1
    80003cbc:	8556                	mv	a0,s5
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	05c080e7          	jalr	92(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003cc6:	9d56                	add	s10,s10,s5
    80003cc8:	000d0023          	sb	zero,0(s10)
    80003ccc:	84ce                	mv	s1,s3
    80003cce:	b7bd                	j	80003c3c <namex+0xc0>
  if(nameiparent){
    80003cd0:	f00b0ce3          	beqz	s6,80003be8 <namex+0x6c>
    iput(ip);
    80003cd4:	8552                	mv	a0,s4
    80003cd6:	00000097          	auipc	ra,0x0
    80003cda:	acc080e7          	jalr	-1332(ra) # 800037a2 <iput>
    return 0;
    80003cde:	4a01                	li	s4,0
    80003ce0:	b721                	j	80003be8 <namex+0x6c>

0000000080003ce2 <dirlink>:
{
    80003ce2:	7139                	addi	sp,sp,-64
    80003ce4:	fc06                	sd	ra,56(sp)
    80003ce6:	f822                	sd	s0,48(sp)
    80003ce8:	f426                	sd	s1,40(sp)
    80003cea:	f04a                	sd	s2,32(sp)
    80003cec:	ec4e                	sd	s3,24(sp)
    80003cee:	e852                	sd	s4,16(sp)
    80003cf0:	0080                	addi	s0,sp,64
    80003cf2:	892a                	mv	s2,a0
    80003cf4:	8a2e                	mv	s4,a1
    80003cf6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003cf8:	4601                	li	a2,0
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	dd2080e7          	jalr	-558(ra) # 80003acc <dirlookup>
    80003d02:	e93d                	bnez	a0,80003d78 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d04:	04c92483          	lw	s1,76(s2)
    80003d08:	c49d                	beqz	s1,80003d36 <dirlink+0x54>
    80003d0a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d0c:	4741                	li	a4,16
    80003d0e:	86a6                	mv	a3,s1
    80003d10:	fc040613          	addi	a2,s0,-64
    80003d14:	4581                	li	a1,0
    80003d16:	854a                	mv	a0,s2
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	b84080e7          	jalr	-1148(ra) # 8000389c <readi>
    80003d20:	47c1                	li	a5,16
    80003d22:	06f51163          	bne	a0,a5,80003d84 <dirlink+0xa2>
    if(de.inum == 0)
    80003d26:	fc045783          	lhu	a5,-64(s0)
    80003d2a:	c791                	beqz	a5,80003d36 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d2c:	24c1                	addiw	s1,s1,16
    80003d2e:	04c92783          	lw	a5,76(s2)
    80003d32:	fcf4ede3          	bltu	s1,a5,80003d0c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d36:	4639                	li	a2,14
    80003d38:	85d2                	mv	a1,s4
    80003d3a:	fc240513          	addi	a0,s0,-62
    80003d3e:	ffffd097          	auipc	ra,0xffffd
    80003d42:	094080e7          	jalr	148(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003d46:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d4a:	4741                	li	a4,16
    80003d4c:	86a6                	mv	a3,s1
    80003d4e:	fc040613          	addi	a2,s0,-64
    80003d52:	4581                	li	a1,0
    80003d54:	854a                	mv	a0,s2
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	c3e080e7          	jalr	-962(ra) # 80003994 <writei>
    80003d5e:	872a                	mv	a4,a0
    80003d60:	47c1                	li	a5,16
  return 0;
    80003d62:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d64:	02f71863          	bne	a4,a5,80003d94 <dirlink+0xb2>
}
    80003d68:	70e2                	ld	ra,56(sp)
    80003d6a:	7442                	ld	s0,48(sp)
    80003d6c:	74a2                	ld	s1,40(sp)
    80003d6e:	7902                	ld	s2,32(sp)
    80003d70:	69e2                	ld	s3,24(sp)
    80003d72:	6a42                	ld	s4,16(sp)
    80003d74:	6121                	addi	sp,sp,64
    80003d76:	8082                	ret
    iput(ip);
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	a2a080e7          	jalr	-1494(ra) # 800037a2 <iput>
    return -1;
    80003d80:	557d                	li	a0,-1
    80003d82:	b7dd                	j	80003d68 <dirlink+0x86>
      panic("dirlink read");
    80003d84:	00005517          	auipc	a0,0x5
    80003d88:	87c50513          	addi	a0,a0,-1924 # 80008600 <syscalls+0x1d0>
    80003d8c:	ffffc097          	auipc	ra,0xffffc
    80003d90:	7a0080e7          	jalr	1952(ra) # 8000052c <panic>
    panic("dirlink");
    80003d94:	00005517          	auipc	a0,0x5
    80003d98:	97450513          	addi	a0,a0,-1676 # 80008708 <syscalls+0x2d8>
    80003d9c:	ffffc097          	auipc	ra,0xffffc
    80003da0:	790080e7          	jalr	1936(ra) # 8000052c <panic>

0000000080003da4 <namei>:

struct inode*
namei(char *path)
{
    80003da4:	1101                	addi	sp,sp,-32
    80003da6:	ec06                	sd	ra,24(sp)
    80003da8:	e822                	sd	s0,16(sp)
    80003daa:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003dac:	fe040613          	addi	a2,s0,-32
    80003db0:	4581                	li	a1,0
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	dca080e7          	jalr	-566(ra) # 80003b7c <namex>
}
    80003dba:	60e2                	ld	ra,24(sp)
    80003dbc:	6442                	ld	s0,16(sp)
    80003dbe:	6105                	addi	sp,sp,32
    80003dc0:	8082                	ret

0000000080003dc2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003dc2:	1141                	addi	sp,sp,-16
    80003dc4:	e406                	sd	ra,8(sp)
    80003dc6:	e022                	sd	s0,0(sp)
    80003dc8:	0800                	addi	s0,sp,16
    80003dca:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dcc:	4585                	li	a1,1
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	dae080e7          	jalr	-594(ra) # 80003b7c <namex>
    80003dd6:	60a2                	ld	ra,8(sp)
    80003dd8:	6402                	ld	s0,0(sp)
    80003dda:	0141                	addi	sp,sp,16
    80003ddc:	8082                	ret

0000000080003dde <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003dde:	1101                	addi	sp,sp,-32
    80003de0:	ec06                	sd	ra,24(sp)
    80003de2:	e822                	sd	s0,16(sp)
    80003de4:	e426                	sd	s1,8(sp)
    80003de6:	e04a                	sd	s2,0(sp)
    80003de8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003dea:	0001d917          	auipc	s2,0x1d
    80003dee:	48690913          	addi	s2,s2,1158 # 80021270 <log>
    80003df2:	01892583          	lw	a1,24(s2)
    80003df6:	02892503          	lw	a0,40(s2)
    80003dfa:	fffff097          	auipc	ra,0xfffff
    80003dfe:	fec080e7          	jalr	-20(ra) # 80002de6 <bread>
    80003e02:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e04:	02c92683          	lw	a3,44(s2)
    80003e08:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e0a:	02d05863          	blez	a3,80003e3a <write_head+0x5c>
    80003e0e:	0001d797          	auipc	a5,0x1d
    80003e12:	49278793          	addi	a5,a5,1170 # 800212a0 <log+0x30>
    80003e16:	05c50713          	addi	a4,a0,92
    80003e1a:	36fd                	addiw	a3,a3,-1
    80003e1c:	02069613          	slli	a2,a3,0x20
    80003e20:	01e65693          	srli	a3,a2,0x1e
    80003e24:	0001d617          	auipc	a2,0x1d
    80003e28:	48060613          	addi	a2,a2,1152 # 800212a4 <log+0x34>
    80003e2c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e2e:	4390                	lw	a2,0(a5)
    80003e30:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e32:	0791                	addi	a5,a5,4
    80003e34:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003e36:	fed79ce3          	bne	a5,a3,80003e2e <write_head+0x50>
  }
  bwrite(buf);
    80003e3a:	8526                	mv	a0,s1
    80003e3c:	fffff097          	auipc	ra,0xfffff
    80003e40:	09c080e7          	jalr	156(ra) # 80002ed8 <bwrite>
  brelse(buf);
    80003e44:	8526                	mv	a0,s1
    80003e46:	fffff097          	auipc	ra,0xfffff
    80003e4a:	0d0080e7          	jalr	208(ra) # 80002f16 <brelse>
}
    80003e4e:	60e2                	ld	ra,24(sp)
    80003e50:	6442                	ld	s0,16(sp)
    80003e52:	64a2                	ld	s1,8(sp)
    80003e54:	6902                	ld	s2,0(sp)
    80003e56:	6105                	addi	sp,sp,32
    80003e58:	8082                	ret

0000000080003e5a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e5a:	0001d797          	auipc	a5,0x1d
    80003e5e:	4427a783          	lw	a5,1090(a5) # 8002129c <log+0x2c>
    80003e62:	0af05d63          	blez	a5,80003f1c <install_trans+0xc2>
{
    80003e66:	7139                	addi	sp,sp,-64
    80003e68:	fc06                	sd	ra,56(sp)
    80003e6a:	f822                	sd	s0,48(sp)
    80003e6c:	f426                	sd	s1,40(sp)
    80003e6e:	f04a                	sd	s2,32(sp)
    80003e70:	ec4e                	sd	s3,24(sp)
    80003e72:	e852                	sd	s4,16(sp)
    80003e74:	e456                	sd	s5,8(sp)
    80003e76:	e05a                	sd	s6,0(sp)
    80003e78:	0080                	addi	s0,sp,64
    80003e7a:	8b2a                	mv	s6,a0
    80003e7c:	0001da97          	auipc	s5,0x1d
    80003e80:	424a8a93          	addi	s5,s5,1060 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e84:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e86:	0001d997          	auipc	s3,0x1d
    80003e8a:	3ea98993          	addi	s3,s3,1002 # 80021270 <log>
    80003e8e:	a00d                	j	80003eb0 <install_trans+0x56>
    brelse(lbuf);
    80003e90:	854a                	mv	a0,s2
    80003e92:	fffff097          	auipc	ra,0xfffff
    80003e96:	084080e7          	jalr	132(ra) # 80002f16 <brelse>
    brelse(dbuf);
    80003e9a:	8526                	mv	a0,s1
    80003e9c:	fffff097          	auipc	ra,0xfffff
    80003ea0:	07a080e7          	jalr	122(ra) # 80002f16 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ea4:	2a05                	addiw	s4,s4,1
    80003ea6:	0a91                	addi	s5,s5,4
    80003ea8:	02c9a783          	lw	a5,44(s3)
    80003eac:	04fa5e63          	bge	s4,a5,80003f08 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003eb0:	0189a583          	lw	a1,24(s3)
    80003eb4:	014585bb          	addw	a1,a1,s4
    80003eb8:	2585                	addiw	a1,a1,1
    80003eba:	0289a503          	lw	a0,40(s3)
    80003ebe:	fffff097          	auipc	ra,0xfffff
    80003ec2:	f28080e7          	jalr	-216(ra) # 80002de6 <bread>
    80003ec6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ec8:	000aa583          	lw	a1,0(s5)
    80003ecc:	0289a503          	lw	a0,40(s3)
    80003ed0:	fffff097          	auipc	ra,0xfffff
    80003ed4:	f16080e7          	jalr	-234(ra) # 80002de6 <bread>
    80003ed8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003eda:	40000613          	li	a2,1024
    80003ede:	05890593          	addi	a1,s2,88
    80003ee2:	05850513          	addi	a0,a0,88
    80003ee6:	ffffd097          	auipc	ra,0xffffd
    80003eea:	e34080e7          	jalr	-460(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80003eee:	8526                	mv	a0,s1
    80003ef0:	fffff097          	auipc	ra,0xfffff
    80003ef4:	fe8080e7          	jalr	-24(ra) # 80002ed8 <bwrite>
    if(recovering == 0)
    80003ef8:	f80b1ce3          	bnez	s6,80003e90 <install_trans+0x36>
      bunpin(dbuf);
    80003efc:	8526                	mv	a0,s1
    80003efe:	fffff097          	auipc	ra,0xfffff
    80003f02:	0f2080e7          	jalr	242(ra) # 80002ff0 <bunpin>
    80003f06:	b769                	j	80003e90 <install_trans+0x36>
}
    80003f08:	70e2                	ld	ra,56(sp)
    80003f0a:	7442                	ld	s0,48(sp)
    80003f0c:	74a2                	ld	s1,40(sp)
    80003f0e:	7902                	ld	s2,32(sp)
    80003f10:	69e2                	ld	s3,24(sp)
    80003f12:	6a42                	ld	s4,16(sp)
    80003f14:	6aa2                	ld	s5,8(sp)
    80003f16:	6b02                	ld	s6,0(sp)
    80003f18:	6121                	addi	sp,sp,64
    80003f1a:	8082                	ret
    80003f1c:	8082                	ret

0000000080003f1e <initlog>:
{
    80003f1e:	7179                	addi	sp,sp,-48
    80003f20:	f406                	sd	ra,40(sp)
    80003f22:	f022                	sd	s0,32(sp)
    80003f24:	ec26                	sd	s1,24(sp)
    80003f26:	e84a                	sd	s2,16(sp)
    80003f28:	e44e                	sd	s3,8(sp)
    80003f2a:	1800                	addi	s0,sp,48
    80003f2c:	892a                	mv	s2,a0
    80003f2e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f30:	0001d497          	auipc	s1,0x1d
    80003f34:	34048493          	addi	s1,s1,832 # 80021270 <log>
    80003f38:	00004597          	auipc	a1,0x4
    80003f3c:	6d858593          	addi	a1,a1,1752 # 80008610 <syscalls+0x1e0>
    80003f40:	8526                	mv	a0,s1
    80003f42:	ffffd097          	auipc	ra,0xffffd
    80003f46:	bf0080e7          	jalr	-1040(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80003f4a:	0149a583          	lw	a1,20(s3)
    80003f4e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f50:	0109a783          	lw	a5,16(s3)
    80003f54:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f56:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f5a:	854a                	mv	a0,s2
    80003f5c:	fffff097          	auipc	ra,0xfffff
    80003f60:	e8a080e7          	jalr	-374(ra) # 80002de6 <bread>
  log.lh.n = lh->n;
    80003f64:	4d34                	lw	a3,88(a0)
    80003f66:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f68:	02d05663          	blez	a3,80003f94 <initlog+0x76>
    80003f6c:	05c50793          	addi	a5,a0,92
    80003f70:	0001d717          	auipc	a4,0x1d
    80003f74:	33070713          	addi	a4,a4,816 # 800212a0 <log+0x30>
    80003f78:	36fd                	addiw	a3,a3,-1
    80003f7a:	02069613          	slli	a2,a3,0x20
    80003f7e:	01e65693          	srli	a3,a2,0x1e
    80003f82:	06050613          	addi	a2,a0,96
    80003f86:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80003f88:	4390                	lw	a2,0(a5)
    80003f8a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f8c:	0791                	addi	a5,a5,4
    80003f8e:	0711                	addi	a4,a4,4
    80003f90:	fed79ce3          	bne	a5,a3,80003f88 <initlog+0x6a>
  brelse(buf);
    80003f94:	fffff097          	auipc	ra,0xfffff
    80003f98:	f82080e7          	jalr	-126(ra) # 80002f16 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003f9c:	4505                	li	a0,1
    80003f9e:	00000097          	auipc	ra,0x0
    80003fa2:	ebc080e7          	jalr	-324(ra) # 80003e5a <install_trans>
  log.lh.n = 0;
    80003fa6:	0001d797          	auipc	a5,0x1d
    80003faa:	2e07ab23          	sw	zero,758(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80003fae:	00000097          	auipc	ra,0x0
    80003fb2:	e30080e7          	jalr	-464(ra) # 80003dde <write_head>
}
    80003fb6:	70a2                	ld	ra,40(sp)
    80003fb8:	7402                	ld	s0,32(sp)
    80003fba:	64e2                	ld	s1,24(sp)
    80003fbc:	6942                	ld	s2,16(sp)
    80003fbe:	69a2                	ld	s3,8(sp)
    80003fc0:	6145                	addi	sp,sp,48
    80003fc2:	8082                	ret

0000000080003fc4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003fc4:	1101                	addi	sp,sp,-32
    80003fc6:	ec06                	sd	ra,24(sp)
    80003fc8:	e822                	sd	s0,16(sp)
    80003fca:	e426                	sd	s1,8(sp)
    80003fcc:	e04a                	sd	s2,0(sp)
    80003fce:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003fd0:	0001d517          	auipc	a0,0x1d
    80003fd4:	2a050513          	addi	a0,a0,672 # 80021270 <log>
    80003fd8:	ffffd097          	auipc	ra,0xffffd
    80003fdc:	bea080e7          	jalr	-1046(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80003fe0:	0001d497          	auipc	s1,0x1d
    80003fe4:	29048493          	addi	s1,s1,656 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fe8:	4979                	li	s2,30
    80003fea:	a039                	j	80003ff8 <begin_op+0x34>
      sleep(&log, &log.lock);
    80003fec:	85a6                	mv	a1,s1
    80003fee:	8526                	mv	a0,s1
    80003ff0:	ffffe097          	auipc	ra,0xffffe
    80003ff4:	094080e7          	jalr	148(ra) # 80002084 <sleep>
    if(log.committing){
    80003ff8:	50dc                	lw	a5,36(s1)
    80003ffa:	fbed                	bnez	a5,80003fec <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003ffc:	5098                	lw	a4,32(s1)
    80003ffe:	2705                	addiw	a4,a4,1
    80004000:	0007069b          	sext.w	a3,a4
    80004004:	0027179b          	slliw	a5,a4,0x2
    80004008:	9fb9                	addw	a5,a5,a4
    8000400a:	0017979b          	slliw	a5,a5,0x1
    8000400e:	54d8                	lw	a4,44(s1)
    80004010:	9fb9                	addw	a5,a5,a4
    80004012:	00f95963          	bge	s2,a5,80004024 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004016:	85a6                	mv	a1,s1
    80004018:	8526                	mv	a0,s1
    8000401a:	ffffe097          	auipc	ra,0xffffe
    8000401e:	06a080e7          	jalr	106(ra) # 80002084 <sleep>
    80004022:	bfd9                	j	80003ff8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004024:	0001d517          	auipc	a0,0x1d
    80004028:	24c50513          	addi	a0,a0,588 # 80021270 <log>
    8000402c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000402e:	ffffd097          	auipc	ra,0xffffd
    80004032:	c48080e7          	jalr	-952(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004036:	60e2                	ld	ra,24(sp)
    80004038:	6442                	ld	s0,16(sp)
    8000403a:	64a2                	ld	s1,8(sp)
    8000403c:	6902                	ld	s2,0(sp)
    8000403e:	6105                	addi	sp,sp,32
    80004040:	8082                	ret

0000000080004042 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004042:	7139                	addi	sp,sp,-64
    80004044:	fc06                	sd	ra,56(sp)
    80004046:	f822                	sd	s0,48(sp)
    80004048:	f426                	sd	s1,40(sp)
    8000404a:	f04a                	sd	s2,32(sp)
    8000404c:	ec4e                	sd	s3,24(sp)
    8000404e:	e852                	sd	s4,16(sp)
    80004050:	e456                	sd	s5,8(sp)
    80004052:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004054:	0001d497          	auipc	s1,0x1d
    80004058:	21c48493          	addi	s1,s1,540 # 80021270 <log>
    8000405c:	8526                	mv	a0,s1
    8000405e:	ffffd097          	auipc	ra,0xffffd
    80004062:	b64080e7          	jalr	-1180(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004066:	509c                	lw	a5,32(s1)
    80004068:	37fd                	addiw	a5,a5,-1
    8000406a:	0007891b          	sext.w	s2,a5
    8000406e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004070:	50dc                	lw	a5,36(s1)
    80004072:	e7b9                	bnez	a5,800040c0 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004074:	04091e63          	bnez	s2,800040d0 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004078:	0001d497          	auipc	s1,0x1d
    8000407c:	1f848493          	addi	s1,s1,504 # 80021270 <log>
    80004080:	4785                	li	a5,1
    80004082:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004084:	8526                	mv	a0,s1
    80004086:	ffffd097          	auipc	ra,0xffffd
    8000408a:	bf0080e7          	jalr	-1040(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000408e:	54dc                	lw	a5,44(s1)
    80004090:	06f04763          	bgtz	a5,800040fe <end_op+0xbc>
    acquire(&log.lock);
    80004094:	0001d497          	auipc	s1,0x1d
    80004098:	1dc48493          	addi	s1,s1,476 # 80021270 <log>
    8000409c:	8526                	mv	a0,s1
    8000409e:	ffffd097          	auipc	ra,0xffffd
    800040a2:	b24080e7          	jalr	-1244(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800040a6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800040aa:	8526                	mv	a0,s1
    800040ac:	ffffe097          	auipc	ra,0xffffe
    800040b0:	164080e7          	jalr	356(ra) # 80002210 <wakeup>
    release(&log.lock);
    800040b4:	8526                	mv	a0,s1
    800040b6:	ffffd097          	auipc	ra,0xffffd
    800040ba:	bc0080e7          	jalr	-1088(ra) # 80000c76 <release>
}
    800040be:	a03d                	j	800040ec <end_op+0xaa>
    panic("log.committing");
    800040c0:	00004517          	auipc	a0,0x4
    800040c4:	55850513          	addi	a0,a0,1368 # 80008618 <syscalls+0x1e8>
    800040c8:	ffffc097          	auipc	ra,0xffffc
    800040cc:	464080e7          	jalr	1124(ra) # 8000052c <panic>
    wakeup(&log);
    800040d0:	0001d497          	auipc	s1,0x1d
    800040d4:	1a048493          	addi	s1,s1,416 # 80021270 <log>
    800040d8:	8526                	mv	a0,s1
    800040da:	ffffe097          	auipc	ra,0xffffe
    800040de:	136080e7          	jalr	310(ra) # 80002210 <wakeup>
  release(&log.lock);
    800040e2:	8526                	mv	a0,s1
    800040e4:	ffffd097          	auipc	ra,0xffffd
    800040e8:	b92080e7          	jalr	-1134(ra) # 80000c76 <release>
}
    800040ec:	70e2                	ld	ra,56(sp)
    800040ee:	7442                	ld	s0,48(sp)
    800040f0:	74a2                	ld	s1,40(sp)
    800040f2:	7902                	ld	s2,32(sp)
    800040f4:	69e2                	ld	s3,24(sp)
    800040f6:	6a42                	ld	s4,16(sp)
    800040f8:	6aa2                	ld	s5,8(sp)
    800040fa:	6121                	addi	sp,sp,64
    800040fc:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800040fe:	0001da97          	auipc	s5,0x1d
    80004102:	1a2a8a93          	addi	s5,s5,418 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004106:	0001da17          	auipc	s4,0x1d
    8000410a:	16aa0a13          	addi	s4,s4,362 # 80021270 <log>
    8000410e:	018a2583          	lw	a1,24(s4)
    80004112:	012585bb          	addw	a1,a1,s2
    80004116:	2585                	addiw	a1,a1,1
    80004118:	028a2503          	lw	a0,40(s4)
    8000411c:	fffff097          	auipc	ra,0xfffff
    80004120:	cca080e7          	jalr	-822(ra) # 80002de6 <bread>
    80004124:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004126:	000aa583          	lw	a1,0(s5)
    8000412a:	028a2503          	lw	a0,40(s4)
    8000412e:	fffff097          	auipc	ra,0xfffff
    80004132:	cb8080e7          	jalr	-840(ra) # 80002de6 <bread>
    80004136:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004138:	40000613          	li	a2,1024
    8000413c:	05850593          	addi	a1,a0,88
    80004140:	05848513          	addi	a0,s1,88
    80004144:	ffffd097          	auipc	ra,0xffffd
    80004148:	bd6080e7          	jalr	-1066(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    8000414c:	8526                	mv	a0,s1
    8000414e:	fffff097          	auipc	ra,0xfffff
    80004152:	d8a080e7          	jalr	-630(ra) # 80002ed8 <bwrite>
    brelse(from);
    80004156:	854e                	mv	a0,s3
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	dbe080e7          	jalr	-578(ra) # 80002f16 <brelse>
    brelse(to);
    80004160:	8526                	mv	a0,s1
    80004162:	fffff097          	auipc	ra,0xfffff
    80004166:	db4080e7          	jalr	-588(ra) # 80002f16 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000416a:	2905                	addiw	s2,s2,1
    8000416c:	0a91                	addi	s5,s5,4
    8000416e:	02ca2783          	lw	a5,44(s4)
    80004172:	f8f94ee3          	blt	s2,a5,8000410e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004176:	00000097          	auipc	ra,0x0
    8000417a:	c68080e7          	jalr	-920(ra) # 80003dde <write_head>
    install_trans(0); // Now install writes to home locations
    8000417e:	4501                	li	a0,0
    80004180:	00000097          	auipc	ra,0x0
    80004184:	cda080e7          	jalr	-806(ra) # 80003e5a <install_trans>
    log.lh.n = 0;
    80004188:	0001d797          	auipc	a5,0x1d
    8000418c:	1007aa23          	sw	zero,276(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004190:	00000097          	auipc	ra,0x0
    80004194:	c4e080e7          	jalr	-946(ra) # 80003dde <write_head>
    80004198:	bdf5                	j	80004094 <end_op+0x52>

000000008000419a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000419a:	1101                	addi	sp,sp,-32
    8000419c:	ec06                	sd	ra,24(sp)
    8000419e:	e822                	sd	s0,16(sp)
    800041a0:	e426                	sd	s1,8(sp)
    800041a2:	e04a                	sd	s2,0(sp)
    800041a4:	1000                	addi	s0,sp,32
    800041a6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800041a8:	0001d917          	auipc	s2,0x1d
    800041ac:	0c890913          	addi	s2,s2,200 # 80021270 <log>
    800041b0:	854a                	mv	a0,s2
    800041b2:	ffffd097          	auipc	ra,0xffffd
    800041b6:	a10080e7          	jalr	-1520(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800041ba:	02c92603          	lw	a2,44(s2)
    800041be:	47f5                	li	a5,29
    800041c0:	06c7c563          	blt	a5,a2,8000422a <log_write+0x90>
    800041c4:	0001d797          	auipc	a5,0x1d
    800041c8:	0c87a783          	lw	a5,200(a5) # 8002128c <log+0x1c>
    800041cc:	37fd                	addiw	a5,a5,-1
    800041ce:	04f65e63          	bge	a2,a5,8000422a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800041d2:	0001d797          	auipc	a5,0x1d
    800041d6:	0be7a783          	lw	a5,190(a5) # 80021290 <log+0x20>
    800041da:	06f05063          	blez	a5,8000423a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800041de:	4781                	li	a5,0
    800041e0:	06c05563          	blez	a2,8000424a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800041e4:	44cc                	lw	a1,12(s1)
    800041e6:	0001d717          	auipc	a4,0x1d
    800041ea:	0ba70713          	addi	a4,a4,186 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800041ee:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800041f0:	4314                	lw	a3,0(a4)
    800041f2:	04b68c63          	beq	a3,a1,8000424a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800041f6:	2785                	addiw	a5,a5,1
    800041f8:	0711                	addi	a4,a4,4
    800041fa:	fef61be3          	bne	a2,a5,800041f0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800041fe:	0621                	addi	a2,a2,8
    80004200:	060a                	slli	a2,a2,0x2
    80004202:	0001d797          	auipc	a5,0x1d
    80004206:	06e78793          	addi	a5,a5,110 # 80021270 <log>
    8000420a:	97b2                	add	a5,a5,a2
    8000420c:	44d8                	lw	a4,12(s1)
    8000420e:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004210:	8526                	mv	a0,s1
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	da2080e7          	jalr	-606(ra) # 80002fb4 <bpin>
    log.lh.n++;
    8000421a:	0001d717          	auipc	a4,0x1d
    8000421e:	05670713          	addi	a4,a4,86 # 80021270 <log>
    80004222:	575c                	lw	a5,44(a4)
    80004224:	2785                	addiw	a5,a5,1
    80004226:	d75c                	sw	a5,44(a4)
    80004228:	a82d                	j	80004262 <log_write+0xc8>
    panic("too big a transaction");
    8000422a:	00004517          	auipc	a0,0x4
    8000422e:	3fe50513          	addi	a0,a0,1022 # 80008628 <syscalls+0x1f8>
    80004232:	ffffc097          	auipc	ra,0xffffc
    80004236:	2fa080e7          	jalr	762(ra) # 8000052c <panic>
    panic("log_write outside of trans");
    8000423a:	00004517          	auipc	a0,0x4
    8000423e:	40650513          	addi	a0,a0,1030 # 80008640 <syscalls+0x210>
    80004242:	ffffc097          	auipc	ra,0xffffc
    80004246:	2ea080e7          	jalr	746(ra) # 8000052c <panic>
  log.lh.block[i] = b->blockno;
    8000424a:	00878693          	addi	a3,a5,8
    8000424e:	068a                	slli	a3,a3,0x2
    80004250:	0001d717          	auipc	a4,0x1d
    80004254:	02070713          	addi	a4,a4,32 # 80021270 <log>
    80004258:	9736                	add	a4,a4,a3
    8000425a:	44d4                	lw	a3,12(s1)
    8000425c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000425e:	faf609e3          	beq	a2,a5,80004210 <log_write+0x76>
  }
  release(&log.lock);
    80004262:	0001d517          	auipc	a0,0x1d
    80004266:	00e50513          	addi	a0,a0,14 # 80021270 <log>
    8000426a:	ffffd097          	auipc	ra,0xffffd
    8000426e:	a0c080e7          	jalr	-1524(ra) # 80000c76 <release>
}
    80004272:	60e2                	ld	ra,24(sp)
    80004274:	6442                	ld	s0,16(sp)
    80004276:	64a2                	ld	s1,8(sp)
    80004278:	6902                	ld	s2,0(sp)
    8000427a:	6105                	addi	sp,sp,32
    8000427c:	8082                	ret

000000008000427e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000427e:	1101                	addi	sp,sp,-32
    80004280:	ec06                	sd	ra,24(sp)
    80004282:	e822                	sd	s0,16(sp)
    80004284:	e426                	sd	s1,8(sp)
    80004286:	e04a                	sd	s2,0(sp)
    80004288:	1000                	addi	s0,sp,32
    8000428a:	84aa                	mv	s1,a0
    8000428c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000428e:	00004597          	auipc	a1,0x4
    80004292:	3d258593          	addi	a1,a1,978 # 80008660 <syscalls+0x230>
    80004296:	0521                	addi	a0,a0,8
    80004298:	ffffd097          	auipc	ra,0xffffd
    8000429c:	89a080e7          	jalr	-1894(ra) # 80000b32 <initlock>
  lk->name = name;
    800042a0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800042a4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042a8:	0204a423          	sw	zero,40(s1)
}
    800042ac:	60e2                	ld	ra,24(sp)
    800042ae:	6442                	ld	s0,16(sp)
    800042b0:	64a2                	ld	s1,8(sp)
    800042b2:	6902                	ld	s2,0(sp)
    800042b4:	6105                	addi	sp,sp,32
    800042b6:	8082                	ret

00000000800042b8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800042b8:	1101                	addi	sp,sp,-32
    800042ba:	ec06                	sd	ra,24(sp)
    800042bc:	e822                	sd	s0,16(sp)
    800042be:	e426                	sd	s1,8(sp)
    800042c0:	e04a                	sd	s2,0(sp)
    800042c2:	1000                	addi	s0,sp,32
    800042c4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042c6:	00850913          	addi	s2,a0,8
    800042ca:	854a                	mv	a0,s2
    800042cc:	ffffd097          	auipc	ra,0xffffd
    800042d0:	8f6080e7          	jalr	-1802(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800042d4:	409c                	lw	a5,0(s1)
    800042d6:	cb89                	beqz	a5,800042e8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800042d8:	85ca                	mv	a1,s2
    800042da:	8526                	mv	a0,s1
    800042dc:	ffffe097          	auipc	ra,0xffffe
    800042e0:	da8080e7          	jalr	-600(ra) # 80002084 <sleep>
  while (lk->locked) {
    800042e4:	409c                	lw	a5,0(s1)
    800042e6:	fbed                	bnez	a5,800042d8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800042e8:	4785                	li	a5,1
    800042ea:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800042ec:	ffffd097          	auipc	ra,0xffffd
    800042f0:	6d4080e7          	jalr	1748(ra) # 800019c0 <myproc>
    800042f4:	591c                	lw	a5,48(a0)
    800042f6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800042f8:	854a                	mv	a0,s2
    800042fa:	ffffd097          	auipc	ra,0xffffd
    800042fe:	97c080e7          	jalr	-1668(ra) # 80000c76 <release>
}
    80004302:	60e2                	ld	ra,24(sp)
    80004304:	6442                	ld	s0,16(sp)
    80004306:	64a2                	ld	s1,8(sp)
    80004308:	6902                	ld	s2,0(sp)
    8000430a:	6105                	addi	sp,sp,32
    8000430c:	8082                	ret

000000008000430e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000430e:	1101                	addi	sp,sp,-32
    80004310:	ec06                	sd	ra,24(sp)
    80004312:	e822                	sd	s0,16(sp)
    80004314:	e426                	sd	s1,8(sp)
    80004316:	e04a                	sd	s2,0(sp)
    80004318:	1000                	addi	s0,sp,32
    8000431a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000431c:	00850913          	addi	s2,a0,8
    80004320:	854a                	mv	a0,s2
    80004322:	ffffd097          	auipc	ra,0xffffd
    80004326:	8a0080e7          	jalr	-1888(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    8000432a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000432e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004332:	8526                	mv	a0,s1
    80004334:	ffffe097          	auipc	ra,0xffffe
    80004338:	edc080e7          	jalr	-292(ra) # 80002210 <wakeup>
  release(&lk->lk);
    8000433c:	854a                	mv	a0,s2
    8000433e:	ffffd097          	auipc	ra,0xffffd
    80004342:	938080e7          	jalr	-1736(ra) # 80000c76 <release>
}
    80004346:	60e2                	ld	ra,24(sp)
    80004348:	6442                	ld	s0,16(sp)
    8000434a:	64a2                	ld	s1,8(sp)
    8000434c:	6902                	ld	s2,0(sp)
    8000434e:	6105                	addi	sp,sp,32
    80004350:	8082                	ret

0000000080004352 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004352:	7179                	addi	sp,sp,-48
    80004354:	f406                	sd	ra,40(sp)
    80004356:	f022                	sd	s0,32(sp)
    80004358:	ec26                	sd	s1,24(sp)
    8000435a:	e84a                	sd	s2,16(sp)
    8000435c:	e44e                	sd	s3,8(sp)
    8000435e:	1800                	addi	s0,sp,48
    80004360:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004362:	00850913          	addi	s2,a0,8
    80004366:	854a                	mv	a0,s2
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	85a080e7          	jalr	-1958(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004370:	409c                	lw	a5,0(s1)
    80004372:	ef99                	bnez	a5,80004390 <holdingsleep+0x3e>
    80004374:	4481                	li	s1,0
  release(&lk->lk);
    80004376:	854a                	mv	a0,s2
    80004378:	ffffd097          	auipc	ra,0xffffd
    8000437c:	8fe080e7          	jalr	-1794(ra) # 80000c76 <release>
  return r;
}
    80004380:	8526                	mv	a0,s1
    80004382:	70a2                	ld	ra,40(sp)
    80004384:	7402                	ld	s0,32(sp)
    80004386:	64e2                	ld	s1,24(sp)
    80004388:	6942                	ld	s2,16(sp)
    8000438a:	69a2                	ld	s3,8(sp)
    8000438c:	6145                	addi	sp,sp,48
    8000438e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004390:	0284a983          	lw	s3,40(s1)
    80004394:	ffffd097          	auipc	ra,0xffffd
    80004398:	62c080e7          	jalr	1580(ra) # 800019c0 <myproc>
    8000439c:	5904                	lw	s1,48(a0)
    8000439e:	413484b3          	sub	s1,s1,s3
    800043a2:	0014b493          	seqz	s1,s1
    800043a6:	bfc1                	j	80004376 <holdingsleep+0x24>

00000000800043a8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800043a8:	1141                	addi	sp,sp,-16
    800043aa:	e406                	sd	ra,8(sp)
    800043ac:	e022                	sd	s0,0(sp)
    800043ae:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800043b0:	00004597          	auipc	a1,0x4
    800043b4:	2c058593          	addi	a1,a1,704 # 80008670 <syscalls+0x240>
    800043b8:	0001d517          	auipc	a0,0x1d
    800043bc:	00050513          	mv	a0,a0
    800043c0:	ffffc097          	auipc	ra,0xffffc
    800043c4:	772080e7          	jalr	1906(ra) # 80000b32 <initlock>
}
    800043c8:	60a2                	ld	ra,8(sp)
    800043ca:	6402                	ld	s0,0(sp)
    800043cc:	0141                	addi	sp,sp,16
    800043ce:	8082                	ret

00000000800043d0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800043d0:	1101                	addi	sp,sp,-32
    800043d2:	ec06                	sd	ra,24(sp)
    800043d4:	e822                	sd	s0,16(sp)
    800043d6:	e426                	sd	s1,8(sp)
    800043d8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800043da:	0001d517          	auipc	a0,0x1d
    800043de:	fde50513          	addi	a0,a0,-34 # 800213b8 <ftable>
    800043e2:	ffffc097          	auipc	ra,0xffffc
    800043e6:	7e0080e7          	jalr	2016(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043ea:	0001d497          	auipc	s1,0x1d
    800043ee:	fe648493          	addi	s1,s1,-26 # 800213d0 <ftable+0x18>
    800043f2:	0001e717          	auipc	a4,0x1e
    800043f6:	f7e70713          	addi	a4,a4,-130 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    800043fa:	40dc                	lw	a5,4(s1)
    800043fc:	cf99                	beqz	a5,8000441a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043fe:	02848493          	addi	s1,s1,40
    80004402:	fee49ce3          	bne	s1,a4,800043fa <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004406:	0001d517          	auipc	a0,0x1d
    8000440a:	fb250513          	addi	a0,a0,-78 # 800213b8 <ftable>
    8000440e:	ffffd097          	auipc	ra,0xffffd
    80004412:	868080e7          	jalr	-1944(ra) # 80000c76 <release>
  return 0;
    80004416:	4481                	li	s1,0
    80004418:	a819                	j	8000442e <filealloc+0x5e>
      f->ref = 1;
    8000441a:	4785                	li	a5,1
    8000441c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000441e:	0001d517          	auipc	a0,0x1d
    80004422:	f9a50513          	addi	a0,a0,-102 # 800213b8 <ftable>
    80004426:	ffffd097          	auipc	ra,0xffffd
    8000442a:	850080e7          	jalr	-1968(ra) # 80000c76 <release>
}
    8000442e:	8526                	mv	a0,s1
    80004430:	60e2                	ld	ra,24(sp)
    80004432:	6442                	ld	s0,16(sp)
    80004434:	64a2                	ld	s1,8(sp)
    80004436:	6105                	addi	sp,sp,32
    80004438:	8082                	ret

000000008000443a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000443a:	1101                	addi	sp,sp,-32
    8000443c:	ec06                	sd	ra,24(sp)
    8000443e:	e822                	sd	s0,16(sp)
    80004440:	e426                	sd	s1,8(sp)
    80004442:	1000                	addi	s0,sp,32
    80004444:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004446:	0001d517          	auipc	a0,0x1d
    8000444a:	f7250513          	addi	a0,a0,-142 # 800213b8 <ftable>
    8000444e:	ffffc097          	auipc	ra,0xffffc
    80004452:	774080e7          	jalr	1908(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004456:	40dc                	lw	a5,4(s1)
    80004458:	02f05263          	blez	a5,8000447c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000445c:	2785                	addiw	a5,a5,1
    8000445e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004460:	0001d517          	auipc	a0,0x1d
    80004464:	f5850513          	addi	a0,a0,-168 # 800213b8 <ftable>
    80004468:	ffffd097          	auipc	ra,0xffffd
    8000446c:	80e080e7          	jalr	-2034(ra) # 80000c76 <release>
  return f;
}
    80004470:	8526                	mv	a0,s1
    80004472:	60e2                	ld	ra,24(sp)
    80004474:	6442                	ld	s0,16(sp)
    80004476:	64a2                	ld	s1,8(sp)
    80004478:	6105                	addi	sp,sp,32
    8000447a:	8082                	ret
    panic("filedup");
    8000447c:	00004517          	auipc	a0,0x4
    80004480:	1fc50513          	addi	a0,a0,508 # 80008678 <syscalls+0x248>
    80004484:	ffffc097          	auipc	ra,0xffffc
    80004488:	0a8080e7          	jalr	168(ra) # 8000052c <panic>

000000008000448c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000448c:	7139                	addi	sp,sp,-64
    8000448e:	fc06                	sd	ra,56(sp)
    80004490:	f822                	sd	s0,48(sp)
    80004492:	f426                	sd	s1,40(sp)
    80004494:	f04a                	sd	s2,32(sp)
    80004496:	ec4e                	sd	s3,24(sp)
    80004498:	e852                	sd	s4,16(sp)
    8000449a:	e456                	sd	s5,8(sp)
    8000449c:	0080                	addi	s0,sp,64
    8000449e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800044a0:	0001d517          	auipc	a0,0x1d
    800044a4:	f1850513          	addi	a0,a0,-232 # 800213b8 <ftable>
    800044a8:	ffffc097          	auipc	ra,0xffffc
    800044ac:	71a080e7          	jalr	1818(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800044b0:	40dc                	lw	a5,4(s1)
    800044b2:	06f05163          	blez	a5,80004514 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800044b6:	37fd                	addiw	a5,a5,-1
    800044b8:	0007871b          	sext.w	a4,a5
    800044bc:	c0dc                	sw	a5,4(s1)
    800044be:	06e04363          	bgtz	a4,80004524 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800044c2:	0004a903          	lw	s2,0(s1)
    800044c6:	0094ca83          	lbu	s5,9(s1)
    800044ca:	0104ba03          	ld	s4,16(s1)
    800044ce:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800044d2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800044d6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800044da:	0001d517          	auipc	a0,0x1d
    800044de:	ede50513          	addi	a0,a0,-290 # 800213b8 <ftable>
    800044e2:	ffffc097          	auipc	ra,0xffffc
    800044e6:	794080e7          	jalr	1940(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    800044ea:	4785                	li	a5,1
    800044ec:	04f90d63          	beq	s2,a5,80004546 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800044f0:	3979                	addiw	s2,s2,-2
    800044f2:	4785                	li	a5,1
    800044f4:	0527e063          	bltu	a5,s2,80004534 <fileclose+0xa8>
    begin_op();
    800044f8:	00000097          	auipc	ra,0x0
    800044fc:	acc080e7          	jalr	-1332(ra) # 80003fc4 <begin_op>
    iput(ff.ip);
    80004500:	854e                	mv	a0,s3
    80004502:	fffff097          	auipc	ra,0xfffff
    80004506:	2a0080e7          	jalr	672(ra) # 800037a2 <iput>
    end_op();
    8000450a:	00000097          	auipc	ra,0x0
    8000450e:	b38080e7          	jalr	-1224(ra) # 80004042 <end_op>
    80004512:	a00d                	j	80004534 <fileclose+0xa8>
    panic("fileclose");
    80004514:	00004517          	auipc	a0,0x4
    80004518:	16c50513          	addi	a0,a0,364 # 80008680 <syscalls+0x250>
    8000451c:	ffffc097          	auipc	ra,0xffffc
    80004520:	010080e7          	jalr	16(ra) # 8000052c <panic>
    release(&ftable.lock);
    80004524:	0001d517          	auipc	a0,0x1d
    80004528:	e9450513          	addi	a0,a0,-364 # 800213b8 <ftable>
    8000452c:	ffffc097          	auipc	ra,0xffffc
    80004530:	74a080e7          	jalr	1866(ra) # 80000c76 <release>
  }
}
    80004534:	70e2                	ld	ra,56(sp)
    80004536:	7442                	ld	s0,48(sp)
    80004538:	74a2                	ld	s1,40(sp)
    8000453a:	7902                	ld	s2,32(sp)
    8000453c:	69e2                	ld	s3,24(sp)
    8000453e:	6a42                	ld	s4,16(sp)
    80004540:	6aa2                	ld	s5,8(sp)
    80004542:	6121                	addi	sp,sp,64
    80004544:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004546:	85d6                	mv	a1,s5
    80004548:	8552                	mv	a0,s4
    8000454a:	00000097          	auipc	ra,0x0
    8000454e:	34c080e7          	jalr	844(ra) # 80004896 <pipeclose>
    80004552:	b7cd                	j	80004534 <fileclose+0xa8>

0000000080004554 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004554:	715d                	addi	sp,sp,-80
    80004556:	e486                	sd	ra,72(sp)
    80004558:	e0a2                	sd	s0,64(sp)
    8000455a:	fc26                	sd	s1,56(sp)
    8000455c:	f84a                	sd	s2,48(sp)
    8000455e:	f44e                	sd	s3,40(sp)
    80004560:	0880                	addi	s0,sp,80
    80004562:	84aa                	mv	s1,a0
    80004564:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004566:	ffffd097          	auipc	ra,0xffffd
    8000456a:	45a080e7          	jalr	1114(ra) # 800019c0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000456e:	409c                	lw	a5,0(s1)
    80004570:	37f9                	addiw	a5,a5,-2
    80004572:	4705                	li	a4,1
    80004574:	04f76763          	bltu	a4,a5,800045c2 <filestat+0x6e>
    80004578:	892a                	mv	s2,a0
    ilock(f->ip);
    8000457a:	6c88                	ld	a0,24(s1)
    8000457c:	fffff097          	auipc	ra,0xfffff
    80004580:	06c080e7          	jalr	108(ra) # 800035e8 <ilock>
    stati(f->ip, &st);
    80004584:	fb840593          	addi	a1,s0,-72
    80004588:	6c88                	ld	a0,24(s1)
    8000458a:	fffff097          	auipc	ra,0xfffff
    8000458e:	2e8080e7          	jalr	744(ra) # 80003872 <stati>
    iunlock(f->ip);
    80004592:	6c88                	ld	a0,24(s1)
    80004594:	fffff097          	auipc	ra,0xfffff
    80004598:	116080e7          	jalr	278(ra) # 800036aa <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000459c:	46e1                	li	a3,24
    8000459e:	fb840613          	addi	a2,s0,-72
    800045a2:	85ce                	mv	a1,s3
    800045a4:	05093503          	ld	a0,80(s2)
    800045a8:	ffffd097          	auipc	ra,0xffffd
    800045ac:	0dc080e7          	jalr	220(ra) # 80001684 <copyout>
    800045b0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800045b4:	60a6                	ld	ra,72(sp)
    800045b6:	6406                	ld	s0,64(sp)
    800045b8:	74e2                	ld	s1,56(sp)
    800045ba:	7942                	ld	s2,48(sp)
    800045bc:	79a2                	ld	s3,40(sp)
    800045be:	6161                	addi	sp,sp,80
    800045c0:	8082                	ret
  return -1;
    800045c2:	557d                	li	a0,-1
    800045c4:	bfc5                	j	800045b4 <filestat+0x60>

00000000800045c6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800045c6:	7179                	addi	sp,sp,-48
    800045c8:	f406                	sd	ra,40(sp)
    800045ca:	f022                	sd	s0,32(sp)
    800045cc:	ec26                	sd	s1,24(sp)
    800045ce:	e84a                	sd	s2,16(sp)
    800045d0:	e44e                	sd	s3,8(sp)
    800045d2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800045d4:	00854783          	lbu	a5,8(a0)
    800045d8:	c3d5                	beqz	a5,8000467c <fileread+0xb6>
    800045da:	84aa                	mv	s1,a0
    800045dc:	89ae                	mv	s3,a1
    800045de:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800045e0:	411c                	lw	a5,0(a0)
    800045e2:	4705                	li	a4,1
    800045e4:	04e78963          	beq	a5,a4,80004636 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800045e8:	470d                	li	a4,3
    800045ea:	04e78d63          	beq	a5,a4,80004644 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800045ee:	4709                	li	a4,2
    800045f0:	06e79e63          	bne	a5,a4,8000466c <fileread+0xa6>
    ilock(f->ip);
    800045f4:	6d08                	ld	a0,24(a0)
    800045f6:	fffff097          	auipc	ra,0xfffff
    800045fa:	ff2080e7          	jalr	-14(ra) # 800035e8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800045fe:	874a                	mv	a4,s2
    80004600:	5094                	lw	a3,32(s1)
    80004602:	864e                	mv	a2,s3
    80004604:	4585                	li	a1,1
    80004606:	6c88                	ld	a0,24(s1)
    80004608:	fffff097          	auipc	ra,0xfffff
    8000460c:	294080e7          	jalr	660(ra) # 8000389c <readi>
    80004610:	892a                	mv	s2,a0
    80004612:	00a05563          	blez	a0,8000461c <fileread+0x56>
      f->off += r;
    80004616:	509c                	lw	a5,32(s1)
    80004618:	9fa9                	addw	a5,a5,a0
    8000461a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000461c:	6c88                	ld	a0,24(s1)
    8000461e:	fffff097          	auipc	ra,0xfffff
    80004622:	08c080e7          	jalr	140(ra) # 800036aa <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004626:	854a                	mv	a0,s2
    80004628:	70a2                	ld	ra,40(sp)
    8000462a:	7402                	ld	s0,32(sp)
    8000462c:	64e2                	ld	s1,24(sp)
    8000462e:	6942                	ld	s2,16(sp)
    80004630:	69a2                	ld	s3,8(sp)
    80004632:	6145                	addi	sp,sp,48
    80004634:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004636:	6908                	ld	a0,16(a0)
    80004638:	00000097          	auipc	ra,0x0
    8000463c:	3c0080e7          	jalr	960(ra) # 800049f8 <piperead>
    80004640:	892a                	mv	s2,a0
    80004642:	b7d5                	j	80004626 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004644:	02451783          	lh	a5,36(a0)
    80004648:	03079693          	slli	a3,a5,0x30
    8000464c:	92c1                	srli	a3,a3,0x30
    8000464e:	4725                	li	a4,9
    80004650:	02d76863          	bltu	a4,a3,80004680 <fileread+0xba>
    80004654:	0792                	slli	a5,a5,0x4
    80004656:	0001d717          	auipc	a4,0x1d
    8000465a:	cc270713          	addi	a4,a4,-830 # 80021318 <devsw>
    8000465e:	97ba                	add	a5,a5,a4
    80004660:	639c                	ld	a5,0(a5)
    80004662:	c38d                	beqz	a5,80004684 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004664:	4505                	li	a0,1
    80004666:	9782                	jalr	a5
    80004668:	892a                	mv	s2,a0
    8000466a:	bf75                	j	80004626 <fileread+0x60>
    panic("fileread");
    8000466c:	00004517          	auipc	a0,0x4
    80004670:	02450513          	addi	a0,a0,36 # 80008690 <syscalls+0x260>
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	eb8080e7          	jalr	-328(ra) # 8000052c <panic>
    return -1;
    8000467c:	597d                	li	s2,-1
    8000467e:	b765                	j	80004626 <fileread+0x60>
      return -1;
    80004680:	597d                	li	s2,-1
    80004682:	b755                	j	80004626 <fileread+0x60>
    80004684:	597d                	li	s2,-1
    80004686:	b745                	j	80004626 <fileread+0x60>

0000000080004688 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004688:	715d                	addi	sp,sp,-80
    8000468a:	e486                	sd	ra,72(sp)
    8000468c:	e0a2                	sd	s0,64(sp)
    8000468e:	fc26                	sd	s1,56(sp)
    80004690:	f84a                	sd	s2,48(sp)
    80004692:	f44e                	sd	s3,40(sp)
    80004694:	f052                	sd	s4,32(sp)
    80004696:	ec56                	sd	s5,24(sp)
    80004698:	e85a                	sd	s6,16(sp)
    8000469a:	e45e                	sd	s7,8(sp)
    8000469c:	e062                	sd	s8,0(sp)
    8000469e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800046a0:	00954783          	lbu	a5,9(a0)
    800046a4:	10078663          	beqz	a5,800047b0 <filewrite+0x128>
    800046a8:	892a                	mv	s2,a0
    800046aa:	8b2e                	mv	s6,a1
    800046ac:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800046ae:	411c                	lw	a5,0(a0)
    800046b0:	4705                	li	a4,1
    800046b2:	02e78263          	beq	a5,a4,800046d6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046b6:	470d                	li	a4,3
    800046b8:	02e78663          	beq	a5,a4,800046e4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800046bc:	4709                	li	a4,2
    800046be:	0ee79163          	bne	a5,a4,800047a0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800046c2:	0ac05d63          	blez	a2,8000477c <filewrite+0xf4>
    int i = 0;
    800046c6:	4981                	li	s3,0
    800046c8:	6b85                	lui	s7,0x1
    800046ca:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800046ce:	6c05                	lui	s8,0x1
    800046d0:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800046d4:	a861                	j	8000476c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800046d6:	6908                	ld	a0,16(a0)
    800046d8:	00000097          	auipc	ra,0x0
    800046dc:	22e080e7          	jalr	558(ra) # 80004906 <pipewrite>
    800046e0:	8a2a                	mv	s4,a0
    800046e2:	a045                	j	80004782 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800046e4:	02451783          	lh	a5,36(a0)
    800046e8:	03079693          	slli	a3,a5,0x30
    800046ec:	92c1                	srli	a3,a3,0x30
    800046ee:	4725                	li	a4,9
    800046f0:	0cd76263          	bltu	a4,a3,800047b4 <filewrite+0x12c>
    800046f4:	0792                	slli	a5,a5,0x4
    800046f6:	0001d717          	auipc	a4,0x1d
    800046fa:	c2270713          	addi	a4,a4,-990 # 80021318 <devsw>
    800046fe:	97ba                	add	a5,a5,a4
    80004700:	679c                	ld	a5,8(a5)
    80004702:	cbdd                	beqz	a5,800047b8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004704:	4505                	li	a0,1
    80004706:	9782                	jalr	a5
    80004708:	8a2a                	mv	s4,a0
    8000470a:	a8a5                	j	80004782 <filewrite+0xfa>
    8000470c:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004710:	00000097          	auipc	ra,0x0
    80004714:	8b4080e7          	jalr	-1868(ra) # 80003fc4 <begin_op>
      ilock(f->ip);
    80004718:	01893503          	ld	a0,24(s2)
    8000471c:	fffff097          	auipc	ra,0xfffff
    80004720:	ecc080e7          	jalr	-308(ra) # 800035e8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004724:	8756                	mv	a4,s5
    80004726:	02092683          	lw	a3,32(s2)
    8000472a:	01698633          	add	a2,s3,s6
    8000472e:	4585                	li	a1,1
    80004730:	01893503          	ld	a0,24(s2)
    80004734:	fffff097          	auipc	ra,0xfffff
    80004738:	260080e7          	jalr	608(ra) # 80003994 <writei>
    8000473c:	84aa                	mv	s1,a0
    8000473e:	00a05763          	blez	a0,8000474c <filewrite+0xc4>
        f->off += r;
    80004742:	02092783          	lw	a5,32(s2)
    80004746:	9fa9                	addw	a5,a5,a0
    80004748:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000474c:	01893503          	ld	a0,24(s2)
    80004750:	fffff097          	auipc	ra,0xfffff
    80004754:	f5a080e7          	jalr	-166(ra) # 800036aa <iunlock>
      end_op();
    80004758:	00000097          	auipc	ra,0x0
    8000475c:	8ea080e7          	jalr	-1814(ra) # 80004042 <end_op>

      if(r != n1){
    80004760:	009a9f63          	bne	s5,s1,8000477e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004764:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004768:	0149db63          	bge	s3,s4,8000477e <filewrite+0xf6>
      int n1 = n - i;
    8000476c:	413a04bb          	subw	s1,s4,s3
    80004770:	0004879b          	sext.w	a5,s1
    80004774:	f8fbdce3          	bge	s7,a5,8000470c <filewrite+0x84>
    80004778:	84e2                	mv	s1,s8
    8000477a:	bf49                	j	8000470c <filewrite+0x84>
    int i = 0;
    8000477c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000477e:	013a1f63          	bne	s4,s3,8000479c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004782:	8552                	mv	a0,s4
    80004784:	60a6                	ld	ra,72(sp)
    80004786:	6406                	ld	s0,64(sp)
    80004788:	74e2                	ld	s1,56(sp)
    8000478a:	7942                	ld	s2,48(sp)
    8000478c:	79a2                	ld	s3,40(sp)
    8000478e:	7a02                	ld	s4,32(sp)
    80004790:	6ae2                	ld	s5,24(sp)
    80004792:	6b42                	ld	s6,16(sp)
    80004794:	6ba2                	ld	s7,8(sp)
    80004796:	6c02                	ld	s8,0(sp)
    80004798:	6161                	addi	sp,sp,80
    8000479a:	8082                	ret
    ret = (i == n ? n : -1);
    8000479c:	5a7d                	li	s4,-1
    8000479e:	b7d5                	j	80004782 <filewrite+0xfa>
    panic("filewrite");
    800047a0:	00004517          	auipc	a0,0x4
    800047a4:	f0050513          	addi	a0,a0,-256 # 800086a0 <syscalls+0x270>
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	d84080e7          	jalr	-636(ra) # 8000052c <panic>
    return -1;
    800047b0:	5a7d                	li	s4,-1
    800047b2:	bfc1                	j	80004782 <filewrite+0xfa>
      return -1;
    800047b4:	5a7d                	li	s4,-1
    800047b6:	b7f1                	j	80004782 <filewrite+0xfa>
    800047b8:	5a7d                	li	s4,-1
    800047ba:	b7e1                	j	80004782 <filewrite+0xfa>

00000000800047bc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800047bc:	7179                	addi	sp,sp,-48
    800047be:	f406                	sd	ra,40(sp)
    800047c0:	f022                	sd	s0,32(sp)
    800047c2:	ec26                	sd	s1,24(sp)
    800047c4:	e84a                	sd	s2,16(sp)
    800047c6:	e44e                	sd	s3,8(sp)
    800047c8:	e052                	sd	s4,0(sp)
    800047ca:	1800                	addi	s0,sp,48
    800047cc:	84aa                	mv	s1,a0
    800047ce:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800047d0:	0005b023          	sd	zero,0(a1)
    800047d4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800047d8:	00000097          	auipc	ra,0x0
    800047dc:	bf8080e7          	jalr	-1032(ra) # 800043d0 <filealloc>
    800047e0:	e088                	sd	a0,0(s1)
    800047e2:	c551                	beqz	a0,8000486e <pipealloc+0xb2>
    800047e4:	00000097          	auipc	ra,0x0
    800047e8:	bec080e7          	jalr	-1044(ra) # 800043d0 <filealloc>
    800047ec:	00aa3023          	sd	a0,0(s4)
    800047f0:	c92d                	beqz	a0,80004862 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	2e0080e7          	jalr	736(ra) # 80000ad2 <kalloc>
    800047fa:	892a                	mv	s2,a0
    800047fc:	c125                	beqz	a0,8000485c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800047fe:	4985                	li	s3,1
    80004800:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004804:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004808:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000480c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004810:	00004597          	auipc	a1,0x4
    80004814:	ea058593          	addi	a1,a1,-352 # 800086b0 <syscalls+0x280>
    80004818:	ffffc097          	auipc	ra,0xffffc
    8000481c:	31a080e7          	jalr	794(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004820:	609c                	ld	a5,0(s1)
    80004822:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004826:	609c                	ld	a5,0(s1)
    80004828:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000482c:	609c                	ld	a5,0(s1)
    8000482e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004832:	609c                	ld	a5,0(s1)
    80004834:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004838:	000a3783          	ld	a5,0(s4)
    8000483c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004840:	000a3783          	ld	a5,0(s4)
    80004844:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004848:	000a3783          	ld	a5,0(s4)
    8000484c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004850:	000a3783          	ld	a5,0(s4)
    80004854:	0127b823          	sd	s2,16(a5)
  return 0;
    80004858:	4501                	li	a0,0
    8000485a:	a025                	j	80004882 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000485c:	6088                	ld	a0,0(s1)
    8000485e:	e501                	bnez	a0,80004866 <pipealloc+0xaa>
    80004860:	a039                	j	8000486e <pipealloc+0xb2>
    80004862:	6088                	ld	a0,0(s1)
    80004864:	c51d                	beqz	a0,80004892 <pipealloc+0xd6>
    fileclose(*f0);
    80004866:	00000097          	auipc	ra,0x0
    8000486a:	c26080e7          	jalr	-986(ra) # 8000448c <fileclose>
  if(*f1)
    8000486e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004872:	557d                	li	a0,-1
  if(*f1)
    80004874:	c799                	beqz	a5,80004882 <pipealloc+0xc6>
    fileclose(*f1);
    80004876:	853e                	mv	a0,a5
    80004878:	00000097          	auipc	ra,0x0
    8000487c:	c14080e7          	jalr	-1004(ra) # 8000448c <fileclose>
  return -1;
    80004880:	557d                	li	a0,-1
}
    80004882:	70a2                	ld	ra,40(sp)
    80004884:	7402                	ld	s0,32(sp)
    80004886:	64e2                	ld	s1,24(sp)
    80004888:	6942                	ld	s2,16(sp)
    8000488a:	69a2                	ld	s3,8(sp)
    8000488c:	6a02                	ld	s4,0(sp)
    8000488e:	6145                	addi	sp,sp,48
    80004890:	8082                	ret
  return -1;
    80004892:	557d                	li	a0,-1
    80004894:	b7fd                	j	80004882 <pipealloc+0xc6>

0000000080004896 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004896:	1101                	addi	sp,sp,-32
    80004898:	ec06                	sd	ra,24(sp)
    8000489a:	e822                	sd	s0,16(sp)
    8000489c:	e426                	sd	s1,8(sp)
    8000489e:	e04a                	sd	s2,0(sp)
    800048a0:	1000                	addi	s0,sp,32
    800048a2:	84aa                	mv	s1,a0
    800048a4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	31c080e7          	jalr	796(ra) # 80000bc2 <acquire>
  if(writable){
    800048ae:	02090d63          	beqz	s2,800048e8 <pipeclose+0x52>
    pi->writeopen = 0;
    800048b2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800048b6:	21848513          	addi	a0,s1,536
    800048ba:	ffffe097          	auipc	ra,0xffffe
    800048be:	956080e7          	jalr	-1706(ra) # 80002210 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800048c2:	2204b783          	ld	a5,544(s1)
    800048c6:	eb95                	bnez	a5,800048fa <pipeclose+0x64>
    release(&pi->lock);
    800048c8:	8526                	mv	a0,s1
    800048ca:	ffffc097          	auipc	ra,0xffffc
    800048ce:	3ac080e7          	jalr	940(ra) # 80000c76 <release>
    kfree((char*)pi);
    800048d2:	8526                	mv	a0,s1
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	100080e7          	jalr	256(ra) # 800009d4 <kfree>
  } else
    release(&pi->lock);
}
    800048dc:	60e2                	ld	ra,24(sp)
    800048de:	6442                	ld	s0,16(sp)
    800048e0:	64a2                	ld	s1,8(sp)
    800048e2:	6902                	ld	s2,0(sp)
    800048e4:	6105                	addi	sp,sp,32
    800048e6:	8082                	ret
    pi->readopen = 0;
    800048e8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800048ec:	21c48513          	addi	a0,s1,540
    800048f0:	ffffe097          	auipc	ra,0xffffe
    800048f4:	920080e7          	jalr	-1760(ra) # 80002210 <wakeup>
    800048f8:	b7e9                	j	800048c2 <pipeclose+0x2c>
    release(&pi->lock);
    800048fa:	8526                	mv	a0,s1
    800048fc:	ffffc097          	auipc	ra,0xffffc
    80004900:	37a080e7          	jalr	890(ra) # 80000c76 <release>
}
    80004904:	bfe1                	j	800048dc <pipeclose+0x46>

0000000080004906 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004906:	711d                	addi	sp,sp,-96
    80004908:	ec86                	sd	ra,88(sp)
    8000490a:	e8a2                	sd	s0,80(sp)
    8000490c:	e4a6                	sd	s1,72(sp)
    8000490e:	e0ca                	sd	s2,64(sp)
    80004910:	fc4e                	sd	s3,56(sp)
    80004912:	f852                	sd	s4,48(sp)
    80004914:	f456                	sd	s5,40(sp)
    80004916:	f05a                	sd	s6,32(sp)
    80004918:	ec5e                	sd	s7,24(sp)
    8000491a:	e862                	sd	s8,16(sp)
    8000491c:	1080                	addi	s0,sp,96
    8000491e:	84aa                	mv	s1,a0
    80004920:	8aae                	mv	s5,a1
    80004922:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004924:	ffffd097          	auipc	ra,0xffffd
    80004928:	09c080e7          	jalr	156(ra) # 800019c0 <myproc>
    8000492c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000492e:	8526                	mv	a0,s1
    80004930:	ffffc097          	auipc	ra,0xffffc
    80004934:	292080e7          	jalr	658(ra) # 80000bc2 <acquire>
  while(i < n){
    80004938:	0b405363          	blez	s4,800049de <pipewrite+0xd8>
  int i = 0;
    8000493c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000493e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004940:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004944:	21c48b93          	addi	s7,s1,540
    80004948:	a089                	j	8000498a <pipewrite+0x84>
      release(&pi->lock);
    8000494a:	8526                	mv	a0,s1
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	32a080e7          	jalr	810(ra) # 80000c76 <release>
      return -1;
    80004954:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004956:	854a                	mv	a0,s2
    80004958:	60e6                	ld	ra,88(sp)
    8000495a:	6446                	ld	s0,80(sp)
    8000495c:	64a6                	ld	s1,72(sp)
    8000495e:	6906                	ld	s2,64(sp)
    80004960:	79e2                	ld	s3,56(sp)
    80004962:	7a42                	ld	s4,48(sp)
    80004964:	7aa2                	ld	s5,40(sp)
    80004966:	7b02                	ld	s6,32(sp)
    80004968:	6be2                	ld	s7,24(sp)
    8000496a:	6c42                	ld	s8,16(sp)
    8000496c:	6125                	addi	sp,sp,96
    8000496e:	8082                	ret
      wakeup(&pi->nread);
    80004970:	8562                	mv	a0,s8
    80004972:	ffffe097          	auipc	ra,0xffffe
    80004976:	89e080e7          	jalr	-1890(ra) # 80002210 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000497a:	85a6                	mv	a1,s1
    8000497c:	855e                	mv	a0,s7
    8000497e:	ffffd097          	auipc	ra,0xffffd
    80004982:	706080e7          	jalr	1798(ra) # 80002084 <sleep>
  while(i < n){
    80004986:	05495d63          	bge	s2,s4,800049e0 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    8000498a:	2204a783          	lw	a5,544(s1)
    8000498e:	dfd5                	beqz	a5,8000494a <pipewrite+0x44>
    80004990:	0289a783          	lw	a5,40(s3)
    80004994:	fbdd                	bnez	a5,8000494a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004996:	2184a783          	lw	a5,536(s1)
    8000499a:	21c4a703          	lw	a4,540(s1)
    8000499e:	2007879b          	addiw	a5,a5,512
    800049a2:	fcf707e3          	beq	a4,a5,80004970 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049a6:	4685                	li	a3,1
    800049a8:	01590633          	add	a2,s2,s5
    800049ac:	faf40593          	addi	a1,s0,-81
    800049b0:	0509b503          	ld	a0,80(s3)
    800049b4:	ffffd097          	auipc	ra,0xffffd
    800049b8:	d5c080e7          	jalr	-676(ra) # 80001710 <copyin>
    800049bc:	03650263          	beq	a0,s6,800049e0 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049c0:	21c4a783          	lw	a5,540(s1)
    800049c4:	0017871b          	addiw	a4,a5,1
    800049c8:	20e4ae23          	sw	a4,540(s1)
    800049cc:	1ff7f793          	andi	a5,a5,511
    800049d0:	97a6                	add	a5,a5,s1
    800049d2:	faf44703          	lbu	a4,-81(s0)
    800049d6:	00e78c23          	sb	a4,24(a5)
      i++;
    800049da:	2905                	addiw	s2,s2,1
    800049dc:	b76d                	j	80004986 <pipewrite+0x80>
  int i = 0;
    800049de:	4901                	li	s2,0
  wakeup(&pi->nread);
    800049e0:	21848513          	addi	a0,s1,536
    800049e4:	ffffe097          	auipc	ra,0xffffe
    800049e8:	82c080e7          	jalr	-2004(ra) # 80002210 <wakeup>
  release(&pi->lock);
    800049ec:	8526                	mv	a0,s1
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	288080e7          	jalr	648(ra) # 80000c76 <release>
  return i;
    800049f6:	b785                	j	80004956 <pipewrite+0x50>

00000000800049f8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800049f8:	715d                	addi	sp,sp,-80
    800049fa:	e486                	sd	ra,72(sp)
    800049fc:	e0a2                	sd	s0,64(sp)
    800049fe:	fc26                	sd	s1,56(sp)
    80004a00:	f84a                	sd	s2,48(sp)
    80004a02:	f44e                	sd	s3,40(sp)
    80004a04:	f052                	sd	s4,32(sp)
    80004a06:	ec56                	sd	s5,24(sp)
    80004a08:	e85a                	sd	s6,16(sp)
    80004a0a:	0880                	addi	s0,sp,80
    80004a0c:	84aa                	mv	s1,a0
    80004a0e:	892e                	mv	s2,a1
    80004a10:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a12:	ffffd097          	auipc	ra,0xffffd
    80004a16:	fae080e7          	jalr	-82(ra) # 800019c0 <myproc>
    80004a1a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a1c:	8526                	mv	a0,s1
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	1a4080e7          	jalr	420(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a26:	2184a703          	lw	a4,536(s1)
    80004a2a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a2e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a32:	02f71463          	bne	a4,a5,80004a5a <piperead+0x62>
    80004a36:	2244a783          	lw	a5,548(s1)
    80004a3a:	c385                	beqz	a5,80004a5a <piperead+0x62>
    if(pr->killed){
    80004a3c:	028a2783          	lw	a5,40(s4)
    80004a40:	ebc9                	bnez	a5,80004ad2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a42:	85a6                	mv	a1,s1
    80004a44:	854e                	mv	a0,s3
    80004a46:	ffffd097          	auipc	ra,0xffffd
    80004a4a:	63e080e7          	jalr	1598(ra) # 80002084 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a4e:	2184a703          	lw	a4,536(s1)
    80004a52:	21c4a783          	lw	a5,540(s1)
    80004a56:	fef700e3          	beq	a4,a5,80004a36 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a5a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a5c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a5e:	05505463          	blez	s5,80004aa6 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004a62:	2184a783          	lw	a5,536(s1)
    80004a66:	21c4a703          	lw	a4,540(s1)
    80004a6a:	02f70e63          	beq	a4,a5,80004aa6 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a6e:	0017871b          	addiw	a4,a5,1
    80004a72:	20e4ac23          	sw	a4,536(s1)
    80004a76:	1ff7f793          	andi	a5,a5,511
    80004a7a:	97a6                	add	a5,a5,s1
    80004a7c:	0187c783          	lbu	a5,24(a5)
    80004a80:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a84:	4685                	li	a3,1
    80004a86:	fbf40613          	addi	a2,s0,-65
    80004a8a:	85ca                	mv	a1,s2
    80004a8c:	050a3503          	ld	a0,80(s4)
    80004a90:	ffffd097          	auipc	ra,0xffffd
    80004a94:	bf4080e7          	jalr	-1036(ra) # 80001684 <copyout>
    80004a98:	01650763          	beq	a0,s6,80004aa6 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a9c:	2985                	addiw	s3,s3,1
    80004a9e:	0905                	addi	s2,s2,1
    80004aa0:	fd3a91e3          	bne	s5,s3,80004a62 <piperead+0x6a>
    80004aa4:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004aa6:	21c48513          	addi	a0,s1,540
    80004aaa:	ffffd097          	auipc	ra,0xffffd
    80004aae:	766080e7          	jalr	1894(ra) # 80002210 <wakeup>
  release(&pi->lock);
    80004ab2:	8526                	mv	a0,s1
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	1c2080e7          	jalr	450(ra) # 80000c76 <release>
  return i;
}
    80004abc:	854e                	mv	a0,s3
    80004abe:	60a6                	ld	ra,72(sp)
    80004ac0:	6406                	ld	s0,64(sp)
    80004ac2:	74e2                	ld	s1,56(sp)
    80004ac4:	7942                	ld	s2,48(sp)
    80004ac6:	79a2                	ld	s3,40(sp)
    80004ac8:	7a02                	ld	s4,32(sp)
    80004aca:	6ae2                	ld	s5,24(sp)
    80004acc:	6b42                	ld	s6,16(sp)
    80004ace:	6161                	addi	sp,sp,80
    80004ad0:	8082                	ret
      release(&pi->lock);
    80004ad2:	8526                	mv	a0,s1
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	1a2080e7          	jalr	418(ra) # 80000c76 <release>
      return -1;
    80004adc:	59fd                	li	s3,-1
    80004ade:	bff9                	j	80004abc <piperead+0xc4>

0000000080004ae0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ae0:	de010113          	addi	sp,sp,-544
    80004ae4:	20113c23          	sd	ra,536(sp)
    80004ae8:	20813823          	sd	s0,528(sp)
    80004aec:	20913423          	sd	s1,520(sp)
    80004af0:	21213023          	sd	s2,512(sp)
    80004af4:	ffce                	sd	s3,504(sp)
    80004af6:	fbd2                	sd	s4,496(sp)
    80004af8:	f7d6                	sd	s5,488(sp)
    80004afa:	f3da                	sd	s6,480(sp)
    80004afc:	efde                	sd	s7,472(sp)
    80004afe:	ebe2                	sd	s8,464(sp)
    80004b00:	e7e6                	sd	s9,456(sp)
    80004b02:	e3ea                	sd	s10,448(sp)
    80004b04:	ff6e                	sd	s11,440(sp)
    80004b06:	1400                	addi	s0,sp,544
    80004b08:	892a                	mv	s2,a0
    80004b0a:	dea43423          	sd	a0,-536(s0)
    80004b0e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b12:	ffffd097          	auipc	ra,0xffffd
    80004b16:	eae080e7          	jalr	-338(ra) # 800019c0 <myproc>
    80004b1a:	84aa                	mv	s1,a0

  begin_op();
    80004b1c:	fffff097          	auipc	ra,0xfffff
    80004b20:	4a8080e7          	jalr	1192(ra) # 80003fc4 <begin_op>

  if((ip = namei(path)) == 0){
    80004b24:	854a                	mv	a0,s2
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	27e080e7          	jalr	638(ra) # 80003da4 <namei>
    80004b2e:	c93d                	beqz	a0,80004ba4 <exec+0xc4>
    80004b30:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b32:	fffff097          	auipc	ra,0xfffff
    80004b36:	ab6080e7          	jalr	-1354(ra) # 800035e8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b3a:	04000713          	li	a4,64
    80004b3e:	4681                	li	a3,0
    80004b40:	e4840613          	addi	a2,s0,-440
    80004b44:	4581                	li	a1,0
    80004b46:	8556                	mv	a0,s5
    80004b48:	fffff097          	auipc	ra,0xfffff
    80004b4c:	d54080e7          	jalr	-684(ra) # 8000389c <readi>
    80004b50:	04000793          	li	a5,64
    80004b54:	00f51a63          	bne	a0,a5,80004b68 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004b58:	e4842703          	lw	a4,-440(s0)
    80004b5c:	464c47b7          	lui	a5,0x464c4
    80004b60:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b64:	04f70663          	beq	a4,a5,80004bb0 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b68:	8556                	mv	a0,s5
    80004b6a:	fffff097          	auipc	ra,0xfffff
    80004b6e:	ce0080e7          	jalr	-800(ra) # 8000384a <iunlockput>
    end_op();
    80004b72:	fffff097          	auipc	ra,0xfffff
    80004b76:	4d0080e7          	jalr	1232(ra) # 80004042 <end_op>
  }
  return -1;
    80004b7a:	557d                	li	a0,-1
}
    80004b7c:	21813083          	ld	ra,536(sp)
    80004b80:	21013403          	ld	s0,528(sp)
    80004b84:	20813483          	ld	s1,520(sp)
    80004b88:	20013903          	ld	s2,512(sp)
    80004b8c:	79fe                	ld	s3,504(sp)
    80004b8e:	7a5e                	ld	s4,496(sp)
    80004b90:	7abe                	ld	s5,488(sp)
    80004b92:	7b1e                	ld	s6,480(sp)
    80004b94:	6bfe                	ld	s7,472(sp)
    80004b96:	6c5e                	ld	s8,464(sp)
    80004b98:	6cbe                	ld	s9,456(sp)
    80004b9a:	6d1e                	ld	s10,448(sp)
    80004b9c:	7dfa                	ld	s11,440(sp)
    80004b9e:	22010113          	addi	sp,sp,544
    80004ba2:	8082                	ret
    end_op();
    80004ba4:	fffff097          	auipc	ra,0xfffff
    80004ba8:	49e080e7          	jalr	1182(ra) # 80004042 <end_op>
    return -1;
    80004bac:	557d                	li	a0,-1
    80004bae:	b7f9                	j	80004b7c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004bb0:	8526                	mv	a0,s1
    80004bb2:	ffffd097          	auipc	ra,0xffffd
    80004bb6:	ed2080e7          	jalr	-302(ra) # 80001a84 <proc_pagetable>
    80004bba:	8b2a                	mv	s6,a0
    80004bbc:	d555                	beqz	a0,80004b68 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bbe:	e6842783          	lw	a5,-408(s0)
    80004bc2:	e8045703          	lhu	a4,-384(s0)
    80004bc6:	c735                	beqz	a4,80004c32 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004bc8:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bca:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004bce:	6a05                	lui	s4,0x1
    80004bd0:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004bd4:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004bd8:	6d85                	lui	s11,0x1
    80004bda:	7d7d                	lui	s10,0xfffff
    80004bdc:	ac1d                	j	80004e12 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004bde:	00004517          	auipc	a0,0x4
    80004be2:	ada50513          	addi	a0,a0,-1318 # 800086b8 <syscalls+0x288>
    80004be6:	ffffc097          	auipc	ra,0xffffc
    80004bea:	946080e7          	jalr	-1722(ra) # 8000052c <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004bee:	874a                	mv	a4,s2
    80004bf0:	009c86bb          	addw	a3,s9,s1
    80004bf4:	4581                	li	a1,0
    80004bf6:	8556                	mv	a0,s5
    80004bf8:	fffff097          	auipc	ra,0xfffff
    80004bfc:	ca4080e7          	jalr	-860(ra) # 8000389c <readi>
    80004c00:	2501                	sext.w	a0,a0
    80004c02:	1aa91863          	bne	s2,a0,80004db2 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004c06:	009d84bb          	addw	s1,s11,s1
    80004c0a:	013d09bb          	addw	s3,s10,s3
    80004c0e:	1f74f263          	bgeu	s1,s7,80004df2 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004c12:	02049593          	slli	a1,s1,0x20
    80004c16:	9181                	srli	a1,a1,0x20
    80004c18:	95e2                	add	a1,a1,s8
    80004c1a:	855a                	mv	a0,s6
    80004c1c:	ffffc097          	auipc	ra,0xffffc
    80004c20:	472080e7          	jalr	1138(ra) # 8000108e <walkaddr>
    80004c24:	862a                	mv	a2,a0
    if(pa == 0)
    80004c26:	dd45                	beqz	a0,80004bde <exec+0xfe>
      n = PGSIZE;
    80004c28:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004c2a:	fd49f2e3          	bgeu	s3,s4,80004bee <exec+0x10e>
      n = sz - i;
    80004c2e:	894e                	mv	s2,s3
    80004c30:	bf7d                	j	80004bee <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004c32:	4481                	li	s1,0
  iunlockput(ip);
    80004c34:	8556                	mv	a0,s5
    80004c36:	fffff097          	auipc	ra,0xfffff
    80004c3a:	c14080e7          	jalr	-1004(ra) # 8000384a <iunlockput>
  end_op();
    80004c3e:	fffff097          	auipc	ra,0xfffff
    80004c42:	404080e7          	jalr	1028(ra) # 80004042 <end_op>
  p = myproc();
    80004c46:	ffffd097          	auipc	ra,0xffffd
    80004c4a:	d7a080e7          	jalr	-646(ra) # 800019c0 <myproc>
    80004c4e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004c50:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004c54:	6785                	lui	a5,0x1
    80004c56:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004c58:	97a6                	add	a5,a5,s1
    80004c5a:	777d                	lui	a4,0xfffff
    80004c5c:	8ff9                	and	a5,a5,a4
    80004c5e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c62:	6609                	lui	a2,0x2
    80004c64:	963e                	add	a2,a2,a5
    80004c66:	85be                	mv	a1,a5
    80004c68:	855a                	mv	a0,s6
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	7c6080e7          	jalr	1990(ra) # 80001430 <uvmalloc>
    80004c72:	8c2a                	mv	s8,a0
  ip = 0;
    80004c74:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c76:	12050e63          	beqz	a0,80004db2 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004c7a:	75f9                	lui	a1,0xffffe
    80004c7c:	95aa                	add	a1,a1,a0
    80004c7e:	855a                	mv	a0,s6
    80004c80:	ffffd097          	auipc	ra,0xffffd
    80004c84:	9d2080e7          	jalr	-1582(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004c88:	7afd                	lui	s5,0xfffff
    80004c8a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004c8c:	df043783          	ld	a5,-528(s0)
    80004c90:	6388                	ld	a0,0(a5)
    80004c92:	c925                	beqz	a0,80004d02 <exec+0x222>
    80004c94:	e8840993          	addi	s3,s0,-376
    80004c98:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004c9c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004c9e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	1a2080e7          	jalr	418(ra) # 80000e42 <strlen>
    80004ca8:	0015079b          	addiw	a5,a0,1
    80004cac:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004cb0:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004cb4:	13596363          	bltu	s2,s5,80004dda <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004cb8:	df043d83          	ld	s11,-528(s0)
    80004cbc:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004cc0:	8552                	mv	a0,s4
    80004cc2:	ffffc097          	auipc	ra,0xffffc
    80004cc6:	180080e7          	jalr	384(ra) # 80000e42 <strlen>
    80004cca:	0015069b          	addiw	a3,a0,1
    80004cce:	8652                	mv	a2,s4
    80004cd0:	85ca                	mv	a1,s2
    80004cd2:	855a                	mv	a0,s6
    80004cd4:	ffffd097          	auipc	ra,0xffffd
    80004cd8:	9b0080e7          	jalr	-1616(ra) # 80001684 <copyout>
    80004cdc:	10054363          	bltz	a0,80004de2 <exec+0x302>
    ustack[argc] = sp;
    80004ce0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ce4:	0485                	addi	s1,s1,1
    80004ce6:	008d8793          	addi	a5,s11,8
    80004cea:	def43823          	sd	a5,-528(s0)
    80004cee:	008db503          	ld	a0,8(s11)
    80004cf2:	c911                	beqz	a0,80004d06 <exec+0x226>
    if(argc >= MAXARG)
    80004cf4:	09a1                	addi	s3,s3,8
    80004cf6:	fb3c95e3          	bne	s9,s3,80004ca0 <exec+0x1c0>
  sz = sz1;
    80004cfa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004cfe:	4a81                	li	s5,0
    80004d00:	a84d                	j	80004db2 <exec+0x2d2>
  sp = sz;
    80004d02:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d04:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d06:	00349793          	slli	a5,s1,0x3
    80004d0a:	f9078793          	addi	a5,a5,-112
    80004d0e:	97a2                	add	a5,a5,s0
    80004d10:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004d14:	00148693          	addi	a3,s1,1
    80004d18:	068e                	slli	a3,a3,0x3
    80004d1a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d1e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d22:	01597663          	bgeu	s2,s5,80004d2e <exec+0x24e>
  sz = sz1;
    80004d26:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d2a:	4a81                	li	s5,0
    80004d2c:	a059                	j	80004db2 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d2e:	e8840613          	addi	a2,s0,-376
    80004d32:	85ca                	mv	a1,s2
    80004d34:	855a                	mv	a0,s6
    80004d36:	ffffd097          	auipc	ra,0xffffd
    80004d3a:	94e080e7          	jalr	-1714(ra) # 80001684 <copyout>
    80004d3e:	0a054663          	bltz	a0,80004dea <exec+0x30a>
  p->trapframe->a1 = sp;
    80004d42:	058bb783          	ld	a5,88(s7)
    80004d46:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004d4a:	de843783          	ld	a5,-536(s0)
    80004d4e:	0007c703          	lbu	a4,0(a5)
    80004d52:	cf11                	beqz	a4,80004d6e <exec+0x28e>
    80004d54:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004d56:	02f00693          	li	a3,47
    80004d5a:	a039                	j	80004d68 <exec+0x288>
      last = s+1;
    80004d5c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004d60:	0785                	addi	a5,a5,1
    80004d62:	fff7c703          	lbu	a4,-1(a5)
    80004d66:	c701                	beqz	a4,80004d6e <exec+0x28e>
    if(*s == '/')
    80004d68:	fed71ce3          	bne	a4,a3,80004d60 <exec+0x280>
    80004d6c:	bfc5                	j	80004d5c <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004d6e:	4641                	li	a2,16
    80004d70:	de843583          	ld	a1,-536(s0)
    80004d74:	158b8513          	addi	a0,s7,344
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	098080e7          	jalr	152(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004d80:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004d84:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004d88:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004d8c:	058bb783          	ld	a5,88(s7)
    80004d90:	e6043703          	ld	a4,-416(s0)
    80004d94:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004d96:	058bb783          	ld	a5,88(s7)
    80004d9a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004d9e:	85ea                	mv	a1,s10
    80004da0:	ffffd097          	auipc	ra,0xffffd
    80004da4:	d80080e7          	jalr	-640(ra) # 80001b20 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004da8:	0004851b          	sext.w	a0,s1
    80004dac:	bbc1                	j	80004b7c <exec+0x9c>
    80004dae:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004db2:	df843583          	ld	a1,-520(s0)
    80004db6:	855a                	mv	a0,s6
    80004db8:	ffffd097          	auipc	ra,0xffffd
    80004dbc:	d68080e7          	jalr	-664(ra) # 80001b20 <proc_freepagetable>
  if(ip){
    80004dc0:	da0a94e3          	bnez	s5,80004b68 <exec+0x88>
  return -1;
    80004dc4:	557d                	li	a0,-1
    80004dc6:	bb5d                	j	80004b7c <exec+0x9c>
    80004dc8:	de943c23          	sd	s1,-520(s0)
    80004dcc:	b7dd                	j	80004db2 <exec+0x2d2>
    80004dce:	de943c23          	sd	s1,-520(s0)
    80004dd2:	b7c5                	j	80004db2 <exec+0x2d2>
    80004dd4:	de943c23          	sd	s1,-520(s0)
    80004dd8:	bfe9                	j	80004db2 <exec+0x2d2>
  sz = sz1;
    80004dda:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dde:	4a81                	li	s5,0
    80004de0:	bfc9                	j	80004db2 <exec+0x2d2>
  sz = sz1;
    80004de2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004de6:	4a81                	li	s5,0
    80004de8:	b7e9                	j	80004db2 <exec+0x2d2>
  sz = sz1;
    80004dea:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dee:	4a81                	li	s5,0
    80004df0:	b7c9                	j	80004db2 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004df2:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004df6:	e0843783          	ld	a5,-504(s0)
    80004dfa:	0017869b          	addiw	a3,a5,1
    80004dfe:	e0d43423          	sd	a3,-504(s0)
    80004e02:	e0043783          	ld	a5,-512(s0)
    80004e06:	0387879b          	addiw	a5,a5,56
    80004e0a:	e8045703          	lhu	a4,-384(s0)
    80004e0e:	e2e6d3e3          	bge	a3,a4,80004c34 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e12:	2781                	sext.w	a5,a5
    80004e14:	e0f43023          	sd	a5,-512(s0)
    80004e18:	03800713          	li	a4,56
    80004e1c:	86be                	mv	a3,a5
    80004e1e:	e1040613          	addi	a2,s0,-496
    80004e22:	4581                	li	a1,0
    80004e24:	8556                	mv	a0,s5
    80004e26:	fffff097          	auipc	ra,0xfffff
    80004e2a:	a76080e7          	jalr	-1418(ra) # 8000389c <readi>
    80004e2e:	03800793          	li	a5,56
    80004e32:	f6f51ee3          	bne	a0,a5,80004dae <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004e36:	e1042783          	lw	a5,-496(s0)
    80004e3a:	4705                	li	a4,1
    80004e3c:	fae79de3          	bne	a5,a4,80004df6 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004e40:	e3843603          	ld	a2,-456(s0)
    80004e44:	e3043783          	ld	a5,-464(s0)
    80004e48:	f8f660e3          	bltu	a2,a5,80004dc8 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e4c:	e2043783          	ld	a5,-480(s0)
    80004e50:	963e                	add	a2,a2,a5
    80004e52:	f6f66ee3          	bltu	a2,a5,80004dce <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e56:	85a6                	mv	a1,s1
    80004e58:	855a                	mv	a0,s6
    80004e5a:	ffffc097          	auipc	ra,0xffffc
    80004e5e:	5d6080e7          	jalr	1494(ra) # 80001430 <uvmalloc>
    80004e62:	dea43c23          	sd	a0,-520(s0)
    80004e66:	d53d                	beqz	a0,80004dd4 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004e68:	e2043c03          	ld	s8,-480(s0)
    80004e6c:	de043783          	ld	a5,-544(s0)
    80004e70:	00fc77b3          	and	a5,s8,a5
    80004e74:	ff9d                	bnez	a5,80004db2 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e76:	e1842c83          	lw	s9,-488(s0)
    80004e7a:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e7e:	f60b8ae3          	beqz	s7,80004df2 <exec+0x312>
    80004e82:	89de                	mv	s3,s7
    80004e84:	4481                	li	s1,0
    80004e86:	b371                	j	80004c12 <exec+0x132>

0000000080004e88 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004e88:	7179                	addi	sp,sp,-48
    80004e8a:	f406                	sd	ra,40(sp)
    80004e8c:	f022                	sd	s0,32(sp)
    80004e8e:	ec26                	sd	s1,24(sp)
    80004e90:	e84a                	sd	s2,16(sp)
    80004e92:	1800                	addi	s0,sp,48
    80004e94:	892e                	mv	s2,a1
    80004e96:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004e98:	fdc40593          	addi	a1,s0,-36
    80004e9c:	ffffe097          	auipc	ra,0xffffe
    80004ea0:	bda080e7          	jalr	-1062(ra) # 80002a76 <argint>
    80004ea4:	04054063          	bltz	a0,80004ee4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004ea8:	fdc42703          	lw	a4,-36(s0)
    80004eac:	47bd                	li	a5,15
    80004eae:	02e7ed63          	bltu	a5,a4,80004ee8 <argfd+0x60>
    80004eb2:	ffffd097          	auipc	ra,0xffffd
    80004eb6:	b0e080e7          	jalr	-1266(ra) # 800019c0 <myproc>
    80004eba:	fdc42703          	lw	a4,-36(s0)
    80004ebe:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80004ec2:	078e                	slli	a5,a5,0x3
    80004ec4:	953e                	add	a0,a0,a5
    80004ec6:	611c                	ld	a5,0(a0)
    80004ec8:	c395                	beqz	a5,80004eec <argfd+0x64>
    return -1;
  if(pfd)
    80004eca:	00090463          	beqz	s2,80004ed2 <argfd+0x4a>
    *pfd = fd;
    80004ece:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ed2:	4501                	li	a0,0
  if(pf)
    80004ed4:	c091                	beqz	s1,80004ed8 <argfd+0x50>
    *pf = f;
    80004ed6:	e09c                	sd	a5,0(s1)
}
    80004ed8:	70a2                	ld	ra,40(sp)
    80004eda:	7402                	ld	s0,32(sp)
    80004edc:	64e2                	ld	s1,24(sp)
    80004ede:	6942                	ld	s2,16(sp)
    80004ee0:	6145                	addi	sp,sp,48
    80004ee2:	8082                	ret
    return -1;
    80004ee4:	557d                	li	a0,-1
    80004ee6:	bfcd                	j	80004ed8 <argfd+0x50>
    return -1;
    80004ee8:	557d                	li	a0,-1
    80004eea:	b7fd                	j	80004ed8 <argfd+0x50>
    80004eec:	557d                	li	a0,-1
    80004eee:	b7ed                	j	80004ed8 <argfd+0x50>

0000000080004ef0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004ef0:	1101                	addi	sp,sp,-32
    80004ef2:	ec06                	sd	ra,24(sp)
    80004ef4:	e822                	sd	s0,16(sp)
    80004ef6:	e426                	sd	s1,8(sp)
    80004ef8:	1000                	addi	s0,sp,32
    80004efa:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004efc:	ffffd097          	auipc	ra,0xffffd
    80004f00:	ac4080e7          	jalr	-1340(ra) # 800019c0 <myproc>
    80004f04:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f06:	0d050793          	addi	a5,a0,208
    80004f0a:	4501                	li	a0,0
    80004f0c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f0e:	6398                	ld	a4,0(a5)
    80004f10:	cb19                	beqz	a4,80004f26 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f12:	2505                	addiw	a0,a0,1
    80004f14:	07a1                	addi	a5,a5,8
    80004f16:	fed51ce3          	bne	a0,a3,80004f0e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f1a:	557d                	li	a0,-1
}
    80004f1c:	60e2                	ld	ra,24(sp)
    80004f1e:	6442                	ld	s0,16(sp)
    80004f20:	64a2                	ld	s1,8(sp)
    80004f22:	6105                	addi	sp,sp,32
    80004f24:	8082                	ret
      p->ofile[fd] = f;
    80004f26:	01a50793          	addi	a5,a0,26
    80004f2a:	078e                	slli	a5,a5,0x3
    80004f2c:	963e                	add	a2,a2,a5
    80004f2e:	e204                	sd	s1,0(a2)
      return fd;
    80004f30:	b7f5                	j	80004f1c <fdalloc+0x2c>

0000000080004f32 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f32:	715d                	addi	sp,sp,-80
    80004f34:	e486                	sd	ra,72(sp)
    80004f36:	e0a2                	sd	s0,64(sp)
    80004f38:	fc26                	sd	s1,56(sp)
    80004f3a:	f84a                	sd	s2,48(sp)
    80004f3c:	f44e                	sd	s3,40(sp)
    80004f3e:	f052                	sd	s4,32(sp)
    80004f40:	ec56                	sd	s5,24(sp)
    80004f42:	0880                	addi	s0,sp,80
    80004f44:	89ae                	mv	s3,a1
    80004f46:	8ab2                	mv	s5,a2
    80004f48:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f4a:	fb040593          	addi	a1,s0,-80
    80004f4e:	fffff097          	auipc	ra,0xfffff
    80004f52:	e74080e7          	jalr	-396(ra) # 80003dc2 <nameiparent>
    80004f56:	892a                	mv	s2,a0
    80004f58:	12050e63          	beqz	a0,80005094 <create+0x162>
    return 0;

  ilock(dp);
    80004f5c:	ffffe097          	auipc	ra,0xffffe
    80004f60:	68c080e7          	jalr	1676(ra) # 800035e8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f64:	4601                	li	a2,0
    80004f66:	fb040593          	addi	a1,s0,-80
    80004f6a:	854a                	mv	a0,s2
    80004f6c:	fffff097          	auipc	ra,0xfffff
    80004f70:	b60080e7          	jalr	-1184(ra) # 80003acc <dirlookup>
    80004f74:	84aa                	mv	s1,a0
    80004f76:	c921                	beqz	a0,80004fc6 <create+0x94>
    iunlockput(dp);
    80004f78:	854a                	mv	a0,s2
    80004f7a:	fffff097          	auipc	ra,0xfffff
    80004f7e:	8d0080e7          	jalr	-1840(ra) # 8000384a <iunlockput>
    ilock(ip);
    80004f82:	8526                	mv	a0,s1
    80004f84:	ffffe097          	auipc	ra,0xffffe
    80004f88:	664080e7          	jalr	1636(ra) # 800035e8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004f8c:	2981                	sext.w	s3,s3
    80004f8e:	4789                	li	a5,2
    80004f90:	02f99463          	bne	s3,a5,80004fb8 <create+0x86>
    80004f94:	0444d783          	lhu	a5,68(s1)
    80004f98:	37f9                	addiw	a5,a5,-2
    80004f9a:	17c2                	slli	a5,a5,0x30
    80004f9c:	93c1                	srli	a5,a5,0x30
    80004f9e:	4705                	li	a4,1
    80004fa0:	00f76c63          	bltu	a4,a5,80004fb8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004fa4:	8526                	mv	a0,s1
    80004fa6:	60a6                	ld	ra,72(sp)
    80004fa8:	6406                	ld	s0,64(sp)
    80004faa:	74e2                	ld	s1,56(sp)
    80004fac:	7942                	ld	s2,48(sp)
    80004fae:	79a2                	ld	s3,40(sp)
    80004fb0:	7a02                	ld	s4,32(sp)
    80004fb2:	6ae2                	ld	s5,24(sp)
    80004fb4:	6161                	addi	sp,sp,80
    80004fb6:	8082                	ret
    iunlockput(ip);
    80004fb8:	8526                	mv	a0,s1
    80004fba:	fffff097          	auipc	ra,0xfffff
    80004fbe:	890080e7          	jalr	-1904(ra) # 8000384a <iunlockput>
    return 0;
    80004fc2:	4481                	li	s1,0
    80004fc4:	b7c5                	j	80004fa4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80004fc6:	85ce                	mv	a1,s3
    80004fc8:	00092503          	lw	a0,0(s2)
    80004fcc:	ffffe097          	auipc	ra,0xffffe
    80004fd0:	482080e7          	jalr	1154(ra) # 8000344e <ialloc>
    80004fd4:	84aa                	mv	s1,a0
    80004fd6:	c521                	beqz	a0,8000501e <create+0xec>
  ilock(ip);
    80004fd8:	ffffe097          	auipc	ra,0xffffe
    80004fdc:	610080e7          	jalr	1552(ra) # 800035e8 <ilock>
  ip->major = major;
    80004fe0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80004fe4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80004fe8:	4a05                	li	s4,1
    80004fea:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80004fee:	8526                	mv	a0,s1
    80004ff0:	ffffe097          	auipc	ra,0xffffe
    80004ff4:	52c080e7          	jalr	1324(ra) # 8000351c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004ff8:	2981                	sext.w	s3,s3
    80004ffa:	03498a63          	beq	s3,s4,8000502e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80004ffe:	40d0                	lw	a2,4(s1)
    80005000:	fb040593          	addi	a1,s0,-80
    80005004:	854a                	mv	a0,s2
    80005006:	fffff097          	auipc	ra,0xfffff
    8000500a:	cdc080e7          	jalr	-804(ra) # 80003ce2 <dirlink>
    8000500e:	06054b63          	bltz	a0,80005084 <create+0x152>
  iunlockput(dp);
    80005012:	854a                	mv	a0,s2
    80005014:	fffff097          	auipc	ra,0xfffff
    80005018:	836080e7          	jalr	-1994(ra) # 8000384a <iunlockput>
  return ip;
    8000501c:	b761                	j	80004fa4 <create+0x72>
    panic("create: ialloc");
    8000501e:	00003517          	auipc	a0,0x3
    80005022:	6ba50513          	addi	a0,a0,1722 # 800086d8 <syscalls+0x2a8>
    80005026:	ffffb097          	auipc	ra,0xffffb
    8000502a:	506080e7          	jalr	1286(ra) # 8000052c <panic>
    dp->nlink++;  // for ".."
    8000502e:	04a95783          	lhu	a5,74(s2)
    80005032:	2785                	addiw	a5,a5,1
    80005034:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005038:	854a                	mv	a0,s2
    8000503a:	ffffe097          	auipc	ra,0xffffe
    8000503e:	4e2080e7          	jalr	1250(ra) # 8000351c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005042:	40d0                	lw	a2,4(s1)
    80005044:	00003597          	auipc	a1,0x3
    80005048:	73458593          	addi	a1,a1,1844 # 80008778 <syscalls+0x348>
    8000504c:	8526                	mv	a0,s1
    8000504e:	fffff097          	auipc	ra,0xfffff
    80005052:	c94080e7          	jalr	-876(ra) # 80003ce2 <dirlink>
    80005056:	00054f63          	bltz	a0,80005074 <create+0x142>
    8000505a:	00492603          	lw	a2,4(s2)
    8000505e:	00003597          	auipc	a1,0x3
    80005062:	68a58593          	addi	a1,a1,1674 # 800086e8 <syscalls+0x2b8>
    80005066:	8526                	mv	a0,s1
    80005068:	fffff097          	auipc	ra,0xfffff
    8000506c:	c7a080e7          	jalr	-902(ra) # 80003ce2 <dirlink>
    80005070:	f80557e3          	bgez	a0,80004ffe <create+0xcc>
      panic("create dots");
    80005074:	00003517          	auipc	a0,0x3
    80005078:	67c50513          	addi	a0,a0,1660 # 800086f0 <syscalls+0x2c0>
    8000507c:	ffffb097          	auipc	ra,0xffffb
    80005080:	4b0080e7          	jalr	1200(ra) # 8000052c <panic>
    panic("create: dirlink");
    80005084:	00003517          	auipc	a0,0x3
    80005088:	67c50513          	addi	a0,a0,1660 # 80008700 <syscalls+0x2d0>
    8000508c:	ffffb097          	auipc	ra,0xffffb
    80005090:	4a0080e7          	jalr	1184(ra) # 8000052c <panic>
    return 0;
    80005094:	84aa                	mv	s1,a0
    80005096:	b739                	j	80004fa4 <create+0x72>

0000000080005098 <sys_dup>:
{
    80005098:	7179                	addi	sp,sp,-48
    8000509a:	f406                	sd	ra,40(sp)
    8000509c:	f022                	sd	s0,32(sp)
    8000509e:	ec26                	sd	s1,24(sp)
    800050a0:	e84a                	sd	s2,16(sp)
    800050a2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800050a4:	fd840613          	addi	a2,s0,-40
    800050a8:	4581                	li	a1,0
    800050aa:	4501                	li	a0,0
    800050ac:	00000097          	auipc	ra,0x0
    800050b0:	ddc080e7          	jalr	-548(ra) # 80004e88 <argfd>
    return -1;
    800050b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800050b6:	02054363          	bltz	a0,800050dc <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800050ba:	fd843903          	ld	s2,-40(s0)
    800050be:	854a                	mv	a0,s2
    800050c0:	00000097          	auipc	ra,0x0
    800050c4:	e30080e7          	jalr	-464(ra) # 80004ef0 <fdalloc>
    800050c8:	84aa                	mv	s1,a0
    return -1;
    800050ca:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800050cc:	00054863          	bltz	a0,800050dc <sys_dup+0x44>
  filedup(f);
    800050d0:	854a                	mv	a0,s2
    800050d2:	fffff097          	auipc	ra,0xfffff
    800050d6:	368080e7          	jalr	872(ra) # 8000443a <filedup>
  return fd;
    800050da:	87a6                	mv	a5,s1
}
    800050dc:	853e                	mv	a0,a5
    800050de:	70a2                	ld	ra,40(sp)
    800050e0:	7402                	ld	s0,32(sp)
    800050e2:	64e2                	ld	s1,24(sp)
    800050e4:	6942                	ld	s2,16(sp)
    800050e6:	6145                	addi	sp,sp,48
    800050e8:	8082                	ret

00000000800050ea <sys_read>:
{
    800050ea:	7179                	addi	sp,sp,-48
    800050ec:	f406                	sd	ra,40(sp)
    800050ee:	f022                	sd	s0,32(sp)
    800050f0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050f2:	fe840613          	addi	a2,s0,-24
    800050f6:	4581                	li	a1,0
    800050f8:	4501                	li	a0,0
    800050fa:	00000097          	auipc	ra,0x0
    800050fe:	d8e080e7          	jalr	-626(ra) # 80004e88 <argfd>
    return -1;
    80005102:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005104:	04054163          	bltz	a0,80005146 <sys_read+0x5c>
    80005108:	fe440593          	addi	a1,s0,-28
    8000510c:	4509                	li	a0,2
    8000510e:	ffffe097          	auipc	ra,0xffffe
    80005112:	968080e7          	jalr	-1688(ra) # 80002a76 <argint>
    return -1;
    80005116:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005118:	02054763          	bltz	a0,80005146 <sys_read+0x5c>
    8000511c:	fd840593          	addi	a1,s0,-40
    80005120:	4505                	li	a0,1
    80005122:	ffffe097          	auipc	ra,0xffffe
    80005126:	976080e7          	jalr	-1674(ra) # 80002a98 <argaddr>
    return -1;
    8000512a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000512c:	00054d63          	bltz	a0,80005146 <sys_read+0x5c>
  return fileread(f, p, n);
    80005130:	fe442603          	lw	a2,-28(s0)
    80005134:	fd843583          	ld	a1,-40(s0)
    80005138:	fe843503          	ld	a0,-24(s0)
    8000513c:	fffff097          	auipc	ra,0xfffff
    80005140:	48a080e7          	jalr	1162(ra) # 800045c6 <fileread>
    80005144:	87aa                	mv	a5,a0
}
    80005146:	853e                	mv	a0,a5
    80005148:	70a2                	ld	ra,40(sp)
    8000514a:	7402                	ld	s0,32(sp)
    8000514c:	6145                	addi	sp,sp,48
    8000514e:	8082                	ret

0000000080005150 <sys_write>:
{
    80005150:	7179                	addi	sp,sp,-48
    80005152:	f406                	sd	ra,40(sp)
    80005154:	f022                	sd	s0,32(sp)
    80005156:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005158:	fe840613          	addi	a2,s0,-24
    8000515c:	4581                	li	a1,0
    8000515e:	4501                	li	a0,0
    80005160:	00000097          	auipc	ra,0x0
    80005164:	d28080e7          	jalr	-728(ra) # 80004e88 <argfd>
    return -1;
    80005168:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000516a:	04054163          	bltz	a0,800051ac <sys_write+0x5c>
    8000516e:	fe440593          	addi	a1,s0,-28
    80005172:	4509                	li	a0,2
    80005174:	ffffe097          	auipc	ra,0xffffe
    80005178:	902080e7          	jalr	-1790(ra) # 80002a76 <argint>
    return -1;
    8000517c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000517e:	02054763          	bltz	a0,800051ac <sys_write+0x5c>
    80005182:	fd840593          	addi	a1,s0,-40
    80005186:	4505                	li	a0,1
    80005188:	ffffe097          	auipc	ra,0xffffe
    8000518c:	910080e7          	jalr	-1776(ra) # 80002a98 <argaddr>
    return -1;
    80005190:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005192:	00054d63          	bltz	a0,800051ac <sys_write+0x5c>
  return filewrite(f, p, n);
    80005196:	fe442603          	lw	a2,-28(s0)
    8000519a:	fd843583          	ld	a1,-40(s0)
    8000519e:	fe843503          	ld	a0,-24(s0)
    800051a2:	fffff097          	auipc	ra,0xfffff
    800051a6:	4e6080e7          	jalr	1254(ra) # 80004688 <filewrite>
    800051aa:	87aa                	mv	a5,a0
}
    800051ac:	853e                	mv	a0,a5
    800051ae:	70a2                	ld	ra,40(sp)
    800051b0:	7402                	ld	s0,32(sp)
    800051b2:	6145                	addi	sp,sp,48
    800051b4:	8082                	ret

00000000800051b6 <sys_close>:
{
    800051b6:	1101                	addi	sp,sp,-32
    800051b8:	ec06                	sd	ra,24(sp)
    800051ba:	e822                	sd	s0,16(sp)
    800051bc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800051be:	fe040613          	addi	a2,s0,-32
    800051c2:	fec40593          	addi	a1,s0,-20
    800051c6:	4501                	li	a0,0
    800051c8:	00000097          	auipc	ra,0x0
    800051cc:	cc0080e7          	jalr	-832(ra) # 80004e88 <argfd>
    return -1;
    800051d0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800051d2:	02054463          	bltz	a0,800051fa <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800051d6:	ffffc097          	auipc	ra,0xffffc
    800051da:	7ea080e7          	jalr	2026(ra) # 800019c0 <myproc>
    800051de:	fec42783          	lw	a5,-20(s0)
    800051e2:	07e9                	addi	a5,a5,26
    800051e4:	078e                	slli	a5,a5,0x3
    800051e6:	953e                	add	a0,a0,a5
    800051e8:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800051ec:	fe043503          	ld	a0,-32(s0)
    800051f0:	fffff097          	auipc	ra,0xfffff
    800051f4:	29c080e7          	jalr	668(ra) # 8000448c <fileclose>
  return 0;
    800051f8:	4781                	li	a5,0
}
    800051fa:	853e                	mv	a0,a5
    800051fc:	60e2                	ld	ra,24(sp)
    800051fe:	6442                	ld	s0,16(sp)
    80005200:	6105                	addi	sp,sp,32
    80005202:	8082                	ret

0000000080005204 <sys_fstat>:
{
    80005204:	1101                	addi	sp,sp,-32
    80005206:	ec06                	sd	ra,24(sp)
    80005208:	e822                	sd	s0,16(sp)
    8000520a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000520c:	fe840613          	addi	a2,s0,-24
    80005210:	4581                	li	a1,0
    80005212:	4501                	li	a0,0
    80005214:	00000097          	auipc	ra,0x0
    80005218:	c74080e7          	jalr	-908(ra) # 80004e88 <argfd>
    return -1;
    8000521c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000521e:	02054563          	bltz	a0,80005248 <sys_fstat+0x44>
    80005222:	fe040593          	addi	a1,s0,-32
    80005226:	4505                	li	a0,1
    80005228:	ffffe097          	auipc	ra,0xffffe
    8000522c:	870080e7          	jalr	-1936(ra) # 80002a98 <argaddr>
    return -1;
    80005230:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005232:	00054b63          	bltz	a0,80005248 <sys_fstat+0x44>
  return filestat(f, st);
    80005236:	fe043583          	ld	a1,-32(s0)
    8000523a:	fe843503          	ld	a0,-24(s0)
    8000523e:	fffff097          	auipc	ra,0xfffff
    80005242:	316080e7          	jalr	790(ra) # 80004554 <filestat>
    80005246:	87aa                	mv	a5,a0
}
    80005248:	853e                	mv	a0,a5
    8000524a:	60e2                	ld	ra,24(sp)
    8000524c:	6442                	ld	s0,16(sp)
    8000524e:	6105                	addi	sp,sp,32
    80005250:	8082                	ret

0000000080005252 <sys_link>:
{
    80005252:	7169                	addi	sp,sp,-304
    80005254:	f606                	sd	ra,296(sp)
    80005256:	f222                	sd	s0,288(sp)
    80005258:	ee26                	sd	s1,280(sp)
    8000525a:	ea4a                	sd	s2,272(sp)
    8000525c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000525e:	08000613          	li	a2,128
    80005262:	ed040593          	addi	a1,s0,-304
    80005266:	4501                	li	a0,0
    80005268:	ffffe097          	auipc	ra,0xffffe
    8000526c:	852080e7          	jalr	-1966(ra) # 80002aba <argstr>
    return -1;
    80005270:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005272:	10054e63          	bltz	a0,8000538e <sys_link+0x13c>
    80005276:	08000613          	li	a2,128
    8000527a:	f5040593          	addi	a1,s0,-176
    8000527e:	4505                	li	a0,1
    80005280:	ffffe097          	auipc	ra,0xffffe
    80005284:	83a080e7          	jalr	-1990(ra) # 80002aba <argstr>
    return -1;
    80005288:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000528a:	10054263          	bltz	a0,8000538e <sys_link+0x13c>
  begin_op();
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	d36080e7          	jalr	-714(ra) # 80003fc4 <begin_op>
  if((ip = namei(old)) == 0){
    80005296:	ed040513          	addi	a0,s0,-304
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	b0a080e7          	jalr	-1270(ra) # 80003da4 <namei>
    800052a2:	84aa                	mv	s1,a0
    800052a4:	c551                	beqz	a0,80005330 <sys_link+0xde>
  ilock(ip);
    800052a6:	ffffe097          	auipc	ra,0xffffe
    800052aa:	342080e7          	jalr	834(ra) # 800035e8 <ilock>
  if(ip->type == T_DIR){
    800052ae:	04449703          	lh	a4,68(s1)
    800052b2:	4785                	li	a5,1
    800052b4:	08f70463          	beq	a4,a5,8000533c <sys_link+0xea>
  ip->nlink++;
    800052b8:	04a4d783          	lhu	a5,74(s1)
    800052bc:	2785                	addiw	a5,a5,1
    800052be:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052c2:	8526                	mv	a0,s1
    800052c4:	ffffe097          	auipc	ra,0xffffe
    800052c8:	258080e7          	jalr	600(ra) # 8000351c <iupdate>
  iunlock(ip);
    800052cc:	8526                	mv	a0,s1
    800052ce:	ffffe097          	auipc	ra,0xffffe
    800052d2:	3dc080e7          	jalr	988(ra) # 800036aa <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800052d6:	fd040593          	addi	a1,s0,-48
    800052da:	f5040513          	addi	a0,s0,-176
    800052de:	fffff097          	auipc	ra,0xfffff
    800052e2:	ae4080e7          	jalr	-1308(ra) # 80003dc2 <nameiparent>
    800052e6:	892a                	mv	s2,a0
    800052e8:	c935                	beqz	a0,8000535c <sys_link+0x10a>
  ilock(dp);
    800052ea:	ffffe097          	auipc	ra,0xffffe
    800052ee:	2fe080e7          	jalr	766(ra) # 800035e8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800052f2:	00092703          	lw	a4,0(s2)
    800052f6:	409c                	lw	a5,0(s1)
    800052f8:	04f71d63          	bne	a4,a5,80005352 <sys_link+0x100>
    800052fc:	40d0                	lw	a2,4(s1)
    800052fe:	fd040593          	addi	a1,s0,-48
    80005302:	854a                	mv	a0,s2
    80005304:	fffff097          	auipc	ra,0xfffff
    80005308:	9de080e7          	jalr	-1570(ra) # 80003ce2 <dirlink>
    8000530c:	04054363          	bltz	a0,80005352 <sys_link+0x100>
  iunlockput(dp);
    80005310:	854a                	mv	a0,s2
    80005312:	ffffe097          	auipc	ra,0xffffe
    80005316:	538080e7          	jalr	1336(ra) # 8000384a <iunlockput>
  iput(ip);
    8000531a:	8526                	mv	a0,s1
    8000531c:	ffffe097          	auipc	ra,0xffffe
    80005320:	486080e7          	jalr	1158(ra) # 800037a2 <iput>
  end_op();
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	d1e080e7          	jalr	-738(ra) # 80004042 <end_op>
  return 0;
    8000532c:	4781                	li	a5,0
    8000532e:	a085                	j	8000538e <sys_link+0x13c>
    end_op();
    80005330:	fffff097          	auipc	ra,0xfffff
    80005334:	d12080e7          	jalr	-750(ra) # 80004042 <end_op>
    return -1;
    80005338:	57fd                	li	a5,-1
    8000533a:	a891                	j	8000538e <sys_link+0x13c>
    iunlockput(ip);
    8000533c:	8526                	mv	a0,s1
    8000533e:	ffffe097          	auipc	ra,0xffffe
    80005342:	50c080e7          	jalr	1292(ra) # 8000384a <iunlockput>
    end_op();
    80005346:	fffff097          	auipc	ra,0xfffff
    8000534a:	cfc080e7          	jalr	-772(ra) # 80004042 <end_op>
    return -1;
    8000534e:	57fd                	li	a5,-1
    80005350:	a83d                	j	8000538e <sys_link+0x13c>
    iunlockput(dp);
    80005352:	854a                	mv	a0,s2
    80005354:	ffffe097          	auipc	ra,0xffffe
    80005358:	4f6080e7          	jalr	1270(ra) # 8000384a <iunlockput>
  ilock(ip);
    8000535c:	8526                	mv	a0,s1
    8000535e:	ffffe097          	auipc	ra,0xffffe
    80005362:	28a080e7          	jalr	650(ra) # 800035e8 <ilock>
  ip->nlink--;
    80005366:	04a4d783          	lhu	a5,74(s1)
    8000536a:	37fd                	addiw	a5,a5,-1
    8000536c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005370:	8526                	mv	a0,s1
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	1aa080e7          	jalr	426(ra) # 8000351c <iupdate>
  iunlockput(ip);
    8000537a:	8526                	mv	a0,s1
    8000537c:	ffffe097          	auipc	ra,0xffffe
    80005380:	4ce080e7          	jalr	1230(ra) # 8000384a <iunlockput>
  end_op();
    80005384:	fffff097          	auipc	ra,0xfffff
    80005388:	cbe080e7          	jalr	-834(ra) # 80004042 <end_op>
  return -1;
    8000538c:	57fd                	li	a5,-1
}
    8000538e:	853e                	mv	a0,a5
    80005390:	70b2                	ld	ra,296(sp)
    80005392:	7412                	ld	s0,288(sp)
    80005394:	64f2                	ld	s1,280(sp)
    80005396:	6952                	ld	s2,272(sp)
    80005398:	6155                	addi	sp,sp,304
    8000539a:	8082                	ret

000000008000539c <sys_unlink>:
{
    8000539c:	7151                	addi	sp,sp,-240
    8000539e:	f586                	sd	ra,232(sp)
    800053a0:	f1a2                	sd	s0,224(sp)
    800053a2:	eda6                	sd	s1,216(sp)
    800053a4:	e9ca                	sd	s2,208(sp)
    800053a6:	e5ce                	sd	s3,200(sp)
    800053a8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800053aa:	08000613          	li	a2,128
    800053ae:	f3040593          	addi	a1,s0,-208
    800053b2:	4501                	li	a0,0
    800053b4:	ffffd097          	auipc	ra,0xffffd
    800053b8:	706080e7          	jalr	1798(ra) # 80002aba <argstr>
    800053bc:	18054163          	bltz	a0,8000553e <sys_unlink+0x1a2>
  begin_op();
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	c04080e7          	jalr	-1020(ra) # 80003fc4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800053c8:	fb040593          	addi	a1,s0,-80
    800053cc:	f3040513          	addi	a0,s0,-208
    800053d0:	fffff097          	auipc	ra,0xfffff
    800053d4:	9f2080e7          	jalr	-1550(ra) # 80003dc2 <nameiparent>
    800053d8:	84aa                	mv	s1,a0
    800053da:	c979                	beqz	a0,800054b0 <sys_unlink+0x114>
  ilock(dp);
    800053dc:	ffffe097          	auipc	ra,0xffffe
    800053e0:	20c080e7          	jalr	524(ra) # 800035e8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800053e4:	00003597          	auipc	a1,0x3
    800053e8:	39458593          	addi	a1,a1,916 # 80008778 <syscalls+0x348>
    800053ec:	fb040513          	addi	a0,s0,-80
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	6c2080e7          	jalr	1730(ra) # 80003ab2 <namecmp>
    800053f8:	14050a63          	beqz	a0,8000554c <sys_unlink+0x1b0>
    800053fc:	00003597          	auipc	a1,0x3
    80005400:	2ec58593          	addi	a1,a1,748 # 800086e8 <syscalls+0x2b8>
    80005404:	fb040513          	addi	a0,s0,-80
    80005408:	ffffe097          	auipc	ra,0xffffe
    8000540c:	6aa080e7          	jalr	1706(ra) # 80003ab2 <namecmp>
    80005410:	12050e63          	beqz	a0,8000554c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005414:	f2c40613          	addi	a2,s0,-212
    80005418:	fb040593          	addi	a1,s0,-80
    8000541c:	8526                	mv	a0,s1
    8000541e:	ffffe097          	auipc	ra,0xffffe
    80005422:	6ae080e7          	jalr	1710(ra) # 80003acc <dirlookup>
    80005426:	892a                	mv	s2,a0
    80005428:	12050263          	beqz	a0,8000554c <sys_unlink+0x1b0>
  ilock(ip);
    8000542c:	ffffe097          	auipc	ra,0xffffe
    80005430:	1bc080e7          	jalr	444(ra) # 800035e8 <ilock>
  if(ip->nlink < 1)
    80005434:	04a91783          	lh	a5,74(s2)
    80005438:	08f05263          	blez	a5,800054bc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000543c:	04491703          	lh	a4,68(s2)
    80005440:	4785                	li	a5,1
    80005442:	08f70563          	beq	a4,a5,800054cc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005446:	4641                	li	a2,16
    80005448:	4581                	li	a1,0
    8000544a:	fc040513          	addi	a0,s0,-64
    8000544e:	ffffc097          	auipc	ra,0xffffc
    80005452:	870080e7          	jalr	-1936(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005456:	4741                	li	a4,16
    80005458:	f2c42683          	lw	a3,-212(s0)
    8000545c:	fc040613          	addi	a2,s0,-64
    80005460:	4581                	li	a1,0
    80005462:	8526                	mv	a0,s1
    80005464:	ffffe097          	auipc	ra,0xffffe
    80005468:	530080e7          	jalr	1328(ra) # 80003994 <writei>
    8000546c:	47c1                	li	a5,16
    8000546e:	0af51563          	bne	a0,a5,80005518 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005472:	04491703          	lh	a4,68(s2)
    80005476:	4785                	li	a5,1
    80005478:	0af70863          	beq	a4,a5,80005528 <sys_unlink+0x18c>
  iunlockput(dp);
    8000547c:	8526                	mv	a0,s1
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	3cc080e7          	jalr	972(ra) # 8000384a <iunlockput>
  ip->nlink--;
    80005486:	04a95783          	lhu	a5,74(s2)
    8000548a:	37fd                	addiw	a5,a5,-1
    8000548c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005490:	854a                	mv	a0,s2
    80005492:	ffffe097          	auipc	ra,0xffffe
    80005496:	08a080e7          	jalr	138(ra) # 8000351c <iupdate>
  iunlockput(ip);
    8000549a:	854a                	mv	a0,s2
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	3ae080e7          	jalr	942(ra) # 8000384a <iunlockput>
  end_op();
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	b9e080e7          	jalr	-1122(ra) # 80004042 <end_op>
  return 0;
    800054ac:	4501                	li	a0,0
    800054ae:	a84d                	j	80005560 <sys_unlink+0x1c4>
    end_op();
    800054b0:	fffff097          	auipc	ra,0xfffff
    800054b4:	b92080e7          	jalr	-1134(ra) # 80004042 <end_op>
    return -1;
    800054b8:	557d                	li	a0,-1
    800054ba:	a05d                	j	80005560 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800054bc:	00003517          	auipc	a0,0x3
    800054c0:	25450513          	addi	a0,a0,596 # 80008710 <syscalls+0x2e0>
    800054c4:	ffffb097          	auipc	ra,0xffffb
    800054c8:	068080e7          	jalr	104(ra) # 8000052c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054cc:	04c92703          	lw	a4,76(s2)
    800054d0:	02000793          	li	a5,32
    800054d4:	f6e7f9e3          	bgeu	a5,a4,80005446 <sys_unlink+0xaa>
    800054d8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054dc:	4741                	li	a4,16
    800054de:	86ce                	mv	a3,s3
    800054e0:	f1840613          	addi	a2,s0,-232
    800054e4:	4581                	li	a1,0
    800054e6:	854a                	mv	a0,s2
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	3b4080e7          	jalr	948(ra) # 8000389c <readi>
    800054f0:	47c1                	li	a5,16
    800054f2:	00f51b63          	bne	a0,a5,80005508 <sys_unlink+0x16c>
    if(de.inum != 0)
    800054f6:	f1845783          	lhu	a5,-232(s0)
    800054fa:	e7a1                	bnez	a5,80005542 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054fc:	29c1                	addiw	s3,s3,16
    800054fe:	04c92783          	lw	a5,76(s2)
    80005502:	fcf9ede3          	bltu	s3,a5,800054dc <sys_unlink+0x140>
    80005506:	b781                	j	80005446 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005508:	00003517          	auipc	a0,0x3
    8000550c:	22050513          	addi	a0,a0,544 # 80008728 <syscalls+0x2f8>
    80005510:	ffffb097          	auipc	ra,0xffffb
    80005514:	01c080e7          	jalr	28(ra) # 8000052c <panic>
    panic("unlink: writei");
    80005518:	00003517          	auipc	a0,0x3
    8000551c:	22850513          	addi	a0,a0,552 # 80008740 <syscalls+0x310>
    80005520:	ffffb097          	auipc	ra,0xffffb
    80005524:	00c080e7          	jalr	12(ra) # 8000052c <panic>
    dp->nlink--;
    80005528:	04a4d783          	lhu	a5,74(s1)
    8000552c:	37fd                	addiw	a5,a5,-1
    8000552e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005532:	8526                	mv	a0,s1
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	fe8080e7          	jalr	-24(ra) # 8000351c <iupdate>
    8000553c:	b781                	j	8000547c <sys_unlink+0xe0>
    return -1;
    8000553e:	557d                	li	a0,-1
    80005540:	a005                	j	80005560 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005542:	854a                	mv	a0,s2
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	306080e7          	jalr	774(ra) # 8000384a <iunlockput>
  iunlockput(dp);
    8000554c:	8526                	mv	a0,s1
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	2fc080e7          	jalr	764(ra) # 8000384a <iunlockput>
  end_op();
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	aec080e7          	jalr	-1300(ra) # 80004042 <end_op>
  return -1;
    8000555e:	557d                	li	a0,-1
}
    80005560:	70ae                	ld	ra,232(sp)
    80005562:	740e                	ld	s0,224(sp)
    80005564:	64ee                	ld	s1,216(sp)
    80005566:	694e                	ld	s2,208(sp)
    80005568:	69ae                	ld	s3,200(sp)
    8000556a:	616d                	addi	sp,sp,240
    8000556c:	8082                	ret

000000008000556e <sys_open>:

uint64
sys_open(void)
{
    8000556e:	7131                	addi	sp,sp,-192
    80005570:	fd06                	sd	ra,184(sp)
    80005572:	f922                	sd	s0,176(sp)
    80005574:	f526                	sd	s1,168(sp)
    80005576:	f14a                	sd	s2,160(sp)
    80005578:	ed4e                	sd	s3,152(sp)
    8000557a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000557c:	08000613          	li	a2,128
    80005580:	f5040593          	addi	a1,s0,-176
    80005584:	4501                	li	a0,0
    80005586:	ffffd097          	auipc	ra,0xffffd
    8000558a:	534080e7          	jalr	1332(ra) # 80002aba <argstr>
    return -1;
    8000558e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005590:	0c054163          	bltz	a0,80005652 <sys_open+0xe4>
    80005594:	f4c40593          	addi	a1,s0,-180
    80005598:	4505                	li	a0,1
    8000559a:	ffffd097          	auipc	ra,0xffffd
    8000559e:	4dc080e7          	jalr	1244(ra) # 80002a76 <argint>
    800055a2:	0a054863          	bltz	a0,80005652 <sys_open+0xe4>

  begin_op();
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	a1e080e7          	jalr	-1506(ra) # 80003fc4 <begin_op>

  if(omode & O_CREATE){
    800055ae:	f4c42783          	lw	a5,-180(s0)
    800055b2:	2007f793          	andi	a5,a5,512
    800055b6:	cbdd                	beqz	a5,8000566c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800055b8:	4681                	li	a3,0
    800055ba:	4601                	li	a2,0
    800055bc:	4589                	li	a1,2
    800055be:	f5040513          	addi	a0,s0,-176
    800055c2:	00000097          	auipc	ra,0x0
    800055c6:	970080e7          	jalr	-1680(ra) # 80004f32 <create>
    800055ca:	892a                	mv	s2,a0
    if(ip == 0){
    800055cc:	c959                	beqz	a0,80005662 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055ce:	04491703          	lh	a4,68(s2)
    800055d2:	478d                	li	a5,3
    800055d4:	00f71763          	bne	a4,a5,800055e2 <sys_open+0x74>
    800055d8:	04695703          	lhu	a4,70(s2)
    800055dc:	47a5                	li	a5,9
    800055de:	0ce7ec63          	bltu	a5,a4,800056b6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	dee080e7          	jalr	-530(ra) # 800043d0 <filealloc>
    800055ea:	89aa                	mv	s3,a0
    800055ec:	10050263          	beqz	a0,800056f0 <sys_open+0x182>
    800055f0:	00000097          	auipc	ra,0x0
    800055f4:	900080e7          	jalr	-1792(ra) # 80004ef0 <fdalloc>
    800055f8:	84aa                	mv	s1,a0
    800055fa:	0e054663          	bltz	a0,800056e6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800055fe:	04491703          	lh	a4,68(s2)
    80005602:	478d                	li	a5,3
    80005604:	0cf70463          	beq	a4,a5,800056cc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005608:	4789                	li	a5,2
    8000560a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000560e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005612:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005616:	f4c42783          	lw	a5,-180(s0)
    8000561a:	0017c713          	xori	a4,a5,1
    8000561e:	8b05                	andi	a4,a4,1
    80005620:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005624:	0037f713          	andi	a4,a5,3
    80005628:	00e03733          	snez	a4,a4
    8000562c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005630:	4007f793          	andi	a5,a5,1024
    80005634:	c791                	beqz	a5,80005640 <sys_open+0xd2>
    80005636:	04491703          	lh	a4,68(s2)
    8000563a:	4789                	li	a5,2
    8000563c:	08f70f63          	beq	a4,a5,800056da <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005640:	854a                	mv	a0,s2
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	068080e7          	jalr	104(ra) # 800036aa <iunlock>
  end_op();
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	9f8080e7          	jalr	-1544(ra) # 80004042 <end_op>

  return fd;
}
    80005652:	8526                	mv	a0,s1
    80005654:	70ea                	ld	ra,184(sp)
    80005656:	744a                	ld	s0,176(sp)
    80005658:	74aa                	ld	s1,168(sp)
    8000565a:	790a                	ld	s2,160(sp)
    8000565c:	69ea                	ld	s3,152(sp)
    8000565e:	6129                	addi	sp,sp,192
    80005660:	8082                	ret
      end_op();
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	9e0080e7          	jalr	-1568(ra) # 80004042 <end_op>
      return -1;
    8000566a:	b7e5                	j	80005652 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000566c:	f5040513          	addi	a0,s0,-176
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	734080e7          	jalr	1844(ra) # 80003da4 <namei>
    80005678:	892a                	mv	s2,a0
    8000567a:	c905                	beqz	a0,800056aa <sys_open+0x13c>
    ilock(ip);
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	f6c080e7          	jalr	-148(ra) # 800035e8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005684:	04491703          	lh	a4,68(s2)
    80005688:	4785                	li	a5,1
    8000568a:	f4f712e3          	bne	a4,a5,800055ce <sys_open+0x60>
    8000568e:	f4c42783          	lw	a5,-180(s0)
    80005692:	dba1                	beqz	a5,800055e2 <sys_open+0x74>
      iunlockput(ip);
    80005694:	854a                	mv	a0,s2
    80005696:	ffffe097          	auipc	ra,0xffffe
    8000569a:	1b4080e7          	jalr	436(ra) # 8000384a <iunlockput>
      end_op();
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	9a4080e7          	jalr	-1628(ra) # 80004042 <end_op>
      return -1;
    800056a6:	54fd                	li	s1,-1
    800056a8:	b76d                	j	80005652 <sys_open+0xe4>
      end_op();
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	998080e7          	jalr	-1640(ra) # 80004042 <end_op>
      return -1;
    800056b2:	54fd                	li	s1,-1
    800056b4:	bf79                	j	80005652 <sys_open+0xe4>
    iunlockput(ip);
    800056b6:	854a                	mv	a0,s2
    800056b8:	ffffe097          	auipc	ra,0xffffe
    800056bc:	192080e7          	jalr	402(ra) # 8000384a <iunlockput>
    end_op();
    800056c0:	fffff097          	auipc	ra,0xfffff
    800056c4:	982080e7          	jalr	-1662(ra) # 80004042 <end_op>
    return -1;
    800056c8:	54fd                	li	s1,-1
    800056ca:	b761                	j	80005652 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800056cc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800056d0:	04691783          	lh	a5,70(s2)
    800056d4:	02f99223          	sh	a5,36(s3)
    800056d8:	bf2d                	j	80005612 <sys_open+0xa4>
    itrunc(ip);
    800056da:	854a                	mv	a0,s2
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	01a080e7          	jalr	26(ra) # 800036f6 <itrunc>
    800056e4:	bfb1                	j	80005640 <sys_open+0xd2>
      fileclose(f);
    800056e6:	854e                	mv	a0,s3
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	da4080e7          	jalr	-604(ra) # 8000448c <fileclose>
    iunlockput(ip);
    800056f0:	854a                	mv	a0,s2
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	158080e7          	jalr	344(ra) # 8000384a <iunlockput>
    end_op();
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	948080e7          	jalr	-1720(ra) # 80004042 <end_op>
    return -1;
    80005702:	54fd                	li	s1,-1
    80005704:	b7b9                	j	80005652 <sys_open+0xe4>

0000000080005706 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005706:	7175                	addi	sp,sp,-144
    80005708:	e506                	sd	ra,136(sp)
    8000570a:	e122                	sd	s0,128(sp)
    8000570c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000570e:	fffff097          	auipc	ra,0xfffff
    80005712:	8b6080e7          	jalr	-1866(ra) # 80003fc4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005716:	08000613          	li	a2,128
    8000571a:	f7040593          	addi	a1,s0,-144
    8000571e:	4501                	li	a0,0
    80005720:	ffffd097          	auipc	ra,0xffffd
    80005724:	39a080e7          	jalr	922(ra) # 80002aba <argstr>
    80005728:	02054963          	bltz	a0,8000575a <sys_mkdir+0x54>
    8000572c:	4681                	li	a3,0
    8000572e:	4601                	li	a2,0
    80005730:	4585                	li	a1,1
    80005732:	f7040513          	addi	a0,s0,-144
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	7fc080e7          	jalr	2044(ra) # 80004f32 <create>
    8000573e:	cd11                	beqz	a0,8000575a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	10a080e7          	jalr	266(ra) # 8000384a <iunlockput>
  end_op();
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	8fa080e7          	jalr	-1798(ra) # 80004042 <end_op>
  return 0;
    80005750:	4501                	li	a0,0
}
    80005752:	60aa                	ld	ra,136(sp)
    80005754:	640a                	ld	s0,128(sp)
    80005756:	6149                	addi	sp,sp,144
    80005758:	8082                	ret
    end_op();
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	8e8080e7          	jalr	-1816(ra) # 80004042 <end_op>
    return -1;
    80005762:	557d                	li	a0,-1
    80005764:	b7fd                	j	80005752 <sys_mkdir+0x4c>

0000000080005766 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005766:	7135                	addi	sp,sp,-160
    80005768:	ed06                	sd	ra,152(sp)
    8000576a:	e922                	sd	s0,144(sp)
    8000576c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000576e:	fffff097          	auipc	ra,0xfffff
    80005772:	856080e7          	jalr	-1962(ra) # 80003fc4 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005776:	08000613          	li	a2,128
    8000577a:	f7040593          	addi	a1,s0,-144
    8000577e:	4501                	li	a0,0
    80005780:	ffffd097          	auipc	ra,0xffffd
    80005784:	33a080e7          	jalr	826(ra) # 80002aba <argstr>
    80005788:	04054a63          	bltz	a0,800057dc <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000578c:	f6c40593          	addi	a1,s0,-148
    80005790:	4505                	li	a0,1
    80005792:	ffffd097          	auipc	ra,0xffffd
    80005796:	2e4080e7          	jalr	740(ra) # 80002a76 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000579a:	04054163          	bltz	a0,800057dc <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000579e:	f6840593          	addi	a1,s0,-152
    800057a2:	4509                	li	a0,2
    800057a4:	ffffd097          	auipc	ra,0xffffd
    800057a8:	2d2080e7          	jalr	722(ra) # 80002a76 <argint>
     argint(1, &major) < 0 ||
    800057ac:	02054863          	bltz	a0,800057dc <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800057b0:	f6841683          	lh	a3,-152(s0)
    800057b4:	f6c41603          	lh	a2,-148(s0)
    800057b8:	458d                	li	a1,3
    800057ba:	f7040513          	addi	a0,s0,-144
    800057be:	fffff097          	auipc	ra,0xfffff
    800057c2:	774080e7          	jalr	1908(ra) # 80004f32 <create>
     argint(2, &minor) < 0 ||
    800057c6:	c919                	beqz	a0,800057dc <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	082080e7          	jalr	130(ra) # 8000384a <iunlockput>
  end_op();
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	872080e7          	jalr	-1934(ra) # 80004042 <end_op>
  return 0;
    800057d8:	4501                	li	a0,0
    800057da:	a031                	j	800057e6 <sys_mknod+0x80>
    end_op();
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	866080e7          	jalr	-1946(ra) # 80004042 <end_op>
    return -1;
    800057e4:	557d                	li	a0,-1
}
    800057e6:	60ea                	ld	ra,152(sp)
    800057e8:	644a                	ld	s0,144(sp)
    800057ea:	610d                	addi	sp,sp,160
    800057ec:	8082                	ret

00000000800057ee <sys_chdir>:

uint64
sys_chdir(void)
{
    800057ee:	7135                	addi	sp,sp,-160
    800057f0:	ed06                	sd	ra,152(sp)
    800057f2:	e922                	sd	s0,144(sp)
    800057f4:	e526                	sd	s1,136(sp)
    800057f6:	e14a                	sd	s2,128(sp)
    800057f8:	1100                	addi	s0,sp,160
  // You can modify this to cd into a symbolic link
  // The modification may not be necessary,
  // depending on you implementation.
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800057fa:	ffffc097          	auipc	ra,0xffffc
    800057fe:	1c6080e7          	jalr	454(ra) # 800019c0 <myproc>
    80005802:	892a                	mv	s2,a0
  
  begin_op();
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	7c0080e7          	jalr	1984(ra) # 80003fc4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000580c:	08000613          	li	a2,128
    80005810:	f6040593          	addi	a1,s0,-160
    80005814:	4501                	li	a0,0
    80005816:	ffffd097          	auipc	ra,0xffffd
    8000581a:	2a4080e7          	jalr	676(ra) # 80002aba <argstr>
    8000581e:	04054b63          	bltz	a0,80005874 <sys_chdir+0x86>
    80005822:	f6040513          	addi	a0,s0,-160
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	57e080e7          	jalr	1406(ra) # 80003da4 <namei>
    8000582e:	84aa                	mv	s1,a0
    80005830:	c131                	beqz	a0,80005874 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	db6080e7          	jalr	-586(ra) # 800035e8 <ilock>
  if(ip->type != T_DIR){
    8000583a:	04449703          	lh	a4,68(s1)
    8000583e:	4785                	li	a5,1
    80005840:	04f71063          	bne	a4,a5,80005880 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005844:	8526                	mv	a0,s1
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	e64080e7          	jalr	-412(ra) # 800036aa <iunlock>
  iput(p->cwd);
    8000584e:	15093503          	ld	a0,336(s2)
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	f50080e7          	jalr	-176(ra) # 800037a2 <iput>
  end_op();
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	7e8080e7          	jalr	2024(ra) # 80004042 <end_op>
  p->cwd = ip;
    80005862:	14993823          	sd	s1,336(s2)
  return 0;
    80005866:	4501                	li	a0,0
}
    80005868:	60ea                	ld	ra,152(sp)
    8000586a:	644a                	ld	s0,144(sp)
    8000586c:	64aa                	ld	s1,136(sp)
    8000586e:	690a                	ld	s2,128(sp)
    80005870:	610d                	addi	sp,sp,160
    80005872:	8082                	ret
    end_op();
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	7ce080e7          	jalr	1998(ra) # 80004042 <end_op>
    return -1;
    8000587c:	557d                	li	a0,-1
    8000587e:	b7ed                	j	80005868 <sys_chdir+0x7a>
    iunlockput(ip);
    80005880:	8526                	mv	a0,s1
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	fc8080e7          	jalr	-56(ra) # 8000384a <iunlockput>
    end_op();
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	7b8080e7          	jalr	1976(ra) # 80004042 <end_op>
    return -1;
    80005892:	557d                	li	a0,-1
    80005894:	bfd1                	j	80005868 <sys_chdir+0x7a>

0000000080005896 <sys_exec>:

uint64
sys_exec(void)
{
    80005896:	7145                	addi	sp,sp,-464
    80005898:	e786                	sd	ra,456(sp)
    8000589a:	e3a2                	sd	s0,448(sp)
    8000589c:	ff26                	sd	s1,440(sp)
    8000589e:	fb4a                	sd	s2,432(sp)
    800058a0:	f74e                	sd	s3,424(sp)
    800058a2:	f352                	sd	s4,416(sp)
    800058a4:	ef56                	sd	s5,408(sp)
    800058a6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058a8:	08000613          	li	a2,128
    800058ac:	f4040593          	addi	a1,s0,-192
    800058b0:	4501                	li	a0,0
    800058b2:	ffffd097          	auipc	ra,0xffffd
    800058b6:	208080e7          	jalr	520(ra) # 80002aba <argstr>
    return -1;
    800058ba:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058bc:	0c054b63          	bltz	a0,80005992 <sys_exec+0xfc>
    800058c0:	e3840593          	addi	a1,s0,-456
    800058c4:	4505                	li	a0,1
    800058c6:	ffffd097          	auipc	ra,0xffffd
    800058ca:	1d2080e7          	jalr	466(ra) # 80002a98 <argaddr>
    800058ce:	0c054263          	bltz	a0,80005992 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800058d2:	10000613          	li	a2,256
    800058d6:	4581                	li	a1,0
    800058d8:	e4040513          	addi	a0,s0,-448
    800058dc:	ffffb097          	auipc	ra,0xffffb
    800058e0:	3e2080e7          	jalr	994(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800058e4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800058e8:	89a6                	mv	s3,s1
    800058ea:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800058ec:	02000a13          	li	s4,32
    800058f0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800058f4:	00391513          	slli	a0,s2,0x3
    800058f8:	e3040593          	addi	a1,s0,-464
    800058fc:	e3843783          	ld	a5,-456(s0)
    80005900:	953e                	add	a0,a0,a5
    80005902:	ffffd097          	auipc	ra,0xffffd
    80005906:	0da080e7          	jalr	218(ra) # 800029dc <fetchaddr>
    8000590a:	02054a63          	bltz	a0,8000593e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000590e:	e3043783          	ld	a5,-464(s0)
    80005912:	c3b9                	beqz	a5,80005958 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005914:	ffffb097          	auipc	ra,0xffffb
    80005918:	1be080e7          	jalr	446(ra) # 80000ad2 <kalloc>
    8000591c:	85aa                	mv	a1,a0
    8000591e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005922:	cd11                	beqz	a0,8000593e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005924:	6605                	lui	a2,0x1
    80005926:	e3043503          	ld	a0,-464(s0)
    8000592a:	ffffd097          	auipc	ra,0xffffd
    8000592e:	104080e7          	jalr	260(ra) # 80002a2e <fetchstr>
    80005932:	00054663          	bltz	a0,8000593e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005936:	0905                	addi	s2,s2,1
    80005938:	09a1                	addi	s3,s3,8
    8000593a:	fb491be3          	bne	s2,s4,800058f0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000593e:	f4040913          	addi	s2,s0,-192
    80005942:	6088                	ld	a0,0(s1)
    80005944:	c531                	beqz	a0,80005990 <sys_exec+0xfa>
    kfree(argv[i]);
    80005946:	ffffb097          	auipc	ra,0xffffb
    8000594a:	08e080e7          	jalr	142(ra) # 800009d4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000594e:	04a1                	addi	s1,s1,8
    80005950:	ff2499e3          	bne	s1,s2,80005942 <sys_exec+0xac>
  return -1;
    80005954:	597d                	li	s2,-1
    80005956:	a835                	j	80005992 <sys_exec+0xfc>
      argv[i] = 0;
    80005958:	0a8e                	slli	s5,s5,0x3
    8000595a:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    8000595e:	00878ab3          	add	s5,a5,s0
    80005962:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005966:	e4040593          	addi	a1,s0,-448
    8000596a:	f4040513          	addi	a0,s0,-192
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	172080e7          	jalr	370(ra) # 80004ae0 <exec>
    80005976:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005978:	f4040993          	addi	s3,s0,-192
    8000597c:	6088                	ld	a0,0(s1)
    8000597e:	c911                	beqz	a0,80005992 <sys_exec+0xfc>
    kfree(argv[i]);
    80005980:	ffffb097          	auipc	ra,0xffffb
    80005984:	054080e7          	jalr	84(ra) # 800009d4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005988:	04a1                	addi	s1,s1,8
    8000598a:	ff3499e3          	bne	s1,s3,8000597c <sys_exec+0xe6>
    8000598e:	a011                	j	80005992 <sys_exec+0xfc>
  return -1;
    80005990:	597d                	li	s2,-1
}
    80005992:	854a                	mv	a0,s2
    80005994:	60be                	ld	ra,456(sp)
    80005996:	641e                	ld	s0,448(sp)
    80005998:	74fa                	ld	s1,440(sp)
    8000599a:	795a                	ld	s2,432(sp)
    8000599c:	79ba                	ld	s3,424(sp)
    8000599e:	7a1a                	ld	s4,416(sp)
    800059a0:	6afa                	ld	s5,408(sp)
    800059a2:	6179                	addi	sp,sp,464
    800059a4:	8082                	ret

00000000800059a6 <sys_pipe>:

uint64
sys_pipe(void)
{
    800059a6:	7139                	addi	sp,sp,-64
    800059a8:	fc06                	sd	ra,56(sp)
    800059aa:	f822                	sd	s0,48(sp)
    800059ac:	f426                	sd	s1,40(sp)
    800059ae:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800059b0:	ffffc097          	auipc	ra,0xffffc
    800059b4:	010080e7          	jalr	16(ra) # 800019c0 <myproc>
    800059b8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800059ba:	fd840593          	addi	a1,s0,-40
    800059be:	4501                	li	a0,0
    800059c0:	ffffd097          	auipc	ra,0xffffd
    800059c4:	0d8080e7          	jalr	216(ra) # 80002a98 <argaddr>
    return -1;
    800059c8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800059ca:	0e054063          	bltz	a0,80005aaa <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800059ce:	fc840593          	addi	a1,s0,-56
    800059d2:	fd040513          	addi	a0,s0,-48
    800059d6:	fffff097          	auipc	ra,0xfffff
    800059da:	de6080e7          	jalr	-538(ra) # 800047bc <pipealloc>
    return -1;
    800059de:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800059e0:	0c054563          	bltz	a0,80005aaa <sys_pipe+0x104>
  fd0 = -1;
    800059e4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800059e8:	fd043503          	ld	a0,-48(s0)
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	504080e7          	jalr	1284(ra) # 80004ef0 <fdalloc>
    800059f4:	fca42223          	sw	a0,-60(s0)
    800059f8:	08054c63          	bltz	a0,80005a90 <sys_pipe+0xea>
    800059fc:	fc843503          	ld	a0,-56(s0)
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	4f0080e7          	jalr	1264(ra) # 80004ef0 <fdalloc>
    80005a08:	fca42023          	sw	a0,-64(s0)
    80005a0c:	06054963          	bltz	a0,80005a7e <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a10:	4691                	li	a3,4
    80005a12:	fc440613          	addi	a2,s0,-60
    80005a16:	fd843583          	ld	a1,-40(s0)
    80005a1a:	68a8                	ld	a0,80(s1)
    80005a1c:	ffffc097          	auipc	ra,0xffffc
    80005a20:	c68080e7          	jalr	-920(ra) # 80001684 <copyout>
    80005a24:	02054063          	bltz	a0,80005a44 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a28:	4691                	li	a3,4
    80005a2a:	fc040613          	addi	a2,s0,-64
    80005a2e:	fd843583          	ld	a1,-40(s0)
    80005a32:	0591                	addi	a1,a1,4
    80005a34:	68a8                	ld	a0,80(s1)
    80005a36:	ffffc097          	auipc	ra,0xffffc
    80005a3a:	c4e080e7          	jalr	-946(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a3e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a40:	06055563          	bgez	a0,80005aaa <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a44:	fc442783          	lw	a5,-60(s0)
    80005a48:	07e9                	addi	a5,a5,26
    80005a4a:	078e                	slli	a5,a5,0x3
    80005a4c:	97a6                	add	a5,a5,s1
    80005a4e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a52:	fc042783          	lw	a5,-64(s0)
    80005a56:	07e9                	addi	a5,a5,26
    80005a58:	078e                	slli	a5,a5,0x3
    80005a5a:	00f48533          	add	a0,s1,a5
    80005a5e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a62:	fd043503          	ld	a0,-48(s0)
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	a26080e7          	jalr	-1498(ra) # 8000448c <fileclose>
    fileclose(wf);
    80005a6e:	fc843503          	ld	a0,-56(s0)
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	a1a080e7          	jalr	-1510(ra) # 8000448c <fileclose>
    return -1;
    80005a7a:	57fd                	li	a5,-1
    80005a7c:	a03d                	j	80005aaa <sys_pipe+0x104>
    if(fd0 >= 0)
    80005a7e:	fc442783          	lw	a5,-60(s0)
    80005a82:	0007c763          	bltz	a5,80005a90 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005a86:	07e9                	addi	a5,a5,26
    80005a88:	078e                	slli	a5,a5,0x3
    80005a8a:	97a6                	add	a5,a5,s1
    80005a8c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005a90:	fd043503          	ld	a0,-48(s0)
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	9f8080e7          	jalr	-1544(ra) # 8000448c <fileclose>
    fileclose(wf);
    80005a9c:	fc843503          	ld	a0,-56(s0)
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	9ec080e7          	jalr	-1556(ra) # 8000448c <fileclose>
    return -1;
    80005aa8:	57fd                	li	a5,-1
}
    80005aaa:	853e                	mv	a0,a5
    80005aac:	70e2                	ld	ra,56(sp)
    80005aae:	7442                	ld	s0,48(sp)
    80005ab0:	74a2                	ld	s1,40(sp)
    80005ab2:	6121                	addi	sp,sp,64
    80005ab4:	8082                	ret

0000000080005ab6 <sys_symlink>:

uint64
sys_symlink(void)
{
    80005ab6:	1141                	addi	sp,sp,-16
    80005ab8:	e406                	sd	ra,8(sp)
    80005aba:	e022                	sd	s0,0(sp)
    80005abc:	0800                	addi	s0,sp,16
  // struct inode *ip;

  // if(argstr(0, target, MAXPATH) < 0 || argstr(1, path, MAXPATH) < 0)
  //   return -1;
  
  panic("You should implement symlink system call.");
    80005abe:	00003517          	auipc	a0,0x3
    80005ac2:	c9250513          	addi	a0,a0,-878 # 80008750 <syscalls+0x320>
    80005ac6:	ffffb097          	auipc	ra,0xffffb
    80005aca:	a66080e7          	jalr	-1434(ra) # 8000052c <panic>
	...

0000000080005ad0 <kernelvec>:
    80005ad0:	7111                	addi	sp,sp,-256
    80005ad2:	e006                	sd	ra,0(sp)
    80005ad4:	e40a                	sd	sp,8(sp)
    80005ad6:	e80e                	sd	gp,16(sp)
    80005ad8:	ec12                	sd	tp,24(sp)
    80005ada:	f016                	sd	t0,32(sp)
    80005adc:	f41a                	sd	t1,40(sp)
    80005ade:	f81e                	sd	t2,48(sp)
    80005ae0:	fc22                	sd	s0,56(sp)
    80005ae2:	e0a6                	sd	s1,64(sp)
    80005ae4:	e4aa                	sd	a0,72(sp)
    80005ae6:	e8ae                	sd	a1,80(sp)
    80005ae8:	ecb2                	sd	a2,88(sp)
    80005aea:	f0b6                	sd	a3,96(sp)
    80005aec:	f4ba                	sd	a4,104(sp)
    80005aee:	f8be                	sd	a5,112(sp)
    80005af0:	fcc2                	sd	a6,120(sp)
    80005af2:	e146                	sd	a7,128(sp)
    80005af4:	e54a                	sd	s2,136(sp)
    80005af6:	e94e                	sd	s3,144(sp)
    80005af8:	ed52                	sd	s4,152(sp)
    80005afa:	f156                	sd	s5,160(sp)
    80005afc:	f55a                	sd	s6,168(sp)
    80005afe:	f95e                	sd	s7,176(sp)
    80005b00:	fd62                	sd	s8,184(sp)
    80005b02:	e1e6                	sd	s9,192(sp)
    80005b04:	e5ea                	sd	s10,200(sp)
    80005b06:	e9ee                	sd	s11,208(sp)
    80005b08:	edf2                	sd	t3,216(sp)
    80005b0a:	f1f6                	sd	t4,224(sp)
    80005b0c:	f5fa                	sd	t5,232(sp)
    80005b0e:	f9fe                	sd	t6,240(sp)
    80005b10:	d99fc0ef          	jal	ra,800028a8 <kerneltrap>
    80005b14:	6082                	ld	ra,0(sp)
    80005b16:	6122                	ld	sp,8(sp)
    80005b18:	61c2                	ld	gp,16(sp)
    80005b1a:	7282                	ld	t0,32(sp)
    80005b1c:	7322                	ld	t1,40(sp)
    80005b1e:	73c2                	ld	t2,48(sp)
    80005b20:	7462                	ld	s0,56(sp)
    80005b22:	6486                	ld	s1,64(sp)
    80005b24:	6526                	ld	a0,72(sp)
    80005b26:	65c6                	ld	a1,80(sp)
    80005b28:	6666                	ld	a2,88(sp)
    80005b2a:	7686                	ld	a3,96(sp)
    80005b2c:	7726                	ld	a4,104(sp)
    80005b2e:	77c6                	ld	a5,112(sp)
    80005b30:	7866                	ld	a6,120(sp)
    80005b32:	688a                	ld	a7,128(sp)
    80005b34:	692a                	ld	s2,136(sp)
    80005b36:	69ca                	ld	s3,144(sp)
    80005b38:	6a6a                	ld	s4,152(sp)
    80005b3a:	7a8a                	ld	s5,160(sp)
    80005b3c:	7b2a                	ld	s6,168(sp)
    80005b3e:	7bca                	ld	s7,176(sp)
    80005b40:	7c6a                	ld	s8,184(sp)
    80005b42:	6c8e                	ld	s9,192(sp)
    80005b44:	6d2e                	ld	s10,200(sp)
    80005b46:	6dce                	ld	s11,208(sp)
    80005b48:	6e6e                	ld	t3,216(sp)
    80005b4a:	7e8e                	ld	t4,224(sp)
    80005b4c:	7f2e                	ld	t5,232(sp)
    80005b4e:	7fce                	ld	t6,240(sp)
    80005b50:	6111                	addi	sp,sp,256
    80005b52:	10200073          	sret
    80005b56:	00000013          	nop
    80005b5a:	00000013          	nop
    80005b5e:	0001                	nop

0000000080005b60 <timervec>:
    80005b60:	34051573          	csrrw	a0,mscratch,a0
    80005b64:	e10c                	sd	a1,0(a0)
    80005b66:	e510                	sd	a2,8(a0)
    80005b68:	e914                	sd	a3,16(a0)
    80005b6a:	6d0c                	ld	a1,24(a0)
    80005b6c:	7110                	ld	a2,32(a0)
    80005b6e:	6194                	ld	a3,0(a1)
    80005b70:	96b2                	add	a3,a3,a2
    80005b72:	e194                	sd	a3,0(a1)
    80005b74:	4589                	li	a1,2
    80005b76:	14459073          	csrw	sip,a1
    80005b7a:	6914                	ld	a3,16(a0)
    80005b7c:	6510                	ld	a2,8(a0)
    80005b7e:	610c                	ld	a1,0(a0)
    80005b80:	34051573          	csrrw	a0,mscratch,a0
    80005b84:	30200073          	mret
	...

0000000080005b8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005b8a:	1141                	addi	sp,sp,-16
    80005b8c:	e422                	sd	s0,8(sp)
    80005b8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005b90:	0c0007b7          	lui	a5,0xc000
    80005b94:	4705                	li	a4,1
    80005b96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005b98:	c3d8                	sw	a4,4(a5)
}
    80005b9a:	6422                	ld	s0,8(sp)
    80005b9c:	0141                	addi	sp,sp,16
    80005b9e:	8082                	ret

0000000080005ba0 <plicinithart>:

void
plicinithart(void)
{
    80005ba0:	1141                	addi	sp,sp,-16
    80005ba2:	e406                	sd	ra,8(sp)
    80005ba4:	e022                	sd	s0,0(sp)
    80005ba6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ba8:	ffffc097          	auipc	ra,0xffffc
    80005bac:	dec080e7          	jalr	-532(ra) # 80001994 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005bb0:	0085171b          	slliw	a4,a0,0x8
    80005bb4:	0c0027b7          	lui	a5,0xc002
    80005bb8:	97ba                	add	a5,a5,a4
    80005bba:	40200713          	li	a4,1026
    80005bbe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005bc2:	00d5151b          	slliw	a0,a0,0xd
    80005bc6:	0c2017b7          	lui	a5,0xc201
    80005bca:	97aa                	add	a5,a5,a0
    80005bcc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005bd0:	60a2                	ld	ra,8(sp)
    80005bd2:	6402                	ld	s0,0(sp)
    80005bd4:	0141                	addi	sp,sp,16
    80005bd6:	8082                	ret

0000000080005bd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005bd8:	1141                	addi	sp,sp,-16
    80005bda:	e406                	sd	ra,8(sp)
    80005bdc:	e022                	sd	s0,0(sp)
    80005bde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005be0:	ffffc097          	auipc	ra,0xffffc
    80005be4:	db4080e7          	jalr	-588(ra) # 80001994 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005be8:	00d5151b          	slliw	a0,a0,0xd
    80005bec:	0c2017b7          	lui	a5,0xc201
    80005bf0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005bf2:	43c8                	lw	a0,4(a5)
    80005bf4:	60a2                	ld	ra,8(sp)
    80005bf6:	6402                	ld	s0,0(sp)
    80005bf8:	0141                	addi	sp,sp,16
    80005bfa:	8082                	ret

0000000080005bfc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005bfc:	1101                	addi	sp,sp,-32
    80005bfe:	ec06                	sd	ra,24(sp)
    80005c00:	e822                	sd	s0,16(sp)
    80005c02:	e426                	sd	s1,8(sp)
    80005c04:	1000                	addi	s0,sp,32
    80005c06:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c08:	ffffc097          	auipc	ra,0xffffc
    80005c0c:	d8c080e7          	jalr	-628(ra) # 80001994 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c10:	00d5151b          	slliw	a0,a0,0xd
    80005c14:	0c2017b7          	lui	a5,0xc201
    80005c18:	97aa                	add	a5,a5,a0
    80005c1a:	c3c4                	sw	s1,4(a5)
}
    80005c1c:	60e2                	ld	ra,24(sp)
    80005c1e:	6442                	ld	s0,16(sp)
    80005c20:	64a2                	ld	s1,8(sp)
    80005c22:	6105                	addi	sp,sp,32
    80005c24:	8082                	ret

0000000080005c26 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c26:	1141                	addi	sp,sp,-16
    80005c28:	e406                	sd	ra,8(sp)
    80005c2a:	e022                	sd	s0,0(sp)
    80005c2c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c2e:	479d                	li	a5,7
    80005c30:	06a7c863          	blt	a5,a0,80005ca0 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005c34:	0001d717          	auipc	a4,0x1d
    80005c38:	3cc70713          	addi	a4,a4,972 # 80023000 <disk>
    80005c3c:	972a                	add	a4,a4,a0
    80005c3e:	6789                	lui	a5,0x2
    80005c40:	97ba                	add	a5,a5,a4
    80005c42:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005c46:	e7ad                	bnez	a5,80005cb0 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c48:	00451793          	slli	a5,a0,0x4
    80005c4c:	0001f717          	auipc	a4,0x1f
    80005c50:	3b470713          	addi	a4,a4,948 # 80025000 <disk+0x2000>
    80005c54:	6314                	ld	a3,0(a4)
    80005c56:	96be                	add	a3,a3,a5
    80005c58:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005c5c:	6314                	ld	a3,0(a4)
    80005c5e:	96be                	add	a3,a3,a5
    80005c60:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005c64:	6314                	ld	a3,0(a4)
    80005c66:	96be                	add	a3,a3,a5
    80005c68:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005c6c:	6318                	ld	a4,0(a4)
    80005c6e:	97ba                	add	a5,a5,a4
    80005c70:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005c74:	0001d717          	auipc	a4,0x1d
    80005c78:	38c70713          	addi	a4,a4,908 # 80023000 <disk>
    80005c7c:	972a                	add	a4,a4,a0
    80005c7e:	6789                	lui	a5,0x2
    80005c80:	97ba                	add	a5,a5,a4
    80005c82:	4705                	li	a4,1
    80005c84:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005c88:	0001f517          	auipc	a0,0x1f
    80005c8c:	39050513          	addi	a0,a0,912 # 80025018 <disk+0x2018>
    80005c90:	ffffc097          	auipc	ra,0xffffc
    80005c94:	580080e7          	jalr	1408(ra) # 80002210 <wakeup>
}
    80005c98:	60a2                	ld	ra,8(sp)
    80005c9a:	6402                	ld	s0,0(sp)
    80005c9c:	0141                	addi	sp,sp,16
    80005c9e:	8082                	ret
    panic("free_desc 1");
    80005ca0:	00003517          	auipc	a0,0x3
    80005ca4:	ae050513          	addi	a0,a0,-1312 # 80008780 <syscalls+0x350>
    80005ca8:	ffffb097          	auipc	ra,0xffffb
    80005cac:	884080e7          	jalr	-1916(ra) # 8000052c <panic>
    panic("free_desc 2");
    80005cb0:	00003517          	auipc	a0,0x3
    80005cb4:	ae050513          	addi	a0,a0,-1312 # 80008790 <syscalls+0x360>
    80005cb8:	ffffb097          	auipc	ra,0xffffb
    80005cbc:	874080e7          	jalr	-1932(ra) # 8000052c <panic>

0000000080005cc0 <virtio_disk_init>:
{
    80005cc0:	1101                	addi	sp,sp,-32
    80005cc2:	ec06                	sd	ra,24(sp)
    80005cc4:	e822                	sd	s0,16(sp)
    80005cc6:	e426                	sd	s1,8(sp)
    80005cc8:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005cca:	00003597          	auipc	a1,0x3
    80005cce:	ad658593          	addi	a1,a1,-1322 # 800087a0 <syscalls+0x370>
    80005cd2:	0001f517          	auipc	a0,0x1f
    80005cd6:	45650513          	addi	a0,a0,1110 # 80025128 <disk+0x2128>
    80005cda:	ffffb097          	auipc	ra,0xffffb
    80005cde:	e58080e7          	jalr	-424(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ce2:	100017b7          	lui	a5,0x10001
    80005ce6:	4398                	lw	a4,0(a5)
    80005ce8:	2701                	sext.w	a4,a4
    80005cea:	747277b7          	lui	a5,0x74727
    80005cee:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005cf2:	0ef71063          	bne	a4,a5,80005dd2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005cf6:	100017b7          	lui	a5,0x10001
    80005cfa:	43dc                	lw	a5,4(a5)
    80005cfc:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cfe:	4705                	li	a4,1
    80005d00:	0ce79963          	bne	a5,a4,80005dd2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d04:	100017b7          	lui	a5,0x10001
    80005d08:	479c                	lw	a5,8(a5)
    80005d0a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d0c:	4709                	li	a4,2
    80005d0e:	0ce79263          	bne	a5,a4,80005dd2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d12:	100017b7          	lui	a5,0x10001
    80005d16:	47d8                	lw	a4,12(a5)
    80005d18:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d1a:	554d47b7          	lui	a5,0x554d4
    80005d1e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d22:	0af71863          	bne	a4,a5,80005dd2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d26:	100017b7          	lui	a5,0x10001
    80005d2a:	4705                	li	a4,1
    80005d2c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d2e:	470d                	li	a4,3
    80005d30:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d32:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d34:	c7ffe6b7          	lui	a3,0xc7ffe
    80005d38:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005d3c:	8f75                	and	a4,a4,a3
    80005d3e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d40:	472d                	li	a4,11
    80005d42:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d44:	473d                	li	a4,15
    80005d46:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d48:	6705                	lui	a4,0x1
    80005d4a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d4c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d50:	5bdc                	lw	a5,52(a5)
    80005d52:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d54:	c7d9                	beqz	a5,80005de2 <virtio_disk_init+0x122>
  if(max < NUM)
    80005d56:	471d                	li	a4,7
    80005d58:	08f77d63          	bgeu	a4,a5,80005df2 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005d5c:	100014b7          	lui	s1,0x10001
    80005d60:	47a1                	li	a5,8
    80005d62:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005d64:	6609                	lui	a2,0x2
    80005d66:	4581                	li	a1,0
    80005d68:	0001d517          	auipc	a0,0x1d
    80005d6c:	29850513          	addi	a0,a0,664 # 80023000 <disk>
    80005d70:	ffffb097          	auipc	ra,0xffffb
    80005d74:	f4e080e7          	jalr	-178(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005d78:	0001d717          	auipc	a4,0x1d
    80005d7c:	28870713          	addi	a4,a4,648 # 80023000 <disk>
    80005d80:	00c75793          	srli	a5,a4,0xc
    80005d84:	2781                	sext.w	a5,a5
    80005d86:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005d88:	0001f797          	auipc	a5,0x1f
    80005d8c:	27878793          	addi	a5,a5,632 # 80025000 <disk+0x2000>
    80005d90:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005d92:	0001d717          	auipc	a4,0x1d
    80005d96:	2ee70713          	addi	a4,a4,750 # 80023080 <disk+0x80>
    80005d9a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005d9c:	0001e717          	auipc	a4,0x1e
    80005da0:	26470713          	addi	a4,a4,612 # 80024000 <disk+0x1000>
    80005da4:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005da6:	4705                	li	a4,1
    80005da8:	00e78c23          	sb	a4,24(a5)
    80005dac:	00e78ca3          	sb	a4,25(a5)
    80005db0:	00e78d23          	sb	a4,26(a5)
    80005db4:	00e78da3          	sb	a4,27(a5)
    80005db8:	00e78e23          	sb	a4,28(a5)
    80005dbc:	00e78ea3          	sb	a4,29(a5)
    80005dc0:	00e78f23          	sb	a4,30(a5)
    80005dc4:	00e78fa3          	sb	a4,31(a5)
}
    80005dc8:	60e2                	ld	ra,24(sp)
    80005dca:	6442                	ld	s0,16(sp)
    80005dcc:	64a2                	ld	s1,8(sp)
    80005dce:	6105                	addi	sp,sp,32
    80005dd0:	8082                	ret
    panic("could not find virtio disk");
    80005dd2:	00003517          	auipc	a0,0x3
    80005dd6:	9de50513          	addi	a0,a0,-1570 # 800087b0 <syscalls+0x380>
    80005dda:	ffffa097          	auipc	ra,0xffffa
    80005dde:	752080e7          	jalr	1874(ra) # 8000052c <panic>
    panic("virtio disk has no queue 0");
    80005de2:	00003517          	auipc	a0,0x3
    80005de6:	9ee50513          	addi	a0,a0,-1554 # 800087d0 <syscalls+0x3a0>
    80005dea:	ffffa097          	auipc	ra,0xffffa
    80005dee:	742080e7          	jalr	1858(ra) # 8000052c <panic>
    panic("virtio disk max queue too short");
    80005df2:	00003517          	auipc	a0,0x3
    80005df6:	9fe50513          	addi	a0,a0,-1538 # 800087f0 <syscalls+0x3c0>
    80005dfa:	ffffa097          	auipc	ra,0xffffa
    80005dfe:	732080e7          	jalr	1842(ra) # 8000052c <panic>

0000000080005e02 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e02:	7119                	addi	sp,sp,-128
    80005e04:	fc86                	sd	ra,120(sp)
    80005e06:	f8a2                	sd	s0,112(sp)
    80005e08:	f4a6                	sd	s1,104(sp)
    80005e0a:	f0ca                	sd	s2,96(sp)
    80005e0c:	ecce                	sd	s3,88(sp)
    80005e0e:	e8d2                	sd	s4,80(sp)
    80005e10:	e4d6                	sd	s5,72(sp)
    80005e12:	e0da                	sd	s6,64(sp)
    80005e14:	fc5e                	sd	s7,56(sp)
    80005e16:	f862                	sd	s8,48(sp)
    80005e18:	f466                	sd	s9,40(sp)
    80005e1a:	f06a                	sd	s10,32(sp)
    80005e1c:	ec6e                	sd	s11,24(sp)
    80005e1e:	0100                	addi	s0,sp,128
    80005e20:	8aaa                	mv	s5,a0
    80005e22:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e24:	00c52c83          	lw	s9,12(a0)
    80005e28:	001c9c9b          	slliw	s9,s9,0x1
    80005e2c:	1c82                	slli	s9,s9,0x20
    80005e2e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e32:	0001f517          	auipc	a0,0x1f
    80005e36:	2f650513          	addi	a0,a0,758 # 80025128 <disk+0x2128>
    80005e3a:	ffffb097          	auipc	ra,0xffffb
    80005e3e:	d88080e7          	jalr	-632(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80005e42:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e44:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005e46:	0001dc17          	auipc	s8,0x1d
    80005e4a:	1bac0c13          	addi	s8,s8,442 # 80023000 <disk>
    80005e4e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005e50:	4b0d                	li	s6,3
    80005e52:	a0ad                	j	80005ebc <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005e54:	00fc0733          	add	a4,s8,a5
    80005e58:	975e                	add	a4,a4,s7
    80005e5a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005e5e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005e60:	0207c563          	bltz	a5,80005e8a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005e64:	2905                	addiw	s2,s2,1
    80005e66:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80005e68:	19690c63          	beq	s2,s6,80006000 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80005e6c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005e6e:	0001f717          	auipc	a4,0x1f
    80005e72:	1aa70713          	addi	a4,a4,426 # 80025018 <disk+0x2018>
    80005e76:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005e78:	00074683          	lbu	a3,0(a4)
    80005e7c:	fee1                	bnez	a3,80005e54 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005e7e:	2785                	addiw	a5,a5,1
    80005e80:	0705                	addi	a4,a4,1
    80005e82:	fe979be3          	bne	a5,s1,80005e78 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005e86:	57fd                	li	a5,-1
    80005e88:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005e8a:	01205d63          	blez	s2,80005ea4 <virtio_disk_rw+0xa2>
    80005e8e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005e90:	000a2503          	lw	a0,0(s4)
    80005e94:	00000097          	auipc	ra,0x0
    80005e98:	d92080e7          	jalr	-622(ra) # 80005c26 <free_desc>
      for(int j = 0; j < i; j++)
    80005e9c:	2d85                	addiw	s11,s11,1
    80005e9e:	0a11                	addi	s4,s4,4
    80005ea0:	ff2d98e3          	bne	s11,s2,80005e90 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ea4:	0001f597          	auipc	a1,0x1f
    80005ea8:	28458593          	addi	a1,a1,644 # 80025128 <disk+0x2128>
    80005eac:	0001f517          	auipc	a0,0x1f
    80005eb0:	16c50513          	addi	a0,a0,364 # 80025018 <disk+0x2018>
    80005eb4:	ffffc097          	auipc	ra,0xffffc
    80005eb8:	1d0080e7          	jalr	464(ra) # 80002084 <sleep>
  for(int i = 0; i < 3; i++){
    80005ebc:	f8040a13          	addi	s4,s0,-128
{
    80005ec0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005ec2:	894e                	mv	s2,s3
    80005ec4:	b765                	j	80005e6c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005ec6:	0001f697          	auipc	a3,0x1f
    80005eca:	13a6b683          	ld	a3,314(a3) # 80025000 <disk+0x2000>
    80005ece:	96ba                	add	a3,a3,a4
    80005ed0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005ed4:	0001d817          	auipc	a6,0x1d
    80005ed8:	12c80813          	addi	a6,a6,300 # 80023000 <disk>
    80005edc:	0001f697          	auipc	a3,0x1f
    80005ee0:	12468693          	addi	a3,a3,292 # 80025000 <disk+0x2000>
    80005ee4:	6290                	ld	a2,0(a3)
    80005ee6:	963a                	add	a2,a2,a4
    80005ee8:	00c65583          	lhu	a1,12(a2)
    80005eec:	0015e593          	ori	a1,a1,1
    80005ef0:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005ef4:	f8842603          	lw	a2,-120(s0)
    80005ef8:	628c                	ld	a1,0(a3)
    80005efa:	972e                	add	a4,a4,a1
    80005efc:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005f00:	20050593          	addi	a1,a0,512
    80005f04:	0592                	slli	a1,a1,0x4
    80005f06:	95c2                	add	a1,a1,a6
    80005f08:	577d                	li	a4,-1
    80005f0a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005f0e:	00461713          	slli	a4,a2,0x4
    80005f12:	6290                	ld	a2,0(a3)
    80005f14:	963a                	add	a2,a2,a4
    80005f16:	03078793          	addi	a5,a5,48
    80005f1a:	97c2                	add	a5,a5,a6
    80005f1c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80005f1e:	629c                	ld	a5,0(a3)
    80005f20:	97ba                	add	a5,a5,a4
    80005f22:	4605                	li	a2,1
    80005f24:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005f26:	629c                	ld	a5,0(a3)
    80005f28:	97ba                	add	a5,a5,a4
    80005f2a:	4809                	li	a6,2
    80005f2c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005f30:	629c                	ld	a5,0(a3)
    80005f32:	97ba                	add	a5,a5,a4
    80005f34:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005f38:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80005f3c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005f40:	6698                	ld	a4,8(a3)
    80005f42:	00275783          	lhu	a5,2(a4)
    80005f46:	8b9d                	andi	a5,a5,7
    80005f48:	0786                	slli	a5,a5,0x1
    80005f4a:	973e                	add	a4,a4,a5
    80005f4c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80005f50:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005f54:	6698                	ld	a4,8(a3)
    80005f56:	00275783          	lhu	a5,2(a4)
    80005f5a:	2785                	addiw	a5,a5,1
    80005f5c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005f60:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005f64:	100017b7          	lui	a5,0x10001
    80005f68:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005f6c:	004aa783          	lw	a5,4(s5)
    80005f70:	02c79163          	bne	a5,a2,80005f92 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80005f74:	0001f917          	auipc	s2,0x1f
    80005f78:	1b490913          	addi	s2,s2,436 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80005f7c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005f7e:	85ca                	mv	a1,s2
    80005f80:	8556                	mv	a0,s5
    80005f82:	ffffc097          	auipc	ra,0xffffc
    80005f86:	102080e7          	jalr	258(ra) # 80002084 <sleep>
  while(b->disk == 1) {
    80005f8a:	004aa783          	lw	a5,4(s5)
    80005f8e:	fe9788e3          	beq	a5,s1,80005f7e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80005f92:	f8042903          	lw	s2,-128(s0)
    80005f96:	20090713          	addi	a4,s2,512
    80005f9a:	0712                	slli	a4,a4,0x4
    80005f9c:	0001d797          	auipc	a5,0x1d
    80005fa0:	06478793          	addi	a5,a5,100 # 80023000 <disk>
    80005fa4:	97ba                	add	a5,a5,a4
    80005fa6:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80005faa:	0001f997          	auipc	s3,0x1f
    80005fae:	05698993          	addi	s3,s3,86 # 80025000 <disk+0x2000>
    80005fb2:	00491713          	slli	a4,s2,0x4
    80005fb6:	0009b783          	ld	a5,0(s3)
    80005fba:	97ba                	add	a5,a5,a4
    80005fbc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005fc0:	854a                	mv	a0,s2
    80005fc2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005fc6:	00000097          	auipc	ra,0x0
    80005fca:	c60080e7          	jalr	-928(ra) # 80005c26 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005fce:	8885                	andi	s1,s1,1
    80005fd0:	f0ed                	bnez	s1,80005fb2 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005fd2:	0001f517          	auipc	a0,0x1f
    80005fd6:	15650513          	addi	a0,a0,342 # 80025128 <disk+0x2128>
    80005fda:	ffffb097          	auipc	ra,0xffffb
    80005fde:	c9c080e7          	jalr	-868(ra) # 80000c76 <release>
}
    80005fe2:	70e6                	ld	ra,120(sp)
    80005fe4:	7446                	ld	s0,112(sp)
    80005fe6:	74a6                	ld	s1,104(sp)
    80005fe8:	7906                	ld	s2,96(sp)
    80005fea:	69e6                	ld	s3,88(sp)
    80005fec:	6a46                	ld	s4,80(sp)
    80005fee:	6aa6                	ld	s5,72(sp)
    80005ff0:	6b06                	ld	s6,64(sp)
    80005ff2:	7be2                	ld	s7,56(sp)
    80005ff4:	7c42                	ld	s8,48(sp)
    80005ff6:	7ca2                	ld	s9,40(sp)
    80005ff8:	7d02                	ld	s10,32(sp)
    80005ffa:	6de2                	ld	s11,24(sp)
    80005ffc:	6109                	addi	sp,sp,128
    80005ffe:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006000:	f8042503          	lw	a0,-128(s0)
    80006004:	20050793          	addi	a5,a0,512
    80006008:	0792                	slli	a5,a5,0x4
  if(write)
    8000600a:	0001d817          	auipc	a6,0x1d
    8000600e:	ff680813          	addi	a6,a6,-10 # 80023000 <disk>
    80006012:	00f80733          	add	a4,a6,a5
    80006016:	01a036b3          	snez	a3,s10
    8000601a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000601e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006022:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006026:	7679                	lui	a2,0xffffe
    80006028:	963e                	add	a2,a2,a5
    8000602a:	0001f697          	auipc	a3,0x1f
    8000602e:	fd668693          	addi	a3,a3,-42 # 80025000 <disk+0x2000>
    80006032:	6298                	ld	a4,0(a3)
    80006034:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006036:	0a878593          	addi	a1,a5,168
    8000603a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000603c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000603e:	6298                	ld	a4,0(a3)
    80006040:	9732                	add	a4,a4,a2
    80006042:	45c1                	li	a1,16
    80006044:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006046:	6298                	ld	a4,0(a3)
    80006048:	9732                	add	a4,a4,a2
    8000604a:	4585                	li	a1,1
    8000604c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006050:	f8442703          	lw	a4,-124(s0)
    80006054:	628c                	ld	a1,0(a3)
    80006056:	962e                	add	a2,a2,a1
    80006058:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000605c:	0712                	slli	a4,a4,0x4
    8000605e:	6290                	ld	a2,0(a3)
    80006060:	963a                	add	a2,a2,a4
    80006062:	058a8593          	addi	a1,s5,88
    80006066:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006068:	6294                	ld	a3,0(a3)
    8000606a:	96ba                	add	a3,a3,a4
    8000606c:	40000613          	li	a2,1024
    80006070:	c690                	sw	a2,8(a3)
  if(write)
    80006072:	e40d1ae3          	bnez	s10,80005ec6 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006076:	0001f697          	auipc	a3,0x1f
    8000607a:	f8a6b683          	ld	a3,-118(a3) # 80025000 <disk+0x2000>
    8000607e:	96ba                	add	a3,a3,a4
    80006080:	4609                	li	a2,2
    80006082:	00c69623          	sh	a2,12(a3)
    80006086:	b5b9                	j	80005ed4 <virtio_disk_rw+0xd2>

0000000080006088 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006088:	1101                	addi	sp,sp,-32
    8000608a:	ec06                	sd	ra,24(sp)
    8000608c:	e822                	sd	s0,16(sp)
    8000608e:	e426                	sd	s1,8(sp)
    80006090:	e04a                	sd	s2,0(sp)
    80006092:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006094:	0001f517          	auipc	a0,0x1f
    80006098:	09450513          	addi	a0,a0,148 # 80025128 <disk+0x2128>
    8000609c:	ffffb097          	auipc	ra,0xffffb
    800060a0:	b26080e7          	jalr	-1242(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800060a4:	10001737          	lui	a4,0x10001
    800060a8:	533c                	lw	a5,96(a4)
    800060aa:	8b8d                	andi	a5,a5,3
    800060ac:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800060ae:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800060b2:	0001f797          	auipc	a5,0x1f
    800060b6:	f4e78793          	addi	a5,a5,-178 # 80025000 <disk+0x2000>
    800060ba:	6b94                	ld	a3,16(a5)
    800060bc:	0207d703          	lhu	a4,32(a5)
    800060c0:	0026d783          	lhu	a5,2(a3)
    800060c4:	06f70163          	beq	a4,a5,80006126 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800060c8:	0001d917          	auipc	s2,0x1d
    800060cc:	f3890913          	addi	s2,s2,-200 # 80023000 <disk>
    800060d0:	0001f497          	auipc	s1,0x1f
    800060d4:	f3048493          	addi	s1,s1,-208 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800060d8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800060dc:	6898                	ld	a4,16(s1)
    800060de:	0204d783          	lhu	a5,32(s1)
    800060e2:	8b9d                	andi	a5,a5,7
    800060e4:	078e                	slli	a5,a5,0x3
    800060e6:	97ba                	add	a5,a5,a4
    800060e8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800060ea:	20078713          	addi	a4,a5,512
    800060ee:	0712                	slli	a4,a4,0x4
    800060f0:	974a                	add	a4,a4,s2
    800060f2:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800060f6:	e731                	bnez	a4,80006142 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800060f8:	20078793          	addi	a5,a5,512
    800060fc:	0792                	slli	a5,a5,0x4
    800060fe:	97ca                	add	a5,a5,s2
    80006100:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006102:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006106:	ffffc097          	auipc	ra,0xffffc
    8000610a:	10a080e7          	jalr	266(ra) # 80002210 <wakeup>

    disk.used_idx += 1;
    8000610e:	0204d783          	lhu	a5,32(s1)
    80006112:	2785                	addiw	a5,a5,1
    80006114:	17c2                	slli	a5,a5,0x30
    80006116:	93c1                	srli	a5,a5,0x30
    80006118:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000611c:	6898                	ld	a4,16(s1)
    8000611e:	00275703          	lhu	a4,2(a4)
    80006122:	faf71be3          	bne	a4,a5,800060d8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006126:	0001f517          	auipc	a0,0x1f
    8000612a:	00250513          	addi	a0,a0,2 # 80025128 <disk+0x2128>
    8000612e:	ffffb097          	auipc	ra,0xffffb
    80006132:	b48080e7          	jalr	-1208(ra) # 80000c76 <release>
}
    80006136:	60e2                	ld	ra,24(sp)
    80006138:	6442                	ld	s0,16(sp)
    8000613a:	64a2                	ld	s1,8(sp)
    8000613c:	6902                	ld	s2,0(sp)
    8000613e:	6105                	addi	sp,sp,32
    80006140:	8082                	ret
      panic("virtio_disk_intr status");
    80006142:	00002517          	auipc	a0,0x2
    80006146:	6ce50513          	addi	a0,a0,1742 # 80008810 <syscalls+0x3e0>
    8000614a:	ffffa097          	auipc	ra,0xffffa
    8000614e:	3e2080e7          	jalr	994(ra) # 8000052c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
