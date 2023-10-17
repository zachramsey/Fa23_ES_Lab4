;====================================
Lab4LCDDisplay.asm
;
; Created: 10/15/2023 7:02:54 PM
; Authors: Trey Vokoun & Zach Ramsey
;====================================

.include "m328Pdef.inc"		; microcontroller-specific definitions
.cseg
.org 0

;==================| Configure I/O |=================
; Output to shiftreg SN74HC595
sbi DDRB,0					; Board Pin 8 O/P: PB0 -> ShiftReg I/P: SER
sbi DDRB,1					; Board Pin 9 O/P: PB1 -> ShiftReg I/P: RCLK
sbi DDRB,2					; Board Pin 10 O/P: PB2 -> ShiftReg I/P: SRCLK
sbi DDRB,3  				; Board Pin 11 O/P: PB3 -> Status LEDs
; Input from pushbuttons
cbi DDRD,7					; Board Pin 7 Pushbutton A -> Board I/P: PD7
cbi DDRD,6					; Board Pin 6 RPG A -> Board I/P: PD6
cbi DDRD,5  				; Board Pin 5 RPG B -> Board I/P: PD5

;==============| Configure Registers |===============
.def Disp_Queue = R16		; Data queue for next digit to be displayed
.def Disp_Decr = R17		; Count of remaining bits to be pushed from Disp_Queue; decrements from 8
.def RPG_Curr = R18			; Current RPG input state
.def RPG_Prev = R19			; previous RPG input state
.def Ptrn_Cnt = R20			; Pattern counter
.def Tmp_Reg = R21			; Temporary register
.def Tmr_Cnt = R22			; Timer counter
.def Btn_Cnt = R23			; Button timer counter

;=========| Load Digit Patterns |==========
rjmp Init					; don't execute data!
Ptrns:

;===================| Main Loop |====================
Init:
	; init timer0 for PWM
	ldi Tmp_Reg, 0x05		; configure prescaler to 1024
	out TCCR0B, Tmp_Reg		; output configuration to TCCR0B
	
	;init timer 1 for Genereral use
	ldi Tmp_Reg, 0x05
	out TCCR1B, Tmp_Reg

	;init LCD


Main:

	; loop Main
	rjmp Main
