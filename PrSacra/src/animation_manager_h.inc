;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;


;If all of these are already defined, don't do it again.
        IF      !DEF(ANIMAN_INC)
ANIMAN_INC  SET  1

	;FUNCTIONS
	EXPORT AM_INIT
	EXPORT AM_ANIMATION_UD
	EXPORT AM_ANIMATION_LR
	EXPORT AM_RESET_PLAYER_SPRITES
	EXPORT AM_EN_ANIMATION_UD
	EXPORT AM_EN_ANIMATION_LR
	EXPORT AM_DECREMENT_EN_TIMER
	EXPORT AM_ENEMY_SPRITE_UP
	EXPORT AM_ENEMY_SPRITE_DOWN
	EXPORT AM_ENEMY_SPRITE_LEFT
	EXPORT AM_ENEMY_SPRITE_RIGHT

	ENDC	;ANIMAN_INC