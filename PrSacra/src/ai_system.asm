 ;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

	INCLUDE "hardware.inc"
	INCLUDE "constants.inc"
	INCLUDE "ai_system_h.inc"
	INCLUDE "entity_manager_h.inc"
	INCLUDE "collision_manager_h.inc"

;============================================================
; User data
;============================================================

SECTION "AI_DATA",WRAM0

_RECALCULE: DS 1 									; bool to know if we have to recalcule the action of the enemies.
_EN_TO_CHECK: DS 1 									; counter to update the enemies collision
_RESERVED_CELLS: DS MAX_ENTITIES*TILE_COORDS		; 2 Tiles * Maximum Number of Enemies

SECTION "AI_System", ROM0

;==============================================================
; Function: Initialize AI System
; Description:
; Modified registers:
; Input: -
;==============================================================

AI_INIT:
	
	ld 	 a, 1
	ld 	 [_RECALCULE], a 

	call EM_GET_ENEMIES_ARRAY 					; a = num_enemies || hl = enemie_array* || de = dma_enemies*
	
	ld 	 hl, _RESERVED_CELLS
	xor  a 										;value to copy. BC will be the same
	ld 	 bc, MAX_ENTITIES*TILE_COORDS
	jp 	 RS_COPY_DATA

;==============================================================
; Function: Update AI System
; Description:
; Modified registers:
; Input: -
;==============================================================

AI_UPDATE:

	ld 	 a, [_RECALCULE] 						; If we don't have to recalcule don't do it.
	or 	 a
	ret  z

	; Get the enemies array and update all of them.

	call EM_GET_ENEMIES_ARRAY					; a = num_enemies || hl = enemie_array* || de = dma_enemies*
	or 	 a
	ret  z 										; if there are no enemies don't update anything

	ld 	 [_TOTAL_EN], a

.ai_update_loop:

	push hl 									; save enemy array position
	call AI_DECIDE_ACTION
	pop  hl

	ld 	 a, [_TOTAL_EN]
	dec  a
	jr 	 z, .ai_updated
	ld 	 [_TOTAL_EN], a
	
	ld 	 de, enemy_size
	add  hl, de
	jr 	 .ai_update_loop

.ai_updated:

	xor  a
	ld 	 [_RECALCULE], a
	ret

;==============================================================
; Function: Decide Action
; Description: The ai decides if it has to attack or move.
; Modified registers: all
; Input: hl
;==============================================================

AI_DECIDE_ACTION:

	; Check if this enemi can see the player.

	push hl
	call AI_SEE_PLAYER 
	pop  hl
	or 	 a
	jr 	 z, ai_decide_action_reset				; The enemy can't see the player -> reset action

	; Check if the action of the player is moving. If that's the case, don't try to attack

	push hl 									; Save enemy address on to the stack.
	ld 	 e, pl_action
	call EM_GET_PLAYER_VARIABLE 				; Modifies HL and D.
	pop  hl 									; Restore the enemy array address.
	and  MOVE_ACTION 							; Check if the player's moving.
	jr 	 nz, AI_DECIDE_MOVE 					; If it is, then do not try to attack.

	; Check if the enemy is in a tile next to the player
	call AI_CHECK_TILES 						; Returns a bool on a and the (if a = 1) attack direction
	or 	 a 										; If a is not 0, that means we can attack the player
	jr 	 z, AI_DECIDE_MOVE
	jr 	 AI_ATTACK

ai_decide_action_reset:

	ld 	 e, en_action
	call EM_GET_ENEMY_VARIABLE 					; Input: e (variable to return), hl (enemy address)
	and  SWAP_ACTION
	ld 	 [hl], a
	ret

;==============================================================
; Function: Attack
; Description: 
; Modified registers: all
; Input: hl, b (movement direction)
; Output: a (bool), c (direction)
;==============================================================

AI_ATTACK:
	
	ld 	 a, c
	ld 	 b, h
	ld 	 c, l

	ld 	 e, en_movementd 						; Set the movement direction
	call EM_SET_ENEMY_VARIABLE 					; This modifies HL.

	ld 	 h, b
	ld 	 l, c

	ld 	 e, en_action
	call EM_GET_ENEMY_VARIABLE 					; This modifies HL.
	and  SWAP_ACTION
	or   ATTACK_ACTION							; Set the action for the enemy.
	ld 	 [hl], a

	ld 	 h, b
	ld 	 l, c

	;push hl

	;ld 	 e, en_damage
	;call EM_GET_ENEMY_VARIABLE 					; a = enemy attack damage
	;call EM_DECREASE_PLAYER_LIFE

	;pop  hl
	ret

;==============================================================
; Function: Check Tiles
; Description: Checks the tiles to see if we can attack the
; player.
; Modified registers: all
; Input: hl
; Output: a (bool), b (direction)
;==============================================================

AI_CHECK_TILES:

	; Set the tiles on the collision manager.

	ld 	 b, h
	ld 	 c, l

	ld 	 e, en_tilex
	call EM_GET_ENEMY_VARIABLE 					; This modifies HL and A.
	call CM_SET_TILEX

	ld 	 h, b
	ld 	 l, c

	ld 	 e, en_tiley
	call EM_GET_ENEMY_VARIABLE 					; This modifies HL and A.
	call CM_SET_TILEY

	ld 	 h, b
	ld 	 l, c
	push hl 									; Save HL address. CM_CHECK_X_AXIS modifies it.
	
	; First check the X axis
	call CM_CHECK_X_AXIS 						; Check if there's collision with the X axis. Returns a bool in a and the direction in b. Modifies HL
	or   a
	jr 	 nz, .ai_check_x_axis_true 				; Returns true if they are the same.

	; Now check the Y axis
	call CM_CHECK_Y_AXIS
	or 	 a
	jr 	 nz, .ai_check_y_axis_true
	jr 	 .ai_check_tiles_true

.ai_check_y_axis_true:

	; If the Y axis check returned true, check if we are at the same X.
	call CM_CHECK_SAME_X 						; Returns a bool in a.
	jr	 .ai_check_tiles_true

.ai_check_x_axis_true:

	; If the X axis check returned true, check if we are at the same Y.
	call CM_CHECK_SAME_Y 						; Returns a bool in a.

.ai_check_tiles_true:

	pop  hl
	ret

;==============================================================
; Function: Move Enemy
; Description: The ai decides where to move to and updates
; the animation of the sprites.
; Modified registers: all
; Input: hl
;==============================================================

AI_DECIDE_MOVE:

	push hl

	ld 	 e, en_velocity
	call EM_GET_ENEMY_VARIABLE
	ld 	 d, a
	dec  a
	jr 	 c, .decide_move_keep

	ld 	 a, d
	and  %00001111
	dec  a
	jr 	 nz, .decide_move_update_velocity

	; Reset velocity
	
	ld 	 a, d
	and  %11110000
	ld 	 d, a
	swap a
	or 	 d
	ld 	 [hl], a

	jp 	 .decide_not_m

.decide_move_update_velocity:

	ld 	 e, a
	ld 	 a, d
	and  %11110000
	or 	 e
	ld 	 [hl], a

	pop  hl

.decide_move_keep:

	ld 	 b, h
	ld 	 c, l 									; Save enemy address on BC

	ld 	 e, en_action
	call EM_GET_ENEMY_VARIABLE
	or 	 MOVE_ACTION							; Set the action for the enemy.
	ld 	 [hl], a

	ld 	 h, b
	ld 	 l, c

	ld 	 e, en_tilex
	call EM_GET_ENEMY_VARIABLE 					; This modifies HL and A.

	ld 	 h, b
	ld 	 l, c 									; Save again initial address on HL.
	ld 	 b, a 									; Save the X Coordinate on B.

	push hl 									; We don't want to lose the initial address of the enemy.

	ld 	 e, en_tiley
	call EM_GET_ENEMY_VARIABLE 					; This modifies HL and A.

	call CM_SET_TILES 							; a = Tile_Y || b = Tile_X

	ld 	 c, a 									; c contains TileX

	; Here we check if the x coordinate of the player is greater than the enemy's.
	; If the enemy and the player have the same x, the enemy will try to move vertically.

	ld 	 e, pl_tilex 							; Get the X coordinate of the player.
	call EM_GET_PLAYER_VARIABLE 				; Modifies HL and D.
	ld 	 b, a
	
	ld 	 a, c 									; C contains TileX of the enemy.
	sub  b 										; Compare with the X of the player.
	jp 	 z, .decide_m_vertical					; If it's the same, try to move on Y.
	jr 	 c, .decide_m_right  					; If player X was greater than enemy's, move right.

	;Move Left (if the tile is not a wall)

	ld 	 a, 2
	call de_check_tile 							; Check if next tile is a wall
	jr 	 nz, .decide_m_vertical 				; If the tile is not floor we won't move to it. Check Y movement.

	pop  hl 									; Get the memory address of the enemy.

	push hl
	ld 	 b, LEFT_JP
	call AI_CHECK_NEXT_ENEMY
	pop  hl

	push hl
	or 	 a
	jr 	 nz, .decide_m_vertical 				; If the tile has an enemy already, don't move to it.
	
	;If it was not a wall, check if the tile is already reserved. Here we have to decrease in two the tile X
	;already saved in the collision manager.

	call CM_GET_TILEX
	sub  2
	call CM_SET_TILEX

	call AI_CHECK_RESERVED_CELLS
	ld 	 b, a

	call CM_GET_TILEX
	add  2
	call CM_SET_TILEX

	ld 	 a, b
	or 	 a
	jp 	 z, .decide_m_vertical 					; If the method returned 0, it means that the cell is already reserved.

	call CM_GET_TILEX
	sub  2
	call CM_SET_TILEX

	;If the tile's not reserved do it, set the movement direction and return.

	call AI_RESERVE_CELL

	pop  hl

	ld 	 e, en_movementd
	ld 	 a, LEFT_JP								; Set the action for the enemy.
	jp 	 EM_SET_ENEMY_VARIABLE 					; This modifies HL.									

.decide_m_right:

	;Move Right (if the tile is not a wall)

	ld 	 a, 3
	call de_check_tile
	jr 	 nz, .decide_m_vertical

	pop  hl

	push hl
	ld 	 b, RIGHT_JP
	call AI_CHECK_NEXT_ENEMY
	pop  hl

	push hl
	or 	 a
	jr 	 nz, .decide_m_vertical 				; If the tile has an enemy already, don't move to it.

	;If it was not a wall, check if the tile is already reserved.

	call CM_GET_TILEX
	add  2
	call CM_SET_TILEX

	call AI_CHECK_RESERVED_CELLS
	ld 	 b, a

	call CM_GET_TILEX
	sub  2
	call CM_SET_TILEX

	ld 	 a, b

	or 	 a
	jp 	 z, .decide_m_vertical 					; If the method returned 0, it means that the cell is already reserved.

	call CM_GET_TILEX
	add  2
	call CM_SET_TILEX

	;If the tile's not reserved, set the movement direction and return.

	call AI_RESERVE_CELL

	pop  hl

	ld 	 e, en_movementd
	ld 	 a, RIGHT_JP							; Set the action for the enemy.
	jp 	 EM_SET_ENEMY_VARIABLE 					; This modifies HL.	

.decide_m_vertical:

	;We will get here if we could not move in X or the X of the player and the enemy are the same.
	;Here is the same, check we did before with the X. If the Y is equal to the player we won't make
	;any move.

	ld 	 e, pl_tiley 							; Get the Y coordinate of the player.
	call EM_GET_PLAYER_VARIABLE 				; Modifies HL and D.
	ld 	 b, a

	call CM_GET_TILEY
	sub  b
	jr 	 z, .decide_not_m
	jr 	 c, .decide_m_down

	;Move Up (if the tile is not a wall)

	xor  a
	call de_check_tile
	jr 	 nz, .decide_not_m

	;If it was not a wall, check if there's an enemy

	pop  hl
	push hl
	ld 	 b, UP_JP
	call AI_CHECK_NEXT_ENEMY
	pop  hl
	push hl
	or 	 a
	jr 	 nz, .decide_not_m						; If the tile has an enemy already, don't move to it.

	; If there's no enemy, check if the tile is already reserved

	call CM_GET_TILEY
	sub  2
	call CM_SET_TILEY

	call AI_CHECK_RESERVED_CELLS
	or 	 a
	jr 	 z, .decide_not_m 						; If the method returned 0, it means that the cell is already reserved.

	;If the tile's not reserved, set the movement direction and return.

	call AI_RESERVE_CELL

	pop  hl

	ld 	 e, en_movementd
	ld 	 a, UP_JP								; Set the action for the enemy.
	jp 	 EM_SET_ENEMY_VARIABLE 					; This modifies HL.	

.decide_m_down:

	;Move Down (if the tile is not a wall)
	
	ld 	 a, 1
	call de_check_tile
	jr 	 nz, .decide_not_m

	;If it was not a wall, check if the tile is already reserved.

	pop  hl

	push hl
	ld 	 b, DOWN_JP
	call AI_CHECK_NEXT_ENEMY
	pop  hl
	push hl
	or 	 a
	jr 	 nz, .decide_not_m 						; If the tile has an enemy already, don't move to it.

	; If there's no enemy, check if the tile is already reserved

	call CM_GET_TILEY
	add  2
	call CM_SET_TILEY

	call AI_CHECK_RESERVED_CELLS
	or 	 a
	jr 	 z, .decide_not_m 						; If the method returned 0, it means that the cell is already reserved.

	;If the tile's not reserved, set the movement direction and return.

	call AI_RESERVE_CELL

	pop  hl

	ld 	 e, en_movementd
	ld 	 a, DOWN_JP								; Set the action for the enemy.
	jp 	 EM_SET_ENEMY_VARIABLE 					; This modifies HL.	

.decide_not_m:

	;If there is no possibility of movement we will get here.

	pop  hl 									; Get the memory address of the enemy.

	ld 	 e, en_action
	call EM_GET_ENEMY_VARIABLE
	and  SWAP_ACTION
	ld 	 [hl], a
	ret

de_check_tile:

	call CM_CHECK_NEXT_TILE_EN
	cp 	 FLOOR_TILE
	ret

;==============================================================
; Function: Check Next Enemy
; Description: Checks if there's another enemy in the direction
; of movement chosen.
; Modified registers: 
; Input: b (movement direction)
;==============================================================

AI_CHECK_NEXT_ENEMY:

	; We don't really need the hl direction as we have already setted in the Collision Manager the
	; tiles of this specific enemy. We just have to check those tiles (+1/-1) with all of the other enemies,
	; depending of the movement direction.

	call EM_GET_ENEMIES_ARRAY  					; a = num_enemies || hl = enemie_array* || de = dma_enemies*				

	ld 	 [_EN_TO_CHECK], a

	ld	 a, b
	and  LEFT_JP
	jr 	 nz, .ai_check_next_en_loop_left

	ld 	 a, b
	and  RIGHT_JP
	jr 	 nz, .ai_check_next_en_loop_right

	ld 	 a, b
	and  DOWN_JP
	jr 	 nz, .ai_check_next_en_loop_down

	jr   .ai_check_next_en_loop_up

.ai_check_next_en_loop_left:

	; If the movement is towards left we have to check the enemy tile X - 1 with the enemies tiles X.
	; If they are exactly the same, we deny the movement.

	push hl 
	call CM_CHECK_ENEMY_LEFT
	pop  hl

	or 	 a 										; 1 = enemy found -> break loop and cancel movement.
	jp   nz, CM_CHECK_SAME_EN_Y 				; The value returned equals 1 (enemy found) --> check if they have the same Y

	; Check if there are enemies left

	ld 	 a, [_EN_TO_CHECK]
	dec  a
	ret  z 										; If there are not, just return. The value returned equals 0 (no enemy found)
	ld 	 [_EN_TO_CHECK], a 						; Update the value of enemies left.

	ld 	 de, enemy_size
	add  hl, de
	jr 	 .ai_check_next_en_loop_left

.ai_check_next_en_loop_right:

	; If the movement is towards right we have to check the enemy tile X + 1 with the enemies tiles X.
	; If they are exactly the same, we deny the movement.

	push hl 
	call CM_CHECK_ENEMY_RIGHT
	pop  hl

	or 	 a 										; 1 = enemy found -> break loop and cancel movement.
	jp   nz, CM_CHECK_SAME_EN_Y 				; The value returned equals 1 (enemy found) --> check if they have the same Y

	; Check if there are enemies left

	ld 	 a, [_EN_TO_CHECK]
	dec  a
	ret  z 										; If there are not, just return. The value returned equals 0 (no enemy found)
	ld 	 [_EN_TO_CHECK], a 						; Update the value of enemies left.

	ld 	 de, enemy_size
	add  hl, de
	jr 	 .ai_check_next_en_loop_right

.ai_check_next_en_loop_up:

	; If the movement is towards up we have to check the enemy tile Y - 1 with the enemies tiles X.
	; If they are exactly the same, we deny the movement.

	push hl 
	call CM_CHECK_ENEMY_UP
	pop  hl

	or 	 a 										; 1 = enemy found -> break loop and cancel movement.
	jp   nz, CM_CHECK_SAME_EN_X 				; The value returned equals 1 (enemy found) --> check if they have the same X

	; Check if there are enemies left

	ld 	 a, [_EN_TO_CHECK]
	dec  a
	ret  z 										; If there are not, just return. The value returned equals 0 (no enemy found)
	ld 	 [_EN_TO_CHECK], a 						; Update the value of enemies left.

	ld 	 de, enemy_size
	add  hl, de
	jr 	 .ai_check_next_en_loop_up

.ai_check_next_en_loop_down:

	; If the movement is towards down we have to check the enemy tile Y + 1 with the enemies tiles X.
	; If they are exactly the same, we deny the movement.

	push hl 
	call CM_CHECK_ENEMY_DOWN
	pop  hl

	or 	 a 										; 1 = enemy found -> break loop and cancel movement.
	jp   nz, CM_CHECK_SAME_EN_X					; The value returned equals 1 (enemy found) --> check if they have the same X

	; Check if there are enemies left

	ld 	 a, [_EN_TO_CHECK]
	dec  a
	ret  z 										; If there are not, just return. The value returned equals 0 (no enemy found)
	ld 	 [_EN_TO_CHECK], a 						; Update the value of enemies left.

	ld 	 de, enemy_size
	add  hl, de
	jr 	 .ai_check_next_en_loop_down

;==============================================================
; Function: Check Reserved Cells
; Description: 
; Modified registers: 
; Input: -
; Output: a
;==============================================================

AI_CHECK_RESERVED_CELLS:

	call EM_GET_ENEMIES_ARRAY 				 	; a = num_enemies || hl = enemie_array* || de = dma_enemies*		
	ld 	 c, a
	ld 	 hl, _RESERVED_CELLS

check_reserved_c_loop:

	; Check if tile Y is the same
	
	ld 	 b, [hl] 								; Reserved Tile Y
	call CM_CHECK_SAME_Y_WITH_PARAM 			; Parameters: b, Output: a (0 = not equal, 1 = equal)
	or 	 a
	jr 	 z, check_reserved_c_next_y   			; If they are not equal, keep iterating through the vector.

	inc  hl
	ld 	 b, [hl]
	call CM_CHECK_SAME_X_WITH_PARAM
	or 	 a
	jr 	 z, check_reserved_c_next

	; We will get here if both tiles are the same

	xor  a
	ret

check_reserved_c_next_y:
	
	inc  hl

check_reserved_c_next:

	inc  hl

	dec  c
	jr 	 nz, check_reserved_c_loop

	; We will get here if the tile is not reserved

	ld 	 a, 1
	ret

;==============================================================
; Function: Reserve Cell
; Description: 
; Modified registers: 
; Input: -
;==============================================================

AI_RESERVE_CELL:

	; Loop and get the position of this actual enemy in the reserved_cells vector.
	; This is done by iterating with the value of _TOTAL_EN

	ld 	 hl, _RESERVED_CELLS
	ld 	  a, [_TOTAL_EN]
	ld 	 de, 2
 	
ai_reserve_cell_loop:

 	dec  a
 	jr 	 z, ai_reserve_cell_do

 	add  hl, de
 	jr 	 ai_reserve_cell_loop

ai_reserve_cell_do:
	; Get the saved tiles from the collision manager

	call CM_GET_TILEY 							; Returns the value in register a
	ld 	 [hl], a
	inc  hl
	call CM_GET_TILEX 							; Returns the value in register a
	ld 	 [hl], a
	ret

;==============================================================
; Function: See Player
; Description: Returns if the enemy can see the player
; Modified registers: 
; Input: -
;==============================================================

AI_SEE_PLAYER:

	; Check if we can see the player on X axis.

	push hl
	ld 	 e, pl_tilex
	call EM_GET_PLAYER_VARIABLE 				; Modified registers: hl, de || Output: a
	pop  hl

	ld 	 b, a

	push hl
	ld 	 e, en_tilex
	call EM_GET_ENEMY_VARIABLE 					; Modified registers: hl, a, d
	pop  hl

	ld 	 d, a
	sub  b
	jr 	 c, ai_see_player_swap_x 	 				; If there's carry, it means the X of the player is greater

	; If it is not greater, check if the result is less or equal than SIGHT_RADIUS
	sub  SIGHT_RADIUS
	jr 	 c, ai_see_player_y
	jr 	 z, ai_see_player_y

	jr 	 ai_see_player_unsuccess

ai_see_player_y:

	; Check if we can see the player on Y axis

	push hl
	ld 	 e, pl_tiley
	call EM_GET_PLAYER_VARIABLE 				; Modified registers: hl, de || Output: a
	pop  hl

	ld 	 b, a

	push hl
	ld 	 e, en_tiley
	call EM_GET_ENEMY_VARIABLE 					; Modified registers: hl, a, d
	pop  hl

	ld 	 d, a
	sub  b
	jr 	 c, ai_see_player_swap_y 				; If there's carry, it means the Y of the player is greater

	; If it is not greater, check if the result is less or equal than SIGHT_RADIUS
	sub  SIGHT_RADIUS
	jr 	 c, ai_see_player_success
	jr 	 z, ai_see_player_success

	; The enemy cannot see the player

	jr 	 ai_see_player_unsuccess

ai_see_player_swap_x:
	
	ld 	 a, b
	sub  d
	sub  SIGHT_RADIUS
	jr 	 c, ai_see_player_y
	jr 	 z, ai_see_player_y
	jr 	 ai_see_player_unsuccess

ai_see_player_swap_y:

	ld 	 a, b
	sub  d
	sub  SIGHT_RADIUS
	jr 	 c, ai_see_player_success
	jr 	 z, ai_see_player_success

ai_see_player_unsuccess:

	xor  a
	ret

ai_see_player_success:

	ld 	 a, 1
	ret