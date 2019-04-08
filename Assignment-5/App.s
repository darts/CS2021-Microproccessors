; Definitions  -- references to 'UM' are to the User Manual.

; Timer Stuff -- UM, Table 173

T0	equ	0xE0004000		; Timer 0 Base Address
T1	equ	0xE0008000

IR	equ	0			; Add this to a timer's base address to get actual register address
TCR	equ	4
MCR	equ	0x14
MR0	equ	0x18

TimerCommandReset	equ	2
TimerCommandRun	equ	1
TimerModeResetAndInterrupt	equ	3
TimerResetTimer0Interrupt	equ	1
TimerResetAllInterrupts	equ	0xFF

; VIC Stuff -- UM, Table 41
VIC	equ	0xFFFFF000		; VIC Base Address
IntEnable	equ	0x10
VectAddr	equ	0x30
VectAddr0	equ	0x100
VectCtrl0	equ	0x200

Timer0ChannelNumber	equ	4	; UM, Table 63
Timer0Mask	equ	1<<Timer0ChannelNumber	; UM, Table 63
IRQslot_en	equ	5		; UM, Table 58

IO0DIR	EQU	0xE0028008
IO0PIN	EQU	0xE0028000
IO0SET	EQU 0xE0028004
IO0CLR	EQU 0xE002800C
	
Red EQU 0x00020000
Green EQU 0x00200000
Blue EQU 0x00040000
	
IO1DIR	EQU	0xE0028018
IO1SET	EQU	0xE0028014
IO1CLR	EQU	0xE002801C
IO1PIN	EQU	0xE0028010
	
StdStackOffset EQU 0x40 ;16 registers/words
SPStackOffset EQU 0x3C  ;15 registers/words
	
	AREA	InitialisationAndMain, CODE, READONLY
	IMPORT	main

	EXPORT	start
start
; initialisation code

; Initialise the VIC
	ldr	r0,=VIC			; looking at you, VIC!

	ldr	r1,=irqhan
	str	r1,[r0,#VectAddr0] 	; associate our interrupt handler with Vectored Interrupt 0

	mov	r1,#Timer0ChannelNumber+(1<<IRQslot_en)
	str	r1,[r0,#VectCtrl0] 	; make Timer 0 interrupts the source of Vectored Interrupt 0

	mov	r1,#Timer0Mask
	str	r1,[r0,#IntEnable]	; enable Timer 0 interrupts to be recognised by the VIC

	mov	r1,#0
	str	r1,[r0,#VectAddr]   	; remove any pending interrupt (may not be needed)

; Initialise Timer 0
	ldr	r0,=T0			; looking at you, Timer 0!

	mov	r1,#TimerCommandReset
	str	r1,[r0,#TCR]

	mov	r1,#TimerResetAllInterrupts
	str	r1,[r0,#IR]

	ldr	r1,=(14745600/200)-1	 ; 5 ms = 1/200 second
	str	r1,[r0,#MR0]

	mov	r1,#TimerModeResetAndInterrupt
	str	r1,[r0,#MCR]

	mov	r1,#TimerCommandRun
	str	r1,[r0,#TCR]
; timer initialisation done

;process initialisation time

	LDR R13, =IRQStack  ;fancy new stack for a fancy new dame (interrupt handler)

    ;each thread is stored in the LL as follows:
    ; | SP | LR/PC | REG:0-12 | CPSR |

	
	;THREAD A ***************************************************
	LDR R0, =procAStack         ;new stack
	;***************************;make stack full decending
	LDR R1, =stackSize
	LDR R1, [R1]
	ADD R0, R0, R1
	;***************************;done making stack full decending
	LDR R1, =LEDTime            ;load first line to LR
	STMFA sp!, {R0,R1}          ;store SP and LR
    STMFA sp!, {R0-R12}         ;store registers
	LDR R3, =0			        ;CPSR flags are null
    STMFA sp!, {R3}             ;store CPSR
	ADD R0, R13, #StdStackOffset;create pointer to next thread
	ADD R0, R0, #4              ;modify pointer
	STMFA sp!, {R0}             ;store pointer
    ;THREAD A ***************************************************


    ;THREAD B ***************************************************
	LDR R0, =procBStack         ;new stack
	;***************************;make stack full decending
	LDR R1, =stackSize
	LDR R1, [R1]
	ADD R0, R0, R1
	;***************************;done making stack full decending
	LDR R1, =CalcTime           ;load first line to LR
	STMFA sp!, {R0,R1}          ;store SP and LR
    STMFA sp!, {R0-R12}         ;store registers
	LDR R3, =0			        ;CPSR flags are null
    STMFA sp!, {R3}             ;store CPSR
	ADD R0, R13, #StdStackOffset;create pointer to next thread
	ADD R0, R0, #4              ;modify pointer
	STMFA sp!, {R0}             ;store pointer
    ;THREAD B ***************************************************



	;point last thread back to first
	LDMFA SP!, {R0}             ;pop existing pointer
	LDR R0, =IRQStack           ;load start addr
	ADD R0, R0, #StdStackOffset ;modify offset to point at end
	STMFA sp!, {R0}             ;store new pointer
    ;done pointing last thread back to first
	
	
	;add blank space for first run
	ADD SP, SP, #StdStackOffset ;space where registers would be
	LDR R0, =IRQStack           ;load pointer to first thread
	ADD R0, R0, #StdStackOffset ;modify pointer to point at end of first thread
	STMFA sp!, {R0}             ;store pointer
    ;go back so registers can be stored when IRQ occurs
	SUB SP, SP, #StdStackOffset ;move pointer so regs can be stored
	SUB SP, SP, #4              ;^^^
    
	LDR R0, =IRQSP              ;load address of stored SP
	STR SP, [R0]                ;save SP @ addr
	
doneThreadSetup B doneThreadSetup


;from here, initialisation is finished, so it should be the main body of the main program


LEDTime
	; Set pins P0.17, P0.18 and P0.21 as outputs
	LDR R0, =IO0DIR			; load IO directory
	LDR R1, [R0]			; get the value at the pins
	ORR R1, R1, #0x00260000	; get pinmask to set as outputs
	STR R1, [R0]			; set the pins as outputs
	
	; Clear the LED's
	LDR R0, =IO0SET			; load the pin addr
	STR R1, [R0]			; store mask in pin addr

	LDR R0, =100  			; init counter
	LDR R2, =Green			; first colour = green
	LDR R3, =IO0CLR			; load register for turning on LED's
	STR R2, [R3]			; setColour(green)
	LDR R4, =IO0SET			; load register for turning off LED's
	LDR R5, =0x00260000		; load clearing mask

foreverLoopLED					; while(true){
	LDR R1, =noOfCycles		; 		timerCounter = loadCounterAddr()
	LDR R1, [R1]			; 		timerCounter = loadCounter(counterAddr)
	CMP R0, R1 				;		if(counter < timerCounter) 
	BGT foreverLoopLED		;			continue
	ADD R0, R0, #100		;		counter += 200 //add one second
							;
	STR R5, [R4]			;		clearLEDs(clearingMask)
							;
	CMP R2, #Red			;		if(currentColour == Red)
	BEQ nowGreen			;			break(green)
	CMP R2, #Green			;		if(currentColour == Green)
	BEQ nowBlue				;			break(blue)
	B nowRed				;		else{ break(red) }
							;
nowGreen					;		*green*
	LDR R2, =Green			;		currentColour = green
	STR R2, [R3]			;		setColour(currentColour)
	B foreverLoopLED		;		continue
							;
nowBlue						;		*blue*
	LDR R2, =Blue			;		currentColour = blue
	STR R2, [R3]			;		setColour(currentColour)	
	B foreverLoopLED		;		continue
							;
nowRed						;		*red*
	LDR R2, =Red			;		currentColour = red
	STR R2, [R3]			;		setColour(currentColour)
	B foreverLoopLED		;		continue
							; }
							
							
							
		
CalcTime
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
	
	CMP R0, #-23		; if(button == reset)
	BEQ start			; {reset()}
	
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
	BNE finish	; {
	MOV R6, R7			;	num1 = num2
	LDR R8, =1			;	isFirst = true
	B finish			; }

	
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
	LDR R3, =600000	; 		timerDelay
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


	AREA	InterruptStuff, CODE, READONLY
irqhan	
	sub	lr,lr,#4			    ;lr adjust
	LDR SP, =IRQSP			    ;load sp
	LDR SP, [SP]			    ;^^
	ADD SP, #8				    ;modify so R0-12 can be stored
	stmfa sp!,{r0-r12}          ;store registers
	MRS R0, CPSR			    ; read CPSR
	STMFA SP!, {R0}			    ; save CPSR 
	SUB SP, SP, #StdStackOffset ; go back to write SP and LR 
	
	;***********************************************
	LDR R0, =noOfCycles		; load noOfCycles
	LDR R1, [R0]			; ^^
	ADD R1, R1, #1			; noOfCycles++
	STR R1, [R0]			; store updated number of cycles

;this is where we stop the timer from making the interrupt request to the VIC
;i.e. we 'acknowledge' the interrupt
	ldr	r0,=T0
	mov	r1,#TimerResetTimer0Interrupt
	str	r1,[r0,#IR]	   	; remove MR0 interrupt request from timer

;here we stop the VIC from making the interrupt request to the CPU:
	ldr	r0,=VIC
	mov	r1,#0
	str	r1,[r0,#VectAddr]	; reset VIC
	;**********************************************
	
	MOV R0, SP					; spTMP = IRQSP
	MOV R2, LR					; lrTMP = LR
	
	MSR CPSR_C, #0x1F 			; switch to system mode
	
	MOV R1, SP                  ; spToWrite = user.SP
	STMFA R0!, {R1,R2}			; save user.SP and LR
	
	
	ADD R0, R0, #SPStackOffset  ; sp++ //get to new sp location pointer
	LDR SP, [R0]				; sp = pointer to next thread
	
	LDR R0, =IRQSP				; load address of stored SP 
	STR SP, [R0]				; save IRQ SP at address
	
	LDR R1, [R0]				;compensate for stack pointer alignment
	SUB R1, R1, #(4 * 16)		;^^^
	STR R1, [R0]				;^^^
	
	LDMFA sp!, {R0}			    ;load thread CPSR
	
	MSR CPSR_f, R0			    ;write thread CPSR
	
	LDMFA SP!, {R0-R12}		    ;load all the registers
	LDMFA SP, {SP, PC}          ;load SP and LR
		
		
	AREA StoreData, DATA, READWRITE
		
procAStack 
	SPACE 512

procBStack 
	SPACE 512
		
IRQStack
	SPACE 512
		
IRQSP
	DCD 0x0


stackSize
	DCD 0x200

noOfCycles
	DCD 0x0


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