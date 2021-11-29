;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

	INCLUDE "hardware.inc"
	INCLUDE "constants.inc"
	INCLUDE "animation_manager_h.inc"
	INCLUDE "entity_manager_h.inc"

;============================================================
; User data
;============================================================

SECTION "Animations_Data",WRAM0

_SPR_TIMER: 	DS 1 			;timer to know when to change an sprite
_EN_TIMER: 		DS 1
_SPR_CHANGE: 	DS 1 			;boolean to know if we have to change the sprites

SECTION "Animations", ROM0

;==============================================================
; Function:	
; Description:
; Modified registers:
; Input: -
;==============================================================

AM_INIT:
	ld 	 a, 1
	ld 	 [_SPR_TIMER], a
	ld 	 [_EN_TIMER], a
	xor  a
	ld 	 [_SPR_CHANGE], a
	ret

;==============================================================
; Function: Reset Player Sprites
; Description: Resets the player sprite to the standing one
; when the user stops moving
; Modified registers: ab, e, hl
; Input: -
;==============================================================

AM_RESET_PLAYER_SPRITES:

	ld 	 e, pl_movementd
	call EM_GET_PLAYER_VARIABLE
	cp 	 DOWN_JP

	jr   nz, .not_frontal 					

	ld   a, ANIM_D_DEFAULT
	jp 	 EM_CHANGE_PL_SPRITES   			;it moved down

.not_frontal:

	cp 	 UP_JP
	jr   nz, .not_back

	ld   a, ANIM_U_DEFAULT
	jp 	 EM_CHANGE_PL_SPRITES   			;it moved up

.not_back:

	ld   a, ANIM_LR_DEFAULT
	jp 	 EM_CHANGE_PL_SPRITES   			;left or right (both has the same index)

;==============================================================
; Function: Animation Up/Down
; Description: Updates the sprite animation from the player
; when he's walking to the top or bottom
; Modified registers: a, b
; Input: b
;==============================================================

AM_ANIMATION_UD:

	ld   a, [_SPR_TIMER] 				;update the animation timer
	dec  a
	ld   [_SPR_TIMER], a 				;if it is not 0, return
	ret  nz

	ld   a, ANIM_TIME
	ld   [_SPR_TIMER], a 				;if it is 0, restart the timer and update the animation

	ld 	 e, pl_sp0n 					;variable we want to check
	call EM_GET_PL_DMA_VAR 				;get the value from the entity manager
	sub  b 								;check if the value is the one passed by input (the default value of the animation)
	jr   nz, .is_not_ud1 				;if it is not the default value, change the sprites
	
	ld   a, [_SPR_CHANGE] 				;if it is the default value, check if we have to change it
	or   a
	jr   nz, .dont_reset_ud

	ld   a, 1
	ld   [_SPR_CHANGE], a 

	ld   a, 4 							;add 4 to the default value of the sprite
	add  b
	jp 	 EM_CHANGE_PL_SPRITES

.dont_reset_ud:
	
	xor  a
	ld   [_SPR_CHANGE], a

	ld   a, 8
	add  b
	jp 	 EM_CHANGE_PL_SPRITES 			;add 8 to the default value of the sprite

.is_not_ud1:

	ld   a, b
	jp 	 EM_CHANGE_PL_SPRITES 			;restart the sprites for the default ones

;==============================================================
; Function: Animation Left/Right
; Description: Updates the sprite animation from the player
; when he's walking to the right or left
; Modified registers: a, b
; Input: -
;==============================================================

AM_ANIMATION_LR:

	ld   a, [_SPR_TIMER]
	dec  a
	ld   [_SPR_TIMER], a
	ret  nz
	
	ld   a, ANIM_TIME
	ld   [_SPR_TIMER], a

	ld 	 e, pl_sp0n 					;variable we want to check
	call EM_GET_PL_DMA_VAR 				;get the value from the entity manager
	sub  ANIM_LR_DEFAULT
	jr   nz, .is_not_lr1

	ld   a, 4
	add  ANIM_LR_DEFAULT
	jp 	 EM_CHANGE_PL_SPRITES

.is_not_lr1:
	
	ld   a, ANIM_LR_DEFAULT
	jp 	 EM_CHANGE_PL_SPRITES

;==============================================================
; Function: Animation Left/Right
; Description: Updates the sprite animation from the enemy
; when he's walking to the right or left
; Modified registers: a, b
; Input: -
;==============================================================

AM_EN_ANIMATION_UD:

	;For the up and down movement animations we just flip and swap the x
	;of the sprites. The swap is made with a boolean (3rd low bit of the _en_action memory address).

	ld 	 a, [_EN_TIMER]
	dec  a
	ret  nz
	
	;push hl
	;call EM_SWAP_EN_X 						; Deprecated function
	;pop  hl

	push hl
	ld 	 e, en_action
	call EM_GET_ENEMY_VARIABLE 				; Returns the action in register a
	xor  SWAP_ACTION
	ld 	 [hl], a 							; Set the new action.
	pop  hl 								; Restore the address.

	push hl
	ld 	 b, XOR_RIGHT
	call EM_CHANGE_EN_ATTRIBUTES
	pop  hl

	ret

AM_EN_ANIMATION_LR:

	;For the left and right movement animations we've got two pair of 4 sprites (8 in total) which
	;we will be swapping with the timer. The right movement has de difference of swapping and flipping
	;the sprites like we do with the other two movement animations. It is coded in the 'move_down' etiquette.

	ld 	 a, [_EN_TIMER]
	dec  a
	ret  nz

	; The HL address we are given is from the ROM array, not the DMA one.

	push hl

	ld 	 e, en_dma_l
	call EM_GET_ENEMY_VARIABLE 				; a = low byte address
	ld 	 c, a 								; save it in register a
	inc  hl
	ld 	 a, [hl]
	ld 	 h, a 								; a = high byte address
	ld 	 l, c 								; b =  low byte address

	; Now we have the DMA address, so we can look up any variable of this array.

	ld 	 e, 2
	add  hl, de
	ld 	 a, [hl]
	ld 	 b, a 							; b = actual sprite

	pop  hl
	push hl
	ld 	 e, en_defsprite
	call EM_GET_ENEMY_VARIABLE
	add  EN_ANIM_LR_DEF 				; a = default left/right sprite
	pop  hl

	sub  b 								; if a == b, then we put the second sprite for the movemet.
	jr 	 z, am_en_animation_lr_2

	ld 	 a, EN_ANIM_LR_DEF
	jp 	 EM_CHANGE_EN_SPRITES

am_en_animation_lr_2:

	ld 	 a, EN_ANIM_LR_2
	jp 	 EM_CHANGE_EN_SPRITES

;==============================================================
; Function: Decrement Enemies Timer
; Description: Updates the sprite animation from the player
; when he's walking to the right or left
; Modified registers: a
; Input: -
;==============================================================

AM_DECREMENT_EN_TIMER:

	ld 	 a, [_EN_TIMER]
	dec  a
	ld 	 [_EN_TIMER], a
	ret  nz

	ld 	 a, ANIM_TIME
	ld 	 [_EN_TIMER], a

	ret

;==============================================================
; Function: Enemy Sprite Up 
; Description: Sets the chosen enemy sprite to default UP
; Modified registers: de, bc, a
; Input: hl
;==============================================================

AM_ENEMY_SPRITE_UP:

	; Reset enemy sprites

	push hl
	ld 	 a, EN_ANIM_U_DEF
	call EM_CHANGE_EN_SPRITES
	pop  hl

	; Change Sprites Attributes

	jr 	 am_and_attribute

AM_ENEMY_SPRITE_DOWN:

	; Reset enemy sprites

	push hl
	ld 	 a, EN_ANIM_D_DEF 					; Change the sprites
	call EM_CHANGE_EN_SPRITES
	pop  hl

	; Change Sprites Attributes

	jr 	 am_and_attribute

AM_ENEMY_SPRITE_LEFT:

	; Reset enemy sprites

	push hl
	ld 	 a, EN_ANIM_LR_DEF
	call EM_CHANGE_EN_SPRITES
	pop  hl

am_and_attribute:

	; Change Sprites Attributes

	ld 	 b, AND_LEFT
	jr 	 am_change_attributes

AM_ENEMY_SPRITE_RIGHT:
	
	; Reset enemy sprites

	push hl
	ld 	 a, EN_ANIM_LR_DEF
	call EM_CHANGE_EN_SPRITES
	pop  hl

	; Set action SWAP = true

	push hl
	ld 	 e, en_action
	call EM_GET_ENEMY_VARIABLE 				; Returns the action in register a
	or 	 SWAP_ACTION
	ld 	 [hl], a 							; Set the new action.
	pop  hl 								; Restore the address.

	; Change Sprites Attributes

	ld 	 b, OR_RIGHT

am_change_attributes:

	; Change Sprites Attributes

	push hl
	call EM_CHANGE_EN_ATTRIBUTES
	pop  hl
	ret
