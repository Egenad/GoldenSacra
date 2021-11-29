;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

;If all of these are already defined, don't do it again.
        IF      !DEF(RENDERSYS_INC)
RENDERSYS_INC  SET  1

	;FUNCTIONS
	EXPORT RS_INIT
	EXPORT RS_DRAW
	EXPORT RS_UPDATE
	EXPORT RS_WAIT_VBLANK
	EXPORT RS_TURN_LCD_OFF
	EXPORT RS_TURN_LCD_ON
	EXPORT RS_TITLE_SCREEN
	EXPORT RS_INIT_BACKGROUND
	EXPORT RS_INIT_OVERWORLD
	EXPORT RS_INIT_HOUSE
	EXPORT RS_COPY_DATA
	EXPORT RS_COPY_MEM
	EXPORT RS_WAIT_MODE_01
	EXPORT RS_GET_PAL_STATE
	EXPORT RS_FADE_OUT
	EXPORT RS_FADE_IN
	EXPORT RS_INIT_FLOOR
	EXPORT RS_INIT_HUD
	EXPORT RS_UPDATE_HP_HUD
	EXPORT RS_UPDATE_FLOOR_HUD
	EXPORT RS_DRAW_TEXT_BOX
	EXPORT RS_HIDE_SCRN1
	EXPORT RS_CLEAR_DMA

	;DATA
	EXPORT vblank_flag
	EXPORT Floor2
	EXPORT Fin_Floor2
	EXPORT Floor3
	EXPORT Fin_Floor3
	EXPORT _OPTION

	ENDC	;RENDERSYS_INC