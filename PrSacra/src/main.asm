;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

	INCLUDE "hardware.inc"
	INCLUDE "header.inc"
	INCLUDE "game_manager_h.inc"
	
SECTION	"Cartridge Header",ROM0[$0100]
	nop
	jp 	 Start

	INIT_HEADER

;============================================================
; Program Start
;============================================================

SECTION "Start",ROM0[$0150]

Start::
	
	;stack pointer (FFFF is IE)
	ld   sp,$FFFE

	;save CPU type
	call GM_SET_TURN

	jp 	 GM_RUN