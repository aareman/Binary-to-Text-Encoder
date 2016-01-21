;	Avraham Areman
;	Final Project, Binary to text Converter
;	Date: 12/07/15 
;
;Log:
;implement ascii85 algorithm
;implement ynet algorithm (optional)
;include readme.txt
;model tiny
jumps
.286    
assume cs:cseg, ds:cseg
cseg segment 'code'
org 100h;	com file header
start:
                                                                   
    jmp realStart
    
    b db ?
    inhandle dw ?
    outhandle dw ?
    ;inname db "try.txt",0
    ;outname db "copy2.txt",0 
	inname db 255 dup(?)
	outname db 255 dup(?)
;for e64
    inb db 3 dup(?)
    outb db 4 dup(?)
;for d64
	inb1 db 4 dup(?)
    outb1 db 3 dup(?)
;for e85
	inb2 db 4 dup(?)
	outb2 db 5 dup(?)
;for d85
	inb3 db 5 dup(?)
	outb3 db 4 dup(?)
;for ascii85 division
	b32a db 4 (?)
	b32b db 4 (?)

	command db 4 dup(?)
	
	switch db 1 dup(?)
	padder db 1 dup(0)
	
	help db "-[e/d|64/85] [Input Filename] [Output Filename]",13,10,"$"
	error1 db "Error: No Output File Specified.",13,10,"$"
	error2 db "Error: No Input File Specified.",13,10,"$"
	error3 db "Error: Invalid switch options used.",13,10,"$"
	error4 db "Error: Input file does not exist.",13,10,"$"
	
	closing db "Program Finished.",13,10,"$"
     
realStart: 
;check commandline input

cld    ;critical
mov si,81h
Loop1:
	
	lodsb
	cmp al,13
	jz Help1
	cmp al,' '
	jbe Loop1
	
mov di,offset command
Loop2:
	stosb
	lodsb
	cmp al,' '
	ja Loop2
	
	cmp al,13
	jz Err2
	
	sub al,al
	stosb
Loop3:
	;mov si,81h
	lodsb
	cmp al,13
	jz Err2
	cmp al,' '
	jbe Loop3
mov di,offset inname
Loop4:
	stosb
	lodsb
	cmp al,' '
	ja Loop4
	
	cmp al,13
	jz Err1
	
	sub al,al
	stosb
Loop5:
	;mov si,81h
	lodsb
	cmp al,13
	jz Err1
	cmp al,' '
	jbe Loop5
mov di,offset outname
Loop6:
	stosb
	lodsb
	cmp al,13
	jz commandCheckpoint1
	cmp al,' '
	ja Loop6	
	
	sub al,al
	stosb

commandCheckpoint1:

;now check for valid switch input
; mov al, command[0]
; cmp al,96h
; jne Err3
mov al,command[1]
cmp al,"e"
je Encrypt
cmp al,"E"
je Encrypt
cmp al,"d"
je Decrypt
cmp al,"D"
je Decrypt

Encrypt:
	mov al, command[2]
	cmp al,"6"
	je Ebase64a
	cmp al,"8"
	je Eascii85a
	jmp Err3
Decrypt:
	mov al, command[2]
	cmp al,"6"
	je Dbase64a
	cmp al,"8"
	je Dascii85a
	jmp Err3
Ebase64a:
	mov al, command[3]
	cmp al,"4"
	je Ebase64b
	jmp Err3
Dbase64a:
	mov al, command[3]
	cmp al,"4"
	je Dbase64b
	jmp Err3
Eascii85a:
	mov al, command[3]
	cmp al,"5"
	je Eascii85b
	jmp Err3
Dascii85a:
	mov al, command[3]
	cmp al,"5"
	je Dascii85b
	jmp Err3
Ebase64b:
	mov switch[0],0
	jmp BeginRead
Dbase64b:
	mov switch[0],1
	jmp BeginRead
Eascii85b:
	mov switch[0],2
	jmp BeginRead
Dascii85b:
	mov switch[0],3

BeginRead:
;--insert code--

   ;open
   mov ax,3d00h
   mov dx, offset inname
   int 21h
   jc Err4
   mov inhandle, ax
   
   ;create output file
   mov ah, 3ch
   mov cx,0
   mov dx,offset outname
   int 21h
   jc Exit
   mov outhandle, ax
 
;USE SWITCH TO DETERMINE SWITCH ALGORITHM TO USE 
mov al, switch[0]
cmp al, 0
je E64
cmp al,1
je D64
cmp al,2
je E85
cmp al,3
je D85
jmp Err1

;----------------------------
;         EBase64 
;----------------------------
E64:
   readwrloop:
   ;read 3 bytes
    mov ah,3fh
    mov bx, inhandle
    mov cx,3
    mov dx,offset inb
    int 21h
        or ax,ax
        jz Exit   
        
;padding logic    
    cmp ax,3
    je continue
    cmp ax,2
    je pad1
    cmp ax,1
    je pad2      
     
	jmp continue
pad1:
    mov inb[2],122
    jmp continue
pad2:
    mov inb[1],122
    mov inb[2],122
    jmp continue         
         
continue:

;end of padding logic        
   ;3 to 4 byte conversion
s1:
    mov al,inb[0]
    shr al,2
    add al,'!'
    mov outb[0],al
s2:
    mov al, inb[0]
    mov ah,inb[1]
    and al,3
    shl al,4
    shr ah,4
    or al,ah
    add al,'!'
    mov outb[1],al
    
s3:
    mov al, inb[1]
    mov ah,inb[2]
    and al,15
    shl al,2
    shr ah,6
    or al,ah 
    add al,'!'
    mov outb[2],al
s4:
    mov al,inb[2]
    and al,63
    add al,'!'
    mov outb[3],al
    
    ;write 4 bytes
    mov ah,40h
    mov bx, outhandle
    mov cx,4
    
    mov dx, offset outb 
    
    int 21h
    jmp readwrloop
;----------------------------
;         DBase64 
;----------------------------
D64:

   readwrloop1:
    ;read 4 bytes
    mov ah,3fh
    mov bx, inhandle
    mov cx,4
    mov dx,offset inb1
    int 21h
        or ax,ax
        jz Exit
        
        ;4 to 3 byte conversion    
    
    
ds1:
    mov al, inb1[0]
    sub al,'!'
    shl al,2
    mov ah,inb1[1]
    sub ah,'!'
    shr ah,4
    and ah,3
    or al,ah
    
    mov outb1[0],al
ds2:
    mov al,inb1[1]
    mov ah,inb1[2]
    sub al,'!'
    sub ah,'!'
    shl al,4
    shr ah,2
    and ah,15
    or al,ah
    cmp al, 122
	je pad3
    mov outb1[1],al
    
ds3:
    mov al,inb1[2]
    mov ah,inb1[3]
    sub al,'!'
    sub ah,'!'
    shl al,6
    and ah,63
    or al,ah
	cmp al,122
	je pad4
    
    mov outb1[2],al
	
	mov cx,3
	jmp print
pad3:
	mov cx,1
	jmp print
pad4:
	mov cx,2
	jmp print

    ;mov cx,3
    ;write 3 bytes
print:
    mov ah,40h	
    mov bx, outhandle    
    mov dx, offset outb1 
    
    int 21h
    jmp readwrloop1

;----------------------------
;         Eascii85 
;----------------------------
.386
E85:
	readwrloop2:
   ;read 3 bytes
    mov ah,3fh
    mov bx, inhandle
    mov cx,4
    mov dx,offset inb2
    int 21h
        or ax,ax
        jz Exit 

;padding logic
	mov padder[0],0
	sub bl,bl
	cmp ax,3
	je p3
	cmp ax,2
	je p2
	cmp ax,1 
	je p1
	jmp a1
	
p1:
	mov inb2[1],0
	inc bl
p2:
	mov inb2[2],0
	inc bl
p3:
	mov inb2[3],0
	inc bl
	mov padder[0],bl
;--END of padding Logic
a1:
	;set up 32bit eax register
	mov ah, inb2[0]
	mov al, inb2[1]
	shl eax,16
	mov ah,inb2[2]
	mov al,inb2[3]
	xor edx,edx
	mov ebx,85
	;divide by 85 and put remainder in lowest slot
	idiv ebx
	add edx,"!"		;add 33 to shift it into text range
	mov outb2[4],dl
	
a2:
	;divide again
	xor edx,edx
	idiv ebx
	add edx,"!"
	mov outb2[3],dl
	
a3:
	;divide again
	xor edx,edx
	idiv ebx
	add edx,"!"
	mov outb2[2],dl
a4:
	;divide again
	xor edx,edx
	idiv ebx
	add edx,"!"
	mov outb2[1],dl
a5:
	;divide again
	xor edx,edx
	idiv ebx
	add edx,"!"
	mov outb2[0],dl    
 ;write 5 bytes
	mov al,padder[0]
	sub cx,cx
	mov cl,5
	sub cl,al
    mov ah,40h	
    mov bx, outhandle    
    mov dx, offset outb2 
    
    int 21h
	sub eax,eax
    jmp readwrloop2
;----------------------------
;         Dascii85 
;----------------------------
D85:
	readwrloop3:
   ;read 5 bytes
    mov ah,3fh
    mov bx, inhandle
    mov cx,5
    mov dx,offset inb3
    int 21h
        or ax,ax
        jz Exit 
		
;padding logic
	mov padder[0],0
	sub bl,bl
	;cmp ax,4
	;je dp4
	cmp ax,3
	je dp3
	cmp ax,2
	je dp2
	cmp ax,1 
	je dp1
	jmp da1
	
dp1:
	mov inb3[1],117
	inc bl
dp2:
	mov inb3[2],117
	inc bl
dp3:
	mov inb3[3],117
	inc bl
dp4:
	mov inb3[4],117
	inc bl
	mov padder[0],bl
;--END of padding Logic

da1:
	sub eax,eax
	mov al,inb3[0]
	sub eax,"!"
	imul edx,eax,85
	
	sub eax,eax
	mov al,inb3[1]
	sub eax,"!"
	add edx,eax
	imul edx,edx,85
	
	sub eax,eax
	mov al,inb3[2]
	sub eax,"!"
	add edx,eax
	imul edx,edx,85
	
	sub eax,eax
	mov al,inb3[3]
	sub eax,"!"
	add edx,eax
	imul edx,edx,85
	
	sub eax,eax
	mov al,inb3[4]
	sub eax,"!"
	add edx,eax
	
	
	mov outb3[3],dl	
	mov outb3[2],dh	
	shr edx,16
	mov outb3[1],dl
	mov outb3[0],dh
	
    ;write 4 bytes
wprint:
	sub cx,cx
	mov cl,4
	sub eax,eax
	mov al, padder[0]
	sub cl,al
    mov ah,40h	
    mov bx, outhandle    
    mov dx, offset outb3 
    
    int 21h
    jmp readwrloop3
;--------------------
;	Error Section
;--------------------
Help1:	
	mov ah, 9h	
	mov dx, offset help			
	int 21h
	jmp Exit

Err1:	
	mov ah, 9h	
	mov dx, offset error1			
	int 21h
	jmp Exit
Err2:	
	mov ah, 9h	
	mov dx, offset error2			
	int 21h
	jmp Exit
Err3:	
	mov ah, 9h	
	mov dx, offset error3			
	int 21h
	jmp Exit
Err4:
	mov ah,9h
	mov dx, offset error4
	int 21h
	jmp Exit

Exit:    
    ;close files
    mov ah,3eh
    mov bx, inhandle
    int 21h
    
    mov ah,3eh
    mov bx, outhandle
    int 21h
	
	mov ah,9h
	mov dx, offset closing
	int 21h
   ; exit program
	int 20h;	exits the program and returns control to the system.

cseg ends
end start
