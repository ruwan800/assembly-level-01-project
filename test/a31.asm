;a27.asm
;this program display units of electricity on lcd
;රු:ප්‍ර:ජ:/වි:a30.asm
;Sat 21 May 2011 03:40:07 PM IST 

LIST P=16F877A
INCLUDE"P16F877A.INC"

__config  _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _XT_OSC & _LVP_OFF 


#define	input		PORTC,2
#define	bitz		STATUS,Z
#define	bitc		STATUS,C
#define	dataen		PORTB,7			;select instruction registry(RS)
#define	signalen	PORTB,6			;signal enable bit
#define	dataport	PORTD			;PORT used to send data
#define	LSKbit		PORTB,0
#define	RSKbit		PORTB,1
#define	okbit		PORTB,2
#define	leftbit		PORTB,3
#define	rightbit	PORTB,4
#define	upbit		PORTB,5
;#define	downbit		PORTB,?
;#define	endbit		PORTB,?

rHlimit	equ	.0
rLlimit	equ	.1
;incr0P 	equ	.3
;incr30P	equ	.2
;incr60P	equ	.3
;incr90P	equ	.2

cblock	0x20
	charptr
	lcdptr
	roundsH
	roundsL
	unitsH
	unitsL
	amountL
	amountH
	tempchar
	TIME1
	TIME2
	TIME3
	TIME4
endc

cblock	0x60
	k5,k6,k7,k8,k9
endc

cblock	0x70
	t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,tA
endc

signal	MACRO
	BSF	signalen
	NOP
	BCF	signalen
	ENDM

settext	MACRO
	;CALL	delay100ms
	BANKSEL	PORTB
	BSF	LSKbit
	;CALL	delay100ms
	BCF	LSKbit
	;CALL	delay1s
	;(macro phone init)
	ENDM

endtext	MACRO
	;CALL	delay100ms
	BANKSEL	PORTB
	BSF	LSKbit
	;CALL	delay100ms
	BCF	LSKbit
	;CALL	delay1s
	;(macro phone init)
	ENDM

down	MACRO
	BANKSEL	PORTB
	;CALL	delay100ms
	BSF	downbit
	;CALL	delay100ms
	BCF	downbit
	;CALL	delay1s
	ENDM
	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

ORG	0x0000
GOTO	main

DATA_TABLE:			;this function create one 'RETLW' instrution at a time and automatically 
	MOVWF	PCL		;   returns with a value

msg0	DT	"Units|"	;generates series of RETLW instructions in memory
msg1	DT	"Starting|"
msg20	DT	"You have reached_ unit 20|"
msg50	DT	"You have reached_ unit 50|"


main:
	BANKSEL	ADCON1
	MOVLW	0x0007
	MOVWF	ADCON1
	BANKSEL	TRISD
	CLRF	TRISD
	CLRF	TRISB
	BANKSEL	PORTD
	CLRF	PORTD
	CLRF	PORTB
	BANKSEL	TRISC		;configure pins for serial transmitting
	;BCF	TRISC,6		;c6=0 as output
	;BSF	TRISC,7		;c7=1 as input
	BSF	TRISC,2
	BANKSEL	PORTC
	BCF	input

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

lcdinit:
	CALL	delay5ms
	MOVLW	0x0030	;setting function set
	CALL	cmd
	MOVLW	0x0030	;setting function set
	CALL	cmd
	MOVLW	0x0030	;setting function set
	CALL	cmd
	MOVLW	0x0038	;setting function set
	CALL	cmd
	MOVLW	0x000C	;display ON/OFF control
	CALL	cmd
	MOVLW	0x0006	;entry mode set
	CALL	cmd
	MOVLW	0x0001	;clear display
	CALL	cmd

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

routine:
	MOVLW	msg1
	CALL	sendmsg
	BANKSEL	roundsH
	CLRF	roundsH
	CLRF	roundsL
	CLRF	unitsH
	CLRF	unitsL
	CLRF	amountH
	CLRF	amountL
check:
;	BANKSEL	PORTC
;	BTFSS	input
;	GOTO	check1
	BCF	bitc
	BANKSEL	roundsL
	INCF	roundsL,F
	BTFSC	bitc
	INCF	roundsH,F
	XORLW	roundsL
	BTFSS	bitz
	GOTO	check
	XORLW	roundsH
	BTFSS	bitz
	GOTO	check
	INCF	unitsL,F
	BTFSC	bitc
	INCF	unitsH,F
	MOVF	unitsL,W
	MOVWF	t3
	MOVF	unitsH,W
	MOVWF	t4
	CALL	decimals
	MOVLW	msg0
	CALL	sendmsg
	MOVLW	.40
	CALL	sendvarmsg
	CALL	limit20
	CALL	limit50
	;(more "limit" stuff)
check1:
;	BANKSEL	PORTC
;	BTFSC	input
;	GOTO	check1
	GOTO	check


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

limit20:
	BANKSEL	unitsL
	MOVLW	unitsL
	XORLW	.20
	BTFSS	bitz
	RETURN
	MOVLW	msg20
	CALL	sendmsg
	settext
	;(text msg select)
	endtext
	RETURN

limit50:
	BANKSEL	unitsL
	MOVLW	unitsL
	XORLW	.50
	BTFSS	bitz
	RETURN
	MOVLW	msg50
	CALL	sendmsg
	settext
	;(text msg select)
	endtext
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sendmsg:			;DATA_TABLE:this function gets 1 char at a time from 'msgX' and send via 'sendchar'
	MOVWF	charptr		;   and returns when value is '0' since msgX has '0' at the end as a char	
	MOVLW	0x0001		;clear display
	CALL	cmd		
SNMF:	MOVF	charptr,W	
	CALL	DATA_TABLE
	MOVWF	tempchar
	INCF	charptr,F
	MOVLW	tempchar
	XORLW	A'_'
	BTFSC	STATUS,Z
	GOTO	newline
	XORLW	A'|'
	BTFSC	STATUS,Z
	GOTO	endch
	MOVLW	tempchar
	CALL	sendchar
	GOTO	SNMF
endch:	RETURN			;end of char string
newline:
	MOVLW	0x00C0
	CALL	cmd
	GOTO	SNMF

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sendchar:			;send a character to LCD
	MOVWF	dataport
	NOP
	BSF	dataen		;select data registry
	signal			;signal enable macro
	NOP
	CLRF	dataport	;make all PORTB outputs low
	BCF	dataen		;select instruction registry
	CALL	delay5ms
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cmd:	MOVWF	dataport	;send command to PORTB
	NOP
	signal			;signal enable macro
	CLRF	dataport	;make all PORTB outputs low
	CALL	delay5ms
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sendvarmsg:
	MOVWF	lcdptr		;starting register should loaded to msgptr
	ADDLW	0x80		;variable 'tempchar' used to handle a character
	CALL	cmd		;'LINEMSGTEMP' function should be initialized near character data tables
	MOVF	t9,W		;'sendchar' function used to send a character
	XORLW	0x00		;once called lineXsg function whole data table characters send to LCD
	BTFSS	bitz		
	ADDLW	0x10
	ADDLW	0x20
	CALL	sendchar
	MOVF	t8,W		
	ADDLW	0x10
	ADDLW	0x20	
	CALL	sendchar
	MOVF	t7,W		
	ADDLW	0x10
	ADDLW	0x20	
	CALL	sendchar
	MOVF	t6,W
	ADDLW	0x30	
	CALL	sendchar	
	MOVF	t5,W
	ADDLW	0x30	
	CALL	sendchar
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;decimals(16bit)
;variables:t0,t1,t3,t4,t5,t6,t7,t8,t9,tA
;input:	t4:t3
;output:t9,t8,t7,t6,t5
;Sat 21 May 2011 02:52:57 PM IST

decimals:
	CLRF	t1
	CLRF	t0
	CLRF	t7
	CLRF	t6
	CLRF	t5
	CALL	DECC
	MOVF	tA,W
	MOVWF	t5
	CALL	DECC
	MOVF	tA,W
	MOVWF	t6
	CALL	DECC
	MOVF	tA,W
	MOVWF	t7
	CALL	DECC
	MOVF	tA,W
	MOVWF	t8
	CALL	DECC
	MOVF	tA,W
	MOVWF	t9
	RETURN
DECC:	
	MOVF	t4,W
	XORLW	0x00
	BTFSC	bitz
	GOTO	$+9
	INCF	t0,F
	BTFSC	bitc
	INCF	t1,F
	MOVLW	.10
	SUBWF	t3,F
	BTFSS	bitc
	DECF	t4,F
	GOTO	DECC
	MOVLW	.10
	SUBWF	t3,W
	BTFSS	bitc
	GOTO	$+6
	MOVWF	t3
	INCF	t0,F
	BTFSC	bitc
	INCF	t1,F
	GOTO	DECC
	MOVF	t3,W
	MOVWF	tA
	MOVF	t0,W
	MOVWF	t3
	MOVF	t1,W
	MOVWF	t4
	CLRF	t0
	CLRF	t1
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

delay4s:
	CALL	delay2s
	CALL	delay2s
	RETURN
delay2s:
	CALL	delay1s
	CALL	delay1s
	RETURN
delay1s:		;(generates 2.000124 delay)
	BANKSEL	TIME4
	MOVLW	0x0A
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
DELAY1:	
	BANKSEL	TIME1
	MOVLW	0x00F8
	MOVWF	TIME1
DELAY2:	NOP
	DECFSZ	TIME1,F
	GOTO	DELAY2
	RETURN

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

END

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
