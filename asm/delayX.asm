;delayX.asm
;this code generates 5 variable delay levals from 5ms to 20s.
;variables:TIME1,TIME2,TIME3,TIME4,TIME5.
;functions:delay20s,delay4s,delay2s,delay100ms,delay5ms.
;above functons can be called at anywhere.
;Sun 22 May 2011 09:12:38 AM IST 

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CBLOCK	0x20		;variable assignment
	TIME1
	TIME2
	TIME3
	TIME4
	TIME5
ENDC

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

delay20s:		;(generates nearly 20s delay)
	BANKSEL	TIME5
	MOVLW	0xC8
	MOVWF	TIME5
DELAY5:	CALL	delay100ms
	DECFSZ	TIME5,F
	GOTO	DELAY5
	RETURN
delay4s:		;(generates nearly 4s delay)
	CALL	delay2s
	CALL	delay2s
	RETURN
delay2s:		;(generates 2.000124s delay)
	BANKSEL	TIME4
	MOVLW	0x14
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
	MOVLW	0x63
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
DELAY1:	BANKSEL	TIME1
	MOVLW	0xF8
	MOVWF	TIME1
DELAY2:	NOP
	DECFSZ	TIME1,F
	GOTO	DELAY2
	RETURN
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
