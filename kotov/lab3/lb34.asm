TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100H
START: JMP BEGIN

; Данные
AVAILABLE_MEMORY db 0Dh,0Ah,'Available memory size: $'
EXTENDED_MEMORY db 0Dh,0Ah,'Extended memory size: $'
BYTES db ' bytes $'
MCB_TYPE db 'MCB  Type:   h  $'
ADRESS db 'Adress:     h  $'
OWNER_UNKNOWN db 'Owner:     h   $'
OWNER_FREE db 'Owner: Free    $'
OWNER_OSXMS db 'Owner: OS XMS UMD  $'
OWNER_DRIVER db 'Owner: High driver memory  $'
OWNER_MSDOS db 'Owner: MS DOS  $'
OWNER_BLOCKUMB db 'Owner: Occupied by 386MAX UMB  $'
OWNER_BLOCKED386 db 'Owner: Blocked by 386MAX  $'
OWNER_OWNED386MAX db 'Owner: 386MAX UMB  $'
AREA_SIZE db 'Area size: $'
SCSD db 'SC/SD: $'
ALLOCPROBLEM db 'There is not enough memory $' 
NEWLINE db 0Dh,0Ah,'$'

; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-----------------------------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;в AL старшая цифра
   pop CX ;в AH младшая
   ret
BYTE_TO_HEX ENDP
;-----------------------------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
   push BX
   mov BH,AH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   dec DI
   mov AL,BH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   pop BX
   ret
WRD_TO_HEX ENDP
;-----------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
   push CX
   push DX
   xor AH,AH
   xor DX,DX
   mov CX,10
loop_bd:
   div CX
   or DL,30h
   mov [SI],DL
   dec SI
   xor DX,DX
   cmp AX,10
   jae loop_bd
   cmp AL,00h
   je end_l
   or AL,30h
   mov [SI],AL
end_l:
   pop DX
   pop CX
   ret
BYTE_TO_DEC ENDP
;-------------------------------
PUTS PROC near
   push ax
   mov ah, 09h
   int 21h
   pop ax
   ret
PUTS ENDP
;-------------------------------
PUTC PROC
	mov dl, es:[di+8]
	mov ah, 02h
	int 21h
	inc di
	ret
PUTC ENDP
;-------------------------------
WRD_TO_DEC PROC
	xor cx, cx 
	mov bx, 10 
seq:
	mov si, ax 
	mov ax, dx 
	xor dx, dx
	div bx 
	mov di, ax 
	mov ax, si 
	div bx 
	push dx 
	inc cx 
	mov dx, di 
	push ax
	or ax, dx
	pop ax
	jnz seq
	
	mov ah, 02h
output:
	pop dx 
    add dl, '0' 
    int 21h
	loop output
	
	ret
WRD_TO_DEC ENDP
;-------------------------------
AVAILABLEMEMORYINFO PROC
	mov dx, offset AVAILABLE_MEMORY
    call PUTS 
	
	mov ah, 48h
	mov bx, 0ffffh
	int 21h
	mov ax, bx
	
	mov bx, 16
    mul bx
	call WRD_TO_DEC
	mov dx, offset BYTES
    call PUTS 
	
	ret
AVAILABLEMEMORYINFO ENDP
;-------------------------------
EXTENDEDMEMORYINFO PROC
	mov dx, offset EXTENDED_MEMORY
    call PUTS 
	
	mov al, 31h
    out 70h, al
    in al, 71h
    mov ah, al
    mov al, 30h
    out 70h, al
    in al, 71h

    mov bx, 1024
    mul bx
	call WRD_TO_DEC
	mov dx, offset BYTES
    call PUTS
	
	ret
EXTENDEDMEMORYINFO ENDP
;-------------------------------
BLOCKLISTINFO PROC
	mov ah, 52h
	int 21h
	mov ax, es:[bx-2]
	mov es, ax
	xor cx, cx
	inc cx
block_info:
	mov dx, offset NEWLINE
    call PUTS

	mov al, es:[0]
	
	mov bx, offset MCB_TYPE
	add bx, 11

	call BYTE_TO_HEX
	mov [bx], ax

	lea dx, MCB_TYPE

	call PUTS

	mov al, cl
	push cx
	mov ax, es

	lea di, ADRESS
	add di, 11
	call WRD_TO_HEX
	lea dx, ADRESS
	call PUTS

	xor ah, ah
	mov al, es:[0]
	push ax
	mov ax, es:[1]
	
	cmp ax, 0000h
	je free

	cmp ax, 0006h
	je xms

	cmp ax, 0007h
	je highdriver
	
	cmp ax, 0008h
	je dos
	
	cmp ax, 0FFFAh
	je max386
	
	cmp ax, 0FFFDh
	je blocked

	cmp ax, 0FFF3h	
	je umb
	
	lea di, OWNER_UNKNOWN
	add di, 10
	call WRD_TO_HEX
	lea dx, OWNER_UNKNOWN
	jmp print
	
free:
	lea dx, OWNER_FREE
	jmp print
	
xms:
	lea dx, OWNER_OSXMS
	jmp print
	
highdriver:
	lea dx, OWNER_DRIVER
	jmp print
	
dos:
	lea dx, OWNER_MSDOS
	jmp print
		
max386:
	lea dx, OWNER_BLOCKUMB
	jmp print
	
blocked:
	lea dx, OWNER_BLOCKED386
	jmp print
	
umb:
	lea dx, OWNER_OWNED386MAX
	
print:
	call PUTS

	mov ax, es:[3]	
	mov dx, offset AREA_SIZE
	call PUTS
	
	mov bx, 16
    mul bx
	call WRD_TO_DEC
	mov dx, offset BYTES
    call PUTS 
	mov dx, offset NEWLINE
    call PUTS 
	
	xor dx, dx
	lea dx , SCSD 
	call PUTS
	mov cx, 8
	xor di, di
   
scsd_info:
	call PUTC
	loop scsd_info
	
	mov ax, es:[3]	
	mov bx, es
	add bx, ax
	inc bx
	mov es,bx
	pop ax
	pop cx
	inc cx
	cmp al, 5Ah
	je last
	jmp block_info

last:
	mov dx, offset NEWLINE
    call PUTS

	ret
BLOCKLISTINFO ENDP
;-------------------------------

; Код
BEGIN:
    mov bx, 4096
	mov ah, 48h
	int 21h
	jnc no_problem
	mov dx, offset ALLOCPROBLEM
	mov ah, 09h
	int 21h

no_problem:
	call AVAILABLEMEMORYINFO
	call EXTENDEDMEMORYINFO
	call BLOCKLISTINFO
	
	xor AL,AL
	mov AH,4Ch
	int 21h
TESTPC ENDS
END START