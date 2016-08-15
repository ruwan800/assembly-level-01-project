;projectQ
;code for transmitting at LED circuit MCU
;this code supports 8 baud rate values between LED transmitter and LDR receiver
;maximum baud rate is 244.14Hz
;minimum baud rate is 0.95Hz
;රු:ප්‍ර:ජ:/P a17.asm
;Fri 06 May 2011 09:23:04 PM IST 

LIST P=16F877A
#INCLUDE"P16F877A.INC"

__config  _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _XT_OSC & _LVP_OFF


;÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷÷

#define		data	PORTD,0	;define the pin LED/LDR connected

baudrate	equ	.7	;only 0-7 are accepted. do not remove "." in this line

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
	w_temp
	status_temp
	pclath_temp
endc

cblock	0x27
	t1
	t2
	t3
endc
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

ORG	0x0000
GOTO	main
ORG	0x0004

interrupt:
	
MOVWF	w_temp			; save off current W register contents
MOVF	STATUS,w		; move status register into W register
MOVWF	status_temp		; save off contents of STATUS register
MOVF	PCLATH,w		; move pclath register into w register
MOVWF	pclath_temp		; save off contents of PCLATH register

BANKSEL	INTCON
BCF	INTCON,T0IF
GOTO	sendchar
	
endi:
	BANKSEL	txptr
	MOVF	txptr,W
	MOVWF	FSR
	MOVF	INDF,W
	MOVWF	bufferchar
	INCF	txptr,F
	BSF	var1,3
	RETURN
	
sendchar:
	BANKSEL	var1
	DECFSZ	var1,F
	CALL	endi
	BANKSEL	bufferchar
	BTFSC	bufferchar,7
	BSF	data
	RLF	bufferchar,F

MOVF	pclath_temp,w		; retrieve copy of PCLATH register
MOVWF	PCLATH			; restore pre-isr PCLATH register contents
MOVF	status_temp,w		; retrieve copy of STATUS register
MOVWF	STATUS			; restore pre-isr STATUS register contents
SWAPF	w_temp,f
SWAPF	w_temp,w		; restore pre-isr W register contents

RETFIE

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

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
MAIN1:
	BANKSEL	rcptr
	MOVLW	0x30
	MOVWF	rcptr
	MOVLW	0x28
	MOVWF	txptr
	MOVLW	0x01
	MOVWF	var1
	CALL	getchar
	BANKSEL	INTCON
	BSF	INTCON,T0IE
MAIN2:	CALL	getchar
	MOVF	rcptr,W
	XORWF	txptr,W
	BTFSC	STATUS,Z
	GOTO	MAIN4
	MOVF	rcptr,W
	XORLW	0x7F
	BTFSC	STATUS,Z
	CALL	txoff
	MOVF	rcptr,W
	XORLW	0x7F
	BTFSS	STATUS,Z
	GOTO	MAIN2
MAIN3:	MOVF	txptr,W
	XORLW	0x7F
	BTFSS	STATUS,Z
	GOTO	MAIN3
	CALL	txon
	GOTO	MAIN4
MAIN4:	MOVLW	0x0027
	MOVWF	txptr
MAIN5:	MOVF	txptr,W
	XORLW	0x28
	BTFSS	STATUS,Z
	GOTO	MAIN5
	BANKSEL	INTCON
	BCF	INTCON,T0IE
	GOTO	MAIN1
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

getchar:
	BANKSEL	PIR1
	BTFSS	PIR1,RCIF
	GOTO	getchar
	BANKSEL	rcptr
	MOVF	rcptr,W
	MOVWF	FSR
	MOVF	RCREG,W
	MOVWF	INDF
	INCF	rcptr,F
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
