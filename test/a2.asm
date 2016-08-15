;This program writes A in LCD unit.
;PORTB=LCDdata,PORTD,0,1,2=RS,R/W,E
;2011/03/17__12:13Hrs
;A2 original file
;Originnaly written by me

LIST P=16F877A
INCLUDE"P16F877A.INC"

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
;configure LCD
init:	
	CALL	delay
	MOVLW	0x0080	;set DDRAM address to line1char1
	CALL	cmd
	MOVLW	0x000C	;display ON/OFF control
	CALL	cmd
	MOVLW	0x0001	;clear display
	CALL	cmd
	MOVLW	0x0002	;set DDRAM address to 00H
	CALL	cmd
	MOVLW	0x0038	;setting function set
	CALL	cmd
	RETURN

cmd:	MOVWF	PORTB	;send command to PORTB
	NOP
	MOVLW	0x0004	;enable signal
	MOVWF	PORTD
	CALL	delay
	MOVLW	0x0000	;disable signal
	MOVWF	PORTD
	NOP
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
	MOVLW	0x0041
	MOVWF	PORTB
	NOP
	MOVLW	0x0005	;enable signal,select data registry
	MOVWF	PORTD
	CALL	delay
	MOVLW	0x0000	;disable signal,select instruction registry
	MOVWF	PORTD
	RETURN


