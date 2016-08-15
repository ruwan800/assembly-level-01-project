
LIST P=16F877A
#INCLUDE"P16F877A.INC"


#define	bitz		STATUS,Z
#define	bitc		STATUS,C

cblock	0x20
	tcounth,tcountl	;0x24:clock counter values saved for further usage	
	m0,m1,t8,t7,t6,t0
endc
GOTO	divide

XPT:	
	BANKSEL TRISB
	BSF	TRISB,3
	BANKSEL	PORTB
XPY:	BTFSS	PORTB,3
	GOTO	XPY
XPZ:	BTFSC	PORTB,3
	GOTO	XPZ
	GOTO	DVLP1
divide:	
	MOVLW	0x03
	MOVWF	t8
	MOVLW	0x93
	MOVWF	t7
	MOVLW	0x87
	MOVWF	t6
	
	
	MOVLW	0x06
	MOVWF	tcounth
	MOVLW	0x1A
	MOVWF	tcountl
	
	
	CLRF	m0	
	CLRF	m1
	CLRF	t0
	MOVLW	.16
	MOVWF	t0
DVLP1:	BCF	STATUS,C
	RLF	m0,F
	RLF	m1,F		
	RLF	t6,F
	RLF	t7,F
	RLF	t8,F
	MOVF	tcounth,W
	SUBWF	t8,W
	BTFSS	bitc
	GOTO	DVLP
	BTFSS	bitz
	GOTO	DVLP2
	MOVF	tcountl,W
	SUBWF	t7,W
	BTFSS	bitc
	GOTO	DVLP
DVLP2:	MOVF	tcountl,W
	SUBWF	t7,F
	BTFSS	bitc
	DECF	t8,F
	MOVF	tcounth,W
	SUBWF	t8,F	
	BSF	m0,0
	GOTO	DVLP
DVLP:	DECFSZ	t0,F
	GOTO	XPT

END