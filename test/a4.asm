;This program writes a one character to LCD unit.
;PORTB=LCDdata(use 8 pins to send data),PORTD,0,1,2=RS,R/W,E(R/W always in write mode)
;2011/03/17__12:13Hrs
;A2 original file
;Originnaly written by me

LIST P=16F877A
INCLUDE"P16F877A.INC"
CBLOCK	0x35
	TIME1
	TIME2
ENDC
ORG	0x0000
NOP
BANKSEL	ADCON1
MOVLW	0x0007
MOVWF	ADCON1
CLRF	TRISB
CLRF	TRISD
BANKSEL	PORTB
CALL	init
CALL	sendchr
CALL	inf
;configure LCD
init:	
	CALL	delay
	MOVLW	0x0030	;set DDRAM address to line1char1
	CALL	cmd
	MOVLW	0x000E	;display ON/OFF control
	CALL	cmd
	MOVLW	0x0006	;clear display
	RETURN

cmd:	MOVWF	PORTB	;send command to PORTB
	NOP
	MOVLW	0x0004	;enable signal
	MOVWF	PORTD
	NOP
	MOVLW	0x0000	;make all PORTB outputs low
	MOVWF	PORTB
	CALL	delay
	MOVLW	0x0000	;disable signal
	MOVWF	PORTD
	RETURN

; 4ms delay
delay:	MOVLW	0x0010
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

;send a character to LCD
sendchr:
	MOVLW	0x0045
	MOVWF	PORTB
	NOP
	MOVLW	0x0005	;enable signal,select data registry
	MOVWF	PORTD
	NOP
	MOVLW	0x0000	;make all PORTB outputs low
	MOVWF	PORTB
	CALL	delay
	MOVLW	0x0000	;disable signal,select instruction registry
	MOVWF	PORTD
	RETURN
inf:NOP				;loop forever
	NOP
	GOTO	inf
END

