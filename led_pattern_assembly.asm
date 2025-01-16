; a2-signalling.asm
; CSC 230: Fall 2022
;
; Student name:
; Student ID:
; Date of completed work:
;
; *******************************
; Code provided for Assignment #2
;
; Author: Mike Zastre (2022-Oct-15)
;
 
; This skeleton of an assembly-language program is provided to help you
; begin with the programming tasks for A#2. As with A#1, there are "DO
; NOT TOUCH" sections. You are *not* to modify the lines within these
; sections. The only exceptions are for specific changes changes
; announced on Brightspace or in written permission from the course
; instructor. *** Unapproved changes could result in incorrect code
; execution during assignment evaluation, along with an assignment grade
; of zero. ****

.include "m2560def.inc"
.cseg
.org 0

; ***************************************************
; **** BEGINNING OF FIRST "STUDENT CODE" SECTION ****
; ***************************************************

	; initializion code will need to appear in this
    ; section

	ldi r16, high(0X21ff)
	out SPH, r16
	ldi r16, low(0X21ff)
	out SPL, r16

	out PORTB, r17
	sts PORTL, r17
	clr r16
	clr r17


; ***************************************************
; **** END OF FIRST "STUDENT CODE" SECTION **********
; ***************************************************

; ---------------------------------------------------
; ---- TESTING SECTIONS OF THE CODE -----------------
; ---- TO BE USED AS FUNCTIONS ARE COMPLETED. -------
; ---------------------------------------------------
; ---- YOU CAN SELECT WHICH TEST IS INVOKED ---------
; ---- BY MODIFY THE rjmp INSTRUCTION BELOW. --------
; -----------------------------------------------------

	;rjmp test_part_a
	;rjmp test_part_b
	;rjmp test_part_c
	;rjmp test_part_d
	rjmp test_part_e
	; Test code


test_part_a:
	ldi r16, 0b00100000
	rcall set_leds
	rcall delay_long

	clr r16
	rcall set_leds
	rcall delay_long

	ldi r16, 0b00111000
	rcall set_leds
	rcall delay_short

	clr r16
	rcall set_leds
	rcall delay_long

	ldi r16, 0b00100001
	rcall set_leds
	rcall delay_long

	clr r16
	rcall set_leds

	rjmp end


test_part_b:
	ldi r17, 0b00101010
	rcall slow_leds
	ldi r17, 0b00010101
	rcall slow_leds
	ldi r17, 0b00101010
	rcall slow_leds
	ldi r17, 0b00010101
	rcall slow_leds

	rcall delay_long
	rcall delay_long

	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds
	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds
	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds
	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds

	rjmp end

test_part_c:
	ldi r16, 0b11111000
	push r16
	rcall leds_with_speed
	pop r16

	ldi r16, 0b11011100
	push r16
	rcall leds_with_speed
	pop r16

	ldi r20, 0b00100000
test_part_c_loop:
	push r20
	rcall leds_with_speed
	pop r20
	lsr r20
	brne test_part_c_loop

	rjmp end


test_part_d:
	ldi r21, 'E'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long

	ldi r21, 'A'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long


	ldi r21, 'M'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long

	ldi r21, 'H'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long

	rjmp end


test_part_e:
	ldi r25, HIGH(WORD10 << 1)
	ldi r24, LOW(WORD10 << 1)
	rcall display_message
	rjmp end

end:
    rjmp end






; ****************************************************
; **** BEGINNING OF SECOND "STUDENT CODE" SECTION ****
; ****************************************************

set_leds:
	clr r17
	clr r18
	push r16
	andi r16, 0b00000001
	breq skip1
		ori r18, 0b10000000
	skip1:
	pop r16
	push r16
	andi r16, 0b00000010
	breq skip2
		ori r18, 0b00100000
	skip2:
	pop r16
	push r16
	andi r16, 0b00000100
	breq skip3
		ori r18, 0b00001000
	skip3:
	pop r16
	push r16
	andi r16, 0b00001000
	breq skip4
		ori r18, 0b00000010
	skip4:
	pop r16
	push r16
	andi r16, 0b00010000
	breq skip5
		ori r17, 0b00001000
	skip5:
	pop r16
	push r16
	andi r16, 0b00100000
	breq skip6
		ori r17, 0b00000010
	skip6:

	out PORTB, r17
	sts PORTL, r18
	pop r16
	clr r16
	clr r17
	clr r18
	ret


slow_leds:
	mov r16, r17
	clr r17
	rcall set_leds
	rcall delay_long
	clr r16
	out PORTB, r16
	sts PORTL, r16

	ret


fast_leds:
	mov r16, r17
	clr r17
	rcall set_leds
	rcall delay_short
	clr r16
	out PORTB, r16
	sts PORTL, r16
	;rcall set_leds
	ret


leds_with_speed:
	;save z register in stack
	push ZL
	push ZH
	;load stack pointer's values into the Z register
	in ZH, SPH
	in ZL, SPL

	ldd r17, Z+6
	
	push r17
	andi r17, 0b11000000
	cpi r17, 0b11000000
	pop r17

	breq speed_skip2
		rcall fast_leds
		rjmp speed_end
	speed_skip2:
	rcall slow_leds
	speed_end:
	pop r16
	pop r16
	clr ZH
	clr ZL

	clr r16
	out PORTB, r16
	sts PORTL, r16

	clr r17
	clr r18
	clr r19
	clr r20
	clr r21
	clr r23
	clr r24


	ret


; Note -- this function will only ever be tested
; with upper-case letters, but it is a good idea
; to anticipate some errors when programming (i.e. by
; accidentally putting in lower-case letters). Therefore
; the loop does explicitly check if the hyphen/dash occurs,
; in which case it terminates with a code not found
; for any legal letter.

encode_letter:
	;initialize Z register to start of the patterns in program memory address
	clr r25
	push ZL
	push ZH

	in ZH, SPH
	in ZL, SPL
	
	;pop the three return addresses and finally the parameter that was pushed before function was called
	;parameter is stored in r20
	ldd r20, Z+6

	ldi r31, high(PATTERNS<<1)
	ldi r30, low(PATTERNS<<1)

	;check which letter from address in program memory has the same byte pattern as the letter in parameter
	check_letter:
		lpm r16, Z+
		cp r16, r20
		brne check_letter
	
	;loop through the patterns in program memory, masking out a result in r25 by setting bits when we encounter 6f (an "o")
	ldi r22, 6
	ldi r23, 0b00100000
	mask_loop:
		lpm r16, Z+8
		cpi r16, 0X2e
		breq skip_to_unset
			or r25, r23
		skip_to_unset:
		lsr r23
		dec r22
		brne mask_loop

	; this stores the number after pattern
	lpm r21, Z
	clr ZH
	clr ZL

	;check if number after pattern is "2" (short)
	cpi r21, 2

	;if it is "2", then skip to the end, making it short duration
	;if it is NOT "2", then ori with 0b11000000, making it long
	brne encode_skip
		rjmp encode_end

	encode_skip:
		ori r25, 0b11000000

	encode_end:

	pop r16
	pop r16
	clr r16

	ret




display_message:

	mov XH, r25
	mov XL, r24


	itterate_letter:
		mov ZH, XH
		mov ZL, XL
		lpm r21, Z
		cpi r21, 0
		breq itterate_break
		push r21
		rcall encode_letter
		pop r21
		push r25
		rcall leds_with_speed
		pop r25
		rcall delay_long
		adiw X, 1
		rjmp itterate_letter

	itterate_break:
	ret


; ****************************************************
; **** END OF SECOND "STUDENT CODE" SECTION **********
; ****************************************************




; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

; about one second
delay_long:
	push r16

	ldi r16, 14
delay_long_loop:
	rcall delay
	dec r16
	brne delay_long_loop

	pop r16
	ret


; about 0.25 of a second
delay_short:
	push r16

	ldi r16, 4
delay_short_loop:
	rcall delay
	dec r16
	brne delay_short_loop

	pop r16
	ret

; When wanting about a 1/5th of a second delay, all other
; code must call this function
;
delay:
	rcall delay_busywait
	ret


; This function is ONLY called from "delay", and
; never directly from other code. Really this is
; nothing other than a specially-tuned triply-nested
; loop. It provides the delay it does by virtue of
; running on a mega2560 processor.
;
delay_busywait:
	push r16
	push r17
	push r18

	ldi r16, 0x08
delay_busywait_loop1:
	dec r16
	breq delay_busywait_exit

	ldi r17, 0xff
delay_busywait_loop2:
	dec r17
	breq delay_busywait_loop1

	ldi r18, 0xff
delay_busywait_loop3:
	dec r18
	breq delay_busywait_loop2
	rjmp delay_busywait_loop3

delay_busywait_exit:
	pop r18
	pop r17
	pop r16
	ret


 ;Some tables
;.cseg
;.org 0x200

PATTERNS:
	; LED pattern shown from left to right: "." means off, "o" means
    ; on, 1 means long/slow, while 2 means short/fast.
	.db "A", "..oo..", 1
	.db "B", ".o..o.", 2
	.db "C", "o.o...", 1
	.db "D", ".....o", 1
	.db "E", "oooooo", 1
	.db "F", ".oooo.", 2
	.db "G", "oo..oo", 2
	.db "H", "..oo..", 2
	.db "I", ".o..o.", 1
	.db "J", ".....o", 2
	.db "K", "....oo", 2
	.db "L", "o.o.o.", 1
	.db "M", "oooooo", 2
	.db "N", "oo....", 1
	.db "O", ".oooo.", 1
	.db "P", "o.oo.o", 1
	.db "Q", "o.oo.o", 2
	.db "R", "oo..oo", 1
	.db "S", "....oo", 1
	.db "T", "..oo..", 1
	.db "U", "o.....", 1
	.db "V", "o.o.o.", 2
	.db "W", "o.o...", 2
	.db "X", "oo....", 2
	.db "Y", "..oo..", 2
	.db "Z", "o.....", 2
	.db "-", "o...oo", 1   ; Just in case!

WORD00: .db "HELLOWORLD", 0, 0
WORD01: .db "THE", 0
WORD02: .db "QUICK", 0
WORD03: .db "BROWN", 0
WORD04: .db "FOX", 0
WORD05: .db "JUMPED", 0, 0
WORD06: .db "OVER", 0, 0
WORD07: .db "THE", 0
WORD08: .db "LAZY", 0, 0
WORD09: .db "DOG", 0
WORD10: .db "ABC", 0

; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================




