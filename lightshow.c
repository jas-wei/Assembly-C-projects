/* a4.c
 * CSC Fall 2022
 * 
 * Student name: Jasmine Wei
 * Student UVic ID: V01017208
 * Date of completed work: April 2, 2024
 *
 *
 * Code provided for Assignment #4
 *
 * Author: Mike Zastre (2022-Nov-22)
 *
 * This skeleton of a C language program is provided to help you
 * begin the programming tasks for A#4. As with the previous
 * assignments, there are "DO NOT TOUCH" sections. You are *not* to
 * modify the lines within these section.
 *
 * You are also NOT to introduce any new program-or file-scope
 * variables (i.e., ALL of your variables must be local variables).
 * YOU MAY, however, read from and write to the existing program- and
 * file-scope variables. Note: "global" variables are program-
 * and file-scope variables.
 *
 * UNAPPROVED CHANGES to "DO NOT TOUCH" sections could result in
 * either incorrect code execution during assignment evaluation, or
 * perhaps even code that cannot be compiled.  The resulting mark may
 * be zero.
 */


/* =============================================
 * ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
 * =============================================
 */

#define __DELAY_BACKWARD_COMPATIBLE__ 1
#define F_CPU 16000000UL

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

#define DELAY1 0.000001
#define DELAY3 0.01

#define PRESCALE_DIV1 8
#define PRESCALE_DIV3 64
#define TOP1 ((int)(0.5 + (F_CPU/PRESCALE_DIV1*DELAY1))) 
#define TOP3 ((int)(0.5 + (F_CPU/PRESCALE_DIV3*DELAY3)))

#define PWM_PERIOD ((long int)500)

volatile long int count = 0;
volatile long int slow_count = 0;


ISR(TIMER1_COMPA_vect) {
	count++;
}


ISR(TIMER3_COMPA_vect) {
	slow_count += 5;
}

/* =======================================
 * ==== END OF "DO NOT TOUCH" SECTION ====
 * =======================================
 */


/* *********************************************
 * **** BEGINNING OF "STUDENT CODE" SECTION ****
 * *********************************************
 */

void led_state(uint8_t LED, uint8_t state) {
	// sets DDRL
	DDRL = 0xFF;
	
	// switch statement comparing the led number and state, setting PORTL appropriately
	switch (LED) {
		case 0:
			if (state==1){
				PORTL |= 0b10000000;
			} 
			else{
				PORTL &= 0b01111111;
			}
		break;
		case 1:
			if (state==1){
				PORTL |= 0b00100000;
			}
			else{
				PORTL &= 0b11011111;
			}
		break;
		case 2:
			if (state==1){
				PORTL |= 0b00001000;
			}
			else{
				PORTL &= 0b11110111;
			}
		break;
		case 3:
			if (state==1){
				PORTL |= 0b00000010;
			}
			else{
				PORTL &= 0b11111101;
			}
		break;
		default:
		PORTL = 0b00000000;
		break;
	}
}

void SOS() {
	// array with light patterns
    uint8_t light[] = {
        0x1, 0, 0x1, 0, 0x1, 0,
        0xf, 0, 0xf, 0, 0xf, 0,
        0x1, 0, 0x1, 0, 0x1, 0,
        0x0
    };
	
	// array with duration of each light pattern
    int duration[] = {
        100, 250, 100, 250, 100, 500,
        250, 250, 250, 250, 250, 500,
        100, 250, 100, 250, 100, 250,
        250
    };
	
	// recording the shared length of both arrays and setting bits of DDRL 
	int length = 19;
	DDRL = 0xFF;
	
	//iterate through both arrays, setting lights as we go
	for (int i=0; i<length; i++){
		uint8_t led = light[i];
		
		//if none of the last four bits are set, clear LED
		if ((led&0b00001111) == 0){
			led_state(-1,0);
		}

		// set appropriate LED
		if (led & 0b00001000){
			led_state(3,1);
		}
		if (led & 0b00000100){
			led_state(2,1);
		}
		if (led & 0b00000010){
			led_state(1,1);
		}
		if (led & 0b00000001){
			led_state(0,1);
		}
		
		//delay by appropriate durations from the array
		_delay_ms(duration[i]);
	}
}


void glow(uint8_t LED, float brightness) {
	
	//multiply the pulse-width modulation by the duty cycle (ratio of time that an led is on vs when its off)
	uint8_t threshold = PWM_PERIOD * brightness;

	// an infinite loop where we set led if count is less than threshold and port is cleared,
	// clear led if count is less than pulse-width modulation and port is set, 
	// and reseting count and setting led if count is greater than PWM_PERIOD 
	for(;;){
		if ((count < threshold) && (PORTL==0)) {
			led_state(LED, 1);
		} else if ((count < PWM_PERIOD) && (PORTL!=0)) {
			led_state(LED, 0);
		} else if (count > PWM_PERIOD){ 
			count = 0;
			led_state(LED, 1);
		}
	}
}



void pulse_glow(uint8_t LED) {
	
	// initialize a threshold and direction of the glow. if direction is 1, its getting brighter. if is -1, its getting dimmer
	int threshold = 0;
	int direction = 1;
	
	// check if threshold is on boundary, if it is, then switch directions
	// check if for direction and if slow_count is greater than 5
	for(;;){ 
		if (threshold == 0){
			threshold ++;
			direction = 1;
			
		} if (threshold >= PWM_PERIOD){
			threshold --;
			direction = -1;
			
		} if (direction == -1 && slow_count > 5){
			threshold --;
			slow_count = 0;
			
		} if (direction == 1 && slow_count > 5){
			threshold ++;
			slow_count = 0;
		}
		
		//for handling led
		
		if ((count < threshold) && (PORTL==0)) {
			led_state(LED, 1);
			
		} else if ((count < PWM_PERIOD) && (PORTL!=0)) {
			led_state(LED, 0);
			
		} else if (count > PWM_PERIOD){
			count = 0;
			led_state(LED, 1);
		}
		
	}
}


void light_show() {
    uint8_t light[] = {
	    0xf, 0, 0xf, 0, 0xf, 0,
		0x6, 0, 0x9, 0,
	    0xf, 0, 0xf, 0, 0xf, 0,
	    0x9, 0, 0x6, 0,
		
		//wave
		0x8, 0, 0xc, 0, 0x6, 0, 0x3, 0,
		0x1, 0, 0x3, 0, 0x6, 0, 0xc, 0,
		0x8, 0, 0xc, 0, 0x6, 0, 0x3, 0,
		0x1, 0, 0x3, 0, 0x6,
		
	    0xf, 0, 0xf, 0,
	    0x6, 0, 0x6, 0
    };

    int duration[] = {
		//20
	    200, 200, 200, 200, 200, 200,
	    100, 100, 100, 100,
	    200, 200, 200, 200, 200, 200,
	    100, 100, 100, 100,
		
		//wave 29
		100, 0, 100, 0, 100, 0, 100, 0, 
		100, 0, 100, 0, 100, 0, 100, 0, 
		100, 0, 100, 0, 100, 0, 100, 0,
		100, 0, 100, 0, 200,
		
		//8
	    200, 200, 200, 200,
	    350, 200, 250, 200
    };
	
	// recording the shared length of both arrays and setting bits of DDRL
    int length = 57;
    DDRL = 0xFF;

	for (int i=0; i<length; i++){
		uint8_t led = light[i];
			
		//if none of the last four bits are set, clear LED
		if ((led & 0b00001111) == 0){
			led_state(-1,0);
		}

		// set appropriate LED
		if (led & 0b00001000){
			led_state(3,1);
		}
		if (led & 0b00000100){
			led_state(2,1);
		}
		if (led & 0b00000010){
			led_state(1,1);
		}
		if (led & 0b00000001){
			led_state(0,1);
		}
			
		//delay by appropriate durations from the array
		_delay_ms(duration[i]);
	}
}


/* ***************************************************
 * **** END OF FIRST "STUDENT CODE" SECTION **********
 * ***************************************************
 */


/* =============================================
 * ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
 * =============================================
 */

int main() {
    /* Turn off global interrupts while setting up timers. */

	cli();

	/* Set up timer 1, i.e., an interrupt every 1 microsecond. */
	OCR1A = TOP1;
	TCCR1A = 0;
	TCCR1B = 0;
	TCCR1B |= (1 << WGM12);
    /* Next two lines provide a prescaler value of 8. */
	TCCR1B |= (1 << CS11);
	TCCR1B |= (1 << CS10);
	TIMSK1 |= (1 << OCIE1A);

	/* Set up timer 3, i.e., an interrupt every 10 milliseconds. */
	OCR3A = TOP3;
	TCCR3A = 0;
	TCCR3B = 0;
	TCCR3B |= (1 << WGM32);
    /* Next line provides a prescaler value of 64. */
	TCCR3B |= (1 << CS31);
	TIMSK3 |= (1 << OCIE3A);


	/* Turn on global interrupts */
	sei();

/* =======================================
 * ==== END OF "DO NOT TOUCH" SECTION ====
 * =======================================
 */


/* *********************************************
 * **** BEGINNING OF "STUDENT CODE" SECTION ****
 * *********************************************
 */

/* This code could be used to test your work for part A.
 */

	//led_state(0, 1);
	//_delay_ms(1000);
	//led_state(2, 1);
	//_delay_ms(1000);
	//led_state(1, 1);
	//_delay_ms(1000);
	//led_state(2, 0);
	//_delay_ms(1000);
	//led_state(0, 0);
	//_delay_ms(1000);
	//led_state(1, 0);
	//_delay_ms(1000);


/* This code could be used to test your work for part B.	
 */

SOS();

/* This code could be used to test your work for part C.
 */

//glow(3, 0.1);


/* This code could be used to test your work for part D.
 */

 //pulse_glow(3);


/* This code could be used to test your work for the bonus part.
*/

//light_show();


/* ****************************************************
 * **** END OF SECOND "STUDENT CODE" SECTION **********
 * ****************************************************
 */
}




