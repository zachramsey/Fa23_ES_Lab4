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
sbi DDRB,4  				; Board Pin 12 O/P: PB4 -> LCD Enable
sbi DDRB,5					; Board pin 13 O/P: PB5 -> LCD Register Select
;LCD outputs
sbi DDRC,0					
sbi DDRC,1
sbi DDRC,2
sbi DDRC,3

; Input from pushbuttons
cbi DDRD,7					; Board Pin 7 Pushbutton A -> Board I/P: PD7
cbi DDRD,6					; Board Pin 6 RPG A -> Board I/P: PD6
cbi DDRD,5  				; Board Pin 5 RPG B -> Board I/P: PD5

sbi DDRD,3  				; Board Pin 3 OC0B -> Board O/P: PD3


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
	
	rjmp Main				;Dont execute prog mem
; Create a static string in program memory.
msg: 
.DB "Hello "
.DB "A.J."
.DW 0


Main:
	sbi PORTB,5				; put LCD in command mode
	;rcall dispString
	ldi r25, 0x45
	swap r25
	out PORTC,r25
	rcall LCD_Strobe
	rcall delay_112us
	swap r25
	out PORTC,r25
	rcall LCD_Strobe
	rcall delay_100ms

	
	rjmp Main				; loop Main

Init_LCD:
	; is there anything missing?
	cbi PORTB,5				; put LCD in command mode
	cbi PORTB,4				;ensure enable line is low

	rcall delay_100ms		;wait 100ms
	;ldi Tmp_Reg,0x00		;load 0 into register to compensate for upper/lower nibble
	;out PORTC,Tmp_Reg		;Send command to lcd display
	;sbi PORTB,3				;pulse enable
	;cbi PORTB,3				
	;rcall delay_5ms			;wait 5ms
	ldi Tmp_Reg,0x03	 	;Load hex 3 into register
	out PORTC,Tmp_Reg		;Send command to lcd display
	rcall LCD_Strobe			
	rcall delay_5ms			;wait 5ms

	;ldi Tmp_Reg,0x00		;load 0 into register to compensate for upper/lower nibble
	;out PORTC,Tmp_Reg		;Send command to lcd display
	;sbi PORTB,3				;pulse enable
	;cbi PORTB,3				
	;rcall delay_5ms			;wait 5ms
	out PORTC,Tmp_Reg		;Send command to lcd display
	rcall LCD_Strobe
	rcall delay_208us

	;ldi Tmp_Reg,0x00		;load 0 into register to compensate for upper/lower nibble
	;out PORTC,Tmp_Reg		;Send command to lcd display
	;sbi PORTB,3				;pulse enable
	;cbi PORTB,3				
	;rcall delay_5ms			;wait 5ms
	out PORTC,Tmp_Reg		;Send command to lcd display
	rcall LCD_Strobe
	rcall delay_208us

	;ldi Tmp_Reg,0x00		;load 0 into register to compensate for upper/lower nibble
	;out PORTC,Tmp_Reg		;Send command to lcd display
	;sbi PORTB,3				;pulse enable
	;cbi PORTB,3				
	;rcall delay_5ms			;wait 5ms
	ldi Tmp_Reg,0x02		;Enable 4-bit mode
	out PORTC,Tmp_Reg
	rcall LCD_Strobe
	rcall delay_5ms

	;green commands
	ldi Tmp_Reg,0x02		;load upper nibble of 0x28
	out PORTC,Tmp_Reg		;send it
	rcall LCD_Strobe

	ldi Tmp_Reg,0x08		;load lower nibble of 0x28
	out PORTC,Tmp_Reg	
	rcall LCD_Strobe	

	ldi Tmp_Reg,0x00		;load 0 into register to compensate for upper/lower nibble
	out PORTC,Tmp_Reg		;Send command to lcd display
	rcall LCD_Strobe			
	rcall delay_5ms			;wait 5ms
	ldi Tmp_Reg,0x08		;hide cursor dont shift display
	out PORTC,Tmp_Reg
	rcall LCD_Strobe

	ldi Tmp_Reg,0x00		;load 0 into register to compensate for upper/lower nibble
	out PORTC,Tmp_Reg		;Send command to lcd display
	rcall LCD_Strobe			
	rcall delay_5ms			;wait 5ms
	ldi Tmp_Reg,0x01		;Clear and home display
	out PORTC,Tmp_Reg
	rcall LCD_Strobe

	ldi Tmp_Reg,0x00		;load 0 into register to compensate for upper/lower nibble
	out PORTC,Tmp_Reg		;Send command to lcd display
	rcall LCD_Strobe			
	rcall delay_5ms			;wait 5ms
	ldi Tmp_Reg,0x06		;move cursor right
	out PORTC,Tmp_Reg
	rcall LCD_Strobe

	ldi Tmp_Reg,0x0C		;turn on display
	out PORTC,Tmp_Reg
	rcall LCD_Strobe

	ret

LCD_Strobe:
	sbi PORTB,4				;pulse enable
	rcall delay_208us
	cbi PORTB,4
	rcall delay_208us
	ret

Init_Timer0:
	ldi Tmp_Reg, 0x05
	out TCCR0B, Tmp_Reg
	ret

Init_Timer2:
	ldi Tmp_Reg, 0
	sts TCNT2, Tmp_Reg		; clear timer2
	ldi Tmp_Reg, 200		; set timer2 TOP val to 200
	sts OCR2A, Tmp_Reg
	ldi Tmp_Reg, 0x23		; configure timer2 to Fast PWM (mode 7)
	sts TCCR2A, Tmp_Reg
	ldi Tmp_Reg, 0x09
	sts TCCR2B, Tmp_Reg
	ldi Tmp_Reg, 80			; set timer2 duty cycle to 0 (DC = OCR2B / 200)
	sts OCR2B, Tmp_Reg
	ret

dispString:
	ldi r24,10 ; r24 <-- length of the string
	ldi r30,LOW(2*msg) ; Load Z register low
	ldi r31,HIGH(2*msg) ; Load Z register high
	L1:
	lpm						; r0 <-- first byte
	swap r0					; Upper nibble in place
	out PORTC,r0			; Send upper nibble out
	rcall LCD_Strobe
	rcall delay_112us		; Wait
	swap r0					; Lower nibble in place
	out PORTC,r0			; Send lower nibble out
	rcall LCD_Strobe
	rcall delay_112us		; Wait
	adiw zh:zl,1			; Increment Z pointer
	dec r24					; Repeat until
	brne L1					; all characters are out

	ret


;delay_112us
delay_112us:
	ldi Tmr_Cnt,7			;init timer config
	ldi Tmp_Reg, 0x01
	out TCCR0B, Tmp_Reg

	loop_100u:
	in Tmp_Reg, TIFR0		; input timer2 interrupt flag register
	sbrs Tmp_Reg, 0			; if overflow flag is not set, loop Running
	rjmp loop_100u

	ldi Tmp_Reg, 0x01
	out TIFR0, Tmp_Reg
	dec Tmr_Cnt				; Decrement Timer counter
	tst Tmr_Cnt				; Is Timer counter zero?
	brne loop_100u			; No, jump to L1, Yes return
	ret

;delay_208us
delay_208us:
	ldi Tmr_Cnt,13			;init timer config
	ldi Tmp_Reg, 0x01
	out TCCR0B, Tmp_Reg

	loop_200u:
	in Tmp_Reg, TIFR0		; input timer2 interrupt flag register
	sbrs Tmp_Reg, 0			; if overflow flag is not set, loop Running
	rjmp loop_200u

	ldi Tmp_Reg, 0x01
	out TIFR0, Tmp_Reg
	dec Tmr_Cnt				; Decrement Timer counter
	tst Tmr_Cnt				; Is Timer counter zero?
	brne loop_200u			; No, jump to L1B, Yes return
	ret

;delay_5.12ms
delay_5ms:
	ldi Tmr_Cnt,40			;init timer config
	ldi Tmp_Reg, 0x02
	out TCCR0B, Tmp_Reg

	loop_5m:
	in Tmp_Reg, TIFR0		; input timer2 interrupt flag register
	sbrs Tmp_Reg, 0			; if overflow flag is not set, loop Running
	rjmp loop_5m

	ldi Tmp_Reg, 0x01
	out TIFR0, Tmp_Reg
	dec Tmr_Cnt				; Decrement Timer counter
	tst Tmr_Cnt				; Is Timer counter zero?
	brne loop_5m			; No, jump to L1C, Yes return
	ret

;delay_100.35ms
delay_100ms:
	ldi Tmr_Cnt,98			;init timer config
	ldi Tmp_Reg, 0x03
	out TCCR0B, Tmp_Reg

	loop_100m:
	in Tmp_Reg, TIFR0		; input timer2 interrupt flag register
	sbrs Tmp_Reg, 0			; if overflow flag is not set, loop Running
	rjmp loop_100m

	ldi Tmp_Reg, 0x01
	out TIFR0, Tmp_Reg
	dec Tmr_Cnt				; Decrement Timer counter
	tst Tmr_Cnt				; Is Timer counter zero?
	brne loop_100m			; No, jump to L1D, Yes return
	ret
