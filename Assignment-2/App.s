	AREA	AsmTemplate, CODE, READONLY
	IMPORT	main

	EXPORT	start
start

IO_DIR	EQU	0xE0028018
IO_SET	EQU	0xE0028014
IO_CLR	EQU	0xE002801C
	
	;convert to bcd		
	LDR R0, =binNum			; load num
	LDR R0, [R0]
	LDR R1, =0x80000000		; load mask
	AND R1, R1, R0			; num && mask
	
	CMP R1, #0				; if (num < 0)
	BEQ isPositive 			; {
	LDR R2, =0x5			; 		minus = 2_1010 (inverse)
	LDR R3, =wrdSpace		; 		addr = wrdSpace.addr
	STRB R2, [R3]			; 		storeSign()
	NEG R0, R0				;		num.2's complement()
	B isNegative			; } 
isPositive 					; else{
	LDR R2, =0xD			; 		plus = 2_1011 (inverse)
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
	LDR R8, =4				; 			i = 4
	LDR R9, =0				; 			maskRes = 0
	LDR R10, =0				; 			invertedNum = 0
numNotAdjusted				; 			while (i > 4)
	CMP R8, #0				; 			{ 
	BEQ numAdjusted			; 				
	AND R9, R4, #1			; 				get first bit
	LSL R10, #1				; 				shift inverted left 
	ORR R10, R10, R9		; 				add bit
	LSR R4, #1				; 				shift old right 
	SUB R8, R8, #1			; 				i--
	B numNotAdjusted		; 			}
numAdjusted					; 
	STRB R10, [R6, R7]		;			storeSign(offset)
incStuff					;		}
							;
	ADD R7, R7, #1			;		offset++
	SUB R2, R2, #1			;		tmpLength--
	B charsLeft				;	
noCharsLeft					;	}
	
	ADD R2, R1, #1			; length += 1	
	;loading stuff for displaying
	LDR R0, =IO_DIR
	LDR R1, =0x000F0000		; select P1.19 through P1.16
	STR R1, [R0]			; set as outputs
	LDR R0, =IO_SET			; 
	STR R1, [R0]			; set the bits to turn off the LEDs
	LDR R1, =IO_CLR			;
							; R0 = set reg
							; R1 = clr reg
	
	LDR R3, =0				; tmpLength = 0
foreverLoop					; while (true) {
	LDR R4, =wrdSpace		; 		addr = wrdSpace.addr
	LDR R5, =0x000F0000		;		zeroMask = mask
	STR R5, [R0]			; 		setReg = mask
	
	LDR	R5,=2000000			; 		timerDelay
delloop						; 		while(timerDelay > 0){
	SUBS R5, R5 ,#1			; 			timerDelay--
	BNE	delloop				; 		}
	
	LDRB R5, [R4, R3]		; 		load next char with offset = tmplength
	LSL R5, #16				; 		shift left by 16 bits
	STR	R5,	[R1]			; 		set the leds
	
	LDR	R5,=7000000			; 		timerDelay
dloop						; 		while (timerDelay > 0){
	SUBS R5, R5 ,#1			; 			timerDelay--
	BNE	dloop				; 		}
	
	ADD R3, R3, #1			; 		tmpLength++
	CMP R3, R2				; 		if (tmpLength == length)
	BNE foreverLoop			; 		{
	LDR R3, =0				;			tmpLength = 0
	LDR R5, =0x000F0000		;			load 0
	STR R5, [R0]			;			clear bits / turn off LEDs
	LDR	R5,=4000000			;			timerDelay
deloop						;			while (timerDelay > 0){
	SUBS R5, R5 ,#1			;				timerDelay--
	BNE	deloop				;			}
	B foreverLoop			; }
stop	B	stop

	AREA TestData, DATA, READWRITE

binNum DCD 0x508			; the binary number to be converted

wrdSpace SPACE	12 			; assign 12 bytes of free space to store the characters	
	END