;This program writes A-Z characters to LCD unit.
;PORTB=LCDdata(use 8 pins to send data),PORTD,0,1,2=RS,R/W,E(R/W always in write mode)
;2011/03/27__10:57Hrs
;A2 original file
;A6 edited file
;A7 final edit
;Originnaly written by me

LIST P=16F877A
errorlevel -302
INCLUDE"P16F877A.INC"
CBLOCK	0x35
	TIME1
	TIME2
	TIME3
	tempchar
	charcount
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
	CALL	delay3
	MOVLW	0x0038	;setting function set
	CALL	cmd
	MOVLW	0x000F	;display ON/OFF control
	CALL	cmd
	MOVLW	0x0001	;clear display
	CALL	cmd
	MOVLW	0x0006	;entry mode set
	CALL	cmd
	MOVLW	0x0080	;set DDRAM address to line1char1
	CALL	cmd
	RETURN

cmd:	MOVWF	PORTB	;send command to PORTB
	NOP
	MOVLW	0x0004	;enable signal
	MOVWF	PORTD
	NOP
	NOP
	MOVLW	0x0000	;disable signal
	MOVWF	PORTD	
	MOVLW	0x0000	;make all PORTB outputs low
	MOVWF	PORTB
	CALL	delay
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

delay3:	MOVLW	0x0014
	MOVWF	TIME3
DELAY4:	NOP
	DECFSZ	TIME3,F
	GOTO	delay
	RETURN

charinit:
	movlw	d'26'
	Movwf	charCount	;initialize charCount with 26
	Movlw	0x0040
	Movwf	tempChar

chargen:
	Movf	tempChar,w	;‘A’ has the ASCII code of 65 decimal (0x41), by
	Addlw	1		;adding 1 to it we have 66, which is B. Therefore, by
	movwf	tempChar	;continuously adding 1 to tempChar we are cycling
	MOVF	tempchar,W
	CALL	sendchar
	movf	tempChar,w	;through the ASCII table (here: alphabets)
	decfsz	charCount
	goto	chargen


;send a character to LCD
sendchar:
	MOVWF	PORTB
	NOP
	MOVLW	0x0005	;enable signal,select data registry
	MOVWF	PORTD
	NOP
	NOP
	MOVLW	0x0000	;disable signal,select instruction registry
	MOVWF	PORTD
	MOVLW	0x0000	;make all PORTB outputs low
	MOVWF	PORTB
	CALL	delay
	RETURN
inf:NOP				;loop forever
	NOP
	GOTO	inf
END

