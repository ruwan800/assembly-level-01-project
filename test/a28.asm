;a27.asm
;this program display units of electricity on lcd
;රු:ප්‍ර:ජ:/වි:a27.asm
;Sat 21 May 2011 03:40:07 PM IST 

LIST P=16F877A
INCLUDE"P16F877A.INC"

__config  _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _XT_OSC & _LVP_OFF 


#define	input		PORTC,2
#define	bitz		STATUS,Z
#define	bitc		STATUS,C
#define	dataen		PORTB,7			;select instruction registry(RS)
#define	signalen	PORTB,6			;signal enable bit
#define	dataport	PORTD			;PORT used to send data


incr0P	equ	3
incr30P	equ	2
incr60P	equ	3
incr90P	equ	2

cblock	0x20
	resolution
	totalunit
	tuhigh
	amount
	amounth
	tempchar
	TIME1
	TIME2
	TIME3
	TIME4
endc

cblock	0x60
	k5,k6,k7,k8,k9
endc

cblock	0x70
	t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,tA
endc

signal	MACRO
	BSF	signalen
	NOP
	BCF	signalen
	ENDM

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

ORG	0x0000
main:
	BANKSEL	ADCON1
	MOVLW	0x0007
	MOVWF	ADCON1
	BANKSEL	TRISD
	CLRF	TRISD
	BANKSEL	PORTD
	CLRF	PORTD
	BANKSEL	TRISC		;configure pins for serial transmitting
	BCF	TRISC,6		;c6=0 as output
	BSF	TRISC,7		;c7=1 as input
	BSF	TRISC,2
	BANKSEL	PORTC
	BCF	input

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

usartinit:
	BANKSEL	RCSTA
	BSF	RCSTA,SPEN
	BANKSEL	TXSTA
	BSF	TXSTA,TXEN
	BSF	TXSTA,BRGH
	BANKSEL	SPBRG		;setting up baud rate
	MOVLW	D'25'
	MOVWF	SPBRG

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
	MOVLW	0x0001	;clear display
	CALL	cmd

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

routine:
	MOVLW	A'm'
	CALL	sendchar
	BANKSEL	resolution
	CLRF	resolution
	CLRF	totalunit
	CLRF	tuhigh
	CLRF	amount
	CLRF	amounth
check:
	;BANKSEL	PORTC
	;BTFSS	input
	;GOTO	check
	BANKSEL	resolution
	INCF	resolution,F
	BTFSS	resolution,1
	GOTO	check1
	INCF	totalunit
	BTFSC	bitz
	INCF	tuhigh
	CLRF	resolution
	MOVF	totalunit,W
	MOVWF	t3
	MOVF	tuhigh,W
	MOVWF	t4
	CALL	decimals	;:::::::::::::::::::::
	MOVF	t9,W
	MOVWF	k9
	MOVF	t8,W
	MOVWF	k8
	MOVF	t7,W
	MOVWF	k7
	MOVF	t6,W
	MOVWF	k6
	MOVF	t5,W
	MOVWF	k5
	CALL	clrmsg
	BANKSEL	totalunit
	CALL	txmsg
	BANKSEL	totalunit
	MOVF	totalunit,W
	SUBLW	.90
	BTFSC	bitc
	GOTO	$+4
	MOVLW	incr90P
	ADDWF	amount,F
	GOTO	$+17		;~~~~~~~~~~
	MOVF	totalunit,W
	SUBLW	.60
	BTFSC	bitc
	GOTO	$+4
	MOVLW	incr60P
	ADDWF	amount,F
	GOTO	$+10		;~~~~~~~~~~
	MOVF	totalunit,W
	SUBLW	.30
	BTFSC	bitc
	GOTO	$+4
	MOVLW	incr30P
	ADDWF	amount,F
	GOTO	$+3		;~~~~~~~~~~
	MOVLW	incr0P
	ADDWF	amount,F
	BTFSC	bitc
	INCF	amounth,F
	MOVF	amount,W
	MOVWF	t3
	MOVF	amounth,W
	MOVWF	t4
	CALL	decimals	;:::::::::::::::::::::	
	CALL	sendmsg
check1:
	;BANKSEL	PORTC
	;BTFSC	input
	;GOTO	check1
	GOTO	check

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
clrmsg:
	MOVLW	0x08
	CALL	usartsend
	CALL	usartsend
	CALL	usartsend
	CALL	usartsend
	CALL	usartsend
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

txmsg:
	MOVF	t9,W
	CALL	usartsend
	MOVF	t8,W
	CALL	usartsend
	MOVF	t7,W
	CALL	usartsend
	MOVF	t6,W
	CALL	usartsend
	MOVF	t5,W
	CALL	usartsend
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

usartsend:
	MOVWF	tempchar
	BANKSEL	TXSTA
	BTFSS	TXSTA,TRMT
	GOTO	usartsend
	BANKSEL	tempchar
	MOVF	tempchar,W
	MOVWF	TXREG
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sendmsg:
	MOVLW	0x0001		;clear display
	CALL	cmd
	MOVLW	A' '
	CALL	sendchar
	MOVLW	A'U'
	CALL	sendchar
	MOVLW	A'n'
	CALL	sendchar
	MOVLW	A'i'
	CALL	sendchar
	MOVLW	A't'
	CALL	sendchar
	MOVLW	A's'
	CALL	sendchar
	MOVLW	A':'
	CALL	sendchar
	MOVF	k9,W
	CALL	sendchar
	MOVF	k8,W
	CALL	sendchar
	MOVF	k7,W
	CALL	sendchar
	MOVF	k6,W
	CALL	sendchar
	MOVF	k5,W
	CALL	sendchar
	MOVLW	0x00C0		;newline
	CALL	cmd
	MOVLW	A'A'
	CALL	sendchar
	MOVLW	A'm'
	CALL	sendchar
	MOVLW	A'o'
	CALL	sendchar
	MOVLW	A'u'
	CALL	sendchar
	MOVLW	A'n'
	CALL	sendchar
	MOVLW	A't'
	CALL	sendchar
	MOVLW	A':'
	CALL	sendchar
	MOVF	t9,W
	CALL	sendchar
	MOVF	t8,W
	CALL	sendchar
	MOVF	t7,W
	CALL	sendchar
	MOVF	t6,W
	CALL	sendchar
	MOVF	t5,W
	CALL	sendchar
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sendchar:			;send a character to LCD
	MOVWF	dataport
	NOP
	BSF	dataen		;select data registry
	signal			;signal enable macro
	NOP
	CLRF	dataport	;make all PORTB outputs low
	BCF	dataen		;select instruction registry
	CALL	delay5ms
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cmd:	MOVWF	dataport	;send command to PORTB
	NOP
	signal			;signal enable macro
	CLRF	dataport	;make all PORTB outputs low
	CALL	delay100ms
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;decimals(16bit)
;variables:t0,t1,t3,t4,t5,t6,t7,t8,t9,tA
;input:	t4:t3
;output:t9,t8,t7,t6,t5
;Sat 21 May 2011 02:52:57 PM IST

decimals:
	CLRF	t1
	CLRF	t0
	CLRF	t7
	CLRF	t6
	CLRF	t5
	CALL	DECC
	MOVF	tA,W
	MOVWF	t5
	CALL	DECC
	MOVF	tA,W
	MOVWF	t6
	CALL	DECC
	MOVF	tA,W
	MOVWF	t7
	CALL	DECC
	MOVF	tA,W
	MOVWF	t8
	CALL	DECC
	MOVF	tA,W
	MOVWF	t9
	RETURN
DECC:	
	MOVF	t4,W
	XORLW	0x00
	BTFSC	bitz
	GOTO	$+9
	INCF	t0,F
	BTFSC	bitc
	INCF	t1,F
	MOVLW	.10
	SUBWF	t3,F
	BTFSS	bitc
	DECF	t4,F
	GOTO	DECC
	MOVLW	.10
	SUBWF	t3,W
	BTFSS	bitc
	GOTO	$+6
	MOVWF	t3
	INCF	t0,F
	BTFSC	bitc
	INCF	t1,F
	GOTO	DECC
	MOVF	t3,W
	MOVWF	tA
	MOVF	t0,W
	MOVWF	t3
	MOVF	t1,W
	MOVWF	t4
	CLRF	t0
	CLRF	t1
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
	BANKSEL	TIME3
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
DELAY1:	
	BANKSEL	TIME1
	MOVLW	0x00F8
	MOVWF	TIME1
DELAY2:	NOP
	DECFSZ	TIME1,F
	GOTO	DELAY2
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

END

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

