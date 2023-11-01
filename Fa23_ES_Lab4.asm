;====================================
;Lab4LCDDisplay.asm
;
; Created: 10/15/2023 7:02:54 PM
; Authors: Trey Vokoun & Zach Ramsey
;====================================

.include "m328Pdef.inc"		; microcontroller-specific definitions
.cseg
.org 0x0000
jmp Start					; Skip to start

.org 0x0002					; INT0 vector
jmp INT0_ISR				; Jump to INT0 ISR

.org 0x000A					; PCINT2 vector
jmp PCINT2_ISR				; Jump to PCINT2 ISR

.org 0x0034					; Start of program memory

ln1_static:					; Create static strings in program memory
	.DB "DC = %"
	.DW 0

ln2_static:
	.DB "Fan: O"
	.DW 0

Start:
;==================| Configure I/O |=================
; Inputs
cbi DDRD, 2					; uC PD7 (INT0)		 <- PBS (Pushbutton)
cbi DDRD, 4					; uC PD6 (PCINT[16]) <- RPG A
cbi DDRD, 5  				; uC PD5 (PCINT[17]) <- RPG B
; Outputs
sbi DDRB, 3  				; uC PB3 		-> LCD E (Enable)
sbi DDRB, 5					; uC PB5 		-> LCD RS (Register Select)
sbi DDRC, 0					; uC PC0 		-> LCD DB4
sbi DDRC, 1					; uC PC1 		-> LCD DB5
sbi DDRC, 2					; uC PC2 		-> LCD DB6
sbi DDRC, 3					; uC PC3 		-> LCD DB7
sbi DDRD, 3  				; uC PD3 (OC0B) -> Fan PWM

;==============| Configure Registers |===============
.def Tmp_Reg = R16			; Temporary register
.def Tmp_Data = R17			; Temporary data register
.def Cnt_Reg = R18			; Timer counter
.def RPG_Curr = R25			; Current RPG input state
.def RPG_Prev = R28			; previous RPG input state
.def DC = R21				; Duty cycle counter

; 16-bit r25division registers
.def drem16uL =r14
.def drem16uH =r15
.def dres16uL =r22
.def dres16uH =r23
.def dd16uL	  =r22
.def dd16uH	  =r23
.def dv16uL	  =r24
.def dv16uH	  =r19
.def dcnt16u  =r20

;==================| Initialize LCD |================
rcall Delay_100m			; wait to power up LCD
ldi Tmp_Data, 0x03			; Set 8-bit mode
rcall Send_Nibble
rcall Delay_5m
rcall Send_Nibble			; Set 8-bit mode
rcall Delay_200u
rcall Send_Nibble			; Set 8-bit mode
rcall Delay_200u
ldi Tmp_Data, 0x02			; Set 4-bit mode
rcall Send_Nibble
rcall Delay_5m
ldi Tmp_Data, 0x28			; Set interface
rcall Send_Instr
rcall Delay_100u
ldi Tmp_Data, 0x08			; dont shift display, hide cursor 
rcall Send_Instr
rcall Delay_100u
ldi Tmp_Data, 0x01			; Clear and home display
rcall Send_Instr
rcall Delay_5m
ldi Tmp_Data, 0x06			; move cursor right
rcall Send_Instr
rcall Delay_100u
ldi Tmp_Data, 0x0C			; turn on display
rcall Send_Instr
rcall Delay_100u

;============| Initialize PWM on timer2 |============
ldi Tmp_Reg, 0				; clear timer0
sts TCNT2, Tmp_Reg
ldi Tmp_Reg, 199			; set timer0 TOP val to 200
sts OCR2A, Tmp_Reg
ldi Tmp_Reg, 0x23			; configure timer0 to Fast PWM (mode 7)
sts TCCR2A, Tmp_Reg
ldi Tmp_Reg, 0x09
sts TCCR2B, Tmp_Reg
ldi Tmp_Reg, 0				; set timer0 duty cycle to 0
sts OCR2B, Tmp_Reg

;=============| Initialize RPG Interupt |============
ldi Tmp_Reg, (1<<PCINT20) | (1<<PCINT21)	; enable PCINT20 and PCINT21
sts PCMSK2, Tmp_Reg
ldi Tmp_Reg, (1<<PCIE2)		; enable PCINT2
sts PCICR, Tmp_Reg

;=============| Initialize PBS Interupt |============
ldi Tmp_Reg, (1<<ISC01)		; enable falling edge detection on INT0
sts EICRA, Tmp_Reg
sbi EIMSK, INT0				; enable INT0

;===================| Main Loop |====================
sei							; Enable interupts globally
ldi DC, 0					; initialize duty cycle counter to 0
ldi XH, 0					; initialize duty cycle display counter to 0
ldi XL, 5
rcall Send_Ln1				; Send initial string to LCD
rcall Send_Ln2
ldi Tmp_Data, 0x46			; 'F' for 'OFF'
rcall Push_Char				; push 'F' to LCD twice
rcall Push_Char
Main:
	nop						; take a short break before looping back
	nop
	rjmp Main				; loop Main

;==============| PBS Interupt Handling |=============
INT0_ISR:
	lds Tmp_Reg, PCICR
	cpi Tmp_Reg, (1<<PCIE2)	; if PCINT2 is enabled, turn fan off
	breq Fan_Off
	; Otherwise turn fan on
	rcall Send_Ln2			; display static string
	ldi Tmp_Data, 0x4E		; Push 'N' for 'ON'
	rcall Push_Char
	ldi Tmp_Data, 0x20		; Push space to remove last 'F' from 'OFF'
	rcall Push_Char
	sts OCR2B, DC			; set duty cycle back to DC
	ldi Tmp_Reg, (1<<PCIE2)	; enable PCINT2 (rpg interupts)
	sts PCICR, Tmp_Reg
	rjmp INT0_Exit
Fan_Off:
	rcall Send_Ln2			;display static display stuff
	ldi Tmp_Data, 0x46		; 'F' for 'OFF'
	rcall Push_Char			; push 'F' to LCD twice
	rcall Push_Char
	ldi Tmp_Reg, 0			; set duty cycle to 0
	sts OCR2B, Tmp_Reg
	clr Tmp_Reg
	sts PCICR, Tmp_Reg		; disable PCINT2 (rpg interupts)
INT0_Exit:
	rcall Delay_5m
	reti

;==============| RPG Interupt Handling |=============
PCINT2_ISR:
	in RPG_Curr, PIND
	andi RPG_Curr, 0x30		; Mask bits 5 and 4
	cpi RPG_Curr, 0x30		; if either is not set, return
	breq RPG_Detent
	mov RPG_Prev, RPG_Curr	; update RPG state
	rjmp PCINT2_Exit
RPG_Detent:
	cpi RPG_Prev, 0x10 		; if prev state was '01', branch to Incr
	breq Incr
	cpi RPG_Prev, 0x20 		; if prev state was '10', branch to Decr
	breq Decr
	rjmp PCINT2_Exit
Incr:
	ldi RPG_Prev, 0x30		; update RPG state to '11'
	cpi DC, 198				; if DC is at 100%, return
	breq PCINT2_Exit
	inc DC
	sts OCR2B, DC			; update timer0 duty cycle
	adiw X, 5				; increment duty cycle display counter
	rcall Send_Ln1			; update line 1 of LCD
	cpi DC, 32
	brne PCINT2_Exit
	rcall Send_Ln2			; update line 2 of LCD
	ldi Tmp_Data, 0x4E		; Push 'N' for 'ON'
	rcall Push_Char
	ldi Tmp_Data, 0x20		; Push space to remove last 'F' from 'OFF'
	rcall Push_Char
	rjmp PCINT2_Exit
Decr:
	ldi RPG_Prev, 0x30		; update RPG state to '11'
	cpi DC, 0				; if DC is at 0%, return
	breq PCINT2_Exit
	dec DC					; decrement DC counter
	sts OCR2B, DC			; update timer0 duty cycle
	sbiw X, 5				; decrement duty cycle display counter
	rcall Send_Ln1			; update line 1 of LCD
	cpi DC, 16
	brne PCINT2_Exit
	rcall Send_Ln2			; update line 2 of LCD
	ldi Tmp_Data, 0x46		; 'F' for 'OFF'
	rcall Push_Char			; push 'F' to LCD twice
	rcall Push_Char
PCINT2_Exit:
	reti

;===============| LCD Communication |================
; Write first line of LCD
Send_Ln1:
	ldi Tmp_Data, 0x80		; set DDRAM address to 0x00
	rcall Send_Instr
	sbi PORTB, 5			; set R/S | Data mode
	nop
	ldi r25, 9 				; r25 <-- length of the string
	ldi r30, LOW(2*ln1_static) 	; Load Z register low
	ldi r31, HIGH(2*ln1_static)	; Load Z register high
Send_Ln1_Loop:
	cpi r25, 4				; if r25 = 4, go to First_Variable
	breq First_Variable
	tst r25					; else if r25 != 0, go to Next_Static
	brne Next_Static
	ret						; else return
Next_Static:
	lpm	Tmp_Data, Z+		; load next byte from prog mem
	rcall Push_Char			; push character to LCD
	dec r25
	rjmp Send_Ln1_Loop
First_Variable:
	mov dres16uH, XH		; result <- DC display counter
	mov dres16uL, XL
Next_Variable:
	mov dd16uH, dres16uH	; dividend <- result
	mov dd16uL, dres16uL
	ldi dv16uH, 0x00		; divisor <- 10
	ldi dv16uL, 0x0A
	rcall div16u			; divide DC display counter by 10
	ldi Tmp_Reg, 0x30		; ASCII digit conversion offset
	mov Tmp_Data, drem16uL	; remainder <- DC display counter
	add Tmp_Data, Tmp_Reg	; convert remainder to ASCII value
	push Tmp_Data			; push remainder to stack
	dec r25
	cpi r25, 1				; Repeat until all digits calculated
	breq Write_Variable
	rjmp Next_Variable
Write_Variable:
	pop Tmp_Data			; pop digit from stack
	rcall Push_Char			; push to LCD
	pop Tmp_Data			; next digit
	rcall Push_Char
	ldi Tmp_Data, 0x2E		; push decimal point to LCD
	rcall Push_Char
	pop Tmp_Data			; next digit
	rcall Push_Char
	rjmp Send_Ln1_Loop
; Write second line of LCD
Send_Ln2:
	ldi Tmp_Data, 0xC0		; set DDRAM address to 0xC0
	rcall Send_Instr
	sbi PORTB, 5			; set R/S | Data mode
	nop
	ldi r25, 6 				; r25 <-- length of the string
	ldi r30, LOW(2*ln2_static) 	; Load Z register low
	ldi r31, HIGH(2*ln2_static)	; Load Z register high
Send_Ln2_Loop:
	lpm	Tmp_Data, Z+		; load next byte from prog mem
	rcall Push_Char			; push character to LCD
	dec r25
	brne Send_Ln2_Loop
	ret
; LCD shared subroutines
Push_Char:
	sbi PORTB, 5			; set R/S | select data register
	cbi PORTB, 3			; clear Enable
	swap Tmp_Data			; swap nibbles
	rcall Send_Nibble		; send upper nibble
	swap Tmp_Data			; swap nibbles back
	rcall Send_Nibble		; send lower nibble
	ret
Send_Instr:
	cbi PORTB, 5			; clear R/S | select instruction register
	cbi PORTB, 3			; clear Enable
	swap Tmp_Data			; swap nibbles
	rcall Send_Nibble		; send upper nibble
	swap Tmp_Data			; swap nibbles back
	rcall Send_Nibble		; send lower nibble
	ret
Send_Nibble:
	out PORTC, Tmp_Data		; send upper nibble
	nop
	sbi PORTB, 3			; drive E high (start strobe)
	nop						; 312 ns delay
	nop
	nop
	nop
	nop
	cbi PORTB, 3			; drive E low
	rcall Delay_100u		; give LCD time to process data
	ret

;==================| Time Delays |===================
Delay_100u:					; 112us delay
	ldi Cnt_Reg,7			; set  timer overflow counter to 7
	ldi Tmp_Reg, 0x01		; set prescaler to none
	out TCCR0B, Tmp_Reg		; output prescaler configurationv
	rjmp Delay_loop			; begin delay
Delay_200u:					; 208us delay
	ldi Cnt_Reg, 13			; set timer overflow counter to 13
	ldi Tmp_Reg, 0x01		; set prescaler to none
	out TCCR0B, Tmp_Reg		; output prescaler configuration
	rjmp Delay_loop			; begin delay
Delay_5m:					; 5.12ms delay
	ldi Cnt_Reg, 40			; set timer overflow counter to 40
	ldi Tmp_Reg, 0x02		; set prescaler to 8
	out TCCR0B, Tmp_Reg		; output prescaler configuration
	rjmp Delay_loop			; begin delay
Delay_100m:					; 100.35ms delay
	ldi Cnt_Reg, 98			; set timer overflow counter to 98
	ldi Tmp_Reg, 0x03		; set prescaler to 64
	out TCCR0B, Tmp_Reg		; output prescaler configuration
	rjmp Delay_loop			; begin delay
Delay_loop:
	in Tmp_Reg, TIFR0		; input timer2 interrupt flag register
	sbrs Tmp_Reg, 0			; if overflow flag is not set, loop
	rjmp Delay_loop
	ldi Tmp_Reg, (1<<TOV0)	; acknowledge overflow flag
	out TIFR0, Tmp_Reg		; output to timer0 interrupt flag register
	dec Cnt_Reg				; Decrement Timer counter
	brne Delay_loop			; if Timer counter is zero, loop
	ret						; otherwise, return

;==================| 16-bit Division |===================
div16u:
	clr	drem16uL			; clear remainder Low byte
	sub	drem16uH,drem16uH	; clear remainder High byte and carry
	ldi	dcnt16u,17			; init loop counter
d16u_1:
	rol	dd16uL				; shift left dividend
	rol	dd16uH
	dec	dcnt16u				; decrement counter
	brne d16u_2				; if done
	ret						; return
d16u_2:
	rol	drem16uL			; shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL		; remainder = remainder - divisor
	sbc	drem16uH,dv16uH
	brcc d16u_3				; if result negative
	add	drem16uL,dv16uL		; restore remainder
	adc	drem16uH,dv16uH
	clc						; clear carry to be shifted into result
	rjmp d16u_1				; else
d16u_3:
	sec						; set carry to be shifted into result
	rjmp d16u_1
