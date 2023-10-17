;====================================
;Lab4LCDDisplay.asm
;
; Created: 10/15/2023 7:02:54 PM
; Authors: Trey Vokoun & Zach Ramsey
;====================================

.include "m328Pdef.inc"		; microcontroller-specific definitions
.cseg
.org 0

;==================| Configure I/O |=================
; Output to LCD
sbi DDRB,3  				; Board Pin 11 O/P: PB3 -> LCD Enable
sbi DDRB,5					; Board pin 13 O/P: PB5 -> LCD Register Select
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
	out TCCR2B, Tmp_Reg

	;init LCD
	;wait to power up 100ms
	ldi Tmp_Reg,0x03		;Load hex 3 into register
	out PORTC,Tmp_Reg		;Send command to lcd display
	;wait 5ms
	out PORTC,Tmp_Reg		;Send command to lcd display
	;wait 200us
	out PORTC,Tmp_Reg		;Send command to lcd display
	;wait 200us
	ldi Tmp_Reg,0x02		;Enable 4-bit mode
	out PORTC,Tmp_Reg

	ldi Tmp_Reg,0x02		;load upper nibble of 0x28
	out PORTC,Tmp_Reg		;send it
	ldi Tmp_Reg,0x04		;load lower nibble of 0x28
	out PORTC,Tmp_Reg	
	ldi Tmp_Reg,0x08		;hide cursor dont shift display
	out PORTC,Tmp_Reg
	ldi Tmp_Reg,0x01		;Clear and home display
	out PORTC,Tmp_Reg
	ldi Tmp_Reg,0x06		;move cursor right
	out PORTC,Tmp_Reg
	ldi Tmp_Reg,0x0C		;turn on display
	out PORTC,Tmp_Reg
Main:

	; loop Main
	rjmp Main

;delay_112us
delay_112us:
;init timer config
	ldi Tmr_Cnt,7
	ldi Tmp_Reg, 0x01
	out TCCR2B, Tmp_Reg

	L1A:
		L2A:
			in Tmp_Reg, TIFR2		; input timer2 interrupt flag register
			sbrs Tmp_Reg, 0			; if overflow flag is not set, loop Running
			rjmp L2A

		dec Tmr_Cnt					; Decrement Timer counter
		tst Tmr_Cnt					; Is Timer counter zero?
		brne L1A					;No, jump to L1, Yes return
	ret

;delay_208us
delay_208us:
;init timer config
	ldi Tmr_Cnt,13
	ldi Tmp_Reg, 0x01
	out TCCR2B, Tmp_Reg

	L1B:
		L2B:
			in Tmp_Reg, TIFR2		; input timer2 interrupt flag register
			sbrs Tmp_Reg, 0			; if overflow flag is not set, loop Running
			rjmp L2B

		dec Tmr_Cnt					; Decrement Timer counter
		tst Tmr_Cnt					; Is Timer counter zero?
		brne L1B					;No, jump to L1B, Yes return

	ret

;delay_5.12ms
delay_5ms:
;init timer config
	ldi Tmr_Cnt,40
	ldi Tmp_Reg, 0x02
	out TCCR2B, Tmp_Reg

	L1C:
		L2C:
			in Tmp_Reg, TIFR2		; input timer2 interrupt flag register
			sbrs Tmp_Reg, 0			; if overflow flag is not set, loop Running
			rjmp L2C

		dec Tmr_Cnt					; Decrement Timer counter
		tst Tmr_Cnt					; Is Timer counter zero?
		brne L1C					;No, jump to L1C, Yes return

	ret

;delay_100.35ms
delay_100ms:
;init timer config
	ldi Tmr_Cnt,98
	ldi Tmp_Reg, 0x03
	out TCCR2B, Tmp_Reg

	L1D:
		L2D:
			in Tmp_Reg, TIFR2		; input timer2 interrupt flag register
			sbrs Tmp_Reg, 0			; if overflow flag is not set, loop Running
			rjmp L2D

		dec Tmr_Cnt					; Decrement Timer counter
		tst Tmr_Cnt					; Is Timer counter zero?
		brne L1D					;No, jump to L1D, Yes return

	ret
