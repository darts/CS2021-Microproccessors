	AREA	AsmTemplate, CODE, READONLY
	IMPORT	main

; sample program makes the 4 LEDs P1.16, P1.17, P1.18, P1.19 go on and off in sequence
; (c) Mike Brady, 2011 -- 2019.

	EXPORT	start
start

IO_DIR	EQU	0xE0028018
IO_SET	EQU	0xE0028014
IO_CLR	EQU	0xE002801C

;	ldr	r1,=IO1DIR
;	ldr	r2,=0x000f0000	;select P1.19--P1.16
;	str	r2,[r1]		;make them outputs
;	ldr	r1,=IO1SET
;	str	r2,[r1]		;set them to turn the LEDs off
;	ldr	r2,=IO1CLR
; r1 points to the SET register
; r2 points to the CLEAR register

;	ldr	r5,=0x00100000	; end when the mask reaches this value
;wloop	ldr	r3,=0x00010000	; start with P1.16.
;floop	str	r3,[r2]	   	; clear the bit -> turn on the LED
;
;delay for about a half second
;	ldr	r4,=4000000			; timerDelay = A NUMBER
;dloop	subs	r4,r4,#1	; while(timerDelay-- > 0){
;	bne	dloop				; }
;
;	str	r3,[r1]		;set the bit -> turn off the LED
;	mov	r3,r3,lsl #1	;shift up to next bit. P1.16 -> P1.17 etc.
;	cmp	r3,r5
;	bne	floop
;	b	wloop
	
	;convert to bcd		
	LDR R0, =binNum			; load num
	LDR R0, [R0]
	LDR R1, =0x80000000		; load mask
	AND R1, R1, R0			; num && mask
	
	CMP R1, #0				; if (num < 0)
	BEQ isPositive 			; {
	LDR R2, =0xA			; 		minus = 2_1010
	LDR R3, =wrdSpace		; 		addr = wrdSpace.addr
	STRB R2, [R3]			; 		storeSign()
	NEG R0, R0				;		num.2's complement()
	B isNegative			; } 
isPositive 					; else{
	LDR R2, =0xB			; 		plus = 2_1011
	LDR R3, =wrdSpace		; 		addr = wrdSpace.addr
	STRB R2, [R3]			; 		storeSign()
isNegative					; }
							
							; Find the number of digits in the number
	LDR R1, =0				; length = 0
	LDR R2, =1				; power = 0
	LDR R3, =10				; multiplier = 10
pwrNotFound					; while (power <= num)
	CMP R2, R0				; {
	BGT pwrFound			;		
	MUL R2, R3, R2			;		power = power * 10
	ADD R1, R1, #1			;		length++
	B pwrNotFound			; 
pwrFound					; }
	
							; Find each of the characters
	LDR R6, =wrdSpace		; addr = wrdSpace.addr
	LDR R7, =1				; offset = 1
	MOV R2, R1				; tmpLength = length
charsLeft					;
	CMP R2, #0				; while (tmpLength > 0)
	BEQ noCharsLeft			; {
	LDR R3, =1				; 		numPwr = 1
	LDR R4, =1				; 		tmpLengthTwo = 1
	LDR R5, =10				; 		multiplier = 10
							;
subLenNotFound				;			 
	CMP R2, R4				; 			while (tmpLength > tmpLengthTwo)
	BEQ subLenFound			; 			{
	MUL R3, R5, R3			;				numPwr = numPwr * 10
	ADD R4, R4, #1			;				tmpLengthTwo++
	B subLenNotFound		;
subLenFound					;			}
							;
	LDR R4, =0				; 		resChar = 0
charNotFound				;		
	CMP R3, R0				;		while (numPwr <= num)
	BGT charFound			;		{
	SUB R0, R0, R3			;			num = num - numPwr
	ADD R4, R4, #1			; 			resChar++
	B charNotFound			;
charFound					; 		}
							;
	CMP R4, #0				;		if (resChar == 0)
	BNE notZero				;		{
	LDR R4, =0xF			; 			resChar = 2_1111
	STRB R4, [R6, R7]		;			storeSign(offset)
	B incStuff				;		}
notZero						;		else{
	STRB R4, [R6, R7]		;			storeSign(offset)
incStuff					;		}
							;
	ADD R7, R7, #1			;		offset++
	SUB R2, R2, #1			;		tmpLength--
	B charsLeft				;	
noCharsLeft					;	}
	
	MOV R2, R1				
	;loading stuff for displaying
	LDR R0, =IO_DIR
	LDR R1, =0x000F0000		; select P1.19 through P1.16
	STR R1, [R0]			; set as outputs
	LDR R0, =IO_SET			; 
	STR R1, [R0]			; set the bits to turn off the LEDs
	LDR R1, =IO_CLR			;
							; R0 = set reg
							; R1 = clr reg
	
foreverLoop
	LDR R3, =0
	LDR R4, =wrdSpace
	LDRB R5, [R4, R3]
	LSL R5, #16
	STR	R5,	[R1]
	
	LDR	R5,=4000000	
dloop	
	SUBS R5, R5 ,#1	
	BNE	dloop
	
	CMP R3, R2
	BNE foreverLoop
	LDR R5, =0x000F0000
	STR R5, [R0]
	
	B foreverLoop
stop	B	stop

	AREA TestData, DATA, READWRITE

binNum DCD 0x10				; the binary number to be converted

wrdSpace SPACE	12 			; assign 12 bytes of free space to store the characters	
	END