; ==========================================
; 编译方法：nasm code/boot.asm -o boot.com

; 注意80386 cpu采用小端字节序！
; ==========================================
%include	"code/GDTHead.inc"	; 常量, 宏, 以及一些说明
;此处在0100打断点不管用,因为不知道cs的段基地址是多少
org	0100h				; 在dos系统中,这个地址是空闲可用的
	xchg bx,bx
	jmp	LABEL_BEGIN

[SECTION .gdt]
; GDT 如发炮制
;                            段基址,        段界限 , 属性
LABEL_GDT:         Descriptor    0,              0, 0         ; 空描述符
LABEL_DESC_NORMAL: Descriptor    0,         0ffffh, DA_DRW    ; Normal 描述符
LABEL_DESC_CODE32: Descriptor    0, SegCode32Len-1, DA_C+DA_32; 非一致代码段, 32
LABEL_DESC_CODE16: Descriptor    0,         0ffffh, DA_C      ; 非一致代码段, 16
LABEL_DESC_CODE_DEST: Descriptor 0,SegCodeDestLen-1, DA_C+DA_32; 非一致代码段,32 作为调用门的目的段
LABEL_DESC_DATA:   Descriptor    0,      DataLen-1, DA_DRW    ; Data
LABEL_DESC_STACK:  Descriptor    0,     TopOfStack, DA_DRWA+DA_32; Stack, 32 位
LABEL_DESC_LDT:    Descriptor       0,        LDTLen - 1, DA_LDT	; 在全局描述表中添加指向LDT的描述符
LABEL_DESC_VIDEO:  Descriptor  0B8000h,     0ffffh, DA_DRW    ; 显存首地址
; 门                               目标选择子,偏移,DCount, 属性
LABEL_CALL_GATE_TEST: Gate SelectorCodeDest,   0,     0, DA_386CGate+DA_DPL0
; GDT 结束

GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1	; GDT界限
		dd	0		; GDT基地址

; GDT 选择子
SelectorNormal		equ	LABEL_DESC_NORMAL		- LABEL_GDT
SelectorCode32		equ	LABEL_DESC_CODE32		- LABEL_GDT
SelectorCode16		equ	LABEL_DESC_CODE16		- LABEL_GDT
SelectorCodeDest	equ	LABEL_DESC_CODE_DEST	- LABEL_GDT		;门目标段的选择子
SelectorData		equ	LABEL_DESC_DATA			- LABEL_GDT
SelectorStack		equ	LABEL_DESC_STACK		- LABEL_GDT
SelectorLDT			equ	LABEL_DESC_LDT			- LABEL_GDT		;LDT表的选择子
SelectorVideo		equ	LABEL_DESC_VIDEO		- LABEL_GDT
SelectorCallGateTest	equ	LABEL_CALL_GATE_TEST	- LABEL_GDT	;门的选择子
; END of [SECTION .gdt]

[SECTION .data1]	 ; 数据段
ALIGN	32
[BITS	32]
LABEL_DATA:
SPValueInRealMode	dw	0
; 字符串
PMMessage:		db	"In Protect Mode now. ^-^", 0	; 在保护模式中显示
OffsetPMMessage		equ	PMMessage - $$
StrTest:		db	"ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
OffsetStrTest		equ	StrTest - $$
DataLen			equ	$ - LABEL_DATA
; END of [SECTION .data1]


; 全局堆栈段
[SECTION .gs]
ALIGN	32
[BITS	32]
LABEL_STACK:				;因为有这么大的一个栈段,导致无法像以前一样放到引导扇区调试了
	times 512 db 0

TopOfStack	equ	$ - LABEL_STACK - 1

; END of [SECTION .gs]


[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	;清零,设置栈地地址
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	mov	[LABEL_GO_BACK_TO_REAL+3], ax		;ax此时就是cs,给jmp的基地址赋正确的值
	mov	[SPValueInRealMode], sp				;存储实模式段栈指针,方便回到实模式时恢复

	; 初始化 16 位代码段描述符 ,把LABEL_SEG_CODE16写入段基址
	mov	ax, cs
	movzx	eax, ax
	shl	eax, 4
	add	eax, LABEL_SEG_CODE16
	mov	word [LABEL_DESC_CODE16 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE16 + 4], al
	mov	byte [LABEL_DESC_CODE16 + 7], ah

	; 初始化 32 位代码段描述符 ,把LABEL_SEG_CODE32写入段基址
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
	mov	byte [LABEL_DESC_CODE32 + 7], ah

	; 初始化调用门的代码段描述符
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE_DEST
	mov	word [LABEL_DESC_CODE_DEST + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE_DEST + 4], al
	mov	byte [LABEL_DESC_CODE_DEST + 7], ah

	; 初始化数据段描述符,把LABEL_DESC_DATA写入段基址
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_DATA
	mov	word [LABEL_DESC_DATA + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_DATA + 4], al
	mov	byte [LABEL_DESC_DATA + 7], ah

	; 初始化堆栈段描述符,把LABEL_DESC_STACK写入段基址
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_STACK
	mov	word [LABEL_DESC_STACK + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK + 4], al
	mov	byte [LABEL_DESC_STACK + 7], ah

	; 初始化 LDT 在 GDT 中的描述符,把LABEL_LDT的地址写入段基址[LABEL_DESC_LDT]
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_LDT
	mov	word [LABEL_DESC_LDT + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_LDT + 4], al
	mov	byte [LABEL_DESC_LDT + 7], ah

	; 初始化 LDT 中的描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_CODE_A
	mov	word [LABEL_LDT_DESC_CODEA + 2], ax
	shr	eax, 16
	mov	byte [LABEL_LDT_DESC_CODEA + 4], al
	mov	byte [LABEL_LDT_DESC_CODEA + 7], ah


	; 维护好GdtPtr, 为加载 GDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt 基地址
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt 基地址

	; 加载 GDTR
	lgdt	[GdtPtr]

	; 关中断
	cli

	; 打开地址线A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; 准备切换到保护模式
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; 利用32位代码段的选择子进行跳转,真正进入保护模式
	jmp	dword SelectorCode32:0	; 执行这一句会把 SelectorCode32 装入 cs, 并跳转到 LABEL_SEG_CODE32:0  处

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LABEL_REAL_ENTRY:		; 从保护模式跳回到实模式就到了这里
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax

	mov	sp, [SPValueInRealMode]		;恢复栈指针

	in	al, 92h			; ┓
	and	al, 11111101b	; ┣ 关闭 A20 地址线
	out	92h, al			; ┛

	sti			; 开中断

	mov	ax, 4c00h	; ┓
	int	21h			; ┛回到 DOS
; END of [SECTION .s16]


[SECTION .s32]; 32 位代码段. 由实模式跳入.
[BITS	32]

LABEL_SEG_CODE32:
	;在32位保护模式下,就要用选择子寻址啦!
	mov	ax, SelectorData
	mov	ds, ax			; 数据段选择子

	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子

	mov	ax, SelectorStack
	mov	ss, ax			; 堆栈段选择子

	mov	esp, TopOfStack ; 栈指针偏移指向栈顶


	; 下面显示一个字符串 "In Protect Mode now. ^-^"
	mov	ah, 0Dh			; 0000: 黑底    1101: 洋红
	xor	esi, esi		;清零
	xor	edi, edi		;清零
	mov	esi, OffsetPMMessage	; 显示多少个字符
	mov	edi, (80 * 10 + 0) * 2	; 目的数据偏移。屏幕第 10 行, 第 0 列。
	;cld相对应的指令是std，二者均是用来操作方向标志位DF（Direction Flag）。
	;cld使DF 复位，即是让DF=0，std使DF置位，即DF=1.
	;通过执行cld或std指令可以控制方向标志DF，决定内存地址是增大（DF=0，向高地址增加）还是减小（DF=1，向地地址减小）。
	cld	
.1:	;不断循环,将esi地址段的内容放入显存,直到esi全0(一次两个Byte)
	lodsb
	test	al, al
	jz	.2
	mov	[gs:edi], ax
	add	edi, 2
	jmp	.1
.2:	; 显示完毕
	call	DispReturn

	; 测试调用门（无特权级变换），将打印字母 'C'，（利用门的选择子跳转，可以提权）
	call	SelectorCallGateTest:0
	;call	SelectorCodeDest:0				;（利用门目的段的选择子跳转，就是一个普通的call）

	; LDT表在GDT的选择子载入LDTR寄存器
	mov	ax, SelectorLDT
	lldt	ax

	jmp	SelectorLDTCodeA:0	; 利用LDT表中CodeA段的选择子，直接跳入局部任务

; 此函数用于打出回车段效果--------------------------------------------------------------
DispReturn:
	push	eax
	push	ebx
	mov	eax, edi
	mov	bl, 160
	div	bl
	and	eax, 0FFh
	inc	eax
	mov	bl, 160
	mul	bl
	mov	edi, eax
	pop	ebx
	pop	eax

	ret
; DispReturn 结束---------------------------------------------------------

SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]

[SECTION .sdest]; 调用门目标段
[BITS	32]

LABEL_SEG_CODE_DEST:
	;jmp	$
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子(目的)

	mov	edi, (80 * 12 + 0) * 2	; 屏幕第 12 行, 第 0 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'C'
	mov	[gs:edi], ax

	retf

SegCodeDestLen	equ	$ - LABEL_SEG_CODE_DEST
; END of [SECTION .sdest]


; 16 位代码段. 由 32 位代码段跳入, 跳出后到实模式
[SECTION .s16code]
ALIGN	32		;32位对齐 16进制代码
[BITS	16]
LABEL_SEG_CODE16:
	; 利用实模式代码段段选择子,跳回实模式:
	mov	ax, SelectorNormal
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax
	mov	ss, ax

	;回退控制寄存器cr0 的0位
	mov	eax, cr0
	and	al, 11111110b
	mov	cr0, eax

LABEL_GO_BACK_TO_REAL:
	jmp	0:LABEL_REAL_ENTRY	; 段地址会在程序开始处被设置成正确的值

Code16Len	equ	$ - LABEL_SEG_CODE16

; END of [SECTION .s16code]

; LDT 表段
[SECTION .ldt]
ALIGN	32
LABEL_LDT:
;                            段基址       段界限      属性
LABEL_LDT_DESC_CODEA: Descriptor 0, CodeALen - 1, DA_C + DA_32 ; Code, 32 位

LDTLen		equ	$ - LABEL_LDT

; LDT 选择子
SelectorLDTCodeA	equ	LABEL_LDT_DESC_CODEA	- LABEL_LDT + SA_TIL
; END of [SECTION .ldt]


; CodeA (LDT, 32 位代码段)
[SECTION .la]
ALIGN	32
[BITS	32]
LABEL_CODE_A:
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子(目的)

	mov	edi, (80 * 13 + 0) * 2	; 屏幕第 13 行, 第 0 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'L'
	mov	[gs:edi], ax

	; 准备经由16位代码段跳回实模式
	jmp	SelectorCode16:0
CodeALen	equ	$ - LABEL_CODE_A
; END of [SECTION .la]
