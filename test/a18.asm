;projectQ
;code for transmitting at LED circuit MCU
;this code supports 8 baud rate values between LED transmitter and LDR receiver
;maximum baud rate is 244.14Hz(set 'baudrate' to value .7 )
;minimum baud rate is 0.95Hz(set 'baudrate' to value .0 )
;රු:ප්‍ර:ජ:/P a17.asm
;Sun 08 May 2011 07:35:33 PM IST 

LIST P=16F877A
#INCLUDE"P16F877A.INC"

__config  _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _XT_OSC & _LVP_OFF


;÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷

#define		data	PORTD,0	;define the pin LED/LDR connected

baudrate	equ	.0	;only 0-7 are accepted. do not remove "." in this line

;÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷

cblock	0x30
	bufferstring
endc

cblock	0x20
	rcptr
	txptr
	var0
	var1
	bufferchar
endc

cblock	0x2D
	t1
	t2
	t3
endc
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

ORG	0x0000

main:
	MOVLW	0x03
	MOVWF	t1
	MOVLW	0xFF
	MOVWF	t2
	MOVLW	0x02
	MOVWF	t3
	CALL	init
	CALL	usartinit
	CALL	timerinit
	CALL	txon
	BANKSEL	rcptr
	MOVLW	0x30
	MOVWF	rcptr
	MOVLW	0x2E
	MOVWF	txptr
	CLRF	var0
	BSF	var0,3
	CLRF	var1
	MOVLW	0xFF
	MOVWF	bufferchar
check:
	BANKSEL	var1
	BTFSS	var1,3
	GOTO	FUNC2
FUNC0:
	BANKSEL	INTCON
	BTFSS	INTCON,T0IF
	GOTO	check
	BCF	INTCON,T0IF
	CALL	sendchar
	BANKSEL	var1
	BTFSC	var1,4
	GOTO	FUNC3
	BANKSEL	txptr
	MOVF	txptr,W
	XORLW	0x7F
	BTFSC	STATUS,Z
	GOTO	FUNC4
	BANKSEL	txptr
	INCF	txptr,W
	XORWF	rcptr,W
	BTFSC	STATUS,Z
	GOTO	FUNC5
	BANKSEL	rcptr
	MOVF	rcptr,W
	XORLW	0x30
	BTFSS	STATUS,Z
	GOTO	check
	BANKSEL	var0
	BTFSS	var0,1
	GOTO	check
	CALL	txoff
	BANKSEL	var1
	BSF	var1,4
	MOVLW	0x2C
	MOVWF	txptr
	GOTO	check
	
FUNC6:
	BANKSEL	var1
	BTFSC	var1,1
	GOTO	FUNC0
	GOTO	check
FUNC2:
	BANKSEL	PIR1
	BTFSS	PIR1,RCIF
	GOTO	FUNC6
	BANKSEL	var1
	BSF	var1,1
	CALL	getchar
	BANKSEL	rcptr
	MOVF	rcptr,W
	XORLW	0x7F
	BTFSS	STATUS,Z
	GOTO	FUNC0
	BSF	var1,3
	CALL	txoff
	GOTO	FUNC0	
FUNC4:
	CALL	txon
	BANKSEL	var1
	BCF	var1,3	
FUNC5:
	MOVLW	0x30
	BANKSEL	rcptr
	MOVWF	rcptr
	MOVLW	0x30
	MOVWF	txptr	
	GOTO	check
FUNC3:
	BANKSEL	txptr
	MOVF	txptr,W
	XORLW	0x2E
	BTFSS	STATUS,Z
	GOTO	check
	CALL	txon
	BANKSEL	var1
	CLRF	var1
	MOVLW	0xFF
	MOVWF	bufferchar
	BCF	data
	GOTO	check

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

getchar:
	BANKSEL	rcptr
	MOVF	rcptr,W
	MOVWF	FSR
	MOVF	RCREG,W
	MOVWF	INDF
	INCF	rcptr,F
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

sendchar:
	BANKSEL	bufferchar
	BCF	data
	BTFSC	bufferchar,7
	BSF	data
	RLF	bufferchar,F
	DECFSZ	var0,F
	RETURN
	BANKSEL	txptr
	INCF	txptr,F
	MOVF	txptr,W
	MOVWF	FSR
	MOVF	INDF,W
	MOVWF	bufferchar
	BSF	var0,3
	RETURN
		
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	
init:	
	BANKSEL	ADCON1
	MOVLW	0x0007
	MOVWF	ADCON1
	BANKSEL	TRISA
	CLRF	TRISA
	CLRF	TRISB
	CLRF	TRISC
	CLRF	TRISD
	CLRF	TRISE
	BANKSEL	PORTA
	CLRF	PORTA
	CLRF	PORTB
	CLRF	PORTC
	CLRF	PORTD
	CLRF	PORTE
	BANKSEL	TRISC		;configure pins for serial transmitting
	BCF	TRISC,6		;c6=0 as output
	BSF	TRISC,7		;c7=1 as input
	RETURN
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

usartinit:
	BANKSEL	RCSTA
	BSF	RCSTA,CREN
	BANKSEL	RCSTA
	BSF	RCSTA,SPEN
	BANKSEL	TXSTA
	BSF	TXSTA,TXEN
	BSF	TXSTA,BRGH
	BANKSEL	SPBRG		;setting up baud rate
	MOVLW	D'25'
	MOVWF	SPBRG
	RETURN	

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

timerinit:
	BANKSEL	INTCON
	CLRF	INTCON
	BANKSEL	OPTION_REG
	CLRF	OPTION_REG
	BSF	OPTION_REG,7
	BSF	OPTION_REG,6
	BANKSEL	baudrate
	MOVLW	baudrate
	MOVWF	var0
	COMF	var0,F
	BTFSS	var0,0
	GOTO	$+3
	BANKSEL	OPTION_REG
	BSF	OPTION_REG,0
	BANKSEL	var0
	BTFSS	var0,1
	GOTO	$+3
	BANKSEL	OPTION_REG
	BSF	OPTION_REG,1
	BANKSEL	var0
	BTFSS	var0,2
	GOTO	$+3
	BANKSEL	OPTION_REG
	BSF	OPTION_REG,2
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

txon:
	BANKSEL	TXSTA
	BTFSS	TXSTA,TRMT
	GOTO	txon
	BANKSEL	TXREG
	MOVLW	0x11
	MOVWF	TXREG
	RETURN

txoff:
	BANKSEL	TXSTA
	BTFSS	TXSTA,TRMT
	GOTO	txon
	BANKSEL	TXREG
	MOVLW	0x13
	MOVWF	TXREG
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

END

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
