;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol MArtínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

;If all of these are already defined, don't do it again.
        IF      !DEF(GAME_MANAGER_INC)
GAME_MANAGER_INC  SET  1

	;FUNCTIONS
	EXPORT GM_RUN
	EXPORT GM_INIT_DUNGEON
	EXPORT GM_GET_GAME_STATE
	EXPORT GM_SET_GAME_STATE
	EXPORT GM_GET_TURN
	EXPORT GM_SET_TURN
	EXPORT GM_GAME_OVER
	EXPORT GM_INCREMENT_ACTUAL_FLOOR
	EXPORT GM_OPEN_GAME_MENU
	EXPORT GM_SET_ATTACK

	ENDC	;GAME_MANAGER_INC