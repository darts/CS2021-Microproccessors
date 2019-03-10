	AREA	buttonUp, CODE, READONLY
	IMPORT	main
		
	EXPORT	start
start

IO1DIR	EQU	0xE0028018
IO1SET	EQU	0xE0028014
IO1CLR	EQU	0xE002801C
IO1PIN	EQU	0xE0028010
	LDR R0, =0
	LDR R1, =0
	LDR R2, =0
	LDR R3, =0
	LDR R4, =0
	LDR R5, =0
	LDR R6, =0
	LDR R7, =0
	LDR R8, =1
	LDR R9, =0
	LDR R10, =0
	
	LDR R1, =IO1DIR
	LDR R2, =0x000F0000		; select P1.19 through P1.16
	STR R2, [R1]			; set as outputs
	LDR R1, =IO1SET			; 
	STR R2, [R1]			; set the bits to turn off the LEDs
	LDR R2, =IO1CLR
	LDR R3, =IO1PIN
	
	; R0 = button
	; R5 = displayingOldResult
	; R6 = num1
	; R7 = num2
	; R8 = first boolean
	; R9 = operand
	; R10 = opTmp	
foreverLoop
	BL getPress			; button = getPress()
	
	CMP R0, #0			; if(button == 0) //nothing pressed
	BEQ foreverLoop		; {break to top}
	
	CMP R5, #1			; if(displayingOldResult)
	BNE increment		; {
	CMP R0, #20			;	if( button == increase
	BEQ clearDisp		;	||
	CMP R0, #21			;	button == decrease)
	BNE foreverLoop		;	{
clearDisp				;		
	LDR R5, =0			;		displayingOldResult = false
	LDR R0, =0			;		button = 0
	BL dispNum			;		dispNum(button)
	B foreverLoop		;	}else{ break to top }
						; }else{ continue}
	
increment               ;     
	CMP R0, #20         ; if(button == increase)
	BNE decrement       ; {
	CMP R6,#7			;	if(num1 >= 7){
	BLT	plusOne 		;	
	MOV R0, R6			;		button = num1
	BL flashNum			;		flashNum(button)
	B foreverLoop		;		B to start
plusOne					;	}else{
	ADD R6,R6,#1        ; 		num1++ }
	B finish       ; }
decrement               ;
	CMP R0,#21          ; elif(button == decrease)
	BNE adder           ; {
	CMP R6,#-8			; 	if(num1<= -8){
	BGT minusOne		;	
	MOV R0, R6			;		button = num1
	BL flashNum			;		flashNum(button)
	B foreverLoop		;		B to start
minusOne				;	}else{	
	SUB R6,R6,#1        ;		num--
	B finish            ; }
adder					;
	CMP R0, #22			; elif(button == add) 
	BNE subber			; {
	LDR R10, =1 		;	opTmp = '+'
	
subPressed	
	CMP R8, #0			; 	if(isFirst)
	BEQ mathTwo			;	{
	MOV R7, R6			;		num2 = num1
	LDR R6, =0			;		num1 = 0
	LDR R8, =0			;		isFirst = false
	MOV R9, R10			; 		operand = opTmp
	B finish			;	}
mathTwo					;	else{
	LDR R5, =1			; 	displayingOldResult = true
	CMP R9, #1			;		if(operand == '+')
	BNE subOne			;		{
	ADD R7, R7, R6		;			num2 = num1 + num2
	B dispResult		;			break to display
subOne					;		}else{
	SUB R7, R7, R6		;			num2 = num2 - num1
dispResult				;		}
	LDR R6, =0			;		num1 = 0
	MOV R0, R7			;		button = num2
	BL dispNum			;		dispNum(button)
	MOV R9, R10			; 		operand = opTmp
	B foreverLoop 		;
	
subber
	CMP R0,#23          ; elif(button == sub)
	BNE longPressAdd    ; {
	LDR R10, =0 		;	operand = '-'
	B subPressed		;	break to math section above
	
longPressAdd
	CMP R0,#-22			; elif(button == clear last)
	BNE longPressSub	; {
	MOV R6, R7			;	num1 = num2
	LDR R8, =1			;	isFirst = true
	B finish			; }
	
longPressSub			 
	CMP R0,#-23			; elif(button == clear all) 
	BNE finish			; {
	LDR R0, =0			;	button = 0
	BL dispNum			;	dispNum(button)
	B start				;	reset()
	
finish
	MOV R0, R6			; button = num1
	BL dispNum			; dispNum(button)
	B foreverLoop		; }

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
	B nonePressed	; }
pressedGetPress			; else{
	LDR R2, =1			; 		isLongPress = 1
	LDR R3, =900000	; 		timerDelay
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
						;		//COMPENSATE FOR SWITCH BOUNCE
	MOV R1, R0			; 		resTmp = originalValue
	LDR R0, =200000		; 		waitTime
	BL wait				; 		wait(waitTime)
	MOV R0, R1			; 		originalValue = resTmp
nonePressed				; }
	LDMFD sp!, {R1-R5, PC}	
	
;Takes number in R0
;Num in range (-8 <= x <= 7)
dispNum
	STMFD sp!, {R1-R2, LR}
	LDR R1, =IO1SET		; load set reg
	LDR R2, =0x000F0000	; load mask
	STR R2, [R1]		; turn off LEDs using mask
	
	LDR R1, =IO1CLR		; load clear reg
	ADD R0, R0, #8		; num += arrayOffset
	LDR R2, =dispArray	; load array address
	LDR R2, [R2, R0]	; load value to display from array
	LSL R2, #16			; Shift to compensate for location offset
	STR R2, [R1]		; Set bits to turn on LEDs
	LDMFD sp!, {R1-R2, PC}
	
;Takes a number in R0
;Num in range (-8 <= x <= 7)
flashNum
	STMFD sp!, {R1-R4, LR}
	MOV R1, R0			; numTmp = num
	LDR R3, =3			; number of flashes = 3
	LDR R4, =1000000	; waitTime
notDoneFlashNum			;
	CMP R3, #0			; while(number of flashes > 0)
	BEQ doneAllFlashNum	; {
	SUB R3, R3, #1		; 	number of flashes --
	LDR R0, =0			;	load 0 to display
	BL dispNum			;	show 0
	MOV R0, R4			;	load waitTime
	BL wait				;	wait(waitTime)
	MOV R0, R1			;	num = numTmp
	BL dispNum			;	show(num)
	MOV R0, R4			;	load waitTime
	BL wait				;	wait(waitTime)
	B notDoneFlashNum	; }
doneAllFlashNum
	LDMFD sp!, {R1-R4, PC}
	
; wait an amount of cycles 
; R0 = cycles
wait
	STMFD sp!, {LR}
loopWait				; while(cycles-- > 0)
	SUBS R0, R0, #1		; {
	BNE loopWait		; }
	LDMFD sp!, {PC}		
	
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