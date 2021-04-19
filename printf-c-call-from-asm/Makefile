.PHONY: all clean

all: printf

printf: printf.o
	gcc -no-pie -m32 -nostartfiles -o $@ $^

printf.o: printf.s
	nasm -f elf -F dwarf -o $@ $^

clean:
	rm -f printf *.o
