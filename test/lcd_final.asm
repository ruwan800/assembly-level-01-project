;Display fixed messages in 2*16 LCD display
;scan a 4x4 keypad matrix and disply the key value in 2*16 LCD display
	list	p=16f877
	errorlevel -302
	include "P16F877.inc"
;**********  STATUS REGISTER BIT DEFINITIONS  **********
#define	_c	STATUS,0		;carry bit
#define	_z	STATUS,2		;zero bit
#define	lcd_en		PORTD,2	; enable lcd
#define	lcd_rs		PORTD,0	; register select of lcd
;***********Variables
	cblock	0x20
	del_cnt,gp1,chpt,lcdch
	t2,t3,key_index,portb_image,key_processed		;for key pad
	endc		
	cblock	0x70
	msg1,msg2
	endc
;**********  CONSTANTS  *****************
tslot		equ	.20		; time slot counter load = 60us
reset_high	equ	.83		; reset low period = 500us
reset_low	equ	.83		; reset high period = 500us
clkr		equ	100h	
div256		equ	b'10000111'	; 256us prescale setting
lcd_clr		equ	b'00000001'	; clears display, resets curcor
lcdcm		equ	b'10000000'	; sets cursor using bits 0 - 6
							; line 1 range - 0 to .15
							; line 2 range - 0x40 to 0x4F
lcdport		equ	PORTB

	__config  _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _XT_OSC & _LVP_OFF
	list
;*********************** MACRO's *******************************
clklcd	macro			
		bsf     lcd_en		
		bcf     lcd_en		
		endm
;***************************************************************
		org 	0		; reset vector
		goto	init
		org		4			; interrupt vector
		goto	intrhndl

callstr		; start of string send pointer area
		movwf	PCL
;LCD Position    1234567890123456
mes0	DT	"  LCD  Display  ",0
mes1	DT	"     ACCIMT     ",0
mes2	DT	"key pressed= ",0
mes_cl	DT	"                ",0 ; clear line message
;
dostr	movwf	chpt		;load character pointer		
dostr2	movfw	chpt				
		call	callstr		;load the PCL with the character address
		iorlw	0		
		bz		eos			;value zero is end of string.
		movwf	lcdch		;load character
		call	chalcd		;call to display the char.		
		incf	chpt,f		;next character to display		
		goto	dostr2		
eos		return					;end of string

sec_del movlw	.32		
		movwf	del_cnt	
time1	clrf	TMR0		
		btfss	TMR0,7		
		goto	$-1		
		decfsz	del_cnt,f	
		goto	time1		
		retlw	00
; ************* waitgp waits for the number of ms in gp1 register
waitgp	movlw	clkr-4		 ; 1ms timeout in timer0
		movwf	TMR0	
waitgpa	movfw	TMR0		 ; test for timeout			
		bnz		waitgpa		 ; wait for rtc to time out
		decf	gp1,f
		bnz		waitgp		 ; loop until delay is complete
		return				 ; exit from waitgp
; *** chalcd writes the character in w register to the lcd. on entry, the display character is in lcdch.
chalcd	movwf	lcdch			; load into working register
		swapf   lcdch,w			; swap nibbles
		andlw   07h				; strip the MS nibble,
								; and mask top bit in case this is the lset 
								; character in a string
		movwf   lcdport			; send the MS nibble to lcd port
		bsf		lcd_rs			; LCD register select -> data	
		clklcd					; clock the MS nibble to the lcd
		movfw   lcdch			;  get the lower nibble and load to the lcd port
		andlw   0fh				; strip the LS nibble
		movwf   lcdport			; send LS nibble to lcd port	
		bsf		lcd_rs			; LCD register select -> data	
		clklcd					; clock the ls nibble to the lcd.
		bcf		lcd_rs
		goto	lcd64			; delay then exit from chalcd
; ****comlcd writes the command in w register to the lcd, on entry, the command character is in lcdch.
comlcd	swapf   lcdch,w			; swap nibbles
		andlw   0fh				; strip the MS nibble
		movwf   lcdport			; send the MS nibble to lcd port	
		clklcd					; clock the ms nibble to the lcd
		movfw   lcdch			; ; get the lower nibble and load to the lcd port	
		andlw   0fh				; strip the LS nibble
		movwf   lcdport			; send the LS nibble to lcd port	
		clklcd					; clock the LS nibble to the lcd	
		goto	lcd2			; delay then exit from comlcd
;*********CLEAR LCD DISPLAY
lcdclr	movlw	lcd_clr		; lcd clear command
		movwf	lcdch
		goto	comlcd
;*******sets cursor position to the location of value in w register (line 1)
lcdcur1	iorlw	lcdcm		; cursor move command...    lcdcm = b'10000000'
		movwf	lcdch
		goto	comlcd
;*******sets cursor position to the location of value in w register (line2)
lcdcur2	iorlw	lcdcm		; cursor move command...    lcdcm = b'10000000'
		movwf	lcdch
		bsf		lcdch,6		; this bit set for line 2
		goto	comlcd		
;*************DELAY LOOPS
lcd64	movlw	clkr-.3		
		goto	lcdel	
lcd2	movlw	clkr-.100	
lcdel	movwf	TMR0	
lcdela	movfw	TMR0			
		bnz	lcdela		
		retlw	.0
;**********  RESET & INITIALISATION  ***************************
init		
		banksel	TRISB
		clrf	TRISB
		banksel	TRISD
		clrf	TRISD
		banksel	PORTB
		clrf	PORTB
		banksel	PORTD
		clrf	PORTD
		banksel	TRISC	;BANK 1
		movlw	0xf0	;RB7-4 inputs, RB3-0 outputs used for keyboard
		movwf	TRISC
		clrf	TRISD
		movlw	div256
		movwf	OPTION_REG
		banksel	PORTC
		clrf	PORTC
		call	kpd_init
		call	display_init
;**********  MAIN PROGRAM  *************************************
main	
		banksel	PORTC
		call	lcdcur1
		movlw	mes0		;w will contain the starting address of mes0 string
		call	dostr
		call	sec_del
		call 	lcdclr
		movlw	0
		call	lcdcur1
		movlw	mes1
		call	dostr
		call	sec_del	
wait
		movf	key_processed,f
		btfss	STATUS,2
		goto 	wait
		movlw	0xff
		movwf	key_processed	;processed key displayed.		
		movlw	0
		call 	lcdcur2
		movlw	mes2
		call	dostr		
		call	read_value
		call	chalcd	
		goto 	wait

read_value
		movf	key_index,0
		addwf	PCL,1
		retlw	0x31;	01
		retlw	0x32;	02
		retlw	0x33;	03
		retlw	0x46;	0F
		retlw	0x34;	04
		retlw	0x35;	05
		retlw	0x36;	06
		retlw	0x45;	0E
		retlw	0x37;	07
		retlw	0x38;	08
		retlw	0x39;	09
		retlw	0x44;	0D
		retlw	0x41;	0A
		retlw	0x30;	00
		retlw	0x42;	0B
		retlw	0x43;	0C
		
;*****interrupt routine *************
intrhndl
		movlw	0x04
		movwf	t2	
del_two	movlw	0xff
		movwf	t3			
del_one	nop
		decfsz	t3,f
		goto	del_one		;10ms delay
		decfsz	t2
		goto	del_two
		
		movlw	0x10
		movwf	key_index	;error in keypress
		movlw	0x0c
		btfss	PORTC,7
		movwf	key_index	;row4
		movlw	0x08
		btfss	PORTC,6
		movwf	key_index	;row3
		movlw	0x04
		btfss	PORTC,5
		movwf	key_index	;row2
		btfss	PORTC,4
		clrf	key_index	;row1    ,row scan finish
		
		movlw	0x10
		xorwf	key_index,w
		btfsc	STATUS,2
		goto	fnsh		;error in  key press
		movlw	0xff
		movwf	PORTC
		movlw	b'11101111'
		movwf	portb_image
		movf	PORTC,f
		bcf		INTCON,0	;clear RBIF
		rrf		portb_image,f
scancol	btfss	STATUS,0	;clear carry bit
		goto	finish		;key identified
		movf	portb_image,w
		movwf	PORTC
		btfss	INTCON,0	;test RBIF
		goto	inckey
		bcf		STATUS,0	;clear carry bit since key found
		goto	scancol
inckey	incf	key_index,f	;not the current column
		rrf		portb_image,f
		goto	scancol
finish	clrf	key_processed
fnsh	movlw	0xf0
		movwf	PORTC
		movf	PORTC,f
		bcf		INTCON,0
		nop
		retfie		
;*******************************************
kpd_init
		movlw	0xF0
		banksel	TRISC
		movwf	TRISC
		clrf	STATUS           	
		BCF		STATUS,RP0
		clrf	PORTC
		movlw	0x88
		movwf	INTCON		;GIE, RBIE Enable		
		movf	PORTC,f
		bcf		INTCON,0	;clear RBIF
		return

display_init
		;4-bit Interface Setup
		bcf	STATUS,RP0
		movlw	.20		
		movwf	gp1
		call	waitgp		
		movlw	b'00000011'	
		movwf   lcdport		
		clklcd					;1	
		movlw	.6		
		movwf	gp1
		call	waitgp		
		movlw	b'00000011'	
		movwf   lcdport		
		clklcd					;2
		movlw	.5		
		movwf	gp1
		call	waitgp		
		movlw	b'00000011'	
		movwf   lcdport		
		clklcd					;3
		movlw	.5		
		movwf	gp1
		call	waitgp		
		movlw	b'00000010'	
		movwf   lcdport		
		clklcd					;4 ;these 4 bytes (3 times 0x03 and once 0x02) should be sent to LCd to enable 4-bit mode

		;Function Set				0 0 1 DL N F * *	DL=0 (4-bit inetrface), N=1 (two lines), F=0 (5x7 dots)
		movlw	.5		
		movwf	gp1
		call	waitgp		
		movlw	b'00000010'	;	0010
		movwf   lcdport		
		clklcd				; clock the nibble to the lcd
		movlw	b'00001000'	;	1000
		movwf   lcdport		; command to lcd port
		clklcd				; clock the nibble to the lcd	
		;Display ON/OFF	control		0 0 0 0 1 D C B		D=0(Display Off), C=0 (Cursor Off), B=0(Cursor Blink Off)	
		movlw	.5			; delay for 5 ms to let lcd settle
		movwf	gp1
		call	waitgp		; wait for lcd
		movlw	b'00000000'	; display off
		movwf   lcdport		; command to lcd port
		clklcd				; clock the nibble to the lcd
		movlw	b'00001000'	; 
		movwf   lcdport		; command to lcd port
		clklcd				; clock the nibble to the lcd	
		;Clearing the Display		0 0 0 0 0 0 0 1
		movlw	.5			; delay for 5 ms to let lcd settle
		movwf	gp1
		call	waitgp		; wait for lcd
		movlw	b'00000000'	; display clear
		movwf   lcdport		; command to lcd port
		clklcd				; clock the nibble to the lcd
		movlw	b'00000001'	; 
		movwf   lcdport		; command to lcd port
		clklcd				; clock the nibble to the lcd
		;Entry Mode Set				0 0 0 0 0 1 I/D S	I/D=1(Increment cursor position), S=0(No Display Shift)
		movlw	.5		; delay for 5 ms to let lcd settle
		movwf	gp1
		call	waitgp		; wait for lcd
		movlw	b'00000000'	; entry mode set
		movwf   lcdport		; command to lcd port
		clklcd			; clock the nibble to the lcd
		movlw	b'00000110'	; 
		movwf   lcdport		; command to lcd port
		clklcd			; clock the nibble to the lcd	
		;Display ON/OFF	control		0 0 0 0 1 D C B		D=1(Display Off), C=0 (Cursor Off), B=0(Cursor Blink Off)				
		movlw	.5			; delay for 5 ms to let lcd settle
		movwf	gp1
		call	waitgp		; wait for lcd
		movlw	b'00000000'	; display on
		movwf   lcdport		; command to lcd port
		clklcd				; clock the nibble to the lcd
		movlw	b'00001100'	; 
		movwf   lcdport		; command to lcd port
		clklcd				; clock the nibble to the lcd		
		movlw	.5			; delay for 5 ms to let lcd settle
		movwf	gp1
		call	waitgp		; wait for lcd		
		return
				
	end
