bits 32

$dword equ 4

sys_exit equ 01h

syscall_int equ 80h

section .text

extern printf

global _start

_start:
	; prolog
	push 33
	push 1488
	push 3802
	push string1
	push string2
	push 33
	push 100
	push 3802
	push string1
	push format_string
	; prolog
	call printf
	; epilog
	add esp, $dword * 10
	; epilog

	mov eax, sys_exit
	xor ebx, ebx
    int syscall_int
ret

format_string: db 'I %s %x %d %% %c %s, but I %s %x %d %% %c', 0Ah, 0
string1: db 'love', 0
string2: db 'MEOW', 0
