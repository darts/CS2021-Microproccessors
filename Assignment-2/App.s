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
	
	
	CMP R0, #20
	BNE foreverLoop1
	LDR R0, =-8
	BL flashNum
	B foreverLoop
foreverLoop1
	CMP R0, #21
	BNE foreverLoop2
	LDR R0, =4
	BL flashNum
	B foreverLoop
foreverLoop2
	CMP R0, #22
	BNE foreverLoop3
	LDR R0, =2
	BL flashNum
	B foreverLoop
foreverLoop3	
	CMP R0, #23
	BNE foreverLoop
	LDR R0, =1
	BL flashNum
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
						;	}
	LDMFD sp!, {R1-R5, PC}	
	
;Takes number in R0
;Num in range (-8 <= x <= 7)
dispNum
	STMFD sp!, {R1-R2, LR}
	LDR R1, =IO1SET		; load set reg
	LDR R2, =0x000F0000	; load mask
	STR R2, [R1]		; turn off LEDs using mask
	
	LDR R1, =IO1CLR		; load clear reg
	ADD R0, R0, #8		; 
	ldr R2, =dispArray	;
	ldr R2, [R2, R0]	;
	LSL R2, #16			;
	STR R2, [R1]		;
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
	; R0 = button
	; R6 = num1
	; R7 = num2
	; R8 = first boolean
	; R9 = operand
	
increment               ;     
	CMP R0, #20         ; if(button == increase)
	BNE decrement       ; {
	CMP R6,#7			;	if(num1>= 7){
	BGE	over 			;		B to over}
	ADD R6,R6,#1        ; 		num1++
	B finish            ; }
decrement               ;
	CMP R0,#21          ; elif(button == decrease)
	BNE adder           ;{
	CMP R6,#-8			; 	if(num1<= -8){
	BLE over			;		B to over} 
	SUB R6,R6,#1        ;		num--
	B finish            ;}
adder                   ;
	CMP R0,#22          ;elif(button == add)
	BNE subtract        ;{
	CMP R8, #0 			;	if(first == true)
	BNE adder2			;		{
	MOV R7,R6			;			num2 = num1
	MOV R6,#0			;			num1 =0
	//clear display code goes here ; display
	MOV R8, #1			;			first = false;	
	B endAdd			;	}
adder2					;	else {
	CMP R9,#0			;		if(operand == 0)
	BNE insub			;		{
	ADD R7,R6,R7		;		num2 = num1 + num2	
	MOV R6,#0			; 		num1 = 0
	//displaythis		;   	display result
	B endAdd			;		}
insub
	CMP R9,#1			;		elif(operand == 1)
	BNE subber			;		{
	SUB R7,R7,R6		;			num2 = num2-num1
	MOV R6,#0			;			num1 = 0;
	//display			;			displayResult;
	B endAdd			;		}
endAdd
	MOV R9,#0    		;		operand = 0;
	B finish			;}
subber
	CMP R0,#23          ;elif(button == sub)
	BNE longPressAdd        ;{
	CMP R8, #0 			;	if(first == true)
	BNE subber2			;		{
	MOV R7,R6			;			num2 = num1
	MOV R6,#0			;			num1 =0
	//clear display code goes here ; display
	MOV R8, #1			;			first = false;	
	B endsub			;	}
subber2					;	else {
	CMP R9,#0			;		if(operand == 0)
	BNE insub1			;		{
	ADD R7,R6,R7		;		num2 = num1 + num2	
	MOV R6,#0			; 		num1 = 0
	//displaythis		;   	display result
	B endsub			;		}
insub1
	CMP R9,#1			;		elif(operand == 1)
	BNE subber			;		{
	SUB R7,R7,R6		;			num2 = num2-num1
	MOV R6,#0			;			num1 = 0;
	//display			;			displayResult;
	B endsub			;		}
endsub
	MOV R9,#1    		;		operand = 1;
	B finish			;}
longPressAdd
	CMP R0,#-22			
	BNE longPressSub
	MOV R9,#3
	MOV R6,#0
	B finish
longPressSub
	CMP R0,#-23
	BNE finish
	MOV R6,#0
	MOV R7,#0
	MOV R8,#0
	MOV R9,#0
	B finish
finish
	B foreverLoop
	;ldr r4, [r3]
	;ldr r6, = 0x00F00000
	;and r4, r4, r6
	;eor r4, r4, r6
	;LDR R0, =IO1PIN		; load button addr
	;LDR R0, [R0]		; load originalValue
	;LDR R1, =0x00F00000	; load mask
	;AND R0, R1, R0		; originalValue &= mask
	;EOR R0, R0, R1
	
over	
	CMP R0, #20
	BNE foreverLoop1
	LDR R0, =-8
	BL flashNum
	B foreverLoop
foreverLoop1
	CMP R0, #21
	BNE foreverLoop2
	LDR R0, =4
	BL flashNum
	B foreverLoop
foreverLoop2
	CMP R0, #22
	BNE foreverLoop3
	LDR R0, =2
	BL flashNum
	B foreverLoop
foreverLoop3	
	CMP R0, #23
	BNE foreverLoop
	LDR R0, =1
	BL flashNum
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
						;	}
	LDMFD sp!, {R1-R5, PC}	
	
;Takes number in R0
;Num in range (-8 <= x <= 7)
dispNum
	STMFD sp!, {R1-R2, LR}
	LDR R1, =IO1SET		; load set reg
	LDR R2, =0x000F0000	; load mask
	STR R2, [R1]		; turn off LEDs using mask
	
	LDR R1, =IO1CLR		; load clear reg
	ADD R0, R0, #8		; 
	ldr R2, =dispArray	;
	ldr R2, [R2, R0]	;
	LSL R2, #16			;
	STR R2, [R1]		;
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