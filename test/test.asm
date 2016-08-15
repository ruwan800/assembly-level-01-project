	;*****Set up the Constants*****
		STATUS 		equ 	03h
		TRISA 		equ	04h
    
   		PORTA 		equ 	05h
   		CounterL 	equ 	0Dh
   		CounterH 	equ 	0Eh
   
	;*****Set up the port*****
   		bsf		STATUS,5
   		bcf		TRISA,0
  		bcf		STATUS,5
   
	;*****Turn the LED on*****
Start 	bsf	PORTA,0
   
	;*****Delay loop1*****
Loop1	decfsz 	CounterL,1
   		goto 	Loop1
   		decfsz 	CounterH,1
   		goto 	Loop1
   
	;*****Turn the LED OFF*****
   		bcf		PORTA,0
   
	;*****Delay loop2*****
Loop2 	decfsz 	CounterL,1
   		goto 	Loop2
   		decfsz 	CounterH,1
   		goto 	Loop2
   		
   		goto 	Start
   
end
