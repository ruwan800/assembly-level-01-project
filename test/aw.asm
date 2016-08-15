LIST P=16F877A
INCLUDE"P16F877A.INC"


w_temp           EQU     0x7D       ; variable used for context saving
status_temp      EQU     0x7E       ; variable used for context saving
pclath_temp      EQU     0x7F       ; variable used for context saving
ByteCounter      EQU     0xBD       ;address used for byte counter


;**********************************************************************
       ORG       0x000             ; processor reset vector
       goto      Main               ; go to beginning of program
;**********************************************************************
; isr code can go here or be located as a call subroutine elsewhere

       ORG       0x004             ; interrupt vector location
       movwf     w_temp             ; save off current W register contents
       movf      STATUS,w           ; move status register into W register
       movwf     status_temp        ; save off contents of STATUS register
       movf      PCLATH,w           ; move pclath register into w register
       movwf     pclath_temp        ; save off contents of PCLATH register

       movf      pclath_temp,w      ; retrieve copy of PCLATH register
       movwf     PCLATH             ; restore pre-isr PCLATH register contents
       movf      status_temp,w      ; retrieve copy of STATUS register
       movwf     STATUS             ; restore pre-isr STATUS register contents
       swapf     w_temp,f
       swapf     w_temp,w           ; restore pre-isr W register contents
       retfie                       ; return from interrupt

Main:
       banksel   TRISC
       bcf       TRISC,6            ;c6=0 as output
       bsf       TRISC,0            ;c0=1 as input
       bsf       TRISC,1            ;c1=1 as input
; UART module setup
       banksel   SPBRG
       movlw     15                 ; rs232 baud as 57.6k as 15
       movwf     SPBRG              ; Enable SPBRG register Baud Rate

       banksel   TXSTA               ; Select memory bank for TXSTA SFR
             
       bcf       TXSTA,TX9             ; 8-bit transmission
       bsf       TXSTA,TXEN             ; Enable Transmission  
       bcf       TXSTA,SYNC             ; Asynchronous mode
       bsf       TXSTA,BRGH             ; High Baud Rate

       banksel   RCSTA
       bcf       RCSTA,SPEN         ; Disable Serial port. I use usart tx function
       bsf       RCSTA,CREN         ; Enable Receiver

       BANKSEL   PIE1
       BCF       PIE1,TXIE
; *******************save data in pic*******************************
SaveData
       bsf      STATUS,RP0             ;bank 1
       movlw    0x42
       movwf    0xBF
       movlw    0x24
       movwf    0xC0
       ;movlw    0x00
       ;movwf    0xC1
       ;movlw    0x00 
       ;movwf    0xC2
       ;movlw    0x00
       ;movwf    0xC3
       ;movlw    0x00
       ;movwf    0xC4
;*********************transmit data new ******************************
       MOVLW     0x02
       MOVWF     ByteCounter
TestTxreg
       banksel   PIR1
       btfss     PIR1,TXIF          ;TXIF=1, is empty,skip
       goto      TestTxreg 
TransData:  
       MOVLW     0xBF
       MOVWF     FSR                ; TO RAM
       ;CLRF      TXREG
GoOnTransData:  
       banksel   TXREG
       MOVF      INDF,0
       MOVWF     TXREG             ; Move the data to the transmit register
       INCF      FSR,1             ; INDF  address number moves next
Wait0:       
       banksel   PIR1
       btfss     PIR1,TXIF        
       goto      Wait0
       clrf      TXREG
       BSF       STATUS,RP0
       DECFSZ    ByteCounter,1  ; ChannelCounter-1
       goto      GoOnTransData     ; go on       
Wait1:    
       banksel   TXSTA
       MOVLW     0x02
       MOVWF     ByteCounter
Delay:
       BANKSEL   RCSTA
       MOVLW     0x02   ;20MHz=50ns=0.05us
       MOVWF     0x20   ;0.05*4=0.2us
LOOP2:
       MOVLW     0x03   ;E5=120us;c5=80us;85=75u;35=45=55=0
       MOVWF     0x21   ;03H=16us
LOOP1:
       DECFSZ    0x21,F
       GOTO      LOOP1
       DECFSZ    0x20,F
       GOTO      LOOP2
       GOTO      TransData
       ;goto      FinishData

FinishData:
       movlw     0x00
       movwf     TXREG
       goto      FinishData
       END
;*********************transmit data finish******************************
