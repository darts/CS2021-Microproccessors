	AREA	AsmTemplate, CODE, READONLY
	IMPORT	main

; sample program makes the 4 LEDs P1.16, P1.17, P1.18, P1.19 go on and off in sequence
; (c) Mike Brady, 2011 -- 2019.

	EXPORT	start
start

IO1DIR	EQU	0xE0028018
IO1SET	EQU	0xE0028014
IO1CLR	EQU	0xE002801C

	ldr	r1,=IO1DIR
	ldr	r2,=0x000f0000	;select P1.19--P1.16
	str	r2,[r1]		;make them outputs
	ldr	r1,=IO1SET
	str	r2,[r1]		;set them to turn the LEDs off
	ldr	r2,=IO1CLR
; r1 points to the SET register
; r2 points to the CLEAR register

	ldr	r5,=0x00100000	; end when the mask reaches this value
wloop	ldr	r3,=0x00010000	; start with P1.16.
floop	str	r3,[r2]	   	; clear the bit -> turn on the LED

;delay for about a half second
	ldr	r4,=4000000
dloop	subs	r4,r4,#1
	bne	dloop

	str	r3,[r1]		;set the bit -> turn off the LED
	mov	r3,r3,lsl #1	;shift up to next bit. P1.16 -> P1.17 etc.
	cmp	r3,r5
	bne	floop
	b	wloop
stop	B	stop


getPress
	STMFD sp, {R1-R5, LR}
	; R0 = original values
	; R1 = mask
	; R2 = isLongPress
	; R3 = timerDelay
	; R4 = button addr
	; R5 = button values
	
	LDR R0, =IO1DIR		; load button addr
	LDR R0, [R0]		; load originalValue
	LDR R1, 0xF00000	; load mask
	AND R0, R1, R0		; originalValue &= mask
	
	CMP R1, R0			; if(button values == mask)
	BNE pressedGetPress	; {
	LDR R0, =0			;		originalValue = 0
	B notNegGetPress	; }
pressedGetPress			; else{
	LDR R2, =1			; 		isLongPress = 1
	LDR R3, =4000000	; 		timerDelay
	LDR R4, =IO1DIR		;		load button addr

waitTimeGetPress
	SUBS R3, R3, #1		;		while(timerdelay)
	BEQ doneWaitGetPress;		{
	LDR R5, [R4]		; 			load button values()
	AND R5, R5, R1		;			button values &= mask
	CMP R5, R0			;			if (original values != button values){
	BEQ waitTimeGetPress;				isLongPress = false
	LDR R2, =0			;				break
doneWaitGetPress		;			}
						;		}
	LSR R0, #20			; 		originalValue >> 20
	AND R0, R0, R1		; 		originalValue &= mask
	CMP R0, #1			; 		if(originalValue == 1)
	BNE chkTwoGetPress	; 		{
	LDR R0, =20			; 			originalValue = 20
	B mayNegGetPress	; 		}
chkTwoGetPress			;
	CMP R0, #2			; 		else if(originalValue == 2)
	BNE chkFourGetPress	; 		{
	LDR R0, =21			; 			originalValue = 21
	B mayNegGetPress	; 		}
chkFourGetPress			;		
	CMP R0, #4			; 		else if(originalValue == 4)
	BNE chk8GetPress	; 		{
	LDR R0, =22			; 			originalValue = 22
	B mayNegGetPress	; 		}  
chk8GetPress			;		else {
	LDR R0, =23			; 			originalValue = 23
mayNegGetPress			; 		}
	CMP R2, #0			; 		if(isLongPress)
	BEQ notNegGetPress	; 		{
	NEG R0, R0			; 			originalValue = 2'sComplementOf(originalValue)
notNegGetPress			; 		}

	LDMFD sp!, {R1-R5, PC}	

	END