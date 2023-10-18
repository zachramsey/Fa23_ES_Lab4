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
.def Tmp_Reg = R16			; Temporary register
.def Tmr_Cnt = R17			; Timer counter
.def RPG_Curr = R18			; Current RPG input state
.def RPG_Prev = R19			; previous RPG input state

;===================| Main Loop |====================
Init:
	rcall Init_Timer0		; init timer0 for PWM
	rcall Init_Timer2		; init timer 2 for General use
	rcall Init_LCD			; initialize LCD

Main:
	rjmp Main				; loop Main

Init_LCD:
	; is there anything missing?
	rcall delay_100ms		;wait 100ms
	ldi Tmp_Reg,0x03		;Load hex 3 into register
	out PORTC,Tmp_Reg		;Send command to lcd display
	rcall delay_5ms			;wait 5ms
	out PORTC,Tmp_Reg		;Send command to lcd display
	rcall delay_208us
	out PORTC,Tmp_Reg		;Send command to lcd display
	rcall delay_208us
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
	ret

Init_Timer0:
	ldi Tmp_Reg, 0x03		; configure timer0 to Fast PWM (mode 7)
	out TCCR0A, Tmp_Reg
	ldi Tmp_Reg, 0x08
	out TCCR0B, Tmp_Reg
	ldi Tmp_Reg, 200		; set timer0 TOP val to 200
	out OCR0A, Tmp_Reg
	ldi Tmp_Reg, 0			; set timer0 duty cycle to 0 (OCR0B = 200 * DC)
	out OCR0B, Tmp_Reg
	ret

Init_Timer2:
	ldi Tmp_Reg, 0x05
	out TCCR2B, Tmp_Reg
	ret

;delay_112us
delay_112us:
	ldi Tmr_Cnt,7			;init timer config
	ldi Tmp_Reg, 0x01
	out TCCR2B, Tmp_Reg

	loop_100u:
	in Tmp_Reg, TIFR2		; input timer2 interrupt flag register
	sbrs Tmp_Reg, 0			; if overflow flag is not set, loop Running
	rjmp loop_100u

	dec Tmr_Cnt				; Decrement Timer counter
	tst Tmr_Cnt				; Is Timer counter zero?
	brne loop_100u			; No, jump to L1, Yes return
	ret

;delay_208us
delay_208us:
	ldi Tmr_Cnt,13			;init timer config
	ldi Tmp_Reg, 0x01
	out TCCR2B, Tmp_Reg

	loop_200u:
	in Tmp_Reg, TIFR2		; input timer2 interrupt flag register
	sbrs Tmp_Reg, 0			; if overflow flag is not set, loop Running
	rjmp loop_200u

	dec Tmr_Cnt				; Decrement Timer counter
	tst Tmr_Cnt				; Is Timer counter zero?
	brne loop_200u			; No, jump to L1B, Yes return
	ret

;delay_5.12ms
delay_5ms:
	ldi Tmr_Cnt,40			;init timer config
	ldi Tmp_Reg, 0x02
	out TCCR2B, Tmp_Reg

	loop_5m:
	in Tmp_Reg, TIFR2		; input timer2 interrupt flag register
	sbrs Tmp_Reg, 0			; if overflow flag is not set, loop Running
	rjmp loop_5m

	dec Tmr_Cnt				; Decrement Timer counter
	tst Tmr_Cnt				; Is Timer counter zero?
	brne loop_5m			; No, jump to L1C, Yes return
	ret

;delay_100.35ms
delay_100ms:
	ldi Tmr_Cnt,98			;init timer config
	ldi Tmp_Reg, 0x03
	out TCCR2B, Tmp_Reg

	loop_100m:
	in Tmp_Reg, TIFR2		; input timer2 interrupt flag register
	sbrs Tmp_Reg, 0			; if overflow flag is not set, loop Running
	rjmp loop_100m

	dec Tmr_Cnt				; Decrement Timer counter
	tst Tmr_Cnt				; Is Timer counter zero?
	brne loop_100m			; No, jump to L1D, Yes return
	ret
