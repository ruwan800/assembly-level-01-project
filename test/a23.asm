
LIST P=16F877A
#INCLUDE"P16F877A.INC"

__config  _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _XT_OSC & _LVP_OFF 

cblock	0x20
	TIME1,TIME2,TIME3,TIME4
endc


ORG	0x0000
CALL	delay100ms
GOTO	FUNC0

delay4s:
	CALL	delay2s
	CALL	delay2s
	RETURN
delay2s:		;(generates 2.000124 delay)
	BANKSEL	TIME4
	MOVLW	0x0014
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
	MOVLW	0x0063
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
DELAY1:	MOVLW	0x00F8
	MOVWF	TIME1
DELAY2:	NOP
	DECFSZ	TIME1,F
	GOTO	DELAY2
	RETURN

FUNC0:	NOP

END