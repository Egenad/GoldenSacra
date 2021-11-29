;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

;If all of these are already defined, don't do it again.
        IF      !DEF(INPUTSYS_INC)
INPUTSYS_INC  SET  1

	;FUNCTIONS
	EXPORT IS_INIT
	EXPORT IS_UPDATE
	EXPORT IS_PRESS_START
	EXPORT IS_CHECK_BPRESSED
	EXPORT IS_CHECK_MENU_BUTTONS
	EXPORT IS_READ_PAD
	EXPORT IS_CHECK_PRESS_AB

	ENDC	;INPUTSYS_INC