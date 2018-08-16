LIST 	P=PIC16F877
		include	<P16f877.inc>
 __CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _HS_OSC & _LVP_OFF & _DEBUG_OFF & _CPD_OFF

	
	    org		0x00
reset:	goto start
	    org		0x04
start:	bcf		STATUS,RP0      ;Bank0
        bcf     STATUS,RP1
        clrf    PORTE
        clrf    PORTD      
        bsf		STATUS,RP0      ;Bank1
        bcf     STATUS,RP1      
        movlw   0x06
        movwf   ADCON1
		clrf	TRISE		;porte output 
		clrf	TRISD		;portd output
        bcf     INTCON,GIE 	;Disable all interupts
        movlw   0x0F		;4 Low bits of PORTB are input,4 High bits output
        movwf   TRISB
        bcf     OPTION_REG,0x07 ; RBPU is ON -->Pull UP on PORTB is enabled

        clrf    TRISD
        bcf     STATUS,RP0      ;Bank 0
        movlw           0x00
        movwf           PORTD

 CALL INIT
 

;---------- Main program area: ---------------------------------------------------------;
main:
call show_first
call show_mult
call show_secound
call show_even_sign
;-----mult 2 numbers
clrf 0x55;result
CALL CHECK_ZERO
CALL mull_first
;---------------
call show_result
clrf 0x50;result
clrf 0x51;result
clrf 0x54;result
goto main
zero:

call show_result
goto main
;------------------------function----------------------------
show_first:
;--------FIRST NUMBER-----------------------------
call wkb
movwf 0x50;first num
movwf 0x54;counter
call delay_500m
clrf 0x60
clrf 0x61
clrf 0x62
clrf 0x63
movfw 0x50
movwf 0x60
call bin_to_bcd
call ADD_30

movlw 0x85
call SEND_C
movfw 0x61
call SEND_D
return
;----------------------------mult SING----------------
show_mult:
movlw 0x86
call SEND_C
movlw 0x2A
call SEND_D
return
;---------SECOUND NUMBER-----------------------
show_secound:
call wkb
movwf 0x51;secound num
call delay_500m
movfw 0x51
movwf 0x60
call bin_to_bcd
call ADD_30


movlw 0x87
call SEND_C
movfw 0x61
call SEND_D
return
;----------------------------EVEN SING----------------
show_even_sign:
movlw 0x88
call SEND_C
movLw 0x3D
call SEND_D
return
;----------------------------RESULT----------------
show_result:
clrf 0x60
clrf 0x61
clrf 0x62
clrf 0x63
movfw 0x55
movwf 0x60
call bin_to_bcd
call ADD_30


movlw 0x89
call SEND_C
movfw 0x62
call SEND_D

movlw 0x8A
call SEND_C
movfw 0x61
call SEND_D



return





ADD_30:
movlw 0x30
addwf 0x61
addwf 0x62
addwf 0x63
return
BANK1:
 BSF STATUS, RP0
 BCF STATUS,RP1
 RETURN 
BANK0:
 BCF STATUS, RP0
 BCF STATUS,RP1
 RETURN


 INIT:
  MOVLW 0X30
  CALL SEND_C
  CALL delay_1ms
  CALL delay_1ms
  CALL delay_1ms
  MOVLW 0X30
  CALL SEND_C
  MOVLW 0X30
  CALL SEND_C
  MOVLW 0X38
  CALL SEND_C
  MOVLW 0X0C
  CALL SEND_C
  MOVLW 0X06
  CALL SEND_C
  MOVLW 0X01
  CALL SEND_C
  RETURN

SEND_C:

  MOVWF PORTD
  BCF PORTE,1
  BSF PORTE,0
  NOP 
  BCF PORTE,0
  CALL delay_1ms
  RETURN

 SEND_D:
 
   MOVWF PORTD
   BSF PORTE,1
   BSF PORTE,0
   NOP 
   BCF PORTE,0
 CALL delay_1ms
   RETURN 

;--------------------------------------------
;                  DELAYS
;--------------------------------------------

;D;-------------------------------------------------------------------------------------------------------

delay_1ms:     ;-----> 1ms delay
  movlw  0x0B   ;N1 = 11d
  movwf  0x20
CONT1: movlw  0x96   ;N2 = 150d
  movwf  0x22
CONT2: decfsz  0x22, f
  goto  CONT2
  decfsz  0x20, f
  goto  CONT1
  return      ; D = (5+4N1+3N1N2)*200nsec = (5+4*11+3*11*150)*200ns = 999.8us=~1ms
;------------------------------------------------------------------------------


bin_mum		EQU H'0060'
bcd_0		EQU	H'0061'
bcd_1		EQU	H'0062'
bcd_2		EQU	H'0063'
counter		EQU	H'006F'

;***********************************************************

bin_to_bcd:
		clrf		bcd_0
		clrf		bcd_1
		clrf		bcd_2
		movlw		0x08
		movwf		counter

		call		regs_left_rot
		decf		counter,f

bcd_lop:movlw		0x05
		subwf		bcd_0,w
		btfss		STATUS,C
		goto		les_5_1
		movlw		0x03
		addwf		bcd_0,f
les_5_1:movlw		0x05
		subwf		bcd_1,w
		btfss		STATUS,C
		goto		les_5_2
		movlw		0x03
		addwf		bcd_1,f
les_5_2:call		regs_left_rot
		decfsz		counter,f
		goto		bcd_lop

		return

regs_left_rot:
		rlf			bin_mum,f
		rlf			bcd_0,f
		btfss		bcd_0,4
		goto		no_C1
		bcf			bcd_0,4
		bsf			STATUS,C
no_C1:	rlf			bcd_1,f
		btfss		bcd_1,4
		goto		no_C2
		bcf			bcd_1,4
		bsf			STATUS,C
no_C2:	rlf			bcd_2,f
		return
wkb:	bcf			PORTB,0x4		;scan Row 1
		bsf			PORTB,0x5
		bsf			PORTB,0x6
		bsf			PORTB,0x7
		btfss		PORTB,0x0
		goto		kb01
		btfss		PORTB,0x1
		goto		kb02
		btfss		PORTB,0x2
		goto		kb03
		btfss		PORTB,0x3
		goto		kb0a

		bsf			PORTB,0x4
		bcf			PORTB,0x5		;scan Row 2
		btfss		PORTB,0x0
		goto		kb04
		btfss		PORTB,0x1
		goto		kb05
		btfss		PORTB,0x2
		goto		kb06
		btfss		PORTB,0x3
		goto		kb0b

		bsf			PORTB,0x5
		bcf			PORTB,0x6		;scan Row 3
		btfss		PORTB,0x0
		goto		kb07
		btfss		PORTB,0x1
		goto		kb08
		btfss		PORTB,0x2
		goto		kb09
		btfss		PORTB,0x3
		goto		kb0c

		bsf			PORTB,0x6
		bcf			PORTB,0x7		;scan Row 4
		btfss		PORTB,0x0
		goto		kb0e
		btfss		PORTB,0x1
		goto		kb00
		btfss		PORTB,0x2
		goto		kb0f
		btfss		PORTB,0x3
		goto		kb0d

		goto		wkb

kb00:	movlw		0x00
		goto		disp
kb01:	movlw		0x01
		goto		disp
kb02:	movlw		0x02
		goto		disp
kb03:	movlw		0x03
		goto		disp
kb04:	movlw		0x04
		goto		disp
kb05:	movlw		0x05
		goto		disp
kb06:	movlw		0x06
		goto		disp
kb07:	movlw		0x07
		goto		disp
kb08:	movlw		0x08
		goto		disp
kb09:	movlw		0x09
		goto		disp
kb0a:	movlw		0x0A
		goto		disp
kb0b:	movlw		0x0B
		goto		disp
kb0c:	movlw		0x0C
		goto		disp
kb0d:	movlw		0x0D
		goto		disp
kb0e:	movlw		0x0E
		goto		disp
kb0f:	movlw		0x0F
		goto		disp

	disp:		return
		goto		wkb


delay_500m:					;-----> 500ms delay
		movlw		0x32			;N1 = 50d
		movwf		0x31
CONT5:	movlw		0x80			;N2 = 128d
		movwf		0x32
CONT6:	movlw		0x80			;N3 = 128d
		movwf		0x53
CONT7:	decfsz		0x53, f
		goto		CONT7
		decfsz		0x32, f
		goto		CONT6
		decfsz		0x31, f
		goto		CONT5
		return						; D = (5+4N1+4N1N2+3N1N2N3)*200nsec = (5+4*50+4*50*128+3*50*128*128)*200ns = 496.7ms=~500ms

CHECK_ZERO:
movf 0x50,f
BTFSS STATUS,Z
GOTO C_2
clrf 0x55
goto zero
C_2:
movf 0x51,f
BTFSS STATUS,Z
RETURN
clrf 0x55
goto zero
return
;--------------------------macpla 0x51*0x50--(using 0x54 counter)------------
mull_first:
movf 0x51,w
addwf 0x55
goto mull
mull:

DECFSZ 0x54,f; skip zero
goto add
movwf 0x52
return

add:
movf 0x55,w; for cheack carry later
movwf 0x59

movf 0x51,w
addwf 0x59
btfsc	STATUS,C
incf 0x56
addwf 0x55
goto mull
return
;-------------------------------



goto $
END