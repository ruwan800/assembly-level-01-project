;projectQ
;code for receiving at LDR circuit MCU
;this code supports 8 baud rate values between LED transmitter and LDR receiver
;maximum baud rate is 244.14Hz(set 'baudrate' to value .7 )
;minimum baud rate is 0.95Hz(set 'baudrate' to value .0 )
;රු:ප්‍ර:ජ:/P a17.asm
;Fri 06 May 2011 09:23:15 PM IST 

LIST P=16F877A
#INCLUDE"P16F877A.INC"

__config  _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _XT_OSC & _LVP_OFF


;÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷

#define		interren	INTCON,T0IE		;timer interrupt enable bit
#define		data	PORTD,0	;define the pin LED/LDR connected

baudrate	equ	.0	;only 0-7 are accepted. do not remove "." in this line

;÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷

cblock	0x75
	var0
	var1
	var2
	tempchar
	bufferchar
endc

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

ORG	0x0000
GOTO	main
ORG	0x0004
interrupt:
	BANKSEL	INTCON
	BCF	INTCON,T0IF
	CALL	recieve
	MOVF	var0,W
	XORLW	0x08
	BTFSS	STATUS,Z
	RETFIE
	CALL	check
	RETFIE
	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	
main:
	CALL	init
	CALL	usartinit
	CALL	timerinit
	CALL	watch
	GOTO	inf

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	
init:
	BANKSEL	TRISD
	CLRF	TRISD
	BANKSEL	PORTD
	CLRF	PORTD
	BANKSEL	TRISC		;configure pins for serial transmitting
	BCF	TRISC,6		;c6=0 as output
	BSF	TRISC,7		;c7=1 as input
	RETURN
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
	RETURN	

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

timerinit:
	BANKSEL	INTCON
	CLRF	INTCON
	BSF	INTCON,GIE
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

watch:
	BANKSEL	INTCON
	BCF	interren
watch0:
	BTFSS	data
	GOTO	watch0
watch2:
	BTFSC	data
	GOTO	watch2
	MOVLW	0x01
	MOVWF	TMR0
	BANKSEL	INTCON
	BSF	interren
	BANKSEL	var0
	BSF	var0,3
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

recieve:
	MOVLW	0x64
	MOVWF	var1
RCLF:	DECFSZ	var1,F
	GOTO	RCLF
	CLRF	bufferchar
	BTFSS	data
	GOTO	RCLF1
	BSF	bufferchar,0
RCLF1:	BCF	STATUS,C
	RLF	bufferchar,F
	DECFSZ	var0,F
	RETURN
	BSF	var0,3
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

check:	BTFSS	var2,0
	GOTO	CHKF
	MOVF	bufferchar,W
	XORLW	0x03
	BTFSS	STATUS,Z
	CALL	usartsend
	BCF	var2,0
	BSF	var2,1
	RETURN
CHKF:	MOVF	bufferchar,W
	XORLW	0x02
	BTFSS	STATUS,Z
	BSF	var2,1
	BSF	var2,0
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

usartsend:
	BANKSEL	bufferchar
	MOVF	bufferchar,W
	MOVWF	tempchar
	BANKSEL	TXSTA
	BTFSS	TXSTA,TRMT
	GOTO	usartsend
	BANKSEL	tempchar
	MOVF	tempchar,W
	MOVWF	TXREG
	CLRF	tempchar
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

inf:	BTFSC	var2,1
	GOTO	watch
madinf:	NOP
	GOTO	madinf

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

END

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
