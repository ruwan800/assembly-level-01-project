;This program communicate with PC serial port
;usart unit used to transmit data
;RS=0,E=1,greenLED=2,Buzzer=3(PORTD)/DATA=PORTB
;originally written by me


LIST P=16F877A
INCLUDE"P16F877A.INC"

;########################################################################

#define	serialen	RCSTA,CREN	;enable serial port when set	
#define	interren	PIE1,RCIE	;enable receiving interrupts when set
#define	grnled		0x7E,1
#define	redled		0x7E,2
#define	msg2en		0x7E,0
#define	msg3en		0x7E,1
#define	signalen	PORTD,1
#define	dataen		PORTD,0
#define	grnen		PORTD,4
#define	reden		PORTD,5
#define	bklight		PORTA,0

CBLOCK	0x20
	TIME1
	TIME2
	TIME3
	TIME4
	nl
	dec20
	ptrpoint
	tempchar
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
	ENDM
	

;########################################################################	

ORG	0x000			; processor reset vector
GOTO	main			; go to beginning of program

;########################################################################


ORG	0x004			; interrupt vector location

BANKSEL	PIE1
BCF	interren
BANKSEL	RCSTA
BSF	serialen

MOVWF	w_temp			; save off current W register contents
MOVF	STATUS,w		; move status register into W register
MOVWF	status_temp		; save off contents of STATUS register
MOVF	PCLATH,w		; move pclath register into w register
MOVWF	pclath_temp		; save off contents of PCLATH register

CALL	configure
CALL	getmsg1
						;BANKSEL	0x007E
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
;CALL	sendmsg0

CALL	ledoff

BANKSEL	PIE1
BSF	interren
BANKSEL	RCSTA
BSF	serialen
GOTO	goback			; return from interrupt

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
	MOVLW	0x0002
	MOVWF	dec20
	MOVLW	0x0030
	MOVWF	ptrpoint
	CALL	getmsg
	RETURN

getmsg2:
	MOVLW	0x0002
	MOVWF	dec20
	MOVLW	0x0050
	MOVWF	ptrpoint
	CALL	getmsg
	RETURN

getmsg3:
	MOVLW	0x0002
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


check:	
	BANKSEL PIR1
	BTFSC	PIR1,RCIF
	RETURN
	GOTO	check

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
	MOVWF	ptrpoint
	CALL	setmsg
	CALL	sendmsg
	CALL	delay4s
	RETURN

sendmsg2:
	MOVLW	0x0030
	MOVWF	ptrpoint
	CALL	setmsg
	CALL	sendmsg
	CALL	delay4s
	RETURN

sendmsg3:
	MOVLW	0x0030
	MOVWF	ptrpoint
	CALL	setmsg
	CALL	sendmsg
	CALL	delay4s
	RETURN

setmsg:
	MOVLW	0x0080		;set DDRAM address to line1char1
	CALL	cmd
	MOVLW	0x0001		;clear display
	CALL	cmd
	MOVLW	0x0010
	MOVWF	nl
	MOVLW	0x0020
	MOVWF	dec20
	RETURN


sendmsg:
	MOVF	ptrpoint,W
	MOVWF	FSR		;load character pointer
	MOVF	INDF,W
	MOVWF	tempchar
	MOVF	tempchar,W						
	call	sendchar	;load the PCL with the character address
	INCF	ptrpoint,F	;next character to display		
	DECFSZ	dec20,F
	GOTO	sendmsg
	RETURN

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

newline:
	DECFSZ	nl,F
	RETURN
	MOVLW	0x00C0		;set DDRAM address to line2char1
	CALL	cmd
	RETURN

;########################################################################


main:	CALL	serialinit
	CALL	picinit
	CALL	lcdinit
	CALL	routine
	
msg0	DT	"This is my LCD HELLO WORLD test program",0
	
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
	MOVLW	0x000F	;display ON/OFF control
	CALL	cmd
	MOVLW	0x0006	;entry mode set
	CALL	cmd
	;MOVLW	0x0080	;set DDRAM address to line1char1
	;CALL	cmd
	MOVLW	0x0001	;clear display
	CALL	cmd



cmd:	MOVWF	PORTB	;send command to PORTB
	NOP
	signal		;signal enable macro
	MOVLW	0x0000	;make all PORTB outputs low
	MOVWF	PORTB
	CALL	delay5ms
	RETURN

delay4s:
	MOVLW	0x000A
	MOVWF	TIME4
DELAY4:	NOP
	CALL	delay100ms
	DECFSZ	TIME4,F
	GOTO	DELAY4
	RETURN
	
delay100ms:
	MOVLW	0x0005
	MOVWF	TIME3
DELAY3:	NOP
	CALL	delay5ms
	DECFSZ	TIME3,F
	GOTO	DELAY3
	RETURN
delay5ms:
	MOVLW	0x0005
	MOVWF	TIME2
DELAY2:	MOVLW	0x00FA
	MOVWF	TIME1
DELAY1:	NOP
	DECFSZ	TIME1,F
	GOTO	DELAY1
	NOP
	DECFSZ	TIME2,F
	GOTO	DELAY2
	RETURN




routine:
BANKSEL	RCSTA
BSF	serialen
BANKSEL	PIE1
BSF	interren
inf:	NOP
	GOTO	inf

END
