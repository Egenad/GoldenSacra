;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

	IF      !DEF(COLLISION_INC)
COLLISION_INC  SET  1

	;FUNCTIONS
	EXPORT CM_SET_TILES
	EXPORT CM_SET_TILEX
	EXPORT CM_SET_TILEY
	EXPORT CM_CHECK_NEXT_TILE
	EXPORT CM_CHECK_NEXT_TILE_EN
	EXPORT CM_GET_TILEX
	EXPORT CM_GET_TILEY
	EXPORT CM_CHECK_X_AXIS
	EXPORT CM_CHECK_Y_AXIS
	EXPORT CM_CHECK_SAME_Y
	EXPORT CM_CHECK_SAME_X
	EXPORT CM_CHECK_ENEMY_LEFT
	EXPORT CM_CHECK_ENEMY_RIGHT
	EXPORT CM_CHECK_ENEMY_UP
	EXPORT CM_CHECK_ENEMY_DOWN
	EXPORT CM_CHECK_SAME_EN_Y
	EXPORT CM_CHECK_SAME_EN_X
	EXPORT CM_CHECK_SAME_Y_WITH_PARAM
	EXPORT CM_CHECK_SAME_X_WITH_PARAM
	
	ENDC	;COLLISION_INC