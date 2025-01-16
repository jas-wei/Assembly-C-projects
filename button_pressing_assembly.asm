;
; a3part-C.asm
;
; Part C of assignment #3
;
;
; Student name: Jasmine Wei
; Student ID:V01017208
; Date of completed work: March 23, 2024
;
; **********************************
; Code provided for Assignment #3
;
; Author: Mike Zastre (2022-Nov-05)
;
; This skeleton of an assembly-language program is provided to help you 
; begin with the programming tasks for A#3. As with A#2 and A#1, there are
; "DO NOT TOUCH" sections. You are *not* to modify the lines within these
; sections. The only exceptions are for specific changes announced on
; Brightspace or in written permission from the course instruction.
; *** Unapproved changes could result in incorrect code execution
; during assignment evaluation, along with an assignment grade of zero. ***
;


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================
;
; In this "DO NOT TOUCH" section are:
; 
; (1) assembler direction setting up the interrupt-vector table
;
; (2) "includes" for the LCD display
;
; (3) some definitions of constants that may be used later in
;     the program
;
; (4) code for initial setup of the Analog-to-Digital Converter
;     (in the same manner in which it was set up for Lab #4)
;
; (5) Code for setting up three timers (timers 1, 3, and 4).
;
; After all this initial code, your own solutions's code may start
;

.cseg
.org 0
	jmp reset

; Actual .org details for this an other interrupt vectors can be
; obtained from main ATmega2560 data sheet
;
.org 0x22
	jmp timer1

; This included for completeness. Because timer3 is used to
; drive updates of the LCD display, and because LCD routines
; *cannot* be called from within an interrupt handler, we
; will need to use a polling loop for timer3.
;
; .org 0x40
;	jmp timer3

.org 0x54
	jmp timer4

.include "m2560def.inc"
.include "lcd.asm"

.cseg
#define CLOCK 16.0e6
#define DELAY1 0.01
#define DELAY3 0.1
#define DELAY4 0.5

#define BUTTON_RIGHT_MASK 0b00000001	
#define BUTTON_UP_MASK    0b00000010
#define BUTTON_DOWN_MASK  0b00000100
#define BUTTON_LEFT_MASK  0b00001000

;changed
#define BUTTON_RIGHT_ADC  0x052
#define BUTTON_UP_ADC     0x0d0   ; was 0x0c3
#define BUTTON_DOWN_ADC   0x180   ; was 0x17c
#define BUTTON_LEFT_ADC   0x24b
#define BUTTON_SELECT_ADC 0x336

.equ PRESCALE_DIV=1024   ; w.r.t. clock, CS[2:0] = 0b101

; TIMER1 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP1=int(0.5+(CLOCK/PRESCALE_DIV*DELAY1))
.if TOP1>65535
.error "TOP1 is out of range"
.endif

; TIMER3 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP3=int(0.5+(CLOCK/PRESCALE_DIV*DELAY3))
.if TOP3>65535
.error "TOP3 is out of range"
.endif

; TIMER4 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP4=int(0.5+(CLOCK/PRESCALE_DIV*DELAY4))
.if TOP4>65535
.error "TOP4 is out of range"
.endif

reset:
; ***************************************************
; **** BEGINNING OF FIRST "STUDENT CODE" SECTION ****
; ***************************************************

; Anything that needs initialization before interrupts
; start must be placed here.
; symbonic names for registers

.def DATAH=r25  ;DATAH:DATAL  store 10 bits data from ADC
.def DATAL=r24
.def LETTER_H=r19
.def LETTER_L=r18
.def BOUNDARY_H=r1  ;hold high byte value of the threshold for button
.def BOUNDARY_L=r0  ;hold low byte value of the threshold for button, r1:r0

; Definitions for using the Analog to Digital Conversion
.equ ADCSRA_BTN=0x7A
.equ ADCSRB_BTN=0x7B
.equ ADMUX_BTN=0x7C
.equ ADCH_BTN=0x79
.equ ADCL_BTN=0x78

;stack
ldi r16, low(RAMEND)
ldi r17, high(RAMEND)
out SPL, r16
out SPH, r17

; upper lim 
.equ THRESHOLD = 900

.equ CHAR1 ='-'
.equ CHAR2 ='*'

; check if ADC val is greater than 900 or not, if it is, then skip, if not, then continue
ldi r16, low(THRESHOLD)   ; Load the low byte of the immediate value into register r16
mov BOUNDARY_L, r16   ; Store the value in register r16 into the memory location BOUNDARY_L
ldi r16, high(THRESHOLD)  ; Load the high byte of the immediate value into register r16
mov BOUNDARY_H, r16


; Initialize TOP_LINE_CONTENT default
;make sure that top line is cleared
push ZH
push ZL

ldi ZH, high(TOP_LINE_CONTENT)
ldi ZL, low(TOP_LINE_CONTENT)

ldi r17, ' '
ldi r16, 16 ;we want to iterate 16 times
loop1:
	st Z+, r17
	dec r16
	brne loop1 ;keep looping through 16 times to set TLC to ' '

; Initialize CURRENT_CHARSET_INDEX default
;make sure that charset is all 0
ldi ZH, high(CURRENT_CHARSET_INDEX)
ldi ZL, low(CURRENT_CHARSET_INDEX)

ldi r17, 0
ldi r16, 16
loop2:
	st Z+, r17
	dec r16
	brne loop2 ;keep looping through 16 times
pop ZL
pop ZH

; Initialize char index to 0
sts CURRENT_CHAR_INDEX, r17 ; set to 0

; load ' ' into each button's display value
ldi r16, ' '
sts L, r16
sts D, r16
sts U, r16
sts R, r16

; ***************************************************
; ******* END OF FIRST "STUDENT CODE" SECTION *******
; ***************************************************

; =============================================
; ====  START OF "DO NOT TOUCH" SECTION    ====
; =============================================

	; initialize the ADC converter (which is needed
	; to read buttons on shield). Note that we'll
	; use the interrupt handler for timer 1 to
	; read the buttons (i.e., every 10 ms)
	;
	ldi temp, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
	sts ADCSRA, temp
	ldi temp, (1 << REFS0)
	sts ADMUX, r16

	; Timer 1 is for sampling the buttons at 10 ms intervals.
	; We will use an interrupt handler for this timer.
	ldi r17, high(TOP1)
	ldi r16, low(TOP1)
	sts OCR1AH, r17
	sts OCR1AL, r16
	clr r16
	sts TCCR1A, r16
	ldi r16, (1 << WGM12) | (1 << CS12) | (1 << CS10)
	sts TCCR1B, r16
	ldi r16, (1 << OCIE1A)
	sts TIMSK1, r16

	; Timer 3 is for updating the LCD display. We are
	; *not* able to call LCD routines from within an 
	; interrupt handler, so this timer must be used
	; in a polling loop.
	ldi r17, high(TOP3)
	ldi r16, low(TOP3)
	sts OCR3AH, r17
	sts OCR3AL, r16
	clr r16
	sts TCCR3A, r16
	ldi r16, (1 << WGM32) | (1 << CS32) | (1 << CS30)
	sts TCCR3B, r16
	; Notice that the code for enabling the Timer 3
	; interrupt is missing at this point.

	; Timer 4 is for updating the contents to be displayed
	; on the top line of the LCD.
	ldi r17, high(TOP4)
	ldi r16, low(TOP4)
	sts OCR4AH, r17
	sts OCR4AL, r16
	clr r16
	sts TCCR4A, r16
	ldi r16, (1 << WGM42) | (1 << CS42) | (1 << CS40)
	sts TCCR4B, r16
	ldi r16, (1 << OCIE4A)
	sts TIMSK4, r16

	sei

; =============================================
; ====    END OF "DO NOT TOUCH" SECTION    ====
; =============================================

; ****************************************************
; **** BEGINNING OF SECOND "STUDENT CODE" SECTION ****
; ****************************************************

start:
	rcall lcd_init
	rjmp timer3
	
stop:
	rjmp stop


timer1:
	push r20
	push r23
	
	;a2d
	lds r20, ADCSRA_BTN

	; bit 6 =1 ADSC (ADC start coversion bit), remain 1 if conversion not done
	; ADSC changed to 0 if conversion is d
	ori r20, 0x40 ; 0x40 = 0b01000000
	sts ADCSRA_BTN, r20

	;check if it is converting analogue to digital yet
	wait: 
		lds r20, ADCSRA_BTN
		andi r20, 0x40
		brne wait

	lds DATAL, ADCL_BTN
	lds DATAH, ADCH_BTN

	;resetting button_is_pressed to 0
	clr r23
	sts BUTTON_IS_PRESSED, r23

	;comparing if data from button press to upper bound of 900
	cp DATAL, BOUNDARY_L
	cpc DATAH, BOUNDARY_H

	; skips indented part if it is greater than 900 (press not registered)
	brsh skip_is_button_pressed
		; stores that 1 into BUTTON_IS_PRESSED for true
		ldi r23, 1
		sts BUTTON_IS_PRESSED, r23

		;check right button
		;Load 50 into letters
		ldi LETTER_L, low(BUTTON_RIGHT_ADC)    
		ldi LETTER_H, high(BUTTON_RIGHT_ADC)
		; Compare data with 50
		cp DATAL, LETTER_L
		cpc DATAH, LETTER_H   

		brlo right_pressed  ; If number < 50, jump to below_50

		;check up button
		;Load 176 into letters
		ldi LETTER_L, low(BUTTON_UP_ADC)    
		ldi LETTER_H, high(BUTTON_UP_ADC)
		; Compare data with 176
		cp DATAL, LETTER_L
		cpc DATAH, LETTER_H 

		brlo up_pressed

		;check down button
		;Load 352 into letters
		ldi LETTER_L, low(BUTTON_DOWN_ADC)    
		ldi LETTER_H, high(BUTTON_DOWN_ADC)
		; Compare data with 352
		cp DATAL, LETTER_L
		cpc DATAH, LETTER_H 

		brlo down_pressed

		;check left button
		;Load 555 into letters
		ldi LETTER_L, low(BUTTON_LEFT_ADC)    
		ldi LETTER_H, high(BUTTON_LEFT_ADC)
		; Compare data with 555
		cp DATAL, LETTER_L
		cpc DATAH, LETTER_H 

		brlo left_pressed
		none_pressed:
			ldi r23, 'N'; button pressed set to right
			sts LAST_BUTTON_PRESSED, r23
			rjmp check_button_end

		right_pressed:
			ldi r23, 'R'; button pressed set to right
			sts LAST_BUTTON_PRESSED, r23
			rjmp check_button_end

		up_pressed:
			ldi r23, 'U'; button pressed set to up
			sts LAST_BUTTON_PRESSED, r23
			rjmp check_button_end

		down_pressed:
			ldi r23, 'D'; button pressed set to down
			sts LAST_BUTTON_PRESSED, r23
			rjmp check_button_end

		left_pressed:
			ldi r23, 'L'; button pressed set to left
			sts LAST_BUTTON_PRESSED, r23
			rjmp check_button_end

		check_button_end:
	skip_is_button_pressed: 

	pop r23
	pop r20

	reti

timer3:
; push temp and all variables and pop it
	push temp
	push r16
	push r17
	push r20
	push r21

	in temp, TIFR3
	sbrs temp, OCF3A
	rjmp timer3

	;resets flag
	ldi r21, (1<<OCF3A)
	out TIFR3, r21

	;set the cursor to row 1, column 15
	ldi r16, 1 
	ldi r17, 15 
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16
		
	lds r16, BUTTON_IS_PRESSED
	cpi r16, 1

	breq is_char2
		is_char1:
			ldi r17, CHAR1
			push r17
			rcall lcd_putchar
			pop r17
			rjmp button_end

		is_char2:
			ldi r17, CHAR2
			push r17
			rcall lcd_putchar
			pop r17
	button_end:
	
	; check if right is pressed
	ldi r20, ' ' ;space
	lds r16, LAST_BUTTON_PRESSED
	cpi r16, 'R'
	brne right_not_pressed
		;right button pressed
		sts L, r20
		sts D, r20
		sts U, r20
		sts R, r16
		rjmp letter_end
	; check if up is pressed
	right_not_pressed:
	cpi r16, 'U'
	brne up_not_pressed
		;up button pressed
		sts L, r20
		sts D, r20
		sts U, r16
		sts R, r20
		rjmp letter_end
	; check if down is pressed
	up_not_pressed:
	cpi r16, 'D'
	brne down_not_pressed
		;down button pressed
		sts L, r20
		sts D, r16
		sts U, r20
		sts R, r20
		rjmp letter_end
	; check if left is pressed
	down_not_pressed:
	cpi r16, 'L'
	brne left_not_pressed
		;down button pressed
		sts L, r16
		sts D, r20
		sts U, r20
		sts R, r20
		rjmp letter_end
	left_not_pressed:
	cpi r16, 'N'
		;no valid button pressed
		sts L, r20
		sts D, r20
		sts U, r20
		sts R, r20

	letter_end:

	;set the cursor to row 1, column 0
	ldi r16, 1 
	ldi r17, 0
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16

	;push the results from the different buttons
	lds r16, L
	push r16
	rcall lcd_putchar
	pop r16

	lds r16, D
	push r16
	rcall lcd_putchar
	pop r16

	lds r16, U
	push r16
	rcall lcd_putchar
	pop r16

	lds r16, R
	push r16
	rcall lcd_putchar
	pop r16

	push XL
	push XH

	; set cursor to the current index
	ldi r16, 0 ;row: 0
	lds r17, CURRENT_CHAR_INDEX ;column: index
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi XH, high(TOP_LINE_CONTENT) ; this is getting the pointer to the first column of TOP_LINE_CONTENT
	ldi XL, low(TOP_LINE_CONTENT)

	clr r16 
	lds r22, CURRENT_CHAR_INDEX ;column: index

	;To get a specific index at pointer for TOP_LINE_CONTENT
	add XL, r22 ;adding with CURRENT_CHAR_INDEX
	adc XH, r16 ;empty register

	ld r17, X
	push r17
	rcall lcd_putchar
	pop r17
	
	pop XH
	pop XL

	pop r21
	pop r20
	pop r17
	pop r16
	pop temp

	rjmp timer3
;
; Note: There is no "timer3" interrupt handler as you must use
; timer3 in a polling style (i.e. it is used to drive the refreshing
; of the LCD display, but LCD functions cannot be called/used from
; within an interrupt handler).


timer4:
	clr r16
	clr r17
	clr r20
	clr r21
	clr r22
	clr r23
	push r16
	push r17
	push r20
	push r21
	push r22
	push r23

	push ZL
	push ZH
	push XL
	push XH
	push YL
	push YH
	
	;if the value is equal 0 no button pressed
	lds r20, BUTTON_IS_PRESSED
	cpi r20, 0
	brne skip_timer_4_end
	jmp end_timer4
	skip_timer_4_end:
		;load the value of CURRENT_CHAR_INDEX into r22. shows the column of lcd we are at rn
		lds r22, CURRENT_CHAR_INDEX

		;first index's address of CURRENT_CHARSET_INDEX
		ldi XL, low(CURRENT_CHARSET_INDEX)
		ldi XH, high(CURRENT_CHARSET_INDEX)

		;updating CURRENT_CHAR_INDEX's pointer
		add XL, r22 ; CURRENT_CHAR_INDEX
		adc XH, r16 ;empty register
		
		;load the value from CURRENT_CHARSET_INDEX (each byte is holding the index of the character from AVAILABLE_CHARSET for each column on lcd)
		;add the offset to the pointer at AVAILABLE_CHARSET so that we are now looking at the current value in AVAILABLE_CHARSET for our current index
		;so we are starting where we left off essentially

		ld r21, X; this is getting index of character at column of lcd
		ldi ZL, low(AVAILABLE_CHARSET<<1)
		ldi ZH, high(AVAILABLE_CHARSET<<1)

		add ZL, r21 ; 
		adc ZH, r16 ;empty register

		;check if up button is being pressed
		lds r20, LAST_BUTTON_PRESSED
		cpi r20, 'U'
		brne check_D
			inc r21 ;increase CURRENT_CHARSET_INDEX of that certain column
			adiw Z, 1
			lpm r23, Z ;get character at current index
			cpi r23, 0 ;sees if AVAILABLE_CHARSET value at Z is 0, if it is, then branch
			brne skip_loop_char_begining
				ldi r21, 0

				;reset pointer
				ldi ZL, low(AVAILABLE_CHARSET<<1)
				ldi ZH, high(AVAILABLE_CHARSET<<1)

				add ZL, r21 
				adc ZH, r16 ;empty register
				lpm r23, Z ;get character at current index
			skip_loop_char_begining:

			;store the offset of charlist at the pointer 
			st X, r21 

			; store the value from char list using the address/offset of the value that is stored in CURRENT_CHARSET_INDEX
			ldi YL, low(TOP_LINE_CONTENT)
			ldi YH, high(TOP_LINE_CONTENT)

			; update pointer of TOP_LINE_CONTENT to current index
			add YL, r22 ; CURRENT_CHAR_INDEX (index offset to TOP_LINE_CONTENT)
			adc YH, r16 ;empty register

			; store the value that was loaded from char list in r23 into the pointer at TOP_LINE_CONTENT's current index
			st Y, r23
			rjmp end_timer4
		check_D:

		;check if down button is being pressed
		cpi r20, 'D'
		brne check_R
			dec r21 ;decrease CURRENT_CHARSET_INDEX of that certain column
			sbiw Z, 1
			lpm r23, Z ;get character at current index
			cpi r23, '0' ;sees if AVAILABLE_CHARSET value at Z is 0, if it is, then branch
			brne skip_loop_char_end
				ldi r21, 16
				
				;reset pointer
				ldi ZL, low(AVAILABLE_CHARSET<<1)
				ldi ZH, high(AVAILABLE_CHARSET<<1)

				add ZL, r21 
				adc ZH, r16 ;empty register
			skip_loop_char_end:

			;store the register holding the offset for that char list into X(the pointer to that index in CURRENT_CHARSET_INDEX)
			ldi XL, low(CURRENT_CHARSET_INDEX)
			ldi XH, high(CURRENT_CHARSET_INDEX)

			clr r16

			; update pointer of CURRENT_CHARSET_INDEX to current index
			add XL, r22 ; CURRENT_CHAR_INDEX (index offset to CURRENT_CHARSET_INDEX)
			adc XH, r16 ;empty register

			;store the offset of charlist at the pointer 
			st X, r21 

			; store the value from char list using the address/offset of the value that is stored in CURRENT_CHARSET_INDEX
			ldi YL, low(TOP_LINE_CONTENT)
			ldi YH, high(TOP_LINE_CONTENT)

			; update pointer of TOP_LINE_CONTENT to current index
			add YL, r22 ; CURRENT_CHAR_INDEX (index offset to TOP_LINE_CONTENT)
			adc YH, r16 ;empty register

			; store the value that was loaded from char list in r23 into the pointer at TOP_LINE_CONTENT's current index
			st Y, r23
			rjmp end_timer4
		check_R:

		;check if right button is being pressed
		cpi r20, 'R'
		brne check_L
			inc r22 ;increase CURRENT_CHAR_INDEX. move index to the right
			cpi r22, 15 ;see if index out of bound to the right, if so, branch
			brne skip_loop_lcd_begining
				ldi r22, 0
			skip_loop_lcd_begining:
			sts CURRENT_CHAR_INDEX, r22
			rjmp end_timer4
		check_L:

		;check if left button is being pressed
		cpi r20, 'L'
		brne end_timer4
			dec r22 ;increase CURRENT_CHAR_INDEX. move index to the right
			cpi r22, 0 ;see if index out of bound to the right, if so, branch
			brne skip_loop_lcd_end
				ldi r22, 15
			skip_loop_lcd_end:
			sts CURRENT_CHAR_INDEX, r22
			rjmp end_timer4

	end_timer4:
	pop YH
	pop YL
	pop XH
	pop XL
	pop ZH
	pop ZL

	pop r23
	pop r22
	pop r21
	pop r20
	pop r17
	pop r16
	reti


; ****************************************************
; ******* END OF SECOND "STUDENT CODE" SECTION *******
; ****************************************************


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

; r17:r16 -- word 1
; r19:r18 -- word 2
; word 1 < word 2? return -1 in r25
; word 1 > word 2? return 1 in r25
; word 1 == word 2? return 0 in r25
;
compare_words:
	; if high bytes are different, look at lower bytes
	cp r17, r19
	breq compare_words_lower_byte

	; since high bytes are different, use these to
	; determine result
	;
	; if C is set from previous cp, it means r17 < r19
	; 
	; preload r25 with 1 with the assume r17 > r19
	ldi r25, 1
	brcs compare_words_is_less_than
	rjmp compare_words_exit

compare_words_is_less_than:
	ldi r25, -1
	rjmp compare_words_exit

compare_words_lower_byte:
	clr r25
	cp r16, r18
	breq compare_words_exit

	ldi r25, 1
	brcs compare_words_is_less_than  ; re-use what we already wrote...

compare_words_exit:
	ret

.cseg
AVAILABLE_CHARSET: .db "0123456789abcdef_", 0


.dseg

BUTTON_IS_PRESSED: .byte 1			; updated by timer1 interrupt, used by LCD update loop
LAST_BUTTON_PRESSED: .byte 1        ; updated by timer1 interrupt, used by LCD update loop

TOP_LINE_CONTENT: .byte 16			; updated by timer4 interrupt, used by LCD update loop
CURRENT_CHARSET_INDEX: .byte 16		; updated by timer4 interrupt, used by LCD update loop
CURRENT_CHAR_INDEX: .byte 1			; ; updated by timer4 interrupt, used by LCD update loop


; =============================================
; ======= END OF "DO NOT TOUCH" SECTION =======
; =============================================


; ***************************************************
; **** BEGINNING OF THIRD "STUDENT CODE" SECTION ****
; ***************************************************

.dseg

L: .byte 1
D: .byte 1
U: .byte 1
R: .byte 1

; If you should need additional memory for storage of state,
; then place it within the section. However, the items here
; must not be simply a way to replace or ignore the memory
; locations provided up above.


; ***************************************************
; ******* END OF THIRD "STUDENT CODE" SECTION *******
; ***************************************************




