;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

;If all of these are already defined, don't do it again.
        IF      !DEF(PHYSYS_INC)
PHYSYS_INC  SET  1

	;FUNCTIONS
	EXPORT PS_INIT
	EXPORT PS_UPDATE
	EXPORT PS_SET_LOCK_SCROLL
	EXPORT PS_SET_UPDATE_ABSOLUTES

	ENDC	;PHYSYS_INC