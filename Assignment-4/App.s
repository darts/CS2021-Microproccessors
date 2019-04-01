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

;from here, initialisation is finished, so it should be the main body of the main program
	
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

foreverLoop					; while(true){
	LDR R1, =noOfCycles		; 		timerCounter = loadCounterAddr()
	LDR R1, [R1]			; 		timerCounter = loadCounter(counterAddr)
	CMP R0, R1 				;		if(counter < timerCounter) 
	BGT foreverLoop			;			continue
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
	B foreverLoop			;		continue
							;
nowBlue						;		*blue*
	LDR R2, =Blue			;		currentColour = blue
	STR R2, [R3]			;		setColour(currentColour)	
	B foreverLoop			;		continue
							;
nowRed						;		*red*
	LDR R2, =Red			;		currentColour = red
	STR R2, [R3]			;		setColour(currentColour)
	B foreverLoop			;		continue
							; }
							

	AREA	InterruptStuff, CODE, READONLY
irqhan	sub	lr,lr,#4
	stmfd	sp!,{r0-r1,lr}	; the lr will be restored to the pc

;this is the body of the interrupt handler

;here you'd put the unique part of your interrupt handler
;all the other stuff is "housekeeping" to save registers and acknowledge interrupts

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

	ldmfd	sp!,{r0-r1,pc}^	; return from interrupt, restoring pc from lr
				; and also restoring the CPSR


		
		
	AREA TestData, DATA, READWRITE
		
noOfCycles
	DCD 0x0
		
			END