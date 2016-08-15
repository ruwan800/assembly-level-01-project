LIST P=16F877A
INCLUDE"P16F877A.INC"

__config  _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _XT_OSC & _LVP_OFF 

;STATUS 	equ	03h
;PIR1   	equ	0Ch
;PIE1   	equ	8Ch
;RCSTA  	equ	18h
;TXREG  	equ	19h
;RCREG  	equ	1Ah
;TXSTA  	equ	98h
;SPBRG  	equ	99h
;TRISC  	equ	87h
CounterL 	equ	0Dh
CounterH 	equ	0Eh

;initialization

init:
	bsf	STATUS,5    ;Switch to Bank 1
	movlw	b'00100110'
	movwf	TXSTA       ;Transmit Enable
	movlw	D'25'
	movwf	SPBRG       ;Baud rate 9600
	bsf	PIE1,5      ;Enable receive interrupt
	bcf	STATUS,5    ;Switch to Bank 0
	bsf	RCSTA,7     ;Enable Serial com
	bsf	RCSTA,4     ;Enable Continuous receive
	clrf	TRISC       ;Output portc,0

; write AT commands
Main: 
	movlw	A'A'        ;AT command
	movwf	TXREG      ;Transmit to GPRS
	movlw	A'T'
	movwf	TXREG 
	movlw	A'E'
	movwf	TXREG 
	movlw	A'0'
	movwf	TXREG 
	movlw	0x0D
	movwf	TXREG
	movlw	A'A'
	movwf	TXREG 
	movlw	A'T'
	movwf	TXREG
	movlw	0x0D
	movwf	TXREG 

	call	Delay       ;waiting for respond
      
test:
	btfss	PIR1,5
	goto	test
	MOVLW	A'O'         ;Received letter     
	xorwf	RCREG,0    ;Compare Received letter with O 
	bsf	PORTC,0

   

Delay:  decfsz CounterL,1
        goto Delay
        decfsz CounterH,1
        goto Delay
        return
        
end
