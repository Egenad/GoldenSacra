;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

	INCLUDE "game_manager_h.inc"
	INCLUDE "entity_manager_h.inc"
	INCLUDE "render_system_h.inc"
	INCLUDE "input_system_h.inc"
	INCLUDE "audio_system_h.inc"
	INCLUDE "physics_system_h.inc"
	INCLUDE "constants.inc"
	INCLUDE "ai_system_h.inc"

SECTION "GM_DATA", WRAM0

_TURN:  		DS 1
_STATE: 		DS 1 								; 0 = Overworld, 1 = Dungeon, 2 = Transition
_CHANGE: 		DS 1 								; bool to know if we have to change state
_ACTUAL_FLOOR: 	DS 1

SECTION "Game_Manager", ROM0

;==============================================================
; Function: Run Game
; Description:
; Modified registers:
; Input: -
;==============================================================

GM_RUN:

	call RS_INIT
	call EM_INIT
	call AM_INIT
	call IS_INIT
	call AS_INIT
	call PS_INIT
	call AI_INIT

	call RS_TITLE_SCREEN
	call RS_TURN_LCD_ON

	call GM_TITLE_SCREEN
	
	ld 	 a, OVERWORLD_STATE
	call GM_SET_GAME_STATE

.gameloop:		

	call GM_CHECK_STATE
	call GM_UPDATE_INPUT
	call RS_UPDATE
	call AS_UPDATE
	call AI_UPDATE

	call RS_WAIT_VBLANK
	call RS_DRAW
	call PS_UPDATE
	jp   .gameloop

;==============================================================
; Function: Title Screen
; Description:
; Modified registers:
; Input: -
;==============================================================

GM_TITLE_SCREEN:
	
	call RS_WAIT_VBLANK
	call AS_UPDATE
	
	call IS_READ_PAD
	ld 	 b, START
	or 	 a
	jr 	 z, GM_TITLE_SCREEN

	call IS_INIT			;restart the input register

	ret

;==============================================================
; Function: Init Game
; Description:
; Modified registers:
; Input: -
;==============================================================

GM_INIT_OVERWORLD:

	ld 	 a, 1
	call AS_SET_ID

	xor  a
	ld 	 [_STATE], a
	ld 	 [_TURN], a

	call RS_INIT_OVERWORLD

	call EM_CREATE_PLAYER

	ld 	 hl, DUNGEON1
	ld 	 a, 1
	call AS_SET_ID

	jp 	 PS_INIT

;==============================================================
; Function: Increment Actual Floor.
; Description: It also sets the game state to transition.
; Modified registers: a
; Input: -
;==============================================================

GM_INCREMENT_ACTUAL_FLOOR:
	
	ld 	 a, [_ACTUAL_FLOOR]
	inc  a
	ld 	 [_ACTUAL_FLOOR], a

	jp 	 RS_UPDATE_FLOOR_HUD

;==============================================================
; Function: Open In Game Menu
; Modified registers:
; Input: -
;==============================================================

GM_OPEN_GAME_MENU:
	ld 	 a, MENU_BOX
	jp 	 RS_DRAW_TEXT_BOX

;==============================================================
; Function: Game Over
; Description:
; Modified registers:
; Input: -
;==============================================================

GM_GAME_OVER:
	
	call EM_DELETE_ALL_ENEMIES
	call EM_DELETE_ALL_BLOCKS

	call RS_CLEAR_DMA

	ld 	 a, HOUSE_STATE
	jp 	 GM_SET_GAME_STATE

;==============================================================
; Function: Init Dungeon
; Description:
; Modified registers:
; Input: -
;==============================================================

GM_INIT_DUNGEON:

	ld 	 a, 1
	ld 	 [_ACTUAL_FLOOR], a

	call EM_CREATE_PLAYER 								; Reset the player
	call RS_INIT_HUD

	ld 	 hl, enemy_entity 								; Create enemies
	call EM_CREATE_ENEMY
	ld 	 hl, enemy_entity2
	call EM_CREATE_ENEMY
	ld 	 hl, enemy_entity6
	call EM_CREATE_ENEMY

	ld 	 hl, block_entity
	call EM_CREATE_BLOCK
	ld 	 hl, block_entity2
	call EM_CREATE_BLOCK
	ld 	 hl, block_entity3
	call EM_CREATE_BLOCK

	ld 	 hl, DUNGEON1
	ld 	 a, 2
	call AS_SET_ID

	jp	 RS_INIT_BACKGROUND 							; Init dungeon map

;==============================================================
; Function: Init House
; Description:
; Modified registers:
; Input: -
;==============================================================

GM_INIT_HOUSE:

	ld 	 a, 1
	call AS_SET_ID

	call EM_CREATE_PLAYER

	ld 	 e, pl_tiley
	ld 	 b, 7
	call EM_SET_PLAYER_VARIABLE
	ld 	 e, pl_tilex
	ld 	 b, 9
	call EM_SET_PLAYER_VARIABLE

	call RS_INIT_HOUSE 									; Init house map

	ld 	 a, 1
	jp 	 PS_SET_LOCK_SCROLL

;==============================================================
; Function: Get and Set Game State
; Description: Returns or sets the state of the game.
;==============================================================

GM_GET_GAME_STATE:
	ld 	 a, [_STATE]
	ret

GM_SET_GAME_STATE:
	ld 	 [_STATE], a
	ld 	 a, 1
	ld 	 [_CHANGE], a
	ret

;==============================================================
; Function: Get and Set Turn.
; Description: Returns or sets the turn.
;==============================================================

GM_GET_TURN:
	ld 	 a, [_TURN]
	ret

GM_SET_TURN:
 	ld 	 [_TURN], a
 	ret

;==============================================================
; Function: Set Attack
; Description:
; Modified registers: e, b
; Input: -
; Output: -
;==============================================================

GM_SET_ATTACK:

	ld 	 a, [_STATE]
	cp   DUNGEON_STATE
	ret  nz  

	ld 	 e, pl_action
	ld 	 b, ATTACK_ACTION
	jp 	 EM_SET_PLAYER_VARIABLE

;==============================================================
; Function: Check State
; Description: 
;==============================================================

GM_CHECK_STATE:

	ld 	 a, [_CHANGE]
	or 	 a
	ret  z 										; 0 = dont do anything.
	dec  a
	jr 	 z, .gm_check_fade_out 					; 1 = fade out
	dec  a
	jr 	 z, GM_LOAD_STATE 					 	; 2 = load state
	jr 	 gm_check_fade_in 						; 3 = fade in

.gm_check_fade_out:

	; Start with a fade out.
	call RS_FADE_OUT
	call RS_GET_PAL_STATE
	or 	 a
	ret  z

	ld 	 a, 2
	ld 	 [_CHANGE], a
	ret

gm_check_fade_in:

	call RS_FADE_IN
	call RS_GET_PAL_STATE
	or 	 a
	ret  nz

	xor  a
	ld 	 [_CHANGE], a
	ret
	
gm_check_turn_on:
	
	ld 	 a, 3
	ld 	 [_CHANGE], a
	jp 	 RS_TURN_LCD_ON

;==============================================================
; Function: Update Input
; Description: Update input only if we are not making a
; transition.
;==============================================================

GM_UPDATE_INPUT:
	
	ld 	 a, [_CHANGE]
	or   a
	ret  nz

	jp 	 IS_UPDATE

;==============================================================
; Function: Load State
; Description: 
;==============================================================

GM_LOAD_STATE:

	ld 	 e, pl_action
	call EM_GET_PLAYER_VARIABLE
	or 	 a
	ret  nz

	call RS_TURN_LCD_OFF

	ld 	 a, [_STATE]
	cp   DUNGEON_STATE
	jr 	 nz, .not_d_state

	call GM_INIT_DUNGEON
	jp 	 gm_check_turn_on

.not_d_state:

	cp 	 OVERWORLD_STATE
	jr 	 nz, .not_o_state
	call GM_INIT_OVERWORLD
	jp 	 gm_check_turn_on

.not_o_state:
	
	cp 	 TRANSIT_STATE
	jr 	 nz, gm_check_h_state

	call GM_GO_NEXT_FLOOR
	jp 	 gm_check_turn_on

gm_check_h_state:
	
	cp 	 HOUSE_STATE
	jr 	 nz, gm_check_m_state

	call GM_INIT_HOUSE
	jp 	 gm_check_turn_on

gm_check_m_state:
	
	jp 	 GM_RUN

;==============================================================
; Function: Go Next Floor
; Description: Fades out and in the screen while loading the
; next tilemap.
;==============================================================

GM_GO_NEXT_FLOOR:

 	ld 	 a, DUNGEON_STATE
 	ld 	 [_STATE], a

	call GM_INCREMENT_ACTUAL_FLOOR
	
	; Check if we have to fade out or fade in
	call EM_DELETE_ALL_ENEMIES
	call EM_DELETE_ALL_BLOCKS

	ld 	 a, [_ACTUAL_FLOOR]
	cp 	 2
	jr 	 z, .floor2
	cp 	 3
	jr   z, .floor3

	ret

.floor2:
	ld 	 hl, Floor2
	ld 	 bc, Fin_Floor2-Floor2
	call RS_INIT_FLOOR
	
	ld 	 hl, enemy_entity2
	call EM_CREATE_ENEMY
	ld 	 hl, enemy_entity3
	call EM_CREATE_ENEMY
	ld 	 hl, enemy_entity4 								; Create enemies
	call EM_CREATE_ENEMY
	ld 	 hl, enemy_entity7
	call EM_CREATE_ENEMY

	ld 	 hl, block_entity4
	call EM_CREATE_BLOCK
	ld 	 hl, block_entity5
	call EM_CREATE_BLOCK
	ld 	 hl, block_entity6
	call EM_CREATE_BLOCK
	ld 	 hl, block_entity7
	jp 	 EM_CREATE_BLOCK

.floor3:

	ld 	 hl, Floor3
	ld 	 bc, Fin_Floor3-Floor3
	call RS_INIT_FLOOR
	
	ld 	 hl, enemy_entity8
	call EM_CREATE_ENEMY
	ld 	 hl, enemy_entity9
	call EM_CREATE_ENEMY
	ld 	 hl, enemy_entity10
	call EM_CREATE_ENEMY
	ld 	 hl, enemy_entity11
	call EM_CREATE_ENEMY

	ld 	 hl, block_entity6
	call EM_CREATE_BLOCK
	ld 	 hl, block_entity9
	call EM_CREATE_BLOCK
	ld 	 hl, block_entity10
	call EM_CREATE_BLOCK
	ld 	 hl, block_entity8
	jp 	 EM_CREATE_BLOCK