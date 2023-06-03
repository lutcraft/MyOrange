	org	07c00h			; 给定程序起始地址
	mov	ax, cs			;清零ds es ，cs已经为0
	mov	ds, ax
	mov	es, ax
	call	DispStr			; let's display a string
	jmp	$			; and loop forever
DispStr:			; 利用bios中断打印字符
	mov	ax, BootMessage
	mov	bp, ax			; ES:BP = string address
	mov	cx, 16			; CX = string length
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 000ch		; RED/BLACK
	mov	dl, 0
	int	10h
	ret
BootMessage:		db	"Hello, OS world!"	;别数了，strlen=16
times 	510-($-$$)	db	0	; fill zeros to make it exactly 512 bytes
;7dfd 因为是小端存储，所以实际存的是55aa
dw 	0xaa55				; boot record signature
