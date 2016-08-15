;projectQ
;code for receiving at LDR circuit MCU
;244.140625
;0.953674316

LIST P=16F877A
#INCLUDE"P16F877A.INC"

__config  _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _XT_OSC & _LVP_OFF

#define		data	PORTD,0

cblock 0x75
	var0
	var1
	var2
	tempchar
	bufferchar
endc


ORG	0x0000
init:
	BANKSEL	TRISD
	CLRF	TRISD
	BANKSEL	PORTD
	CLRF	PORTD
	BANKSEL	TRISC		;configure pins for serial transmitting
	BCF	TRISC,6		;c6=0 as output
	BSF	TRISC,7		;c7=1 as input

usartinit:
	BANKSEL	RCSTA
	BSF	RCSTA,SPEN
	BANKSEL	TXSTA
	BSF	TXSTA,TXEN
	BSF	TXSTA,BRGH
	BANKSEL	SPBRG		;setting up baud rate
	MOVLW	D'25'
	MOVWF	SPBRG
	BANKSEL	tempchar	
	MOVLW	0x41
	MOVWF	tempchar
usartsend:
	BANKSEL	TXSTA
	BTFSS	TXSTA,TRMT
	GOTO	usartsend
	BANKSEL	tempchar
	MOVF	tempchar,W
	MOVWF	TXREG
	GOTO	usartsend

END

