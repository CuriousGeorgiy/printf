.PHONY: all clean

all: printf

printf: main.o printf.o
	gcc -m32 -no-pie -o $@ $^

main.o: main.c
	gcc -gdwarf -m32 -fno-plt -fno-pie -c -o $@ $<

printf.o: printf.s
	nasm -f elf -F dwarf -o $@ $<

clean:
	rm -f printf *.o
