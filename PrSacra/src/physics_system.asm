;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

	INCLUDE "physics_system_h.inc"
	INCLUDE "hardware.inc"
	INCLUDE "entity_manager_h.inc"
	INCLUDE "animation_manager_h.inc"
	INCLUDE "constants.inc"
	INCLUDE "collision_manager_h.inc"
	INCLUDE "ai_system_h.inc"
	INCLUDE "audio_system_h.inc"

;==============================================================
; RAM Data
;==============================================================

SECTION "PS_DATA", WRAM0

_NPIXM: 		DS 1 			; number of pixels moved
_SCROLL: 		DS 1 			; bool to know if the scroll is locked
_UPDT_ABS: 		DS 1 			; bool to know if we have to update absolutes.
_ATTACK_END: 	DS 1 			; bool to know if enemies can start the attack

SECTION "Physics_System", ROM0

;==============================================================
; Function: Init Physics System
; Description: Initializes the physics system
; Modified registers: a
; Input: -
;==============================================================

PS_INIT:
	xor  a
	ld 	 [_ATTACK_END], a
	ld 	 [_NPIXM], a
	ld 	 [_SCROLL], a
	inc  a
	ld 	 [_UPDT_ABS], a
	ret

;==============================================================
; Function: Update Physics System
; Description: Update the physics system
; Modified registers: all
; Input: -
;==============================================================

PS_UPDATE:

 	call PS_UPDATE_PLAYER
	call PS_UPDATE_ENEMIES
	jp   PS_UPDATE_ITEMS

;==============================================================
; Function: Update Enemies Physics
; Description: Update the enemies physics
; Modified registers:
; Input: -
;==============================================================

PS_UPDATE_ENEMIES:
	
	;Get the number of enemies created

	call EM_GET_ENEMIES_ARRAY 				; a = num_enemies || hl = enemie_array* || de = dma_enemies*
	or 	 a
	ret  z 									; if there are no enemies don't update anything

	ld 	 [_TOTAL_EN], a

.ps_update_en_loop:

	push hl

	ld 	 b, h
	ld 	 c, l

	ld 	 e, pl_action
	call EM_GET_PLAYER_VARIABLE 			; This modifies HL

	ld 	 e, a 								; Save the get value on e so we don't lose it.
	and  WAIT_ACTION
	jr 	 nz, .ps_update_move
	ld 	 a, e
	and  ATTACK_ACTION
	jr 	 nz, .ps_update_move
	ld 	 a, e
	and  MOVE_ACTION
	jr 	 z, .ps_update_absolutes

.ps_update_move:

	ld 	 h, b
	ld 	 l, c

	ld 	 e, en_action
	call EM_GET_ENEMY_VARIABLE 			; this method modifies hl
	ld 	 d, a
	and  MOVE_ACTION
	jr   z, .ps_update_attack

	; Start Movement

	ld 	 h, b
	ld 	 l, c
	call PS_MOVE_ENEMY
	jr 	 .ps_update_absolutes

.ps_update_attack:

	ld 	 a, d
	and  ATTACK_ACTION
	jr 	 z, .ps_update_absolutes

	; Start/Keep Attack

	ld 	 h, b
	ld 	 l, c
	call PS_EN_ATTACK

.ps_update_absolutes:

	pop  hl

	call EM_GET_ENEMIES_NUMBER
	or 	 a
	ret  z

	push hl

	call EM_ENEMIES_ABSOLUTE_Y 				; this method modifies a, hl, bc

	pop  hl
	push hl

	call EM_ENEMIES_ABSOLUTE_X

.ps_check_all_enemies_updated:
	
	ld 	 a, [_TOTAL_EN] 					; check if there's still enemies to update
	dec  a
	jr 	 z, .update_done
	ld 	 [_TOTAL_EN], a 					; update the number of enemies left

	pop  hl
	ld 	 de, enemy_size
	add  hl, de

	jr 	 .ps_update_en_loop 				; get back to the loop

.update_done:

	call AM_DECREMENT_EN_TIMER
	pop  hl
	ret

;==============================================================
; Function: Set Update Absolutes
; Modified registers: -
; Input: a
;==============================================================

PS_SET_UPDATE_ABSOLUTES:

	ld 	[_UPDT_ABS], a
	ret

;==============================================================
; Function: Update Items Physics
; Description: Update the items physics
; Modified registers:
; Input: -
;==============================================================

PS_UPDATE_ITEMS:

	ld 	 a, [_UPDT_ABS]
	or 	 a
	ret  z

	;Get the number of enemies created

	call EM_GET_BLOCKS_ARRAY 				; a = num_blocks || hl = block_array* || de = dma_blocks*
	or 	 a
	ret  z 									; if there are no items don't update anything

	ld 	 [_TOTAL_EN], a

.ps_update_items_loop:

	push hl

	call EM_BLOCKS_ABSOLUTE_Y 				; this method modifies a, hl, bc

	pop  hl
	push hl

	call EM_BLOCKS_ABSOLUTE_X
	
	ld 	 a, [_TOTAL_EN] 					; check if there's still enemies to update
	dec  a
	jr 	 z, .ps_update_items_done
	ld 	 [_TOTAL_EN], a 					; update the number of enemies left

	pop  hl
	ld 	 de, block_size
	add  hl, de

	jr 	 .ps_update_items_loop 				; get back to the loop

.ps_update_items_done:

	pop  hl
	ret

;==============================================================
; Function: Update Player Physics
; Description: Update the player's physics
; Modified registers: hl, de, b, a
; Input: -
;==============================================================

PS_UPDATE_PLAYER:
	
	ld 	 e, pl_action
	call EM_GET_PLAYER_VARIABLE
	ld 	 b, a
	and  MOVE_ACTION 						; Check if the player is moving.
	jr 	 nz, .update_pl_mov 				; If not, we will check wether he's attacking.

	ld 	 a, b
	and  ATTACK_ACTION
	jr   z, .ps_update_player_wait

	jp   PS_PL_ATTACK

.ps_update_player_wait:

	ld 	 a, b
	and  WAIT_ACTION
	jr 	 z, .reset_action

	jp 	 PS_WAIT_ACTION

.reset_action: 								
 								
	ld	 b, 0 								; If we get here is because we are Standing or Swapping sprites.
	jp 	 EM_SET_PLAYER_VARIABLE 			; If the player's not moving or attacking reset the action.

.update_pl_mov:

	ld 	 a, [_NPIXM] 						; If the player is already moving don't check for collisions.
	or 	 a
	jp 	 nz, PS_MOVE_PLAYER

	call PS_CHECK_ENEMIES
	or   a
	jr   nz, .update_pl_stand

	call PS_CHECK_PL_COL 					; Check collisions. This returns on a the value of the next tile.
	call PS_CHECK_MOVABLE_TILE				; Here we check if that tile is a movable tile.
	dec  b
	jr   nz, .update_pl_move_true			; If it was not a wall, move the player.

	ld 	 hl, OBSTACLE_SOUND
	call AS_PLAY_NOTE_CHANNEL_2

.update_pl_stand:

	jr	 PS_PLAYER_STAND 					; Otherwise, just stand and do nothing.

.update_pl_move_true:

	call EM_UPDATE_PL_TILES
	jp 	 PS_MOVE_PLAYER

;==============================================================
; Function: Check Player Collisions
; Description: Checks if the next tile is a not-movable-to tile
; Modified registers: hl, de, b, a
; Input: -
;==============================================================

PS_PLAYER_STAND:

	ld 	 e, pl_action  						;if we can't move to that direction put the action to STAND and reset the sprite
	ld 	 b, STAND_ACTION
	call EM_SET_PLAYER_VARIABLE
	jp 	 AM_RESET_PLAYER_SPRITES

;==============================================================
; Function: Check Player Collisions
; Description: Checks if the next tile is a not-movable-to tile
; Modified registers: hl, de, b, a
; Input: -
;==============================================================

PS_CHECK_PL_COL:

	ld 	 e, pl_tilex 						;let's put the tile values in the collision manager
	call EM_GET_PLAYER_VARIABLE
	ld 	 b, a
	ld 	 e, pl_tiley
	call EM_GET_PLAYER_VARIABLE
	
	call CM_SET_TILES 						;a (_TILE_Y), b (_TILE_X). Return value = a
	jp 	 CM_CHECK_NEXT_TILE 				;let's get the number id of the tile we are trying to move to. The number id is saved on a.
	

;==============================================================
; Function: Player Attack
; Description:
; Modified registers: a
; Input: -
;==============================================================

PS_PL_ATTACK:

	;Check if it's the first frame

	ld   a, [_NPIXM]
	or   a
	jp   nz, .pl_a_go

	;If it's the first frame we change the sprites

	ld 	 e, pl_movementd 					; Let's check in which direction we are moving and update it
	call EM_GET_PLAYER_VARIABLE
	ld 	 b, a
	and  DOWN_JP
	jr   z, .pl_a_up

	; Sprites for Attack Down

	ld   a, ANIM_A_DOWN
	call EM_CHANGE_PL_SPRITES
	jr 	 .pl_a_go

.pl_a_up:

	ld   a, b
	and  UP_JP
	jr   z, .pl_a_lr

	; Sprites for Attack Up

	ld   a, ANIM_A_UP
	call EM_CHANGE_PL_SPRITES
	jr 	 .pl_a_go

.pl_a_lr:

	; Sprites for Attack Right/Left

	ld   a, ANIM_A_LR
	call EM_CHANGE_PL_SPRITES

.pl_a_go:
	
	;[START OF THE ATTACK MOVEMENT]
	;If we are here we have to move the player sprite, first in the direction of the movement and then in the inverse one.

	ld 	 e, pl_movementd 					
	call EM_GET_PLAYER_VARIABLE
	ld 	 b, a
	and  DOWN_JP
	jr   z, .pl_go_up

	;We are attacking towards down. We have to move 3 times to down and then 3 times to up.

	ld 	 b, 4
	call .pl_check_npixm
	jr 	 c, .pl_go_keep_down 				;If NPIXM equals less than 4, we will move towards down.

	ld 	 b, 8 								;If we already moved 8 times (4 and 4), reset the player.
	call .pl_check_npixm
	jr 	 z, .pl_attack_end

	call EM_DECREASE_PLAYER_Y
	jr 	 .pl_inc_npixm

.pl_go_keep_down:

	call EM_INCREASE_PLAYER_Y
	jr 	 .pl_inc_npixm

.pl_go_up:

	ld 	 a, b
	and  UP_JP
	jr 	 z, .pl_go_left

	ld 	 b, 4
	call .pl_check_npixm
	jr 	 c, .pl_go_keep_up 					;If NPIXM equals less than 4, we will move towards up.

	ld 	 b, 8 								;If we already moved 8 times (4 and 4), reset the player.
	call .pl_check_npixm
	jr 	 z, .pl_attack_end

	call EM_INCREASE_PLAYER_Y
	jr 	 .pl_inc_npixm

.pl_go_keep_up:

	call EM_DECREASE_PLAYER_Y
	jr 	 .pl_inc_npixm

.pl_go_left:

	ld 	 a, b
	and  LEFT_JP
	jr 	 z, .pl_go_right

	ld 	 b, 4
	call .pl_check_npixm
	jr 	 c, .pl_go_keep_left 				;If NPIXM equals less than 4, we will move towards left.

	ld 	 b, 8 								;If we already moved 8 times (4 and 4), reset the player.
	call .pl_check_npixm
	jr 	 z, .pl_attack_end

	call EM_INCREASE_PLAYER_X
	jr 	 .pl_inc_npixm

.pl_go_keep_left:

	call EM_DECREASE_PLAYER_X
	jr 	 .pl_inc_npixm

.pl_go_right:

	ld 	 b, 4
	call .pl_check_npixm
	jr 	 c, .pl_go_keep_right 				;If NPIXM equals less than 4, we will move towards up.

	ld 	 b, 8 								;If we already moved 8 times (4 and 4), reset the player.
	call .pl_check_npixm
	jr 	 z, .pl_attack_end

	call EM_DECREASE_PLAYER_X
	jr 	 .pl_inc_npixm

.pl_go_keep_right:

	call EM_INCREASE_PLAYER_X
	jr 	 .pl_inc_npixm

.pl_inc_npixm:

	ld 	 a, [_NPIXM]
	inc  a
	ld   [_NPIXM], a
	ret

.pl_check_npixm:
	
	ld 	 a, [_NPIXM]
	sub  b
	ret

.pl_attack_end:
	
	ld 	 a, 1
	ld 	 [_ATTACK_END], a

	call PS_CHECK_ENEMIES
	or   a
	call nz, PS_DO_DAMAGE

	call AM_RESET_PLAYER_SPRITES
	ld 	 e, pl_action
	ld 	 b, WAIT_ACTION
	call EM_SET_PLAYER_VARIABLE

	call EM_INCREASE_PLAYER_LIFE
	jp 	 EM_DECREASE_PLAYER_HUNGER

;==============================================================
; Function: Check Movable Tile
; Description:
; Modified registers: -
; Input: a
; Output: b. 1 = not movable, 0 = movable
;==============================================================

PS_CHECK_MOVABLE_TILE:

	ld b, 1
	ld c, 0

	cp DOOR1_TILE
	jp z, PS_START_TRANSITION

	inc c

	cp DOOR2_TILE
	jp z, PS_START_TRANSITION

	inc c

	cp CARPET_TILE
	jp z, PS_START_TRANSITION

	cp WOOD_TILE
	jr z, .movable_tile

	cp FLOOR_TILE
	jr z, .movable_tile

	inc c

	cp STAIRS1_TILE
	jp z, PS_START_TRANSITION

	cp STAIRS2_TILE
	jp z, PS_START_TRANSITION

	cp STAIRS3_TILE
	jp z, PS_START_TRANSITION

	ret

.movable_tile:

	ld b, 0
	ret

;==============================================================
; Function: Move Player
; Description: Checks the direction of the player and moves
; accordingly.
; Modified registers: all
; Input: -
;==============================================================

PS_MOVE_PLAYER:

	ld 	 e, pl_movementd 					; Let's check in which direction we are moving and update it
	call EM_GET_PLAYER_VARIABLE
	ld 	 b, a
	and  UP_JP
	jr 	 nz, PS_MOVE_PL_UP
	ld 	 a, b
	and  DOWN_JP
	jr 	 nz, PS_MOVE_PL_DOWN
	ld 	 a, b
	and  LEFT_JP
	jr 	 nz, PS_MOVE_PL_LEFT
	ld 	 a, b
	and  RIGHT_JP
	jr 	 nz, PS_MOVE_PL_RIGHT

	ret

;==============================================================
; Function: Move Player Up
; Description:
; Modified registers: all
; Input: -
;==============================================================

PS_MOVE_PL_UP:

	ld 	 a, [_SCROLL]
	dec  a
	jr 	 z, move_up_2

	ld 	 e, pl_sp0y
	call EM_GET_PL_DMA_VAR
	sub  72
	jr   nz, move_up_2

	ld   a, [rSCY]
	or   a
	jr   z, move_up_2

	dec  a
	ld   [rSCY], a
	ld 	 b, ANIM_U_DEFAULT
	call AM_ANIMATION_UD		 			;Update the animation
	jp 	 PS_UPDATE_NPIXM

move_up_2:

	call EM_DECREASE_PLAYER_Y
	ld 	 b, ANIM_U_DEFAULT
	call AM_ANIMATION_UD		 			;Update the animation
	jp 	 PS_UPDATE_NPIXM

;==============================================================
; Function: Move Player Down
; Description: 
; Modified registers:
; Input: -
;==============================================================

PS_MOVE_PL_DOWN:

	ld 	 a, [_SCROLL]
	dec  a
	jr 	 z, move_down_2

	ld 	 e, pl_sp0y
	call EM_GET_PL_DMA_VAR
	sub  72
	jr   nz, move_down_2

	ld   a, [rSCY]
	cp   MAX_SCROLLY
	jr   z, move_down_2

	inc  a
	ld   [rSCY], a
	ld 	 b, ANIM_D_DEFAULT
	call AM_ANIMATION_UD		 			;Update the animation
	jp 	 PS_UPDATE_NPIXM

move_down_2:

	call EM_INCREASE_PLAYER_Y
	ld 	 b, ANIM_D_DEFAULT
	call AM_ANIMATION_UD		 			;Update the animation
	jp 	 PS_UPDATE_NPIXM

;==============================================================
; Function: Move Player Left
; Description: 
; Modified registers:
; Input: -
;==============================================================

PS_MOVE_PL_LEFT:

	ld 	 a, [_SCROLL]
	dec  a
	jr 	 z, move_left_2
	
	ld 	 e, pl_sp0x 						;Get the X axis of the top-left sprite and check if he's not in the default value
	call EM_GET_PL_DMA_VAR
	sub  80
	jr   nz, move_left_2
	
	ld   a, [rSCX] 							;If the scroll X is already on 0 don't decrease it more
	or 	 a
	jr   z, move_left_2

	dec  a
	ld   [rSCX], a 							;If he's in the default value just decrease the x scroll
	call AM_ANIMATION_LR		 			;Update the animation

	jp 	 PS_UPDATE_NPIXM

move_left_2:

	call EM_DECREASE_PLAYER_X 				;If the player is not in the default value decrease his x coordinates
	call AM_ANIMATION_LR		 			;Update the animation
	jp 	 PS_UPDATE_NPIXM

;==============================================================
; Function: Move Player Right
; Description:  
; Modified registers:
; Input: -
;==============================================================

PS_MOVE_PL_RIGHT:

	ld 	 a, [_SCROLL]
	dec  a
	jr 	 z, move_right_2

	ld 	 e, pl_sp1x
	call EM_GET_PL_DMA_VAR
	sub  85
	jr   nz, move_right_2
	
	ld   a, [rSCX]
	cp 	 MAX_SCROLLX
	jr   z, move_right_2

	inc  a
	ld   [rSCX], a
	call AM_ANIMATION_LR		 			;Update the animation

	jp 	 PS_UPDATE_NPIXM

move_right_2:

	call EM_INCREASE_PLAYER_X
	call AM_ANIMATION_LR		 			;Update the animation
	jp 	 PS_UPDATE_NPIXM

;==============================================================
; Function: Update Number of Pixels Moved
; Description:  
; Modified registers:
; Input: -
;==============================================================

PS_UPDATE_NPIXM:
	
	ld 	 a, [_NPIXM]
	inc  a
	ld   [_NPIXM], a

	sub  16
	ret  nz

	call PS_UPDATE_ENEMIES

	xor  a
	ld 	 [_NPIXM], a

	ld 	 e, pl_action
	ld 	 b, 0
	call EM_SET_PLAYER_VARIABLE
	call EM_INCREASE_PLAYER_LIFE
	call EM_DECREASE_PLAYER_HUNGER

	call AM_RESET_PLAYER_SPRITES

	call EM_GRAB_ITEM

	jp 	 AI_INIT

;==============================================================
; Function: Check Enemies
; Description: Check if an enemy is in the direction of the
; attack.
; Modified registers:
; Input: -
;==============================================================

PS_CHECK_ENEMIES:

	call EM_GET_ENEMIES_ARRAY 				; a = num_enemies || hl = enemie_array* || de = dma_enemies*
	or 	 a
	ret  z 									; if there are no enemies don't update anything

	ld 	 [_TOTAL_EN], a 					; save the number of enemies for later on
	
	ld 	 e, pl_movementd 					; Check the direction of the attack.
	call EM_GET_PLAYER_VARIABLE
	ld 	 b, a
	and  DOWN_JP
	jr 	 z, .check_en_up

	;We are attacking towards down. We have to check the Y coordinates of the enemies.

	ld 	 e, pl_tiley
	call EM_GET_PLAYER_VARIABLE 			; Save onto b the tiley of the player to compare
	add  2
	ld 	 b, a 	

	jp 	 PS_CHECK_Y_AXIS

.check_en_up:

	ld 	 a, b
	and  UP_JP
	jr 	 z, .check_en_left

	;We are attacking towards up.

	ld 	 e, pl_tiley
	call EM_GET_PLAYER_VARIABLE				; Save onto b the sp0y of the player to compare
	sub  2 					
	ld 	 b, a 	

	jp 	 PS_CHECK_Y_AXIS

.check_en_left:

	ld 	 a, b
	and  LEFT_JP
	jr 	 z, .check_en_right

	;We are attacking towards left.

	ld 	 e, pl_tilex
	call EM_GET_PLAYER_VARIABLE 			; Save onto b the tilex of the player to compare
	sub  2				
	ld 	 b, a 	

	jp 	 PS_CHECK_X_AXIS

.check_en_right:

	;We are attacking towards right

	ld 	 e, pl_tilex
	call EM_GET_PLAYER_VARIABLE				; Save onto b the tilex of the player to compare
	add  2 								
	ld 	 b, a 	

	jp 	 PS_CHECK_X_AXIS

;==============================================================
; Function: Start Transition
; Description:  
; Modified registers:
; Input: c
;==============================================================

PS_START_TRANSITION:
	
	ld 	 hl, DOOR_SOUND
	call AS_PLAY_NOTE_CHANNEL_4

	dec  c
	jr 	 z, .start_t_house 					; c = 1

	dec  c
	jr   z, .start_t_overworld 				; c = 2

	dec  c
	jr 	 z, .start_t_nextlvl 				; c = 3
	
	ld 	 a, DUNGEON_STATE 					; c = 0
	jr 	 .set_t_state

.start_t_house:
	
	ld 	 a, HOUSE_STATE
	jr 	 .set_t_state

.start_t_overworld:

	ld 	 a, OVERWORLD_STATE
	jr 	 .set_t_state

.start_t_nextlvl:

	ld 	 a, TRANSIT_STATE

.set_t_state:

	call GM_SET_GAME_STATE
	jp 	 PS_MOVE_PLAYER

;==============================================================
; Function: Set Locked Scroll
; Input: a
;==============================================================

PS_SET_LOCK_SCROLL:
	ld [_SCROLL], a
	ret

;==============================================================
; Function: Check Y Axis
; Description:
; Input: b
;==============================================================

PS_CHECK_Y_AXIS:

	call EM_GET_ENEMIES_ARRAY 				; a = num_enemies || hl = enemie_array* || de = dma_enemies*				
	ld 	 e, en_tiley
	call EM_GET_ENEMY_VARIABLE

.check_y_axis_loop:

	ld 	 a, [hl] 							; hl = enemie_array(tile_y)
	sub  b
	jr 	 z, .check_y_loop_x 				; If the enemy is below or above us then check his X coordinate

	call EM_GET_NEXT_ENEMY
	or 	 a
	jp 	 z, check_en_failure

	jr 	 .check_y_axis_loop

.check_y_loop_x:
	
	dec  hl 								; Get the X Coordinate and then put back the address to Y
	ld 	 a, [hl]
	ld 	 c, a
	inc  hl 								; Get back to the initial value (y)

	push hl 								; Save on to the stack the direction.

	ld 	 e, pl_tilex
	call EM_GET_PLAYER_VARIABLE 			; Save onto a the tilex of the player to compare
	pop  hl 								; Get back de dma enemy address.
	sub  c
	jp 	 z, check_en_success				; If the coordinate X is the same, do damage.

	call EM_GET_NEXT_ENEMY
	or   a
	jr 	 z, check_en_failure

	jr 	 .check_y_axis_loop 				; Otherwise try another enemy

;==============================================================
; Function: Check X Axis
; Description:
; Input: b
;==============================================================

PS_CHECK_X_AXIS:

	call EM_GET_ENEMIES_ARRAY 				; a = num_enemies || hl = enemie_array* || de = dma_enemies*
	ld 	 e, en_tilex
	call EM_GET_ENEMY_VARIABLE			

.check_x_axis_loop:

	ld 	 a, [hl] 							; hl = dma_enemies(spr0x)
	sub  b
	jr 	 z, .check_x_loop_y 

	call EM_GET_NEXT_ENEMY
	or   a
	jr 	 z, check_en_failure

	jr 	 .check_x_axis_loop

.check_x_loop_y:
	
	inc  hl 								; Get the y Coordinate and then put back the address to x
	ld 	 a, [hl]
	ld 	 c, a
	dec  hl 								; Get back to the initial value (x)

	push hl 								; Save on to the stack the direction.

	ld 	 e, pl_tiley
	call EM_GET_PLAYER_VARIABLE 			; Save onto a the sp0x of the player to compare
	pop  hl 								; Get back de dma enemy address.
	sub  c
	jr 	 z, check_en_success 				; If the coordinate y is the same, do damage.

	call EM_GET_NEXT_ENEMY
	or 	 a
	jr 	 z, check_en_failure

	jr 	 .check_x_axis_loop 				; Otherwise try another enemy

check_en_success:

	ld   a, 1
	ret

check_en_failure:

	xor  a
	ret

;==============================================================
; Function: Do Damage
; Description:
; Input: -
;==============================================================

PS_DO_DAMAGE:

	; To do damage, we only have pretty much the _TOTAL_EN value. With that, we can get the actual enemy.

	call EM_GET_ENEMIES_ARRAY 				; a = num_enemies || hl = enemie_array* || de = dma_enemies*
	ld 	 c, a
	ld 	 d, 0
	ld 	 e, enemy_size 						; we are gonna add to enemy_size the amount of times _TOTAL_EN - 1 indicates

	ld 	 a, [_TOTAL_EN]
	ld 	 b, a
	ld 	 a, c
	sub  b							
	or 	 a 									; if the value was already 1, just go and try to do damage.
	jp 	 z, EM_DECREASE_EN_LIFE

.check_do_damage_loop:

	add  hl, de
	dec  a
	jp 	 z, EM_DECREASE_EN_LIFE 			; if we got to 0 go and try to do damage.
	jr 	.check_do_damage_loop

;==============================================================
; Function: Move Enemy
; Description:
; Input: hl (memory address of the enemy)
;==============================================================

PS_MOVE_ENEMY:

	ld 	 b, h 								; Save HL address.
	ld 	 c, l
	
	ld 	 e, en_movementd
	call EM_GET_ENEMY_VARIABLE				; Modifies HL returns value on A.

	ld 	 h, b
	ld 	 l, c 								; Get back enemy memory address.
	
	cp 	 UP_JP
	jr 	 nz, .ps_m_e_down

	; Check if the player moved to the tile we are trying to move aswell. If that's the case, cancel de movement.

	ld 	 a, [_NPIXM] 						; First pixel = 1
	dec  a 									; Actual pixel == First Pixel? Change Sprites.
	jr	 nz, .ps_move_en_up
	ret  c

	call AI_CHECK_TILES 					; Check if the player is close to us.

	ld 	 b, h
	ld 	 c, l

	or 	 a 									; If it's not 0, we have to stop the movement.
	jp 	 nz, ps_en_mov_deny

	; Change sprites attributes

	ld 	 e, en_tiley
	call EM_GET_ENEMY_VARIABLE 				; Modified registers: hl, a, d
	sub  2
	ld 	 [hl], a

	ld 	 h, b
	ld 	 l, c

	call AM_ENEMY_SPRITE_UP

	call ps_en_mov_reset_action

.ps_move_en_up:

	; If the enemy is moving up, we have to decrease his Y coordinates and decrease in 2 his tile_y.

	ld 	 e, en_abs_y
	call EM_GET_ENEMY_VARIABLE
	dec  a
	ld 	 [hl], a

	ld 	 h, b
	ld   l, c

	jp   AM_EN_ANIMATION_UD 				; Update the animation

.ps_m_e_down:

	cp 	 DOWN_JP
	jr 	 nz, .ps_m_e_left

	; Check if the player moved to the tile we are trying to move aswell. If that's the case, cancel de movement.

	ld 	 a, [_NPIXM]
	dec  a
	jr	 nz, .ps_move_en_down

	call AI_CHECK_TILES 					; Check if the player is close to us.

	ld 	 b, h
	ld 	 c, l

	or 	 a 									; If it's not 0, we have to stop the movement.
	jp 	 nz, ps_en_mov_deny
	ret  c

	ld 	 e, en_tiley 						; Update Tile Y
	call EM_GET_ENEMY_VARIABLE
	add  2
	ld 	 [hl], a

	ld 	 h, b
	ld 	 l, c

	call AM_ENEMY_SPRITE_DOWN

	call ps_en_mov_reset_action

.ps_move_en_down:

	; If the enemy is moving up, we have to increase his Y coordinates and increase in 2 his tile_y.

	ld 	 e, en_abs_y
	call EM_GET_ENEMY_VARIABLE
	inc  a
	ld 	 [hl], a

	ld 	 h, b
	ld   l, c

	jp   AM_EN_ANIMATION_UD 				; Update the animation
	
.ps_m_e_left:

	cp 	 LEFT_JP
	jr 	 nz, .ps_m_e_right

	; Check if the player moved to the tile we are trying to move aswell. If that's the case, cancel de movement.

	ld 	 a, [_NPIXM]
	dec  a
	jr	 nz, .ps_move_en_left

	call AI_CHECK_TILES 					; Check if the player is close to us.

	ld 	 b, h
	ld 	 c, l

	or 	 a 									; If it's not 0, we have to stop the movement.
	jp 	 nz, ps_en_mov_deny
 	ret  c

	ld 	 e, en_tilex
	call EM_GET_ENEMY_VARIABLE
	sub  2
	ld 	 [hl], a

	ld 	 h, b
	ld 	 l, c

	call AM_ENEMY_SPRITE_LEFT

	; Set action if SWAP == true then SWAP = false

	call ps_en_mov_reset_action

.ps_move_en_left:

	; If the enemy is moving left, we have to decrease his X coordinates and decrease in 2 his tile_x.

	ld 	 e, en_abs_x
	call EM_GET_ENEMY_VARIABLE
	dec  a
	ld 	 [hl], a

	ld 	 h, b
	ld   l, c

	jp   AM_EN_ANIMATION_LR 				; Update the animation

.ps_m_e_right:

	; Check if the player moved to the tile we are trying to move aswell. If that's the case, cancel de movement.

	ld 	 a, [_NPIXM]
	dec  a
	jr	 nz, .ps_move_en_right

	call AI_CHECK_TILES 					; Check if the player is close to us.

	ld 	 b, h
	ld 	 c, l

	or 	 a									; If it's not 0, we have to stop the movement.
	jp 	 nz, ps_en_mov_deny
	ret  c
	
	; Increase the tile only if is the first frame and change sprites

	ld 	 a, [_NPIXM]
	dec  a
	ret  nz

	ld 	 e, en_tilex
	call EM_GET_ENEMY_VARIABLE
	add  2
	ld 	[hl], a

	ld 	 h, b
	ld 	 l, c

	call AM_ENEMY_SPRITE_RIGHT

.ps_move_en_right:

	; If the enemy is moving right, we have to increase his X coordinates and increase in 2 his tile_x.

	ld 	 e, en_abs_x
	call EM_GET_ENEMY_VARIABLE
	inc  a
	ld 	 [hl], a

	ld 	 h, b
	ld   l, c

	jp   AM_EN_ANIMATION_LR 				; Update the animation

ps_en_mov_deny:

	ld 	 a, 1
	ld 	 [_ATTACK_END], a

	ld 	 e, en_action
	call EM_GET_ENEMY_VARIABLE
	and  SWAP_ACTION
	or 	 ATTACK_ACTION 						; Set the action to ATTACK_ACTION
	ld   [hl], a

	ret 									; Return so we deny the movement

ps_en_mov_reset_action:

	; Set action if SWAP == true then SWAP = false

	push hl
	ld 	 e, en_action
	call EM_GET_ENEMY_VARIABLE 				; Returns the action in register a
	ld 	 b, a
	and  SWAP_ACTION
	jp   z, .ps_done
	ld 	 a, b
	xor  SWAP_ACTION
	ld 	 [hl], a 							; Set the new action.

.ps_done: 

	pop  hl 								; Restore the address.
	ret

;==============================================================
; Function: Wait Action
; Description:
; Input: -
;==============================================================

PS_WAIT_ACTION:

	ld 	 a, [_NPIXM]
	inc  a
	ld 	 [_NPIXM], a
	sub  16
	ret  nz

	xor  a
	ld 	 [_NPIXM], a
	ld 	 [_ATTACK_END], a
	ld 	 e, pl_action  
	ld 	 b, 0
	call EM_SET_PLAYER_VARIABLE

	jp 	 AI_INIT

;==============================================================
; Function: Enemy Attack
; Description:
; Input: HL (enemy address)
;==============================================================

PS_EN_ATTACK:
	
	ld 	 a, [_ATTACK_END]
	or 	 a
	ret  z

	ld 	 b, h
	ld 	 c, l

	call AI_CHECK_TILES 					; Check if the player is close to us.

	ld 	 b, h
	ld 	 c, l

	or 	 a 									; If it's not 1, we have to stop the attack
	jp   z, ps_en_attack_reset

	ld 	 e, en_movementd 				; We have stored in which direction attack
	call EM_GET_ENEMY_VARIABLE 			; Modified registers: hl, a, d

	ld 	 h, b
	ld 	 l, c

	cp 	 UP_JP
	jr 	 nz, ps_en_attack_down

	; Attack Up

	; Check if it's first frame

	ld 	 a, [_NPIXM]
	sub  9
	ret  c
	jr 	 nz, ps_en_attack_up_go

	; Make Damage to Player
	call ps_en_attack_damage

	call EM_GET_ENEMIES_NUMBER
	or 	 a
	ret  z

	; Change sprites
	call AM_ENEMY_SPRITE_UP
	call ps_en_mov_reset_action

ps_en_attack_up_go:
	
	ld 	 a, [_NPIXM]
	sub  15
	jp 	 z, ps_en_attack_reset
	ld 	 a, [_NPIXM]
	sub  12
	jr 	 nc, ps_end_attack_up_go2

	; Move towards up

	push hl
	ld 	 e, en_abs_y
	call EM_GET_ENEMY_VARIABLE
	dec  a
	ld 	 [hl], a
	pop  hl

	ret

ps_end_attack_up_go2:

	; Move towards down
	
	push hl
	ld 	 e, en_abs_y
	call EM_GET_ENEMY_VARIABLE
	inc  a
	ld 	 [hl], a
	pop  hl

	ret
ps_en_attack_down:

	cp 	 DOWN_JP
	jr 	 nz, ps_en_attack_left

	; Attack Down.

	; Check if it's first frame

	ld 	 a, [_NPIXM]
	sub  9
	ret  c
	jr 	 nz, ps_en_attack_down_go

	; Make Damage to Player
	call ps_en_attack_damage

	call EM_GET_ENEMIES_NUMBER
	or 	 a
	ret  z

	; Change sprites
	call AM_ENEMY_SPRITE_DOWN
	call ps_en_mov_reset_action

ps_en_attack_down_go:
	
	ld 	 a, [_NPIXM]
	sub  15
	jp 	 z, ps_en_attack_reset
	ld 	 a, [_NPIXM]
	sub  12
	jr 	 nc, ps_end_attack_down_go2

	; Move towards down

	push hl
	ld 	 e, en_abs_y
	call EM_GET_ENEMY_VARIABLE
	inc  a
	ld 	 [hl], a
	pop  hl

	ret

ps_end_attack_down_go2:

	; Move towards up
	
	push hl
	ld 	 e, en_abs_y
	call EM_GET_ENEMY_VARIABLE
	dec  a
	ld 	 [hl], a
	pop  hl

	ret

ps_en_attack_left:

	cp 	 LEFT_JP
	jr 	 nz, ps_en_attack_right

	; Attack Left

	; Check if it's first frame

	ld 	 a, [_NPIXM]
	sub  9
	ret  c
	jr 	 nz, ps_en_attack_left_go

	; Make Damage to Player
	call ps_en_attack_damage

	call EM_GET_ENEMIES_NUMBER
	or 	 a
	ret  z

	; Change sprites
	call AM_ENEMY_SPRITE_LEFT
	call ps_en_mov_reset_action

ps_en_attack_left_go:
	
	ld 	 a, [_NPIXM]
	sub  15
	jp 	 z, ps_en_attack_reset
	ld 	 a, [_NPIXM]
	sub  12
	jr 	 nc, ps_end_attack_left_go2

	; Move towards left

	push hl
	ld 	 e, en_abs_x
	call EM_GET_ENEMY_VARIABLE
	dec  a
	ld 	 [hl], a
	pop  hl

	ret

ps_end_attack_left_go2:

	; Move towards right
	
	push hl
	ld 	 e, en_abs_x
	call EM_GET_ENEMY_VARIABLE
	inc  a
	ld 	 [hl], a
	pop  hl

	ret

ps_en_attack_right:

	; Attack Right

	; Check if it's first frame

	ld 	 a, [_NPIXM]
	sub  9
	ret  c
	jr 	 nz, ps_en_attack_right_go

	; Make Damage to Player
	call ps_en_attack_damage

	call EM_GET_ENEMIES_NUMBER
	or 	 a
	ret  z

	; Change sprites
	call AM_ENEMY_SPRITE_RIGHT

ps_en_attack_right_go:
	
	ld 	 a, [_NPIXM]
	sub  15
	jp 	 z, ps_en_attack_reset
	ld 	 a, [_NPIXM]
	sub  12
	jr 	 nc, ps_end_attack_right_go2

	; Move towards right

	push hl
	ld 	 e, en_abs_x
	call EM_GET_ENEMY_VARIABLE
	inc  a
	ld 	 [hl], a
	pop  hl

	ret

ps_end_attack_right_go2:

	; Move towards left
	
	push hl
	ld 	 e, en_abs_x
	call EM_GET_ENEMY_VARIABLE
	dec  a
	ld 	 [hl], a
	pop  hl

	ret

ps_en_attack_damage:

	push hl
	ld 	 e, en_damage
	call EM_GET_ENEMY_VARIABLE 					; a = enemy attack damage
	call EM_DECREASE_PLAYER_LIFE
	pop  hl
	ret

ps_en_attack_reset:

	ld 	 e, en_action
	call EM_GET_ENEMY_VARIABLE 				; Returns the action in register a
	xor  ATTACK_ACTION
	ld 	 [hl], a
	ret
	

