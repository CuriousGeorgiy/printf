bits 32

$byte  equ 1
$word  equ 2
$dword equ 4

sys_exit     equ 01h
sys_write    equ 04h

syscall_int equ 80h

stdout equ 1

null equ 0

bits_in_byte equ 8

section .text

global _start

_start:
	; prolog
	push 255
	push 33
	push 1488
	push 3802
	push string1
	push string2
	push 255
	push 33
	push 100
	push 3802
	push string1
	push format_string
	; prolog
	call printf
	; epilog
	add esp, $dword * 12
	; epilog

	mov eax, sys_exit
	xor ebx, ebx
    int syscall_int
ret

;----------------------------------------------------------------------------------------------------------------------
; Input:     1 <- format string offset, ... <- format string arguments
; Output:    none
; Destroyed: ax, bx, cx, si, di
;----------------------------------------------------------------------------------------------------------------------
printf:
	push ebp
	mov ebp, esp

	mov edi, [ebp + $dword * (1 + 1)]
	xor ebx, ebx
	mov esi, $dword * (1 + 2)

analyze_format_string:
	cmp byte [buffer_size], buffer_capacity

	jb continue_bufferizing

	; prolog
	push ebx
	; prolog
	call flush_buffer
	; epilog
	pop ebx
	; epilog

continue_bufferizing:
	cmp byte [edi + ebx], null
	je finish_analyzing_format_string

	cmp byte [edi + ebx], '%'
	je analyze_format_specificator

	mov dl, [edi + ebx]
	push ebx
	mov ebx, buffer
	add bl, byte [buffer_size]
	adc ebx, 0
	mov [ebx], dl
	inc byte [buffer_size]
	pop ebx

	jmp finish_analyzing_char

analyze_format_specificator:
	inc ebx

	movzx edx, byte [edi + ebx]
	imul edx, $byte + $dword
	add edx, jump_table
	jmp edx

print_procent_char:
	push ebx
	mov ebx, buffer
	add bl, byte [buffer_size]
	adc ebx, 0
	mov byte [ebx], '%'
	inc byte [buffer_size]
	pop ebx

	jmp finish_analyzing_char

print_char:
	mov dl, [ebp + esi]

	push ebx
	mov ebx, buffer
	add bl, byte [buffer_size]
	adc ebx, 0
	mov [ebx], dl
	inc byte [buffer_size]
	pop ebx

	jmp finish_analyzing_format_specificator

print_str:
	; prolog
	push edi
	push esi
	push ebx
	push eax

	push dword [ebp + esi]
	; prolog
	call print_str_bufferized
	; epilog
	add esp, $dword

	pop eax
	pop ebx
	pop esi
	pop edi
	; epilog

	jmp finish_analyzing_format_specificator

print_decimal:
	push edi
	push esi
	push ebx
	push eax

	; prolog
	push dword [ebp + esi]
	; prolog
	call convert_to_decimal
	; epilog
	add esp, $dword
	; epilog

	; prolog
	push conversion_result
	; prolog
	call print_str_bufferized
	; epilog
	add esp, $dword
	; epilog

	pop eax 
	pop ebx
	pop esi
	pop edi
	jmp finish_analyzing_format_specificator

print_binary:
	push edi 
	push esi 
	push ebx
	push eax

	; prolog
	push 1
	push 1
	push dword [ebp + esi]
	; prolog
	call convert_to_power_of_two
	; epilog
	add esp, $dword * 3
	; epilog

	; prolog
	push conversion_result
	; prolog
	call print_str_bufferized
	; epilog
	add esp, $dword
	; epilog

	pop eax 
	pop ebx
	pop esi
	pop edi
	jmp finish_analyzing_format_specificator

print_octal:
	push edi 
	push esi
	push ebx
	push eax

	; prolog
	push 7
	push 3
	push dword [ebp + esi]
	; prolog
	call convert_to_power_of_two
	; epilog
	add esp, $dword * 3
	; epilog

	; prolog
	push conversion_result
	; prolog
	call print_str_bufferized
	; epilog
	add esp, $dword
	; epilog

	pop eax 
	pop ebx
	pop esi
	pop edi
	jmp finish_analyzing_format_specificator

print_hex:
	push edi
	push esi
	push ebx
	push eax

	; prolog
	push 0Fh
	push 4
	push dword [ebp + esi]
	; prolog
	call convert_to_power_of_two
	; epilog
	add esp, $dword * 3
	; epilog

	; prolog
	push conversion_result
	; prolog
	call print_str_bufferized
	; epilog
	add esp, $dword
	; epilog

	pop eax 
	pop ebx
	pop esi
	pop edi
	jmp finish_analyzing_format_specificator

finish_analyzing_format_specificator:
	add esi, $dword

finish_analyzing_char:
	inc ebx
	jmp analyze_format_string

finish_analyzing_format_string:
	cmp byte [buffer_size], 0
	je return

	; prolog
	call flush_buffer
	; epilog

return:
	pop ebp
ret

;----------------------------------------------------------------------------------------------------------------------
; Input:     buffer <- string to display, buffer_size <- current size of buffer
; Output:    none
; Destroyed: ax, bx, cx, dx
;----------------------------------------------------------------------------------------------------------------------
flush_buffer:
	mov eax, sys_write
	mov ebx, stdout
	mov ecx, buffer
	movzx edx, byte [buffer_size]
    int syscall_int

	mov byte [buffer_size], 0
ret

;----------------------------------------------------------------------------------------------------------------------
; Input:     1 <- string to print
; Output:    none
; Destroyed: ax, bx, cx, dx, si, di
;----------------------------------------------------------------------------------------------------------------------
print_str_bufferized:
	push ebp
	mov ebp, esp

	; prolog
	push dword [ebp + $dword * (1 + 1)]
	; prolog
	call strlen
	; epilog
	pop esi
	; epilog

	mov ecx, eax
	add cl, byte [buffer_size]
	adc ecx, 0
	cmp ecx, buffer_capacity

	jbe bufferize_str

print_while_cannot_fit_in_buffer:
	mov ecx, buffer_capacity
	movzx edx, byte[buffer_size]
	sub ecx, edx

	mov edi, buffer
	add edi, edx
	mov byte [buffer_size], buffer_capacity

	cld
	rep movsb

	; prolog
	push eax
	; prolog
	call flush_buffer
	; epilog	
	pop eax
	; epilog

	mov ecx, [ebp + $dword * (1 + 1)]
	add ecx, eax
	sub ecx, esi
	
	cmp ecx, buffer_capacity
	jbe bufferize_str
	
	jmp print_while_cannot_fit_in_buffer

bufferize_str:
	mov ecx, [ebp + $dword * (1 + 1)]
	add ecx, eax
	sub ecx, esi

	mov edi, buffer
	movzx edx, byte [buffer_size]
	add edi, edx
	add byte [buffer_size], cl

	cld
	rep movsb
	
	pop ebp
ret

;----------------------------------------------------------------------------------------------------------------------
; Input:     1 <- input string offset
; Output:    ax <- input string length
; Destroyed: cx, di
;----------------------------------------------------------------------------------------------------------------------
strlen:
	push ebp
	mov ebp, esp

	mov edi, [ebp + $dword * (1 + 1)]
	xor eax, eax
	xor ecx, ecx
	not ecx

	cld
	repne scasb

	not ecx
	dec ecx
	mov eax, ecx

	pop ebp
ret

;----------------------------------------------------------------------------------------------------------------------
; Input:     1 <- number
; Output:    conversion_result <- number converted to decimal (string)
; Destroyed: ax, bx, cx, dx, si, di
;----------------------------------------------------------------------------------------------------------------------
convert_to_decimal:
	push ebp
	mov ebp, esp

    xor edx, edx
	mov eax, [ebp + $dword * (1 + 1)]
	mov ebx, 10
	mov edi, $word * bits_in_byte - 1
convert_decimal_digit:
	div ebx
	add edx, '0'
	mov byte [conversion_result + edi], dl

	cmp eax, 0
	je end_decimal_digit_conversion

	xor edx, edx
	dec edi
	jmp convert_decimal_digit
end_decimal_digit_conversion:
    mov ecx, edi
    jcxz no_leading_decimal_zeros

	; prolog
	push edi
	; prolog
	call omit_leading_zeros
	; epilog
	add esp, $dword
	; epilog

no_leading_decimal_zeros:
	pop ebp
ret

;----------------------------------------------------------------------------------------------------------------------
; Input:     1 <- number, 2 <- base (power of two), 3 <- bit mask (2^(power_of_two) - 1)
; Output:    conversion_result <- number converted to binary (string)
; Destroyed: ax, bx, cx, si, di
;----------------------------------------------------------------------------------------------------------------------
convert_to_power_of_two:
	push ebp
	mov ebp, esp

	mov eax, [ebp + $dword * (1 + 1)]
	mov cl, [ebp + $dword * (1 + 2)]
    mov edi, $word * bits_in_byte - 1
convert_digit:
	mov ebx, [ebp + $dword * (1 + 3)]
	and ebx, eax
	shr ax, cl
	mov dl, [hex_digits + ebx]
	mov byte [conversion_result + edi], dl

	cmp eax, 0
	je end_digit_conversion

	dec edi
	jmp convert_digit
end_digit_conversion:
    mov ecx, edi
    jcxz no_leading_zeros

	; prolog
    push edi
    ; prolog
    call omit_leading_zeros
    ; epilog
    add esp, $dword
	; epilog

no_leading_zeros:
	pop ebp
ret

;----------------------------------------------------------------------------------------------------------------------
; Input:     1 <- offset to first significant digit
; Output:    conversion_result <- number without leading zeros
; Destroyed: bx, cx, si, di
;----------------------------------------------------------------------------------------------------------------------
omit_leading_zeros:
	push ebp
	mov ebp, esp

	mov ecx, $word * bits_in_byte + 1
	mov ebx, [ebp + $dword * (1 + 1)]
	sub ecx, ebx
	lea esi, [conversion_result + ebx]
	mov edi, conversion_result

	cld
	rep movsb

	pop ebp
ret

section .data

hex_digits: db '0123456789ABCDEF'
conversion_result_len equ $word * bits_in_byte + 1
conversion_result: times conversion_result_len db 0

buffer_capacity equ 16
buffer: times buffer_capacity db 0
buffer_size: db 0

jump_table:
times '%' jmp finish_analyzing_format_string

jmp print_procent_char

times 'b' - '%' - 1 jmp finish_analyzing_format_string

jmp print_binary

jmp print_char

jmp print_decimal

times 'o' - 'd' - 1 jmp finish_analyzing_format_string

jmp print_octal

times 's' - 'o' - 1 jmp finish_analyzing_format_string

jmp print_str

times 'x' - 's' - 1 jmp finish_analyzing_format_string

jmp print_hex

times 255 - 'x' jmp finish_analyzing_format_string

format_string: db 'I %s %x %d %% %c %b %s, but I %s %x %d %% %c %b', 0Ah, 0
string1: db 'love', 0
string2: db 'MEOW', 0
