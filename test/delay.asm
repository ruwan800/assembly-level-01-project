;Delay Generating code
;ru.pra.ja/asm:2011/04/03-13:02hrs
;delays(5ms,100ms,4s)
;[cblock:TIME1,TIME2,TIME3,TIME4]
;[functions:delay5ms,delay100ms,delay4s]
delay4s:
	MOVLW	0x000A
	MOVWF	TIME4
DELAY4:	NOP
	GOTO	delay100ms
	DECFSZ	TIME4,F
	GOTO	DELAY4
	RETURN
	
delay100ms:
	MOVLW	0x0005
	MOVWF	TIME3
DELAY3:	NOP
	GOTO	delay5ms
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
