;**********************************************************************************
; EXAMPLE CODE 1
;**********************************************************************************
; This code displays on the first “upper” row of the LCD the 26 English letters in alphabetical order
; The code starts with LCD initialization commands such as clearing the LCD, setting modes and
; display shifting.
;
; Outputs:
; LCD Control:
; RB2: RS (Register Select)
; RB3: E (LCD Enable)
; LCD Data:
; PORTC 0-7 to LCD DATA 0-7 for sending commands/characters
; Notes:
; The RW pin (Read/Write) - of the LCD - is connected to GND (always write mode)
; The BL pin (Back Light) – of the LCD – is not connected (NC) – Not used
;**********************************************************************************
include "p16f877A.inc"
;**********************************************************************************
cblock 0x20
tempChar ;holds the character to be displayed
charCount ;holds the number of the English alphabet
lsd ;lsd and msd are used in delay loop calculation
msd
endc
;**********************************************************************************
; Start of executable code
org 0x000
goto Initial
;**********************************************************************************
; Interrupt vector
INT_SVC org 0x0004
goto INT_SVC
;**********************************************************************************
; Initial Routine
; INPUT: NONE
; OUTPUT: NONE
; RESULT: Configure I/O ports (PORTC and PORTB as output)
; Configure LCD to work in 8-bit mode, with two lines of display and 5x7 dot format.
; Set the cursor to the home location (location 00), set the cursor to the visible state
; with no blinking
;**********************************************************************************
Initial
Banksel TRISB ;PORTC and PORTB as outputs
Clrf TRISB
Clrf TRISD
Banksel PORTB
Clrf PORTB
Clrf PORTD
movlw d'26'
Movwf charCount ; initialize charCount with 26:
; Number of Characters in the English language
Movlw 0x38 ;8-bit mode, 2-line display, 5x7 dot format
Call send_cmd
Movlw 0x0e ;Display on, Cursor Underline on, Blink off
Call send_cmd
Movlw 0x02 ;Display and cursor home
Call send_cmd
Movlw 0x01 ;clear display
Call send_cmd
;**********************************************************************************
; Main Routine
;**********************************************************************************
Main
Movlw 'A'
Movwf tempChar
CharacterDisplay ; Generate and display all 26 English Letters
Call send_char
Movf tempChar ,w ; ‘A’ has the ASCII code of 65 decimal (0x41), by
Addlw 1 ; adding 1 to it we have 66, which is B. Therefore, by
movwf tempChar ; continuously adding 1 to tempChar we are cycling
movf tempChar ,w ; through the ASCII table (here: alphabets)
decfsz charCount
goto CharacterDisplay
Mainloop
Movlw 0x1c ;This command shifts the display to the right once
Call send_cmd
Call delay
Goto Mainloop ; This loop makes the character rotate continuously
;**********************************************************************************
send_cmd
movwf PORTB ; Refer to table 1 on Page 5 for review of this subroutine
bcf PORTD, 0
bsf PORTD, 2
nop
bcf PORTD, 2
call delay
return
;**********************************************************************************
send_char
movwf PORTB ; Refer to table 1 on Page 5 for review of this subroutine
bsf PORTD, 0
bsf PORTD, 2
nop
bcf PORTD, 2
call delay
return
;**********************************************************************************
delay
movlw 0x80
movwf msd
clrf lsd
loop2
decfsz lsd,f
goto loop2
decfsz msd,f
endLcd
goto loop2
return
;**********************************************************************************
End
