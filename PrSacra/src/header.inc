;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol MArtínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

IF      !DEF(HEADER_INC)
HEADER_INC  SET  1

SECTION "Reset Table",ROM0[$28]
COPY_DMA_DATA:
	pop hl 					;here we get the return address onto hl. It is the top of the stack
	push bc 				;we save the value of bc just in case it has something important

	; here we get the number of bytes to copy
  	; hl contains the address of the bytes following the "rst $28" call

	ld  a,[hli]
	ld  b,a
	ld  a,[hli]
	ld  c,a

	;now bc contains the total bytes to copy ($000D)
	;and hl points to the first byte of our assembled subroutine (which is $F5)

COPY_DMA_DATA_LOOP:

	ld  a,[hli] 			;save the data of hl in a and increase it
	ld  [de],a 		 		;save the data of  a in de (FF80)
	inc de 					;increase the memory address of the destination
	dec bc 					;decrease the byte counter
	ld  a, b 				
	or  c
	jr  nz, COPY_DMA_DATA_LOOP
	pop bc 					;restore the initial value of bc
	push hl 				;push on to the stack the memory address which is the ret of the DMA_COPY function
	reti					;return to the top of the stack memory address

SECTION "VBlank IRQ",ROM0[$40]
	ld  a,$1
	ld  [vblank_flag],a
	reti

SECTION	"LCD IRQ Vector",ROM0[$48]
LCD_VECT:
	reti

SECTION	"Timer IRQ Vector",ROM0[$50]
TIMER_VECT:
	reti

SECTION	"Serial IRQ Vector",ROM0[$58]
SERIAL_VECT:
	reti

SECTION	"Joypad IRQ Vector",ROM0[$60]
JOYPAD_VECT:
	reti

	ENDC