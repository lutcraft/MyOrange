BOOT:=code/boot.asm
LDR:=code/loader.asm
BOOT_BIN:=boot.bin
LDR_BIN:=loader.bin
FLOPPY:=/mnt/floppy/


.PHONY : everything

everything : $(BOOT_BIN) $(LDR_BIN)
	dd if=boot.bin of=a.img bs=512 count=1 conv=notrunc
	# sudo mkdir $(FLOPPY)
	sudo mount -o loop a.img $(FLOPPY)
	sudo cp $(LDR_BIN) $(FLOPPY) -v
	sudo umount $(FLOPPY)
	# sudo rm -rf $(FLOPPY)
	bochs -q

$(BOOT_BIN) : $(BOOT)
	nasm code/boot.asm -o boot.bin

$(LDR_BIN) : $(LDR)
	nasm code/loader.asm -o loader.bin

image :
	gzip -cd a.img.gz > a.img
	gzip -cd freedos.img.gz > freedos.img

clean :
	rm -f *.img *.bin *.com
	sudo umount $(FLOPPY)
	# sudo rm -rf $(FLOPPY)
