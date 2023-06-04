SRC:=boot.asm
BIN:=$(subst .asm,.com,$(SRC))

.PHONY : run
run : mount
	bochs -q

mount : $(BIN)
	sudo mkdir /mnt/floppy/
	sudo mount -o loop a.img /mnt/floppy/
	sudo cp $(BIN) /mnt/floppy/ -v
	sudo cp DEBUG32.EXE /mnt/floppy/ -v
	sudo umount /mnt/floppy/
	sudo rm -rf /mnt/floppy/

$(BIN) : image
	nasm code/boot.asm -o boot.com

image :
	gzip -cd a.img.gz > a.img
	gzip -cd freedos.img.gz > freedos.img

clean :
	rm -f *.img *.bin *.com
