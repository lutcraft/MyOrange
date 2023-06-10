BOOT:=code/boot.asm
LDR:=code/loader.asm
KERNEL:=code/kernel.asm
BOOT_BIN:=boot.bin
LDR_BIN:=loader.bin
KERNEL_BIN:=kernel.bin

IMG:=a.img
FLOPPY:=/mnt/floppy/

.PHONY : everything

everything : $(BOOT_BIN) $(LDR_BIN) $(KERNEL_BIN) image
	dd if=$(BOOT_BIN) of=$(IMG) bs=512 count=1 conv=notrunc
	# sudo mkdir $(FLOPPY)
	sudo mount -o loop a.img $(FLOPPY)
	sudo cp $(LDR_BIN) $(FLOPPY) -v
	sudo cp $(KERNEL_BIN) $(FLOPPY) -v
	sudo umount $(FLOPPY)
	# sudo rm -rf $(FLOPPY)
	bochs -q

$(BOOT_BIN) : $(BOOT)
	nasm $< -o $@

$(LDR_BIN) : $(LDR)
	nasm $< -o $@

$(KERNEL_BIN) : $(KERNEL)
	nasm -f elf -o $(subst .asm,.o,$(KERNEL)) $<
	ld -Ttext 0x30400 -m elf_i386 -s -o $@ $(subst .asm,.o,$(KERNEL))

image :
	gzip -cd a.img.gz > a.img
	# gzip -cd freedos.img.gz > freedos.img

clean :
	rm -f $(BOOT_BIN) $(LDR_BIN) $(KERNEL_BIN) code/*.o
	rm -f *.img *.bin *.com
	sudo umount $(FLOPPY)
	# sudo rm -rf $(FLOPPY)
