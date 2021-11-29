;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

	INCLUDE "entity_manager_h.inc"
	INCLUDE "render_system_h.inc"
	INCLUDE "hardware.inc"
	INCLUDE "constants.inc"
	INCLUDE "game_manager_h.inc"
	INCLUDE "audio_system_h.inc"

;==============================================================
; RAM Data
;==============================================================

SECTION "Entities_Data", WRAM0[$C000]

						; Each sprite needs 4 bytes, that means we can store 160/4 = 40 sprites simultaneously
dma_player: 	DS 16
dma_hud: 		DS 32 	; HUD entities
dma_enemies:    DS 64 	; Each enenemy consists of 4 sprites
dma_blocks:     DS 48   ; A 'block entity' could be an item, wich consists only of 1 sprite

num_enemies: 	DS 1
num_blocks:     DS 1

last_dmaen_ptr: DS 2
last_enem_ptr: 	DS 2
last_dmabl_ptr: DS 2
last_block_ptr: DS 2

player_vector:  DS player_size
enemie_array: 	DS enemy_size*MAX_ENTITIES
block_array: 	DS block_size*MAX_BLOCKS

_TOTAL_EN: 		DS 1 	; General purpose RAM Variable to keep the number of enemies left to update.

SECTION "Entities", ROM0

;==============================================================
; Function: Initialize Entity Manager
; Description: Initializes the address of the last entity ptr
; to the first position of the array and resets the number of
; entities to 0
; Modified registers: hl, a
; Input: -
;==============================================================

EM_INIT:

	; ENEMIES

	ld 	 hl, dma_enemies			; Reset the last dma element ptr to the first position of the dma entities
	ld 	 a, h
	ld 	 [last_dmaen_ptr+1], a
	ld 	 a, l
	ld 	 [last_dmaen_ptr], a

	ld 	 hl, enemie_array			; Reset the last element ptr to the first position of the array
	ld 	 a, h
	ld 	 [last_enem_ptr+1], a
	ld 	 a, l
	ld 	 [last_enem_ptr], a

	; BLOCKS

	ld 	 hl, dma_blocks
	ld 	 a, h
	ld 	 [last_dmabl_ptr+1], a
	ld 	 a, l
	ld 	 [last_dmabl_ptr], a

	ld 	 hl, block_array
	ld 	 a, h
	ld 	 [last_block_ptr+1], a
	ld 	 a, l
	ld 	 [last_block_ptr], a

	; COUNTERS

	xor  a 							; Put to 0 the number of entities
	ld 	 [num_enemies], a
	ld 	 [num_blocks], a
	ret

;==============================================================
; Function: Create Player
; Description: Reads the player initial values and inserts them
; into both arrays.
; Modified registers: hl, de, bc, a
;==============================================================

EM_CREATE_PLAYER:

	ld 	 hl, player_entity

	call EM_ADD_DMA_PLAYER 				; This method modifies HL
	
	ld 	 de, player_vector
	ld 	 bc, player_size 				; Get the size of the entity we are gonna create

	jp 	 RS_COPY_MEM 					; Copy all data

;==============================================================
; Function: Create Enemy
; Description: Creates an entity and adds it to the entities
; array. It also increments 'num_enemies'.
; Modified registers: all
; Input: hl
;==============================================================

EM_CREATE_ENEMY:

	call EM_ADD_DMA_ENEMY				; This method modifies HL
	
	ld 	 a, [last_enem_ptr+1]
	ld 	 d, a
	ld 	 a, [last_enem_ptr]
	ld 	 e, a

	inc  de
	inc  de

	ld 	 bc, enemy_nodma 				; The enemy size is 8 but we already have saved 2 of them (dma address is excluded)

	call RS_COPY_MEM 					; Copy all data

	ld 	 h, d
	ld 	 l, e
	inc  hl
	ld 	 a, [last_dmaen_ptr] 				; The last 2 bytes will have the memory address in little endian of the dma position.
	ld 	 [hl], a
	inc  hl
	ld 	 a, [last_dmaen_ptr+1]
	ld 	 [hl], a

	ld 	 a, [num_enemies] 				; Increase the number of entities
	inc  a
	ld 	 [num_enemies], a

	;Update last_enem_ptr

	call EM_GET_LAST_EN_PTR
	ld 	 bc, enemy_size

	add  hl, bc

	call EM_SET_LAST_EN_PTR

	;Update last_dmaen_ptr

	call EM_GET_LAST_DMA_EN_PTR
	ld 	 bc, entity_dma_size
	add  hl, bc
	jp   EM_SET_LAST_DMA_EN_PTR

;==============================================================
; Function: Delete All Enemies
; Description: Deletes all entities from the enemies array. 
; Modified registers: all
; Input: hl (enemy)
;==============================================================

EM_DELETE_ALL_ENEMIES:
	
	call EM_GET_ENEMIES_ARRAY
	or   a 								; enemy number
	ret  z 								; If there's still an enemy, delete it.
	call EM_DELETE_ENEMY
	jr 	 EM_DELETE_ALL_ENEMIES

;==============================================================
; Function: Deletes Enemy
; Description: Deletes an entity from the enemies array. 
; It also decrements 'num_enemies'.
; Modified registers: all
; Input: hl (enemy)
;==============================================================

EM_DELETE_ENEMY:

	; Input hl is the direction of the enemy we are gonna delete
	; We are gonna copy there the data of the last_enem_ptr
	; But first, we will delete the dma data from the pointer the entity contains.

	push hl 									;save the address so later we will just need to pop it to copy data in the enemy array

	ld 	 bc, enemy_noptr
	add  hl, bc 								;hl points to the first byte of the dma address
	ld 	 e, [hl]
	inc  hl
	ld 	 d, [hl]
	
	; Now de has the dma address of the entity we want to erase

	call EM_GET_LAST_DMA_EN_PTR
	ld 	 b, $FF
	ld 	 c, $F0 								;-15 = FFF0
	add  hl, bc 								;hl now has the last enemy created

	ld 	 bc, entity_dma_size 					;the size of each entity in dma

	call RS_COPY_MEM

	;Now we have to delete the data from the last_dmaen_ptr. We will copy a 0 to all positions.

	ld 	 b, $FF
	ld 	 c, $F1 								;-14 = FFF1
	add  hl, bc 								;hl now has the last enemy created

	xor  a 										;value to copy. BC will be the same
	ld 	 bc, entity_dma_size 					
	call RS_COPY_DATA

	;Now we just need to update the last dma ptr

	ld 	 b, $FF
	ld 	 c, $F0 								;-15 = FFF0
	add  hl, bc 								;hl now has the new last_dmaen_ptr address

	call EM_SET_LAST_DMA_EN_PTR 				;now the last_dmaen_ptr is updated.

	;Now we have to delete the data from the enemies array.
	;In this case, we don't need to put to 0 all the data since we won't use it at all anyway.

	pop  hl 									;we get here the initial address to erase

	ld 	 d, h 									;de will have the destiny address
	ld 	 e, l

	call EM_GET_LAST_EN_PTR
	ld 	 b, $FF
	ld 	 c, $F4 								;-11 = FFF4
	add  hl, bc

	ld 	 bc, enemy_noptr 						;b will have the amount of bytes to copy
	call RS_COPY_MEM 							;with this, the enemy should be completely erased from memory.

	;Now we just need to update the enemies array last_enem_ptr and decrease the number of enemies

	call EM_GET_LAST_EN_PTR
 	ld 	 b, $FF
	ld 	 c, $F4 								;-11 = FFF4

	add  hl, bc

	call EM_SET_LAST_EN_PTR

	ld 	 a, [num_enemies]
	dec  a
	ld 	 [num_enemies], a

	ret

;==============================================================
; Function: Create Block
; Description: Creates a block entity and adds it to 
; the block entities array. It also increments 'num_blocks'.
; Modified registers: all
; Input: hl
;==============================================================

EM_CREATE_BLOCK:

	call EM_ADD_DMA_BLOCK				; This method modifies HL
	
	ld 	 a, [last_block_ptr+1]
	ld 	 d, a
	ld 	 a, [last_block_ptr]
	ld 	 e, a

	inc  de
	inc  de
	inc  de

	ld 	 bc, block_nodma 				; The block size is 7 but we already have saved 3 of them (dma address is excluded)

	call RS_COPY_MEM 					; Copy all data

	ld 	 h, d
	ld 	 l, e
	inc  hl
	ld 	 a, [last_dmabl_ptr] 			; The last 2 bytes will have the memory address in little endian of the dma position.
	ld 	 [hl], a
	inc  hl
	ld 	 a, [last_dmabl_ptr+1]
	ld 	 [hl], a

	ld 	 a, [num_blocks] 				; Increase the number of entities
	inc  a
	ld 	 [num_blocks], a

	;Update last_enem_ptr

	call EM_GET_LAST_BL_PTR
	ld 	 bc, block_size
	add  hl, bc
	call EM_SET_LAST_BL_PTR

	;Update last_dmabl_ptr

	call EM_GET_LAST_DMA_BL_PTR
	ld 	 bc, block_dma_size
	add  hl, bc
	jp   EM_SET_LAST_DMA_BL_PTR

;==============================================================
; Function: Add DMA Block
; Description: 
; Modified registers: hl, de, b, a
; Input: hl
;==============================================================

EM_ADD_DMA_BLOCK:

	ld 	 c, [hl] 					;c = blockid_0 (absolute_y)
	push hl 						;Save on to the stack the memory address of the block to create

	call EM_GET_LAST_BL_PTR 		; hl = ROM address
	ld 	 [hl], c 					;Block_array_N_0 = blockid_0

	call EM_GET_LAST_DMA_BL_PTR 	; hl = DMA address

	ld 	 a, [rSCY]
	ld   b, a 						; b = Screen_Y
	ld   a, c 						; a = c = abs_y
	sub  b 							; a = a - b = abs_y - Screen_y
	ld 	 [hl], a 					;SPR0_Y = blockid_0 - [rSCY]

	inc  hl 						; hl = DMA address + 1
	ld 	 d, h 						; de = DMA address + 1
	ld 	 e, l

	pop  hl 						; hl = input address
	inc  hl
	ld   c, [hl] 					;a has the next value of the block
	push hl 						;save the memory address we are copying from

	call EM_GET_LAST_BL_PTR 		; hl = ROM address
	inc  hl
	ld 	 [hl], c 					;Block_array_N_1 = blockid_1

	ld 	 h, d
	ld 	 l, e
	ld 	 a, [rSCX]
	ld   b, a
	ld   a, c
	sub  b
	ld 	 [hl], a 					;SPR0_X = blockid_1 - [rSCX]

	inc  hl
	ld 	 d, h
	ld 	 e, l

	pop  hl
	inc  hl
	ld   c, [hl] 					;a has the next value of the block
	push hl 						;save the memory address we are copying from

	call EM_GET_LAST_BL_PTR
	inc  hl
	inc  hl
	ld 	 [hl], c 					;Block_array_N_1 = blockid_1

	ld 	 h, d
	ld 	 l, e
	ld 	 [hl], c

	inc  hl
	xor  a
	ld 	 [hl], a 					;SPR0_ATT = 0

	; DMA done, get back ROM address.

	pop  hl
	inc  hl

	ret

;==============================================================
; Function: Delete All Blocks
; Description: Deletes all entities from the enemies array. 
; Modified registers: all
; Input: hl (enemy)
;==============================================================

EM_DELETE_ALL_BLOCKS:
	
	call EM_GET_BLOCKS_ARRAY
	or   a 								; enemy number
	ret  z 								; If there's still a block, delete it.
	call EM_DELETE_BLOCK
	jr 	 EM_DELETE_ALL_BLOCKS

;==============================================================
; Function: Deletes Enemy
; Description: Deletes a block from the blocks array. 
; It also decrements 'num_blocks'.
; Modified registers: all
; Input: hl (block)
;==============================================================

EM_DELETE_BLOCK:

	; Input hl is the direction of the block we are gonna delete
	; We are gonna copy there the data of the last_bl_ptr
	; But first, we will delete the dma data from the pointer the entity contains.

	push hl 									;save the address so later we will just need to pop it to copy data in the enemy array

	ld 	 bc, block_dma_l
	add  hl, bc 								;hl points to the first byte of the dma address
	ld 	 e, [hl]
	inc  hl
	ld 	 d, [hl]
 	
 	; Now de has the dma address of the entity we want to erase

	call EM_GET_LAST_DMA_BL_PTR
	ld 	 b, $FF
	ld 	 c, $FC 								;-3 = FFFC
	add  hl, bc 								;hl now has the last enemy created

	ld 	 bc, block_dma_size 					;the size of each block in dma

	call RS_COPY_MEM

	;Now we have to delete the data from the last_dmabl_ptr. We will copy a 0 to all positions.

	ld 	 b, $FF
	ld 	 c, $FD 								;-2 = FFFD
	add  hl, bc 								;hl now has the last enemy created

	xor  a 										;value to copy. BC will be the same
	ld 	 bc, block_dma_size 					
	call RS_COPY_DATA

	;Now we just need to update the last dma ptr

	ld 	 b, $FF
	ld 	 c, $FC 								;-3 = FFFC
	add  hl, bc 								;hl now has the new last_dmaen_ptr address

	call EM_SET_LAST_DMA_BL_PTR 				;now the last_dmabl_ptr is updated.

	;Now we have to delete the data from the blocks array.
	;In this case, we don't need to put to 0 all the data since we won't use it at all anyway.

	pop  hl 									;we get here the initial address to erase

	ld 	 d, h 									;de will have the destiny address
	ld 	 e, l

	call EM_GET_LAST_BL_PTR
	ld 	 b, $FF
	ld 	 c, $F9 								;-6 = FFF9
	add  hl, bc

	ld 	 bc, block_noptr 						;b will have the amount of bytes to copy
	call RS_COPY_MEM 							;with this, the enemy should be completely erased from memory.

	;Now we just need to update the enemies array last_bl_ptr and decrease the number of blocks

	call EM_GET_LAST_BL_PTR
 	ld 	 b, $FF
	ld 	 c, $F9 								;-6 = FFF9

	add  hl, bc

	call EM_SET_LAST_BL_PTR

	ld 	 a, [num_blocks]
	dec  a
	ld 	 [num_blocks], a

	ret

;==============================================================
; Function: Get Enemies Array
; Description: Returns the number of entities we have in a
; certain moment of in-game and a ptr to the entities array.
; Modified registers: a, hl
; Input: -
; Output: a, hl, de
;==============================================================

EM_GET_ENEMIES_ARRAY:
	ld 	 a, [num_enemies]
	ld 	 hl, enemie_array
	ld   de, dma_enemies
	ret

;==============================================================
; Function: Get Enemies Number
; Description: Returns the number of entities we have in a
; certain moment of in-game
; Modified registers: a
; Input: -
; Output: a
;==============================================================

EM_GET_ENEMIES_NUMBER:
	ld 	 a, [num_enemies]
	ret

;==============================================================
; Function: Get Enemies DMA Variable
; Description: Returns the variable specified from the
; specified address.
; Modified registers: a, hl, d
; Input: a
; Input: e, hl
;==============================================================

EM_GET_ENEMIES_DMA_VAR:
	ld 	 d, 0
	add  hl, de
	ld 	 a, [hl]
	ret

;==============================================================
; Function: Get Blocks Array
; Description: Returns the number of blocks we have in a
; certain moment of in-game and a ptr to the blocks array.
; Modified registers: a, hl
; Input: -
; Output: a, hl, de
;==============================================================

EM_GET_BLOCKS_ARRAY:
	ld 	 a, [num_blocks]
	ld 	 hl, block_array
	ld   de, dma_blocks
	ret

;==============================================================
; Function: Get Last Enemies ptr
; Modified registers: hl, a
; Output: hl
;==============================================================

EM_GET_LAST_EN_PTR:
	ld 	 a, [last_enem_ptr+1] 					;hl will have the origin address
	ld 	 h, a
	ld 	 a, [last_enem_ptr]
	ld 	 l, a
	ret

;==============================================================
; Function: Set Last Enemies ptr
; Modified registers: a
; Input: hl
;==============================================================

EM_SET_LAST_EN_PTR:
	ld 	 a, h
	ld 	 [last_enem_ptr+1], a
	ld 	 a, l
	ld 	 [last_enem_ptr], a
	ret

;==============================================================
; Function: Get Last DMA ptr
; Modified registers: hl, a
; Output: hl
;==============================================================

EM_GET_LAST_DMA_EN_PTR:

	ld 	 a, [last_dmaen_ptr+1] 					;hl will now be the origin address to copy from
	ld 	 h, a
	ld 	 a, [last_dmaen_ptr]
	ld 	 l, a
	ret

;==============================================================
; Function: Set Last DMA Enemies ptr
; Modified registers: a
; Input: hl
;==============================================================

EM_SET_LAST_DMA_EN_PTR:

	ld 	 a, h
	ld 	 [last_dmaen_ptr+1], a
	ld 	 a, l
	ld 	 [last_dmaen_ptr], a
	ret

;==============================================================
; Function: Get Last Blocks ptr
; Modified registers: hl, a
; Output: hl
;==============================================================

EM_GET_LAST_BL_PTR:
	ld 	 a, [last_block_ptr+1] 					;hl will have the origin address
	ld 	 h, a
	ld 	 a, [last_block_ptr]
	ld 	 l, a
	ret

;==============================================================
; Function: Set Last Blocks ptr
; Modified registers: a
; Input: hl
;==============================================================

EM_SET_LAST_BL_PTR:
	ld 	 a, h
	ld 	 [last_block_ptr+1], a
	ld 	 a, l
	ld 	 [last_block_ptr], a
	ret

;==============================================================
; Function: Get Last DMA blocks ptr
; Modified registers: hl, a
; Output: hl
;==============================================================

EM_GET_LAST_DMA_BL_PTR:

	ld 	 a, [last_dmabl_ptr+1] 					;hl will now be the origin address to copy from
	ld 	 h, a
	ld 	 a, [last_dmabl_ptr]
	ld 	 l, a
	ret

;==============================================================
; Function: Set Last DMA blocks ptr
; Modified registers: a
; Input: hl
;==============================================================

EM_SET_LAST_DMA_BL_PTR:

	ld 	 a, h
	ld 	 [last_dmabl_ptr+1], a
	ld 	 a, l
	ld 	 [last_dmabl_ptr], a
	ret

;==============================================================
; Function: Add DMA Player
; Description: 
; Modified registers: hl, de, b, a
; Input: hl
;==============================================================

EM_ADD_DMA_PLAYER:

	ld   de, dma_player
	ld   b, 16 						; Player entity consist of 4 sprites --> 4 bytes * 4 sprites = 16

em_add_ent_loop:

	ld   a, [hl]
	ld   [de], a

	inc  hl
	inc  de

	dec  b
	jr   nz, em_add_ent_loop

	ret

;==============================================================
; Function: Add DMA Enemy
; Description: 
; Modified registers: hl, de, b, a
; Input: hl
;==============================================================

EM_ADD_DMA_ENEMY:
	
	ld 	 c, [hl] 					;c = enemyid_0
	push hl 						;Save on to the stack the memory address of the enemy to create

	call EM_GET_LAST_EN_PTR
	ld 	 [hl], c 					;Enemy_array_N_0 = enemyid_0

	call EM_GET_LAST_DMA_EN_PTR

	ld 	 a, [rSCY]
	ld   b, a
	ld   a, c
	sub  b
	ld 	 [hl], a 					;SPR0_Y = enemyid_0 - [rSCY]
	ld   e, 4
	ld   d, 0
	add  hl, de
	ld 	 [hl], a 					;SPR1_Y = enemyid_0 - [rSCY]

	ld   b, 8
	add  b

	ld   e, 4
	ld   d, 0
	add  hl, de
	ld   [hl], a 					;SPR2_Y = enemyid_0 + 8 - [rSCY]
	add  hl, de
	ld   [hl], a 					;SPR3_Y = enemyid_0 + 8 - [rSCY]

	ld   e, $F5
	ld   d, $FF 					;number is -10
	add  hl, de 					;now hl points to SPR0_X

	ld   d, h
	ld   e, l
	
	pop  hl
	inc  hl
	ld   c, [hl] 					;a has the next value of the enemy
	push hl 						;save the memory address we are copying from

	call EM_GET_LAST_EN_PTR
	inc  hl
	ld 	 [hl], c 					;Enemy_array_N_1 = enemyid_1

	ld 	 h, d
	ld 	 l, e
	ld 	 a, [rSCX]
	ld   b, a
	ld   a, c
	sub  b
	ld 	 [hl], a 					;SPR0_X = enemyid_1 - [rSCX]

	ld 	 e, 8
	ld 	 d, 0
	add  hl, de
	ld 	 [hl], a 					;SPR2_X = enemyid_1 - [rSCX]

	ld   e, $FC
	ld 	 d, $FF 					;number is -3
	add  hl, de
	ld   b, 8
	add  b
	ld 	 [hl], a 					;SPR1_X = enemyid_1 + 8 - [rSCX]

	ld 	 e, 8
	ld   d, 0
	add  hl, de
	ld 	 [hl], a 					;SPR3_X = enemyid_1 + 8 - [rSCX]

	ld   e, $F5
	ld   d, $FF 					;number is -10
	add  hl, de 					;now hl points to SPR0_NUM

	ld   d, h
	ld 	 e, l

	pop  hl
	inc  hl
	ld   a, [hl]
	push hl

	ld   h, d
	ld   l, e
	ld   [hl], a 					;SPR0_NUM = enemyid_2

	ld 	 d, 0
	ld 	 e, 8
	add  hl, de
	inc  a
	ld 	 [hl], a 					;SPR2_NUM = enemyid_2 + 1

	ld   e, $FC
	ld 	 d, $FF 					;number is -3
	add  hl, de

	inc  a
	ld 	 [hl], a 					;SPR1_NUM = enemyid_2 + 2

	ld   e, 8
	ld   d, 0
	add  hl, de
	inc  a
	ld   [hl], a 					;SPR3_NUM = enemyid_2 + 3

	;Get back into hl the values array from which we are creating an enemy

	pop  hl
	inc  hl

	ret

;==============================================================
; Function: Set Player Variable
; Modified registers: hl, de, b
; Output: -
; Input: b (value), e (variable to change)
;==============================================================

EM_SET_PLAYER_VARIABLE:

	ld 	 hl, player_vector
	ld 	 d, 0
	add  hl, de

	ld 	 [hl], b

	ret

;==============================================================
; Function: Set Player Action
; Description: Checks if the player is making any action and,
; if not, changes it for the input value.
; Modified registers: hl, de, b
; Output: -
; Input: b (value)
;==============================================================

EM_SET_PLAYER_ACTION:

	ld 	 hl, player_vector
	ld 	 d, 0
	ld   e, pl_action
	add  hl, de

	ld 	 a, [hl]
	and  a

	ret  nz
	
	ld   [hl], b

	ret

;==============================================================
; Function: Reset Player Hunger
; Description: Resets the player's hunger to the maximum.
; Modified registers: de, hl, a
; Output: -
;==============================================================

EM_RESET_PLAYER_HUNGER:
	
	ld 	 b, PL_MAX_HUNGER
	ld 	 e, pl_hunger
	call EM_SET_PLAYER_VARIABLE

	ld 	 e, pl_action
	ld 	 b, WAIT_ACTION
	jp 	 EM_SET_PLAYER_VARIABLE 		 	; Input: b (value), e (variable to change)

;==============================================================
; Function: Get Player Variable
; Modified registers: hl, de, a
; Output: a
; Input: e (variable to return)
;==============================================================

EM_GET_PLAYER_VARIABLE:
	
	ld 	 hl, player_vector
	ld 	 d, 0
	add  hl, de

	ld 	 a, [hl]

	ret

;==============================================================
; Function: Set Player DMA Variable
; Modified registers: hl, de, b, a
; Output: -
; Input: b (value), e (variable to change)
;==============================================================

EM_SET_PL_DMA_VAR:
	
	ld 	 hl, dma_player
	ld 	 d, 0
	add  hl, de

	ld 	 [hl], b

	ret

;==============================================================
; Function: Get Player DMA Variable
; Modified registers: hl, de, b, a
; Output: a, hl
; Input: e (variable to return)
;==============================================================

EM_GET_PL_DMA_VAR:
	
	ld 	 hl, dma_player
	ld 	 d, 0
	add  hl, de

	ld 	 a, [hl]

	ret

;==============================================================
; Function: Get Player Array
; Modified registers: hl, de
; Output: hl, de
;==============================================================

EM_GET_PL_ARRAY:
	
	ld 	 hl, player_vector
	ld 	 de, dma_player
	ret

;==============================================================
; Function: Set Enemy Variable
; Modified registers: hl, d
; Output: -
; Input: a (value), e (variable to change), hl (enemy address)
;==============================================================

EM_SET_ENEMY_VARIABLE:

	ld 	 d, 0
	add  hl, de

	ld 	 [hl], a

	ret

;==============================================================
; Function: Get Enemy Variable
; Modified registers: hl, a, d
; Output: a
; Input: e (variable to return), hl (enemy address)
;==============================================================

EM_GET_ENEMY_VARIABLE:
	
	ld 	 d, 0
	add  hl, de

	ld 	 a, [hl]

	ret

;==============================================================
; Function: Decrease Player Y
; Modified registers: hl, de, b, a
; Output: -
; Input: -
;==============================================================

EM_DECREASE_PLAYER_Y:
	
	ld 	 hl, dma_player
	ld 	 a, [hl]
	dec  a
	ld 	 [hl], a 			;SPR0_Y--
	ld 	 d, 0
	ld 	 e, 4
	add  hl, de
	ld 	 [hl], a 			;SPR1_Y = SPR0_Y
	add  hl, de
	ld 	 a, [hl]
	dec  a
	ld 	 [hl], a 			;SPR2_Y--
	add  hl, de
	ld 	 [hl], a 			;SPR3_Y = SPR2_Y

	ret

;==============================================================
; Function: Increase Player Y
; Modified registers: hl, de, b, a
; Output: -
; Input: -
;==============================================================

EM_INCREASE_PLAYER_Y:
	
	ld 	 hl, dma_player
	ld 	 a, [hl]
	inc  a
	ld 	 [hl], a 			;SPR0_Y++
	ld 	 d, 0
	ld 	 e, 4
	add  hl, de
	ld 	 [hl], a 			;SPR1_Y = SPR0_Y
	add  hl, de
	ld 	 a, [hl]
	inc  a
	ld 	 [hl], a 			;SPR2_Y++
	add  hl, de
	ld 	 [hl], a 			;SPR3_Y = SPR2_Y

	ret

;==============================================================
; Function: Decrease Player X
; Modified registers: hl, de, b, a
; Output: -
; Input: -
;==============================================================

EM_DECREASE_PLAYER_X:
	
	ld 	 hl, dma_player
	inc  hl
	ld 	 a, [hl]
	dec  a
	ld 	 [hl], a 			;SPR0_X--
	ld 	 d, 0
	ld 	 e, 4
	add  hl, de
	ld   a, [hl]
	dec  a
	ld 	 [hl], a 			;SPR1_X--
	add  hl, de
	ld 	 a, [hl]
	dec  a
	ld 	 [hl], a 			;SPR2_X--
	add  hl, de
	ld   a, [hl]
	dec  a
	ld 	 [hl], a 			;SPR3_X--

	ret

;==============================================================
; Function: Increase Player X
; Modified registers: hl, de, b, a
; Output: -
; Input: -
;==============================================================

EM_INCREASE_PLAYER_X:
	
	ld 	 hl, dma_player
	inc  hl
	ld 	 a, [hl]
	inc  a
	ld 	 [hl], a 			;SPR0_X++
	ld 	 d, 0
	ld 	 e, 4
	add  hl, de
	ld   a, [hl]
	inc  a
	ld 	 [hl], a 			;SPR1_X++
	add  hl, de
	ld 	 a, [hl]
	inc  a
	ld 	 [hl], a 			;SPR2_X++
	add  hl, de
	ld   a, [hl]
	inc  a
	ld 	 [hl], a 			;SPR3_X++

	ret

;==============================================================
; Function: Enemies Absolute Y
; Description: Updates the absolute position of the sprites
; so it doesn't do weird things with the window scrolling.
; Modified registers: a, bc, hl
; Output: -
; Input: hl
;==============================================================

EM_ENEMIES_ABSOLUTE_Y:

	ld   a, [rSCY]
	ld   b, a
	ld   a, [hl]
	sub  b

	ld 	 b, a

	; The HL address we are given is from the ROM array, not the DMA one.

	ld 	 e, en_dma_l
	call EM_GET_ENEMY_VARIABLE 				; a = low byte address
	ld 	 c, a 								; save it in register a
	inc  hl
	ld 	 a, [hl]
	ld 	 h, a 								; a = high byte address
	ld 	 l, c 								; b =  low byte address

	; Now we have the DMA address, so we can look up any variable of this array.

	ld 	 a, b

	ld   [hl], a 			;SPR0_Y
	ld   b, 0
	ld   c, 4
	add  hl, bc
	ld   [hl], a 			;SPR1_Y
	add  8
	ld 	 b, 0
	add  hl, bc
	ld   [hl], a  			;SPR2_Y
	add  hl, bc
	ld   [hl], a 			;SPR3_Y

	ret

;==============================================================
; Function: Enemies Absolute X
; Description: Updates the absolute position of the sprites
; so it doesn't do weird things with the window scrolling.
; Modified registers: a, bc, hl
; Output: -
; Input: hl
;==============================================================

EM_ENEMIES_ABSOLUTE_X:

	inc  hl
	ld   a, [rSCX]
	ld   b, a
	ld   a, [hl]
	sub  b

	ld 	 b, a

	dec  hl
	push hl

	; The HL address we are given is from the ROM array, not the DMA one.

	ld 	 e, en_dma_l
	call EM_GET_ENEMY_VARIABLE 				; a = low byte address
	ld 	 c, a 								; save it in register a
	inc  hl
	ld 	 a, [hl]
	ld 	 h, a 								; a = high byte address
	ld 	 l, c 								; b =  low byte address

	; Now we have the DMA address, so we can look up any variable of this array.
	
	ld 	 a, b

	ld 	 b, h 											; Save dma address on to bc
	ld 	 c, l

	pop  hl 											; Get the ROM address
	ld 	 d, 0 											; Get the action memory section
	ld 	 e, en_action
	add  hl, de
	ld 	 d, a 											; Restore the input value on to b
	ld 	 a, [hl] 										; Get the ROM value (action) on to a to be checked
	and  SWAP_ACTION 									; We check if the sprites are swapped.
	jr 	 z, .update_abs_x_normal 						; Depending on this, the update is different.

	ld 	 h, b
	ld 	 l, c

	ld 	 a, d
	add  8

	inc  hl
	ld   [hl], a 			;SPR0_X
	ld   b, 0
	ld   c, 8
	add  hl, bc
	ld   [hl], a 			;SPR2_X

	ld 	 b, $FF 	
	ld   c, $FC		
	add  hl, bc

	sub  8

	ld   [hl], a 			;SPR1_X
	ld   b, 0
	ld   c, 8
	add  hl, bc
	ld   [hl], a 			;SPR3_X

	ret

.update_abs_x_normal:

	ld 	 h, b
	ld 	 l, c

	ld 	 a, d

	inc  hl
	ld   [hl], a 			;SPR0_X
	ld   b, 0
	ld   c, 8
	add  hl, bc
	ld   [hl], a 			;SPR2_X
	ld 	 b, $FF 	
	ld   c, $FC		
	add  hl, bc
	add  8
	ld   [hl], a 			;SPR1_X
	ld   b, 0
	ld   c, 8
	add  hl, bc
	ld   [hl], a 			;SPR3_X

	ret

;==============================================================
; Function: Blocks Absolute
; Description: Updates the absolute position of the sprites
; so it doesn't do weird things with the window scrolling.
; Modified registers: a, bc, hl
; Output: -
; Input: hl
;==============================================================

EM_BLOCKS_ABSOLUTE_Y:
	
	ld   a, [rSCY]
	ld   b, a
	ld   a, [hl]
	sub  b
	ld 	 b, a

	call em_blocks_abs_aux

	; Now we have the DMA address, so we can look up any variable of this array.

	ld 	 a, b
	ld   [hl], a 			;SPR0_Y

	ret

EM_BLOCKS_ABSOLUTE_X:
	
	ld   a, [rSCX]
	ld   b, a
	inc  hl
	ld   a, [hl]
	sub  b
	ld 	 b, a
	dec  hl

	call em_blocks_abs_aux

	; Now we have the DMA address, so we can look up any variable of this array.

	inc  hl

	ld 	 a, b
	ld   [hl], a 			;SPR0_Y

	ret

em_blocks_abs_aux:

	; The HL address we are given is from the ROM array, not the DMA one.

	ld 	 e, block_dma_l
	call EM_GET_ENEMY_VARIABLE 				; a = low byte address
	ld 	 c, a 								; save it in register a
	inc  hl
	ld 	 a, [hl]
	ld 	 h, a 								; a = high byte address
	ld 	 l, c 								; b =  low byte address

	ret

;==============================================================
; Function: Change Player Sprites
; Description: Changes the sprites of the player according of
; the input received.
; Modified registers: ab, e, hl
; Input: a
;==============================================================

EM_CHANGE_PL_SPRITES:

	ld 	 b, a 				; Get method modifies the input
	
	ld 	 e, pl_sp0n
	call EM_GET_PL_DMA_VAR

	jr 	 EM_CHANGE_SPRITES_AUX

;==============================================================
; Function: Change Enemy Sprites
; Description: Changes the sprites of the enemy in a cascade
; method, increasing the value we receive as input.
; Modified registers: 
; Input: hl, a
;==============================================================

EM_CHANGE_EN_SPRITES:

	push hl

	ld 	 b, a
	ld 	 e, en_defsprite
	call EM_GET_ENEMY_VARIABLE 				; Modifies hl, a, de
	add  b
	ld 	 b, a

	pop  hl

	; The HL address we are given is from the ROM array, not the DMA one.

	ld 	 e, en_dma_l
	call EM_GET_ENEMY_VARIABLE 				; a = low byte address
	ld 	 c, a 								; save it in register a
	inc  hl
	ld 	 a, [hl]
	ld 	 h, a 								; a = high byte address
	ld 	 l, c 								; b =  low byte address

	; Now we have the DMA address, so we can look up any variable of this array.

	ld 	 e, pl_sp0n 						; Indexes are the same for player and enemies sprites
	call EM_GET_ENEMIES_DMA_VAR 			; This method doesn't modify BC registers. Modifies HL.

EM_CHANGE_SPRITES_AUX:

	ld 	 a, b 				; Restore the input received
	ld 	 e, 4
	
	ld   [hl], a 			; en_sp0n
	add  2
	add  hl, de
	ld   [hl], a 			; en_sp2n
	add  hl, de
	dec  a
	ld   [hl], a 			; en_sp1n
	add  2
	add  hl, de
	ld   [hl], a 			; en_sp3n

	ret

;==============================================================
; Function: Change Player Attributes
; Description: Changes the attributes of the player according 
; of the input received.
; Modified registers: a, hl, e
; Input: b
;==============================================================

EM_CHANGE_PL_ATTRIBUTES:

	ld 	 e, pl_action 						;Check if we already swapped the sprites
	call EM_GET_PLAYER_VARIABLE
	and  SWAP_ACTION
	ret  nz

	ld 	 e, pl_sp0a
	call EM_GET_PL_DMA_VAR 					;a = pl_sp0a

	dec  b
	jr   nz, .att_not_right

	or 	 RIGHT_ATTRIBUTE

	jr 	 .check_att_done

.att_not_right:

	and  LEFT_ATTRIBUTE

.check_att_done:

	ld 	 e, 4

	ld   [hl], a 							;pl_sp0a
	add  hl, de
	ld   [hl], a 							;pl_sp1a
	add  hl, de
	ld   [hl], a 							;pl_sp2a
	add  hl, de
	ld   [hl], a 							;pl_sp3a

	;Check if we have to swap the sprites on x

	ld 	 e, pl_action 						;Check if we already swapped the sprites
	call EM_GET_PLAYER_VARIABLE
	and  STAND_ACTION
	ret  nz

	ld 	 e, pl_lastmov
	call EM_GET_PLAYER_VARIABLE

	cp   RIGHT_JP
	jr 	 z, EM_SWAP_PL_X

	;If the last movement is not right, let's check if the next move is not going to be right aswell

	ld 	 e, pl_movementd
	call EM_GET_PLAYER_VARIABLE
	cp 	 RIGHT_JP
	jr 	 z, EM_SWAP_PL_X 					;if the next move is right but the last one is not, swap the sprites

	ret

;==============================================================
; Function: Change Enemies Attributes
; Description: Changes the attributes of the enemy according 
; of the input received.
; Modified registers: a, hl, e
; Input: b
;==============================================================

EM_CHANGE_EN_ATTRIBUTES:

	; The HL address we are given is from the ROM array, not the DMA one.

	ld 	 e, en_dma_l
	call EM_GET_ENEMY_VARIABLE 				; a = low byte address
	ld 	 c, a 								; save it in register a
	inc  hl
	ld 	 a, [hl]
	ld 	 h, a 								; a = high byte address
	ld 	 l, c 								; b =  low byte address

	ld 	 d, b 								; Save the input value

	; Now we have the DMA address, so we can look up any variable of this array.

	ld 	 b, 0
	ld 	 c, pl_sp0a							; Get the attribute memory address of the first sprite
	add  hl, bc
	ld 	 c, 4

	ld 	 a, d
	cp 	 AND_LEFT
	jr 	 z, .em_change_en_attributes_left

	cp 	 OR_RIGHT
	jr 	 z, .em_change_en_attributes_right_or

	ld 	 a, [hl]
	xor  RIGHT_ATTRIBUTE
	jr 	 .em_change_en_attributes_do

.em_change_en_attributes_right_or:

	ld 	 a, [hl]
	or 	 RIGHT_ATTRIBUTE
	jr 	 .em_change_en_attributes_do

.em_change_en_attributes_left:

	ld 	 a, [hl]
	and  LEFT_ATTRIBUTE

.em_change_en_attributes_do:

	ld 	 [hl], a 							; en_sp0a
	add  hl, bc
	ld 	 [hl], a 							; en_sp1a
	add  hl, bc
	ld 	 [hl], a 							; en_sp2a
	add  hl, bc
	ld 	 [hl], a 							; en_sp3a

	ret

;==============================================================
; Function: Swap Player X coordinates
; Description:
; Modified registers: all
; Input: -
;==============================================================

EM_SWAP_PL_X:

	ld   e, pl_sp0x
	call EM_GET_PL_DMA_VAR

	ld 	 b, a

	ld   e, pl_sp1x
	call EM_GET_PL_DMA_VAR
	ld 	 c, a
	ld 	 [hl], b 							;SPR1_X = SPR0_X

	ld   e, pl_sp0x
	call EM_GET_PL_DMA_VAR
	ld 	 a, c
	ld 	 [hl], c 							;SPR0_X = SPR1_X

	ld   e, pl_sp2x
	call EM_GET_PL_DMA_VAR
	ld 	 [hl], c 							;SPR2_X = SPR1_X

	ld   e, pl_sp3x
	call EM_GET_PL_DMA_VAR
	ld 	 [hl], b							;SPR3_X = SPR0_X

	ld 	 e, pl_action 						;Check if we already swapped the sprites
	call EM_GET_PLAYER_VARIABLE
	or   SWAP_ACTION
	ld 	 b, a
	call EM_SET_PLAYER_VARIABLE

	jp AM_RESET_PLAYER_SPRITES

;==============================================================
; Function: Update Player Tiles
; Description:
; Modified registers:
; Input:
;==============================================================

EM_UPDATE_PL_TILES:

	ld 	 e, pl_movementd
	call EM_GET_PLAYER_VARIABLE
	cp 	 UP_JP
	jr   nz, .ut_down
	
	;Move Up
	
	ld 	 e, pl_tiley
	call EM_GET_PLAYER_VARIABLE
	sub  2								; we move 16 pixels each time -> 2 tiles
	ld 	 b, a 							; b contains the new value for tile_y
	jp 	 EM_SET_PLAYER_VARIABLE

.ut_down:

	cp 	 DOWN_JP
	jr   nz, .ut_left
	
	;Move Down

	ld 	 e, pl_tiley
	call EM_GET_PLAYER_VARIABLE
	add  2						
	ld 	 b, a 							
	jp 	 EM_SET_PLAYER_VARIABLE

.ut_left:

	cp 	 LEFT_JP
	jr   nz, .ut_right
	
	;Move Left
	
	ld 	 e, pl_tilex
	call EM_GET_PLAYER_VARIABLE
	sub  2								
	ld 	 b, a 							
	jp 	 EM_SET_PLAYER_VARIABLE

.ut_right:
	
	;Move Right
	
	ld 	 e, pl_tilex
	call EM_GET_PLAYER_VARIABLE
	add  2								
	ld 	 b, a 						
	jp 	 EM_SET_PLAYER_VARIABLE


;==============================================================
; Function: Decrease Enemy Life
; Description:
; Modified registers: all
; Input: hl
;==============================================================

EM_DECREASE_EN_LIFE:

	ld 	 d, h 							;Save the address in case the enemy dies.
	ld 	 e, l
	
	ld 	 b, 0
	ld 	 c, en_lifes
	add  hl, bc
	ld 	 a, [hl]
	dec  a
	jr 	 z, .decrease_en_die 	 		;If the lifes are 0, erase him from memory.
	ld 	 [hl], a  						;Otherwise just update it.

	ld 	 hl, DAMAGE_SOUND
	call AS_PLAY_NOTE_CHANNEL_4

	ret

.decrease_en_die:

	ld 	 hl, DAMAGE_SOUND
	call AS_PLAY_NOTE_CHANNEL_4


	ld 	 h, d
	ld 	 l, e
	jp 	 EM_DELETE_ENEMY

;==============================================================
; Function: Get Next Enemy
; Description:
; Input: hl
;==============================================================

EM_GET_NEXT_ENEMY:

	ld 	 a, [_TOTAL_EN] 					; check if there's still enemies to update
	dec  a
	jr 	 z, .no_more_enemies				; if there are no more enemies to update, exit.
	ld 	 [_TOTAL_EN], a 					; update the number of enemies left

	ld 	 d, 0
	ld 	 e, enemy_size

	add  hl, de 							; Get the next enemy spry.

	ld   a, 1
	ret

.no_more_enemies:

	xor  a
	ret

;==============================================================
; Function: Decrease Player's Hunger
; Description: If the hunger is 0, decrease player's life.
; Input: hl
;==============================================================

EM_DECREASE_PLAYER_HUNGER:

	call GM_GET_GAME_STATE
	cp 	 DUNGEON_STATE
	ret  nz
	
	ld 	 e, pl_hunger
	call EM_GET_PLAYER_VARIABLE
	or 	 a
	jr 	 z, .em_decrease_player_hungerandlife

	dec  a
	ld 	 [hl], a

	;Check if we have left 30 of hungry and show a text box with feedback.
	cp 	 30
	jr 	 z, .em_decrease_player_hunger_hungryfeed

	;Also, check if the result was 0 to show the starving feedback
	or 	 a
	jr 	 z, .em_decrease_player_hunger_starvingfeed

	ret

.em_decrease_player_hungerandlife:
	
	ld 	 a, 5
	jr 	 EM_DECREASE_PLAYER_LIFE

.em_decrease_player_hunger_hungryfeed:

	ld 	 a, HUNGRY_BOX
	jp 	 RS_DRAW_TEXT_BOX

.em_decrease_player_hunger_starvingfeed

	ld 	 a, STARVING_BOX
	jp 	 RS_DRAW_TEXT_BOX

;==============================================================
; Function: Decrease & Increase Player's Life
; Description: Decreases/Increases the player life and updates
; the hud.
; Input: a (damage)
; Modified registers: all
;==============================================================

EM_DECREASE_PLAYER_LIFE:
	
	ld 	 b, a
	
	ld 	 e, pl_lifes
	call EM_GET_PLAYER_VARIABLE
	sub  b

	jp 	 z, GM_GAME_OVER
	jp 	 c, GM_GAME_OVER

	ld 	 [hl], a

	ld 	 hl, DAMAGE_SOUND
	call AS_PLAY_NOTE_CHANNEL_4

	jp 	 RS_UPDATE_HP_HUD

EM_INCREASE_PLAYER_LIFE:

	ld 	 e, pl_lifes
	call EM_GET_PLAYER_VARIABLE
	inc  a
	ld 	 [hl], a
	jp 	 RS_UPDATE_HP_HUD

;==============================================================
; Function: Grab Item
; Description: Once the player stopped moving, check if it is
; possible to grab an item. Tile X and Y must be the same.
; Input: -
; Modified registers: all
;==============================================================

EM_GRAB_ITEM:

	; Set collision tiles on the collision manager

	ld 	 e, pl_tilex
	call EM_GET_PLAYER_VARIABLE
	ld 	 b, a
	inc  hl
	ld 	 a, [hl]
	call CM_SET_TILES

	call EM_GET_BLOCKS_ARRAY 				; a = num_blocks, hl = block_array, de = dma_blocks
	or 	 a
	ret  z

	ld 	 [_TOTAL_EN], a

.em_grab_item_loop:

	push hl

	ld 	 de, block_tilex
	add  hl, de
	ld 	 b, [hl] 							; hl = tile_x
	call CM_CHECK_SAME_X_WITH_PARAM
	or 	 a
	jr 	 z, .em_grab_item_next

	inc  hl
	ld 	 b, [hl] 							; hl = tile_y
	call CM_CHECK_SAME_Y_WITH_PARAM
	or 	 a
	jr 	 z, .em_grab_item_next

	; If we get here is because we can grab the item.

	; Get Type

	dec  hl
	dec  hl

	ld 	 a, [hl]
	
	call EM_ADD_ITEM

	ld 	 hl, OBJECT_SOUND
	call AS_PLAY_NOTE_CHANNEL_2

	pop  hl
	jp 	 EM_DELETE_BLOCK

.em_grab_item_next:

	pop  hl

	ld 	 a, [_TOTAL_EN]
	dec  a
	ld 	 [_TOTAL_EN], a
	ret  z

	ld 	 de, block_size
	add  hl, de

	jr 	 .em_grab_item_loop

;==============================================================
; Function: Add Item
; Description: Adds the item given an input.
; Input: a
; Modified registers: all
;==============================================================

EM_ADD_ITEM:

	cp 	 BASIC_POTION
	jr 	 nz, .add_item_sp

	ld 	 e, pl_baspotion
	ld 	 c, BASIC_POTION
	jr 	 .add_item_finish

.add_item_sp:

	cp 	 SUPER_POTION
	jr 	 nz, .add_item_apple

	ld 	 e, pl_suppotion
	ld 	 c, SUPER_POTION
	jr 	 .add_item_finish

.add_item_apple:

	ld 	 e, pl_basapple
	ld 	 c, BASIC_APPLE

.add_item_finish:

	ld 	 b, a

	call EM_GET_PLAYER_VARIABLE 			; Modified registers: hl, de
	inc  a
	ld 	 [hl], a

	ld 	 a, ITEM_BOX
	ld 	 b, c
	jp 	 RS_DRAW_TEXT_BOX

;==============================================================
; Function: Add Health to Player
; Description:
; Input: a (health to add)
; Modified registers: all
;==============================================================

EM_ADD_PLAYER_HEALTH:
	
	ld 	 b, a 								; b = health to add
	ld 	 e, pl_lifes								
	call EM_GET_PLAYER_VARIABLE 			; Modified registers: hl, de; a = actual health
	add  b
	ld 	 [hl], a 							; hl = actual health + input
	call RS_UPDATE_HP_HUD

	ld 	 e, pl_action
	ld 	 b, WAIT_ACTION
	jp 	 EM_SET_PLAYER_VARIABLE 		 	; Input: b (value), e (variable to change)


SECTION "Entity_Default_Values", ROMX

;==============================================================
; Entity default values
;==============================================================

;movement_direction: 	 direction of movement of an entity
;action: 				 booleans to know if player's attacking or moving. 1st low bit is attacking, 2nd is moving
;absolute_y, absolute_x: positions where needs to be added the scrX or scrY

; [sprite_y, sprite_x, sprite_number, sprite_att]*4, lifes, tile_x, tile_y, movement_direction, last_movement, action, hunger, b_potions, s_potions, b_apples
player_entity: 	DB 72, 80, 39, 0, 72, 88, 41, 0, 80, 80, 40, 0, 80, 88, 42, 0, 42, 19, 17, 1, 1, 0, PL_MAX_HUNGER, 0, 0, 0

; ENEMIES

; absolute_y, absolute_x, sprite_number, lifes, tile_x, tile_y, movement_direction, action, default_sprite, damage, velocity
enemy_entity: 	DB 88, 80, SKULL_ENEMY, 4, 9, 9, 0, 0, SKULL_ENEMY, 10, %01010101
enemy_entity2: 	DB 232, 208, THIEF_ENEMY, 6, 25, 27, 0, 0, THIEF_ENEMY, 5, 0
enemy_entity3: 	DB 232, 192, SKULL_ENEMY, 4, 23, 27, 0, 0, SKULL_ENEMY, 10, %01010101
enemy_entity4: 	DB 24, 32, SKULL_ENEMY, 4, 3, 1, 0, 0, SKULL_ENEMY, 10, %01010101
enemy_entity5: 	DB 240, 192, SKULL_ENEMY, 4, 23, 29, 0, 0, SKULL_ENEMY, 10, %01010101
enemy_entity6: 	DB 216, 16, THIEF_ENEMY, 6, 1, 25, 0, 0, THIEF_ENEMY, 5, 0
enemy_entity7: 	DB 216, 16, ORC_ENEMY, 4, 1, 25, 0, 0, ORC_ENEMY, 15, %00110011
enemy_entity8: 	DB 184, 192, ARMOR_ENEMY, 6, 23, 21, 0, 0, ARMOR_ENEMY, 15, %00100010
enemy_entity9: 	DB 24, 64, ORC_ENEMY, 6, 7, 1, 0, 0, ORC_ENEMY, 15, %00110011
enemy_entity10: DB 73, 96, THIEF_ENEMY, 6, 11, 7, 0, 0, THIEF_ENEMY, 15, 0
enemy_entity11: DB 41, 224, SKULL_ENEMY, 6, 27, 3, 0, 0, SKULL_ENEMY, 10, %01010101

; ITEMS

;absolute_y, absolute_x, type, tile_x, tile_y
block_entity: 	DB 232, 240, BASIC_POTION, 29, 27
block_entity2: 	DB 40, 32, SUPER_POTION, 3, 3
block_entity3: 	DB 104, 160, BASIC_APPLE, 19, 11
block_entity4: 	DB 30, 146, BASIC_POTION, 17, 1
block_entity5: 	DB 170, 68, BASIC_APPLE, 7, 19
block_entity6: 	DB 158, 163, SUPER_POTION, 19, 17
block_entity7: 	DB 254, 196, BASIC_POTION, 23, 29
block_entity8: 	DB 184, 208, BASIC_APPLE, 25, 21
block_entity9: 	DB 170, 68, SUPER_POTION, 7, 19
block_entity10: DB 30, 240, BASIC_POTION, 29, 1

; HUD

hud_entities: 	DB 16, 8, 7, 0, 16, 16, 15, 0, 16, 24, FULL_LIFE, 0, 16, 32, FULL_LIFE, 0, 16, 40, FULL_LIFE, 0  ; Player Lifes
				DB 16, 144, 5, 0, 16, 152, 26, 0, 16, 160, 27, 0 							; Floor Number 