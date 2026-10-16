; sudo apt update
; sudo apt install -y nasm gcc gcc-multilib libc6-dev-i386
; nasm -f elf32 labexer1.asm -o labexer1.o
; ld -m elf_i386 labexer1.o -o labexer1
; ./labexer1

section .data
    menu        db  "----------------------------------", 10
                db  "MENU", 10
                db  "[A]dd", 10
                db  "[S]ubtract", 10
                db  "[M]ultiply", 10
                db  "[D]ivide", 10
                db  "----------------------------------", 10
                db  "Enter your choice: "
    menu_len    equ $ - menu

    first_msg   db  "Enter first number: "
    first_len   equ $ - first_msg
    second_msg  db  "Enter second number: "
    second_len  equ $ - second_msg
    sum_msg     db  "The sum is "
    sum_len     equ $ - sum_msg
    diff_msg    db  "The difference is "
    diff_len    equ $ - diff_msg
    prod_msg    db  "The product is "
    prod_len    equ $ - prod_msg
    quot_msg    db  "The quotient is "
    quot_len    equ $ - quot_msg
    remainder_msg db " The remainder is "
    remainder_len equ $ - remainder_msg
    again_msg   db  10, "Do you want to try again (Y/N): "
    again_len   equ $ - again_msg
    invalid_msg db  "Invalid choice. Please select A, S, M, or D.", 10
    invalid_len equ $ - invalid_msg
    zero_msg    db  "Cannot divide by zero.", 10
    zero_len    equ $ - zero_msg
    newline     db  10

section .bss
    input       resb 64
    number_buf  resb 16
    first_num   resd 1
    second_num  resd 1
    result      resd 1

section .text
    global _start

_start:
menu_loop:
    call clear_screen
    mov ecx, menu
    mov edx, menu_len
    call print

    call read_line
    mov al, [input]
    or al, 00100000b       ; accept lowercase input as well

    cmp al, 'a'
    je  do_add
    cmp al, 's'
    je  do_subtract
    cmp al, 'm'
    je  do_multiply
    cmp al, 'd'
    je  do_divide

    mov ecx, invalid_msg
    mov edx, invalid_len
    call print
    jmp ask_again

do_add:
    call get_two_numbers
    mov eax, [first_num]
    add eax, [second_num]
    mov [result], eax
    mov ecx, sum_msg
    mov edx, sum_len
    call print
    jmp show_result

do_subtract:
    call get_two_numbers
    mov eax, [first_num]
    sub eax, [second_num]
    mov [result], eax
    mov ecx, diff_msg
    mov edx, diff_len
    call print
    jmp show_result

do_multiply:
    call get_two_numbers
    mov eax, [first_num]
    imul eax, [second_num]
    mov [result], eax
    mov ecx, prod_msg
    mov edx, prod_len
    call print
    jmp show_result

do_divide:
    call get_two_numbers
    cmp dword [second_num], 0
    je  divide_by_zero

    mov eax, [first_num]
    xor edx, edx
    div dword [second_num]
    mov [result], eax
    push edx                 ; save remainder while quotient is printed
    mov ecx, quot_msg
    mov edx, quot_len
    call print
    mov eax, [result]
    call print_signed
    mov ecx, remainder_msg
    mov edx, remainder_len
    call print
    pop eax
    call print_unsigned
    call print_newline
    jmp ask_again

divide_by_zero:
    mov ecx, zero_msg
    mov edx, zero_len
    call print
    jmp ask_again

show_result:
    mov eax, [result]
    call print_signed
    call print_newline

ask_again:
    mov ecx, again_msg
    mov edx, again_len
    call print
    call read_line
    mov al, [input]
    or al, 00100000b
    cmp al, 'y'
    je  menu_loop

    mov eax, 1              ; sys_exit
    xor ebx, ebx
    int 0x80

; Reads one line into input and terminates it with a zero byte.
read_line:
    mov eax, 3              ; sys_read
    xor ebx, ebx            ; stdin
    mov ecx, input
    mov edx, 63
    int 0x80
    mov esi, input
    add esi, eax
    mov byte [esi], 0
    ret

; Prompts for two unsigned numbers (0 through 99 in normal use).
get_two_numbers:
    mov ecx, first_msg
    mov edx, first_len
    call print
    call read_line
    call parse_unsigned
    mov [first_num], eax

    mov ecx, second_msg
    mov edx, second_len
    call print
    call read_line
    call parse_unsigned
    mov [second_num], eax
    ret

; Converts decimal ASCII in input to an unsigned integer in EAX.
parse_unsigned:
    xor eax, eax
    xor esi, esi
.parse_loop:
    mov bl, [input + esi]
    cmp bl, 0
    je  .done
    cmp bl, '0'
    jb  .done
    cmp bl, '9'
    ja  .done
    imul eax, eax, 10
    sub bl, '0'
    movzx ebx, bl
    add eax, ebx
    inc esi
    jmp .parse_loop
.done:
    ret

print_signed:
    test eax, eax
    jns print_unsigned
    push eax
    mov byte [number_buf], '-'
    mov ecx, number_buf
    mov edx, 1
    call print
    pop eax
    neg eax

print_unsigned:
    mov edi, number_buf + 15
    mov byte [edi], 0
    mov ebx, 10
.convert:
    xor edx, edx
    div ebx
    add dl, '0'
    dec edi
    mov [edi], dl
    test eax, eax
    jnz .convert
    mov ecx, edi
    mov edx, number_buf + 15
    sub edx, edi
    call print
    ret

print_newline:
    mov ecx, newline
    mov edx, 1
    jmp print

print:
    push eax
    push ebx
    push ecx
    push edx
    mov eax, 4              ; sys_write
    mov ebx, 1              ; stdout
    int 0x80
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

clear_screen:
    ; ANSI escape sequence: clear terminal and move cursor home.
    mov ecx, clear_code
    mov edx, clear_len
    jmp print

section .rodata
    clear_code db 27, "[2J", 27, "[H"
    clear_len  equ $ - clear_code
