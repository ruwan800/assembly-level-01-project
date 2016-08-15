;This program communicate with PC serial port
;usart unit used to transmit dataCALL	delay4s
;2011/04/08__23:15hrs
;RS=0,E=1,greenLED=2,Buzzer=3(PORTD)/DATA=PORTB
;originally written by me


LIST P=16F877A
INCLUDE"P16F877A.INC"

;########################################################################

#define	serialen	RCSTA,CREN	;enable serial port when set	
#define	interren	PIE1,RCIE	;enable receiving interrupts when set
#define	grnled		0x7E,2
#define	redled		0x7E,3
#define	msg2en		0x7E,0
#define	msg3en		0x7E,1
#define	signalen	PORTD,1
#define	dataen		PORTD,0
#define	grnen		PORTD,2
#define	reden		PORTD,3

CBLOCK	0x20
	TIME1
	TIME2
	TIME3
	TIME4
	nl
	dec20
	ptrpoint
	tempchar
	msgptr
ENDC

CBLOCK	0x30
	msg1
ENDC

CBLOCK	0x50
	msg2
ENDC

CBLOCK	0xA0
	msg3
ENDC
	
CBLOCK	0x79
	TIMEy
	TIMEz
	w_temp		; variable used for context saving
	status_temp	; variable used for context saving
	pclath_temp	; variable used for context saving
	config0		; serial program instructions(0x7E)
	config1		; serial program instructions(0x7F)
ENDC

signal	MACRO
	BSF	signalen
	NOP
	BCF	signalen
	NOP
	ENDM

;########################################################################	

ORG	0x000			; processor reset vector
GOTO	main			; go to beginning of program
ORG	0x004
GOTO	interrupt

LINEMSGTEMP:
	MOVWF	PCL

msg0	DT	" Please record_your attendance|"

;########################################################################

interrupt:			; interrupt vector location

MOVWF	w_temp			; save off current W register contents
MOVF	STATUS,w		; move status register into W register
MOVWF	status_temp		; save off contents of STATUS register
MOVF	PCLATH,w		; move pclath register into w register
MOVWF	pclath_temp		; save off contents of PCLATH register

BANKSEL	PIE1
BCF	interren
BANKSEL	RCSTA
BSF	serialen

CALL	configure
CALL	getmsg1
BTFSC	msg2en
CALL	getmsg2
BTFSC	msg3en
CALL	getmsg3
BANKSEL	RCSTA
BCF	serialen

CALL	ledon

CALL	sendmsg1
BTFSS	msg2en
CALL	delay4s
BTFSC	msg2en
CALL	sendmsg2
BTFSC	msg3en
CALL	sendmsg3
CALL	delay4s
CALL	sendmsg0

CALL	ledoff

BANKSEL	PIE1
BSF	interren
BANKSEL	RCSTA
BSF	serialen
CALL	goback			; return from interrupt

;########################################################################

configure:
	CALL	getchr
	MOVLW	0x007E
	MOVWF	FSR
	MOVF	tempchar,W
	MOVWF	INDF
	CALL	check
	CALL	getchr
	MOVLW	0x007F
	MOVWF	FSR
	MOVF	tempchar,W
	MOVWF	INDF
	RETURN

getmsg1:
	MOVLW	0x0020
	MOVWF	dec20
	MOVLW	0x0030
	MOVWF	ptrpoint
	CALL	getmsg
	RETURN

getmsg2:
	MOVLW	0x0020
	MOVWF	dec20
	MOVLW	0x0050
	MOVWF	ptrpoint
	CALL	getmsg
	RETURN

getmsg3:
	MOVLW	0x0020
	MOVWF	dec20
	MOVLW	0x00A0
	MOVWF	ptrpoint
	CALL	getmsg
	RETURN

getmsg:	CALL	check
	CALL	getchr
	MOVF	ptrpoint,W
	MOVWF	FSR
	MOVF	tempchar,W
	MOVWF	INDF
	INCF	ptrpoint,F
	decfsz	dec20
	goto	getmsg
	RETURN

check:	MOVLW	0x00FA
	MOVWF	TIMEz
DELAYz:
	MOVLW	0x00FA
	MOVWF	TIMEy
DELAYy:
	BANKSEL PIR1
	BTFSC	PIR1,RCIF
	RETURN
	DECFSZ	TIMEy,F
	GOTO	DELAYy
	NOP
	NOP
	DECFSZ	TIMEz,F
	CALL	DELAYz
	CALL	goback	


getchr:
	BANKSEL	RCREG
	MOVF	RCREG,W
	BANKSEL	tempchar
	MOVWF	tempchar
	RETURN

goback:	MOVF	pclath_temp,w		; retrieve copy of PCLATH register
	MOVWF	PCLATH			; restore pre-isr PCLATH register contents
	MOVF	status_temp,w		; retrieve copy of STATUS register
	MOVWF	STATUS			; restore pre-isr STATUS register contents
	SWAPF	w_temp,f
	SWAPF	w_temp,w		; restore pre-isr W register contents
	RETFIE

;########################################################################


ledon:	BTFSC	grnled
	BSF	grnen
	BTFSC	redled
	BSF	reden
	RETURN

ledoff:	BCF	grnen
	BCF	reden
	RETURN


;########################################################################

sendmsg1:
	MOVLW	0x0030
	CALL	sendmsg
	RETURN

sendmsg2:
	MOVLW	0x0050
	CALL	sendmsg
	RETURN

sendmsg3:
	MOVLW	0x00A0
	CALL	sendmsg
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sendmsg0:
	BANKSEL	msg0
	MOVLW	msg0		;starting register should loaded to msgptr
	MOVWF	msgptr		;variable 'tempchar' used to handle a character
xtvy:
	MOVF	msgptr,W	;'LINEMSGTEMP' function should be initialized near character data tables
	CALL	LINEMSGTEMP	;'sendchar' function used to send a character
	MOVWF	tempchar	;once called lineXsg function whole data table characters send to LCD
	INCF	msgptr,F
	MOVF	tempchar,W
	XORLW	0x5F
	BTFSC	STATUS,Z
	GOTO	NEWLINE
	MOVF	tempchar,W	
	XORLW	0x7C
	BTFSC	STATUS,Z
	RETURN
	MOVF	tempchar,W
	CALL	sendchar
	GOTO	xtvy
NEWLINE:
	MOVLW	0x00C0
	CALL	cmd
	GOTO	xtvy

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sendmsg:
	MOVWF	ptrpoint	;variable 'tempchar' used to handle a character
	MOVLW	0x0080		;set DDRAM address to line1char1
	CALL	cmd
	MOVLW	0x0001		;clear display
	CALL	cmd
xtvz:	MOVF	ptrpoint,W
	MOVWF	FSR		;load character pointer
	MOVF	INDF,W
	MOVWF	tempchar
	INCF	ptrpoint,F
	MOVF	tempchar,W
	XORLW	0x5F
	BTFSC	STATUS,Z
	GOTO	NEWLINE1
	MOVF	tempchar,W	
	XORLW	0x7C
	BTFSC	STATUS,Z
	GOTO	xtva
	MOVF	tempchar,W
	CALL	sendchar
	GOTO	xtvz
NEWLINE1:
	MOVLW	0x00C0
	CALL	cmd
	GOTO	xtvy
xtva:	CALL	delay4s
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sendchar:			;send a character to LCD
	MOVWF	PORTB
	NOP
	BSF	dataen		;select data registry
	signal			;signal enable macro
	NOP
	MOVLW	0x0000		;make all PORTB outputs low
	MOVWF	PORTB
	BCF	dataen		;select instruction registry
	CALL	delay5ms
	CALL	newline		;goto next line if 16 characters written
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


main:	CALL	delay2s
	CALL	serialinit
	CALL	picinit
	CALL	lcdinit
	CALL	sendmsg0
	CALL	routine
	
serialinit:
	BANKSEL	PIE1
	CLRF	PIE1		;stop all interrupts
				;****RC INTERRUPT DISABLED HERE****
	BANKSEL	INTCON
	MOVLW	B'11000000'	;enable all interrupts
	MOVWF	INTCON

	BANKSEL	TRISC		;configure pins for serial transmitting
	BCF	TRISC,6		;c6=0 as output
	BSF	TRISC,7		;c7=1 as input
	BANKSEL	SPBRG		;setting up baud rate
	MOVLW	D'25'
	MOVWF	SPBRG
	
	BANKSEL	TXSTA		;setting TXSTA register
	MOVLW	B'00000100'
	MOVWF	TXSTA
	BANKSEL	RCSTA		;setting RCSTA register
	MOVLW	B'10000000'	;****SERIAL RECEIVING DISABLED HERE****
	MOVWF	RCSTA

picinit:
	BANKSEL	ADCON1
	MOVLW	0x0007
	MOVWF	ADCON1
	CLRF	TRISB
	CLRF	TRISD
	BANKSEL	PORTB

lcdinit:
	CALL	delay100ms
	MOVLW	0x0030	;setting function set
	CALL	cmd
	MOVLW	0x0030	;setting function set
	CALL	cmd
	MOVLW	0x0030	;setting function set
	CALL	cmd
	MOVLW	0x0038	;setting function set
	CALL	cmd
	MOVLW	0x000C	;display ON/OFF control
	CALL	cmd
	MOVLW	0x0006	;entry mode set
	CALL	cmd
	;MOVLW	0x0080	;set DDRAM address to line1char1
	;CALL	cmd
	MOVLW	0x0001	;clear display
	CALL	cmd

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cmd:	MOVWF	PORTB	;send command to PORTB
	NOP
	signal		;signal enable macro
	MOVLW	0x0000	;make all PORTB outputs low
	MOVWF	PORTB
	CALL	delay5ms
	RETURN


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

delay4s:
	CALL	delay2s
	CALL	delay2s
	RETURN
delay2s:		;(generates 2.000124 delay)
	MOVLW	0x0020
	MOVWF	TIME4
DELAY4:	NOP
	CALL	delay100ms
	DECFSZ	TIME4,F
	GOTO	DELAY4
	RETURN
	
delay100ms:		;(absolute 100ms delay)
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	MOVLW	0x0063
	MOVWF	TIME3
DELAY3:	NOP
	CALL	delay5ms
	DECFSZ	TIME3,F
	GOTO	DELAY3
	RETURN
delay5ms:		;(generates 5.008ms delay)
	CALL	DELAY1
	CALL	DELAY1
	CALL	DELAY1
	CALL	DELAY1
	CALL	DELAY1
	RETURN
DELAY1:	MOVLW	0x00F8
	MOVWF	TIME1
DELAY2:	NOP
	DECFSZ	TIME1,F
	GOTO	DELAY1
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

routine:
BANKSEL	RCSTA
BSF	serialen
BANKSEL	PIE1
BSF	interren
inf:	NOP
	GOTO	inf

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

END

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
