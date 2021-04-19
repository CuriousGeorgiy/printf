.PHONY: all clean

all: printf

printf: printf.o
	ld -m elf_i386 -o $@ $^

printf.o: printf.s
	nasm -f elf -F dwarf -o $@ $<

clean:
	rm -f printf *.o
