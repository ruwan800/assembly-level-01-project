;This program communicate with PC serial port
;usart unit used to transmit dataCALL	delay4s
;2011/04/08__23:15hrs
;RS=0,E=1,greenLED=2,Buzzer=3(PORTD)/DATA=PORTB
;originally written by me


LIST P=16F877A
INCLUDE"P16F877A.INC"

__config  _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _XT_OSC & _LVP_OFF 

;########################################################################

#define	serialen	RCSTA,CREN	;enable serial port when set
#define	grnled		0x7E,0
#define	redled		0x7E,1
#define	signalen	PORTD,7
#define	dataen		PORTD,6
#define	grnen		PORTD,4
#define	reden		PORTD,5
#define	bklight		PORTA,0

CBLOCK	0x20
	TIME1
	TIME2
	TIME3
	TIME4
	ptrpoint
	tempchar
	msgptr
ENDC

CBLOCK	0x30
	msg1
ENDC

CBLOCK	0x52
	msg2
ENDC

CBLOCK	0xA0
	msg3
ENDC
	
CBLOCK	0x7C
	TIMEy
	TIMEz
	config0		; serial program instructions(0x7E)
	msgen		; serial program instructions(0x7F)
ENDC

signal	MACRO
	BSF	signalen
	NOP
	BCF	signalen
	ENDM

;########################################################################	

ORG	0x000			; processor reset vector
GOTO	main			; go to beginning of program

LINEMSGTEMP:
	MOVWF	PCL

msg0	DT	"Test_01|"

;########################################################################

routine:
	BANKSEL	RCSTA
	BSF	serialen
	CALL	check

	CALL	configure
	CALL	getmsg1
	BANKSEL	msgen
	MOVF	msgen,W
	XORLW	0x31
	BTFSC	STATUS,Z
	GOTO	$+7
	CALL	getmsg2
	BANKSEL	msgen
	MOVF	msgen,W
	XORLW	0x33
	BTFSC	STATUS,Z
	CALL	getmsg3
	BANKSEL	RCSTA
	BCF	serialen

	CALL	ledon

	CALL	sendmsg1
	BANKSEL	msgen
	MOVF	msgen,W
	XORLW	0x31
	BTFSC	STATUS,Z
	GOTO	$+7
	CALL	sendmsg2
	BANKSEL	msgen
	MOVF	msgen,W
	XORLW	0x33
	BTFSC	STATUS,Z
	CALL	sendmsg3
	NOP
	MOVLW	0x0080		;set DDRAM address to line1char1
	CALL	cmd
	MOVLW	0x0001		;clear display
	CALL	cmd
	CALL	sendmsg0
	CALL	ledoff

	GOTO	routine	

;########################################################################

configure:
	CALL	getchr
	MOVLW	config0
	MOVWF	FSR
	MOVF	tempchar,W
	MOVWF	INDF
	CALL	check
	CALL	getchr
	MOVLW	msgen
	MOVWF	FSR
	MOVF	tempchar,W
	MOVWF	INDF
	RETURN

getmsg1:
	MOVLW	0x0030
	MOVWF	ptrpoint
	CALL	getmsg
	RETURN

getmsg2:
	
	MOVLW	0x0052
	MOVWF	ptrpoint
	CALL	getmsg
	RETURN

getmsg3:
	MOVLW	0x00A0
	MOVWF	ptrpoint
	CALL	getmsg
	RETURN

getmsg:	CALL	check
	CALL	getchr
	BANKSEL	ptrpoint
	MOVF	ptrpoint,W
	MOVWF	FSR
	MOVF	tempchar,W
	MOVWF	INDF
	INCF	ptrpoint,F
	BANKSEL	tempchar
	MOVF	tempchar,W	
	XORLW	0x7C
	BTFSS	STATUS,Z
	goto	getmsg
	RETURN

check:	
	BANKSEL PIR1
	BTFSS	PIR1,RCIF
	GOTO	check
	RETURN	


getchr:
	BANKSEL	RCREG
	MOVF	RCREG,W
	BANKSEL	tempchar
	MOVWF	tempchar
	RETURN


;########################################################################


ledon:
	BANKSEL	0x7E	
	BTFSC	grnled
	BSF	grnen
	BTFSS	grnled
	BSF	reden
	RETURN

ledoff:	
	BANKSEL	0x7E
	BCF	grnen
	BCF	reden
	RETURN


;########################################################################

sendmsg1:
	MOVLW	0x0030
	CALL	sendmsg
	RETURN

sendmsg2:
	MOVLW	0x0052
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
	BANKSEL	tempchar
	MOVF	tempchar,W
	XORLW	0x5F
	BTFSC	STATUS,Z
	GOTO	NEWLINE1
	MOVF	tempchar,W	
	XORLW	0x7C
	BTFSC	STATUS,Z
	RETURN
	MOVF	tempchar,W
	CALL	sendchar
	GOTO	xtvz
NEWLINE1:
	MOVLW	0x00C0
	CALL	cmd
	GOTO	xtvz
	

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
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


main:
	BANKSEL	PORTA
	BSF	PORTA,0	
	CALL	serialinit
	CALL	picinit
	CALL	lcdinit
	CALL	sendmsg0
	GOTO	routine
	
serialinit:
	BANKSEL	PIE1
	CLRF	PIE1		;stop all interrupts
				;****RC INTERRUPT DISABLED HERE****
	BANKSEL	INTCON		;disable all interrupts
	CLRF	INTCON

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
	RETURN

picinit:
	BANKSEL	ADCON1
	MOVLW	0x0007
	MOVWF	ADCON1
	CLRF	TRISB
	CLRF	TRISB
	CLRF	TRISD
	BANKSEL	PORTA
	BSF		PORTA,0
	RETURN

lcdinit:
	CALL	delay5ms
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
	RETURN

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
	BANKSEL	TIME4
	MOVLW	0x0014
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
	CALL	DELAY1
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
	GOTO	DELAY2
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

END

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
