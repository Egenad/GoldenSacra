;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

;If all of these are already defined, don't do it again.
        IF      !DEF(AISYS_INC)
AISYS_INC  SET  1

	;FUNCTIONS
	EXPORT AI_INIT
	EXPORT AI_UPDATE
	EXPORT AI_CHECK_TILES

	ENDC	;AISYS_INC