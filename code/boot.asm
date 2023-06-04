; ==========================================
; 编译方法：nasm boot.asm -o boot.bin

; 注意80386 cpu采用小端字节序！
; ==========================================
%include	"GDTHead.inc"	; 常量, 宏, 以及一些说明

	org	07c00h			; 给定程序起始地址
		jmp	LABEL_BEGIN				;07c04
[SECTION .gdt]			;GDT 全局描述符段
;0x7c04
;                              段基址,       段界限     , 属性
LABEL_GDT:	   Descriptor       0,                0, 0           ; 空描述符 ;07c0c
;0x7c0c
LABEL_DESC_CODE32: Descriptor       0, SegCode32Len - 1, DA_C + DA_32; 非一致代码段
;0x0714
LABEL_DESC_VIDEO:  Descriptor 0B8000h,           0ffffh, DA_DRW	     ; 显存段 

;GDT相关描述信息
GdtLen		equ	$ - LABEL_GDT	; GDT长度 不占空间，如同立即数

;0x071c
;GDT寄存器
GdtPtr		dw	GdtLen - 1	; GDT界限 24-1			此结构6个字节 48位，和gdtr一样大
		dd	0		; GDT基地址
;071f

; GDT 选择子 相当与GDT表的index，描述了某个GDT记录向GDT开始的偏移
SelectorCode32		equ	LABEL_DESC_CODE32	- LABEL_GDT			;偏移 8,没有权限变化时，这样就可以了
SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT			;偏移 16,没有权限变化时，这样就可以了


[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov	ax, cs			;清零ds es ，cs已经为0
	mov	ds, ax
	mov	es, ax
	mov	ss, ax			;清零，初始化堆栈
	mov	sp, 0100h			;堆栈寄存器赋值，这个时候用print-stack将看到堆栈头在0x0100
	; 初始化 32 位代码段描述符 LABEL_DESC_CODE32 的段基地址
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32		;放入段基地址
	mov	word [LABEL_DESC_CODE32 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
;7c48
	mov	byte [LABEL_DESC_CODE32 + 7], ah

;7c4c
	; 维护GdtPtr
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt 基地址
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt 基地址
	; 加载 GdtPtr到GDTR
	lgdt	[GdtPtr]		;gdtr:base=0x0000000000007c04, limit=0x17
	; 关中断
	cli

	; 打开地址线A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; 控制寄存器cr0的0位置1，CPU调整到保护模式
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; 切换cs：ip开始执行保护模式32位代码
	jmp	dword SelectorCode32:0

[SECTION .s32]; 32 位代码段. 由实模式跳入.
[BITS	32]
;0x7c80
LABEL_SEG_CODE32:
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子

	mov	edi, (80 * 11 + 79) * 2	; 屏幕第 11 行, 第 79 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'P'
	;32位保护模式使用 选择子：偏移 的方式进行寻址
	;此处直接向显存写入P
	mov	[gs:edi], ax

	; 到此停止
	jmp	$
SegCode32Len	equ	$ - LABEL_SEG_CODE32	;值15
;没有0xaa55因为我们复用了之前的软盘镜像a.img，这个镜像已经被做成了可引导的。
