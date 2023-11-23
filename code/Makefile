# Entry point of Orange'S
# It must have the same value with 'KernelEntryPointPhyAddr' in load.inc!
ENTRYPOINT	= 0x30400

# Offset of entry point in kernel file
# It depends on ENTRYPOINT
ENTRYOFFSET	=   0x400

# Programs, flags, etc.
ASM		= nasm
DASM		= ndisasm
CC		= gcc
LD		= ld
ASMBFLAGS	= -I boot/include/
ASMKFLAGS	= -I include/ -f elf
CFLAGS		= -I include/ -c -fno-builtin -m32
LDFLAGS		= -s -Ttext $(ENTRYPOINT) -m elf_i386  -s
DASMFLAGS	= -u -o $(ENTRYPOINT) -e $(ENTRYOFFSET)

# This Program
ORANGESBOOT	= boot/boot.bin boot/loader.bin
ORANGESKERNEL	= kernel.bin
OBJS		= kernel/kernel.o kernel/start.o lib/kliba.o lib/string.o
DASMOUTPUT	= kernel.bin.asm


BOOT_BIN:=boot/boot.bin
IMG:=../a.img
FLOPPY:=/mnt/floppy/

# All Phony Targets
.PHONY : everything final image clean realclean disasm all buildimg

# Default starting position
everything : $(ORANGESBOOT) $(ORANGESKERNEL)

all : realclean everything

final : all clean

image : final buildimg

clean :
	rm -f $(OBJS)

realclean :
	rm -f $(OBJS) $(ORANGESBOOT) $(ORANGESKERNEL)
	rm -f ../*.img

disasm :
	$(DASM) $(DASMFLAGS) $(ORANGESKERNEL) > $(DASMOUTPUT)

prebuildimage :
	gzip -cd ../a.img.gz > ../a.img

# We assume that "a.img" exists in current folder
buildimg : prebuildimage
	dd if=$(BOOT_BIN) of=$(IMG) bs=512 count=1 conv=notrunc
	# sudo mkdir $(FLOPPY)
	sudo mount -o loop $(IMG) $(FLOPPY)
	sudo cp boot/loader.bin $(FLOPPY) -v
	sudo cp kernel.bin $(FLOPPY) -v
	sudo umount $(FLOPPY)
	# sudo rm -rf $(FLOPPY)
	# bochs -q -f ../bochsrc

boot/boot.bin : boot/boot.asm boot/include/load.inc boot/include/fat12hdr.inc
	$(ASM) $(ASMBFLAGS) -o $@ $<

boot/loader.bin : boot/loader.asm boot/include/load.inc \
			boot/include/fat12hdr.inc boot/include/fat12hdr.inc
	$(ASM) $(ASMBFLAGS) -o $@ $<

$(ORANGESKERNEL) : $(OBJS)
	$(LD) $(LDFLAGS) -o $(ORANGESKERNEL) $(OBJS)

kernel/kernel.o : kernel/kernel.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

kernel/start.o : kernel/start.c include/type.h include/const.h include/protect.h
	$(CC) $(CFLAGS) -o $@ $<

lib/kliba.o : lib/kliba.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

lib/string.o : lib/string.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<




# .PHONY : everything

# everything : $(BOOT_BIN) $(LDR_BIN) $(KERNEL_BIN) image


# $(BOOT_BIN) : $(BOOT)
# 	nasm $< -o $@

# $(LDR_BIN) : $(LDR)
# 	nasm $< -o $@

# $(KERNEL_BIN) : $(KERNEL) code/start.c code/string.asm
# 	nasm -f elf -o $(subst .asm,.o,$(KERNEL)) $<
# 	nasm -f elf -o string.o code/string.asm
# 	nasm -f elf -o kliba.o code/kliba.asm
# 	gcc -m32 -c -fno-builtin -o start.o  code/start.c
# 	ld -Ttext 0x30400 -m elf_i386 -s -o $@ $(subst .asm,.o,$(KERNEL)) string.o start.o kliba.o

# image :
# 	gzip -cd a.img.gz > a.img
# 	# gzip -cd freedos.img.gz > freedos.img

# clean :
# 	rm -f $(BOOT_BIN) $(LDR_BIN) $(KERNEL_BIN) code/*.o
# 	rm -f *.img *.bin *.com *.o
# 	sudo umount $(FLOPPY)
# 	# sudo rm -rf $(FLOPPY)
