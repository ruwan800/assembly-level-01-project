;This program writes "This is my LCD HELLO WORLD test program" to LCD unit.
;PORTB=LCDdata(use 8 pins to send data),PORTD,0,1,2=RS,R/W,E(R/W always in write mode)
;2011/04/03__14:28hrs
;A2 original file
;A6 edited file
;A7 edited file
;A8 edited file
;A9 final edit
;Originally written by me

LIST P=16F877A
INCLUDE"P16F877A.INC"
CBLOCK	0x35
	TIME1
	TIME2
	TIME3
	TIME4
	nl
	cc
	ci
ENDC

msg0	DT	"This is my LCD HELLO WORLD test program",0

main:	ORG	0x0000
	NOP
	BANKSEL	ADCON1
	MOVLW	0x0007
	MOVWF	ADCON1
	CLRF	TRISB
	CLRF	TRISD
	BANKSEL	PORTB
	CALL	init
	CALL	charinit
	CALL	msginit
	CALL	inf
	
;configure LCD
init:	
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
	RETURN

cmd:	MOVWF	PORTB	;send command to PORTB
	NOP
	MOVLW	0x0004	;enable signal
	MOVWF	PORTD
	NOP
	MOVLW	0x0000	;disable signal
	MOVWF	PORTD	
	MOVLW	0x0000	;make all PORTB outputs low
	MOVWF	PORTB
	CALL	delay5ms
	RETURN

;delays(5ms,100ms,4s)
;[cblock:TIME1,TIME2,TIME3,TIME4]
;[functions:delay5ms,delay100ms,delay4s]
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

msginit:
	MOVLW	0x0080	;set DDRAM address to line1char1
	CALL	cmd
	MOVLW	0x0001	;clear display
	CALL	cmd
	MOVLW	0x000F
	MOVWF	nl
	MOVLW	0x001F
	MOVWF	cc
	MOVLW	msg0		;w will contain the starting address of mes0 string
	MOVWF	ci
	CALL	sendmsg

sendmsg:MOVFW	ci
	MOVWF	FSR		;load character pointer
	MOVF	INDF,W
	MOVWF	tempchar
	MOVFW	tempchar							
	call	sendchar	;load the PCL with the character address
	INCF	ci,F		;next character to display		
	DECFSZ	cc,F
	GOTO	sendmsg
	RETURN

newline:
	DECFSZ	nl,F
	RETURN
	MOVLW	0x00C0	;set DDRAM address to line2char1
	CALL	cmd
	RETURN
	
;send a character to LCD
sendchar:
	MOVWF	PORTB
	NOP
	MOVLW	0x0005	;enable signal,select data registry
	MOVWF	PORTD
	NOP
	MOVLW	0x0001	;disable signal
	MOVWF	PORTD
	NOP
	MOVLW	0x0000	;select instruction registry
	MOVWF	PORTD
	MOVLW	0x0000	;make all PORTB outputs low
	MOVWF	PORTB
	CALL	delay5ms
	CALL	newline	;goto next line if 16 characters written
	RETURN
inf:	NOP		;loop forever
	GOTO	inf
END

