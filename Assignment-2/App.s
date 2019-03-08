	AREA	buttonUp, CODE, READONLY
	IMPORT	main
		
	EXPORT	start
start

IO1DIR	EQU	0xE0028018
IO1SET	EQU	0xE0028014
IO1CLR	EQU	0xE002801C
IO1PIN	EQU	0xE0028010
	
	LDR R1, =IO1DIR
	LDR R2, =0x000F0000		; select P1.19 through P1.16
	STR R2, [R1]			; set as outputs
	LDR R1, =IO1SET			; 
	STR R2, [R1]			; set the bits to turn off the LEDs
	ldr r2, =IO1CLR
	ldr r3, =IO1PIN
	
foreverLoop
	BL getPress
	
	;ldr r4, [r3]
	;ldr r6, = 0x00F00000
	;and r4, r4, r6
	;eor r4, r4, r6
	;LDR R0, =IO1PIN		; load button addr
	;LDR R0, [R0]		; load originalValue
	;LDR R1, =0x00F00000	; load mask
	;AND R0, R1, R0		; originalValue &= mask
	;EOR R0, R0, R1
	
	
	CMP R0, #-20
	BNE foreverLoop1
	LDR R0, =-8
	BL dispNum
	B foreverLoop
foreverLoop1
	CMP R0, #-21
	BNE foreverLoop2
	LDR R0, =4
	BL dispNum
	B foreverLoop
foreverLoop2
	CMP R0, #-22
	BNE foreverLoop3
	LDR R0, =2
	BL dispNum
	B foreverLoop
foreverLoop3	
	CMP R0, #-23
	BNE foreverLoop
	LDR R0, =1
	BL dispNum
	B foreverLoop


stop B stop

;Returns pressed key in R0
getPress
	STMFD sp!, {R1-R5, LR}
	; R0 = original values
	; R1 = mask
	; R2 = isLongPress
	; R3 = timerDelay
	; R4 = button addr
	; R5 = button values
	
	LDR R0, =IO1PIN		; load button addr
	LDR R0, [R0]		; load originalValue
	LDR R1, =0x00F00000	; load mask
	AND R0, R1, R0		; originalValue &= mask
	
	CMP R1, R0			; if(button values == mask)
	BNE pressedGetPress	; {
	LDR R0, =0			;		originalValue = 0
	B notNegGetPress	; }
pressedGetPress			; else{
	LDR R2, =1			; 		isLongPress = 1
	LDR R3, =1100000	; 		timerDelay
	LDR R4, =IO1PIN		;		load button addr

waitTimeGetPress
	SUBS R3, R3, #1		;		while(timerdelay)
	BEQ doneWaitGetPress;		{
	LDR R5, [R4]		; 			load button values()
	AND R5, R5, R1		;			button values &= mask
	CMP R5, R0			;			if (original values != button values){
	BEQ waitTimeGetPress;				isLongPress = false
	LDR R2, =0			;				break
	B shortPressGetPress;
doneWaitGetPress		;			}
	LDR R5, [R4]		; 			load button values()
	AND R5, R5, R1		;			button values &= mask
	CMP R5, R0			;			while(button values == originalValues)
	BEQ doneWaitGetPress;			{wait()}
shortPressGetPress
	EOR R0, R0, R1		; 		originalValue XOR mask
	LSR R0, #20			; 		originalValue >> 20
	
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
	
;Takes number in R0
;Num in range 
dispNum
	STMFD sp!, {R1-R2, LR}
	LDR R1, =IO1SET
	LDR R2, =0x000F0000
	STR R2, [R1]
	
	LDR R1, =IO1CLR
	ADD r0, r0, #8
	ldr r2, =dispArray
	ldr r2, [r2, r0]
	LSL R2, #16
	STR R2, [R1]
	LDMFD sp!, {R1-R2, PC}
	
	AREA TestData, DATA, READWRITE

dispArray
	DCB 2_0001
	DCB 2_1001
	DCB 2_0101
	DCB 2_1101
	DCB 2_0011
	DCB 2_1011
	DCB 2_0111
	DCB 2_1111
	DCB 2_0000
	DCB 2_1000
	DCB 2_0100
	DCB 2_1100
	DCB 2_0010
	DCB 2_1010
	DCB 2_0110
	DCB 2_1110
		
	END