;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

	INCLUDE "collision_manager_h.inc"
	INCLUDE "hardware.inc"
	INCLUDE "constants.inc"
	INCLUDE "input_system_h.inc"
	INCLUDE "render_system_h.inc"

;==============================================================
; RAM Data
;==============================================================

SECTION "Collision_Data", WRAM0

_TILE_Y: DS 1
_TILE_X: DS 1

SECTION "Collisions", ROM0

;==============================================================
; Function: Set Tiles
; Description:
; Modified registers: a
; Input: a (_TILE_Y), b (_TILE_X)
;==============================================================

CM_SET_TILES:
	
	ld 	 [_TILE_Y], a
	ld 	 a, b
	ld 	 [_TILE_X], a

	ret

;==============================================================
; Function: Get Tile X
; Description:
; Modified registers: a
; Input: -
;==============================================================

CM_GET_TILEX:

	ld 	a, [_TILE_X]
	ret

;==============================================================
; Function: Get Tile Y
; Description:
; Modified registers: a
; Input: -
;==============================================================

CM_GET_TILEY:

	ld 	a, [_TILE_Y]
	ret

;==============================================================
; Function: Set Tile X
; Description:
; Modified registers: -
; Input: a
;==============================================================

CM_SET_TILEX:
	ld [_TILE_X], a
	ret

;==============================================================
; Function: Set Tile Y
; Description:
; Modified registers: -
; Input: a
;==============================================================

CM_SET_TILEY:

	ld [_TILE_Y], a
	ret

;==============================================================
; Function: Check Tile
; Description: Puts on hl the address of the tile the player
; is standing on.
; Modified registers: a, b, de, hl
; Input: -
; Output: hl
;==============================================================

CM_CHECK_TILE:

	ld 	 hl, _SCRN0 				;32x32 tiles
	ld 	 e, 32
	ld 	 d, 0
	ld 	 b, 0
	ld 	 a, [_TILE_Y] 				

cnt_yloop:

	;move first in the y axis --> add 32 to the actual address to change 1 screen line 
	
	add  hl, de
	inc  b
	cp   b
	jr 	 nz, cnt_yloop
	
	;move now on the x axis		
	
	ld 	 a, [_TILE_X]
	ld 	 e, a
	add  hl, de
	ret

;==============================================================
; Function: Check Next Tile
; Description: Checks the value of the next tile we want to
; move to and puts it on the b register.
; Modified registers: all
; Input: -
; Output: b
;==============================================================

CM_CHECK_NEXT_TILE:

	call CM_CHECK_TILE

	ld 	 b, h
	ld   c, l

	ld 	 e, pl_movementd
	call EM_GET_PLAYER_VARIABLE

	ld   h, b
	ld   l, c

	cp 	 LEFT_JP
	jr 	 z, cnt_left

	cp 	 RIGHT_JP
	jr 	 z, cnt_right

	cp 	 UP_JP
	jr 	 z, cnt_top

	cp 	 DOWN_JP
	jr 	 z, cnt_bot

	ret

;==============================================================
; Function: Check Next Tile Enemy
; Description: The last function uses part of this one. This is
; for the ai. The direction is saved onto _COUNT to save memory
; space as this value is just used on the tilemap function.
; Input: _COUNT (0 = Up, 1 = Down, 2 = Left, 3 = Right), hl
; Output: a
; Modified register: all
;==============================================================

CM_CHECK_NEXT_TILE_EN:

	ld 	 c, a

	call CM_CHECK_TILE 		; Returns on HL the memory address of the tile. Modifies HL, A, B, DE.

	ld 	 a, c
	or 	 a
	jr 	 z, cnt_top
	dec  a
	jr 	 z, cnt_bot
	dec  a
	jr 	 z, cnt_left
	jr 	 cnt_right

cnt_top:

	ld 	 de, $FFE0 		;This number is -31
	add  hl, de
	call RS_WAIT_MODE_01
	ld 	 a, [hl]
	ret

cnt_right:

	inc  hl
	inc  hl
	call RS_WAIT_MODE_01
	ld 	 a, [hl]
	ret

cnt_bot:

	ld 	 de, 64
	add  hl, de
	call RS_WAIT_MODE_01
	ld 	 a, [hl]
	ret

cnt_left:

	dec  hl
	dec  hl
	call RS_WAIT_MODE_01
	ld 	 a, [hl]
	ret

;==============================================================
; Function: Check X Axis Tiles
; Description: Checks if the player tiles are close to the
; one the enemy is at the moment.
; Input: -
; Output: a (bool), b (direction)
; Modified register: all
;==============================================================

CM_CHECK_X_AXIS:

	ld 	 e, pl_tilex 							; Get the X coordinate of the player.
	call EM_GET_PLAYER_VARIABLE 				; Modifies HL and D.
	ld 	 b, a

	ld 	 c, RIGHT_JP

	ld 	 a, [_TILE_X] 							; enemy_x + 2 == player_x ?
	add  2 										; Check right tile.
	sub  b
	jr 	 z, .cm_check_x_axis_true

	ld 	 c, LEFT_JP

	ld 	 a, [_TILE_X] 							; enemy_x - 2 == player_x ?
	sub  2 										; Check left tile.
	sub  b
	jr 	 z, .cm_check_x_axis_true

	xor  a 										; If neither of them was the same, return false.
	ret

.cm_check_x_axis_true:

	ld 	 a, 1
	ret

;==============================================================
; Function: Check X Axis Tiles
; Description: Checks if the player tiles are close to the
; one the enemy is at the moment.
; Input: -
; Output: a (bool), c (direction)
; Modified register: all
;==============================================================

CM_CHECK_Y_AXIS:

	ld 	 e, pl_tiley 							; Get the X coordinate of the player.
	call EM_GET_PLAYER_VARIABLE 				; Modifies HL and D.
	ld 	 b, a

	ld 	 c, DOWN_JP

	ld 	 a, [_TILE_Y]
	add  2										; Check right tile.
	sub  b
	jr 	 z, .cm_check_x_axis_true

	ld 	 c, UP_JP

	ld 	 a, [_TILE_Y]
	sub  2										; Check left tile.
	sub  b
	jr 	 z, .cm_check_x_axis_true

	xor  a 										; If neither of them was the same, return false.
	ret

.cm_check_x_axis_true:

	ld 	 a, 1
	ret

;==============================================================
; Function: Check Same Y Tile
; Description: Checks if the player tile are the same to the
; one the enemy is at the moment.
; Input: -
; Output: a (bool)
; Modified register: a, hl, de
;==============================================================

CM_CHECK_SAME_Y:

	ld 	 e, pl_tiley 							; Get the X coordinate of the player.
	call EM_GET_PLAYER_VARIABLE 				; Modifies HL and D.
	ld 	 b, a

CM_CHECK_SAME_Y_WITH_PARAM:

	ld 	 a, [_TILE_Y]

	sub  b
	jr	 z, .cm_check_same_y_true
	xor  a
	ret

.cm_check_same_y_true:

	ld a, 1
	ret

;==============================================================
; Function: Check Same X Tile
; Description: Checks if the player tile are the same to the
; one the enemy is at the moment.
; Input: -
; Output: a (bool)
; Modified register: a, hl, de
;==============================================================

CM_CHECK_SAME_X:

	ld 	 e, pl_tilex 							; Get the X coordinate of the player.
	call EM_GET_PLAYER_VARIABLE 				; Modifies HL and D.
	ld 	 b, a

CM_CHECK_SAME_X_WITH_PARAM:

	ld 	 a, [_TILE_X]

	sub  b
	jr	 z, .cm_check_same_x_true
	xor  a
	ret

.cm_check_same_x_true:
	ld 	 a, 1
	ret

;==============================================================
; Function: Check Enemy 
; Description: Checks if the enemy tile at his left equals 
; any from another enemy.
; Input: hl
; Modified register:
;==============================================================

CM_CHECK_ENEMY_LEFT:
	
	ld 	 e, en_tilex 						
	call EM_GET_ENEMY_VARIABLE 				; Modifies HL and D.
	ld 	 b, a

	ld 	 a, [_TILE_X]
	sub  2 

	sub  b
	jr	 z, cm_check_enemy_true
	xor  a
	ret

CM_CHECK_ENEMY_RIGHT:
	
	ld 	 e, en_tilex 							
	call EM_GET_ENEMY_VARIABLE				; Modifies HL and D.
	ld 	 b, a

	ld 	 a, [_TILE_X]
	add  2 

	sub  b
	jr	 z, cm_check_enemy_true
	xor  a
	ret

CM_CHECK_ENEMY_DOWN:
	
	ld 	 e, en_tiley 							
	call EM_GET_ENEMY_VARIABLE 				; Modifies HL and D.
	ld 	 b, a

	ld 	 a, [_TILE_Y]
	add  2 

	sub  b
	jr	 z, cm_check_enemy_true
	xor  a
	ret

CM_CHECK_ENEMY_UP:
	
	ld 	 e, en_tiley 							
	call EM_GET_ENEMY_VARIABLE 				; Modifies HL and D.
	ld 	 b, a

	ld 	 a, [_TILE_Y]
	sub  2

	sub  b
	jr	 z, cm_check_enemy_true
	xor  a
	ret

cm_check_enemy_true:
	ld 	 a, 1
	ret

;==============================================================
; Function: Check Enemy 
; Description: Checks if the enemy tile at his left equals 
; any from another entity.
; Input: hl
; Modified register:
;==============================================================

CM_CHECK_SAME_EN_Y:

	ld 	 e, en_tiley 							; Get the X coordinate of the player.
	call EM_GET_ENEMY_VARIABLE 					; Modifies HL and D.
	ld 	 b, a

	ld 	 a, [_TILE_Y]

	sub  b
	jr	 z, cm_check_same_x_en_true
	xor  a
	ret

CM_CHECK_SAME_EN_X:

	ld 	 e, en_tilex 							; Get the X coordinate of the player.
	call EM_GET_ENEMY_VARIABLE 					; Modifies HL and D.
	ld 	 b, a

	ld 	 a, [_TILE_X]

	sub  b
	jr	 z, cm_check_same_x_en_true
	xor  a
	ret

cm_check_same_x_en_true:

	ld a, 1
	ret
