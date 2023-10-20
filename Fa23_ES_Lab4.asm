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
sbi DDRB,3  				; O/P: PB3 -> LCD Enable
sbi DDRB,5					; O/P: PB5 -> LCD Register Select
sbi DDRC, 0					; O/P: PC0 -> LCD Data Bit 4
sbi DDRC, 1					; O/P: PC1 -> LCD Data Bit 5
sbi DDRC, 2					; O/P: PC2 -> LCD Data Bit 6
sbi DDRC, 3					; O/P: PC3 -> LCD Data Bit 7
; Input from pushbuttons
cbi DDRD,7					; Board Pin 7 Pushbutton A -> Board I/P: PD7
cbi DDRD,6					; Board Pin 6 RPG A -> Board I/P: PD6
cbi DDRD,5  				; Board Pin 5 RPG B -> Board I/P: PD5

sbi DDRD,3  				; Board Pin 3 OC0B -> Board O/P: PD3

;==============| Configure Registers |===============
.def Tmp_Reg = R16			; Temporary register
.def Tmp_Data = R17			; Temporary data register
.def Tmr_Cnt = R18			; Timer counter
.def RPG_Curr = R19			; Current RPG input state
.def RPG_Prev = R20			; previous RPG input state

; Create a static string in program memory.
rjmp Init					;Dont execute prog mem
msg: 
	.DB "Hello A.J."
	.DW 0

;===================| Main Loop |====================
Init:
	rcall Init_LCD			; initialize LCD
	rcall Init_Timer2		; init timer2 for PWM
	rcall display_string	; display string on LCD

Main:
	rjmp Main				; loop Main

Init_Timer2:
	ldi Tmp_Reg, 0
	sts TCNT2, Tmp_Reg		; clear timer0
	ldi Tmp_Reg, 200		; set timer0 TOP val to 200
	sts OCR2A, Tmp_Reg
	ldi Tmp_Reg, 0x23		; configure timer0 to Fast PWM (mode 7)
	sts TCCR2A, Tmp_Reg
	ldi Tmp_Reg, 0x09
	sts TCCR2B, Tmp_Reg
	ldi Tmp_Reg, 80			; set timer0 duty cycle to 0 (DC = OCR0B / 200)
	sts OCR2B, Tmp_Reg
	ret

Init_LCD:
	rcall delay_100m		; wait to power up LCD
	cbi PORTB, 5			; clear R/S | Instruction mode
	nop
	
	ldi Tmp_Data, 0x30		; Set 8-bit mode
	rcall out_nibble
	rcall delay_5m

	rcall out_nibble		; Set 8-bit mode
	rcall delay_200u

	rcall out_nibble		; Set 8-bit mode
	rcall delay_200u

	ldi Tmp_Data, 0x20		; Set 4-bit mode
	rcall out_nibble
	rcall delay_5m
	
	ldi Tmp_Data, 0x28		; Set interface
	rcall out_byte
	rcall delay_100u

	ldi Tmp_Data, 0x08		; dont shift display, hide cursor 
	rcall out_byte
	rcall delay_100u

	ldi Tmp_Data, 0x01		; Clear and home display
	rcall out_byte
	rcall delay_5m

	ldi Tmp_Data, 0x06		; move cursor right
	rcall out_byte
	rcall delay_100u

	ldi Tmp_Data, 0x0C		; turn on display
	rcall out_byte
	rcall delay_100u
	
	ret

display_string:
	sbi PORTB, 5			; set R/S | Data mode
	nop
	ldi r24,10 				; r24 <-- length of the string
	ldi r30,LOW(2*msg) 		; Load Z register low
	ldi r31,HIGH(2*msg) 	; Load Z register high
	next_char:
		lpm	Tmp_Data, Z+	; load byte from prog mem at Z in Tmp_Reg, post-increment Z
		rcall out_byte		; output byte
		dec r24				; Repeat until all characters are out
		brne next_char
		ret

out_byte:
	rcall out_nibble		; send upper nibble
	rcall delay_100u
	swap Tmp_Data			; swap nibbles
	rcall out_nibble		; send lower nibble
	rcall delay_100u
	ret

out_nibble:
	out PORTC, Tmp_Data		; send upper nibble
	nop
	rcall strobe			; strobe E
	ret

strobe:
	sbi PORTB, 3			; drive E high
	nop						; 312 ns delay
	nop
	nop
	nop
	nop
	cbi PORTB, 3			; drive E low
	ret

; 112us delay
delay_100u:
	ldi Tmr_Cnt,7				; set  timer overflow counter to 7
	ldi Tmp_Reg, 0x01			; set prescaler to none
	out TCCR0B, Tmp_Reg

	loop_100u:
		in Tmp_Reg, TIFR0		; input timer2 interrupt flag register
		sbrs Tmp_Reg, 0			; if overflow flag is not set, loop
		rjmp loop_100u

		ldi Tmp_Reg, (1<<TOV0)	; acknowledge overflow flag
		out TIFR0, Tmp_Reg		; output to timer0 interrupt flag register

		dec Tmr_Cnt				; Decrement Timer counter
		brne loop_100u			; if Timer counter is zero, loop
		ret						; otherwise, return

; 208us delay
delay_200u:
	ldi Tmr_Cnt, 13				; set timer overflow counter to 13
	ldi Tmp_Reg, 0x01			; set prescaler to none
	out TCCR0B, Tmp_Reg

	loop_200u:
		in Tmp_Reg, TIFR0		; input timer2 interrupt flag register
		sbrs Tmp_Reg, 0			; if overflow flag is not set, loop
		rjmp loop_200u

		ldi Tmp_Reg, (1<<TOV0)	; acknowledge overflow flag
		out TIFR0, Tmp_Reg		; output to timer0 interrupt flag register

		dec Tmr_Cnt				; Decrement Timer counter
		brne loop_200u			; if Timer counter is zero, loop
		ret						; otherwise, return

; 5.12ms delay
delay_5m:
	ldi Tmr_Cnt, 40				; set timer overflow counter to 40
	ldi Tmp_Reg, 0x02			; set prescaler to 8
	out TCCR0B, Tmp_Reg

	loop_5m:
		in Tmp_Reg, TIFR0		; input timer2 interrupt flag register
		sbrs Tmp_Reg, 0			; if overflow flag is not set, loop
		rjmp loop_5m

		ldi Tmp_Reg, (1<<TOV0)	; acknowledge overflow flag
		out TIFR0, Tmp_Reg		; output to timer0 interrupt flag register

		dec Tmr_Cnt				; Decrement Timer counter
		brne loop_5m			; if Timer counter is zero, loop
		ret						; otherwise, return

; 100.35ms delay
delay_100m:
	ldi Tmr_Cnt, 98				; set timer overflow counter to 98
	ldi Tmp_Reg, 0x03			; set prescaler to 64
	out TCCR0B, Tmp_Reg

	loop_100m:
		in Tmp_Reg, TIFR0		; input timer2 interrupt flag register
		sbrs Tmp_Reg, 0			; if overflow flag is not set, loop
		rjmp loop_100m

		ldi Tmp_Reg, (1<<TOV0)	; acknowledge overflow flag
		out TIFR0, Tmp_Reg		; output to timer0 interrupt flag register

		dec Tmr_Cnt				; Decrement Timer counter
		brne loop_100m			; if Timer counter is zero, loop
		ret		
