;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

	INCLUDE "hardware.inc"
	INCLUDE "constants.inc"
	INCLUDE "input_system_h.inc"
	INCLUDE "render_system_h.inc"
	INCLUDE "entity_manager_h.inc"

;============================================================
; User data
;============================================================

SECTION "InputSys_Data",WRAM0

_PAD: DS 1

SECTION "Input_System", ROM0

;==============================================================
; Function: Init Input System
; Description: Initializes the input system
; Modified registers: a
; Input: -
;==============================================================

IS_INIT:
	xor a
	ld [_PAD], a
	ret

;==============================================================
; Function: Update Input System
; Description: Updates the input system, reading first the
; pad and then 
; Modified registers: a,b,
; Input: -
;==============================================================

IS_UPDATE:
	call IS_READ_PAD
	call IS_CHECK_BUTTONS
	ret

;==============================================================
; Function: Read Pad
; Description: reads few times the pad to see if there's any
; input from the player
; Modified registers: a,b,
; Input: -
;==============================================================

IS_READ_PAD:
	
	ld 	 a, P1F_5    		;bit 4 a 0, bit 5 a 1 (cruzeta activada, botones no)
    ld 	 [rP1], a
	
	ld 	 a, [rP1]
	ld 	 a, [rP1]
	ld 	 a, [rP1]
	ld 	 a, [rP1] 			;leemos varias veces para evitar el bouncing

	and  $0F 				;solo queremos los 4 bits bajos
	swap a  				;cambiamos los valores altos por los bajos
	ld 	 b, a

	ld 	 a, P1F_4    		;bit 4 a 1, bit 5 a 0 (botones activados, cruzeta no)
    ld 	 [rP1], a

	ld 	 a, [rP1]
	ld 	 a, [rP1]
	ld 	 a, [rP1]
	ld 	 a, [rP1]

	and  $0F
	or   b

	cpl 					;complementario de a
	ld 	 [_PAD], a
							;         pad    but
	ret 					;result = [0000][0000]

;==============================================================
; Function: Check Buttons
; Description: Checks which buttons are pressed and calls for
; the necessary events.
; Modified registers: all
; Input: -
; Output: -
;==============================================================

IS_CHECK_BUTTONS:

	ld 	 e, pl_action
	call EM_GET_PLAYER_VARIABLE
	or 	 a
	ret  nz 						;If the player's already doing something, don't check the buttons

	;ld b, A_BUTTON
	;call IS_CHECK_BPRESSED
	;jr nz,

	ld 	 b, B_BUTTON
	call IS_CHECK_BPRESSED
	jp 	 nz, GM_SET_ATTACK

	ld 	 b, RIGHT_JP
	call IS_CHECK_BPRESSED
	jp 	 nz, IS_CHANGE_MOVEMENT

	ld 	 b, LEFT_JP
	call IS_CHECK_BPRESSED
	jp 	 nz, IS_CHANGE_MOVEMENT

	ld 	 b, UP_JP
	call IS_CHECK_BPRESSED
	jp 	 nz, IS_CHANGE_MOVEMENT

	ld 	 b, DOWN_JP
	call IS_CHECK_BPRESSED
	jp 	 nz, IS_CHANGE_MOVEMENT

	ld 	 e, pl_action
	ld 	 b, 0
	call EM_SET_PLAYER_VARIABLE

	ld 	 b, START
	call IS_CHECK_BPRESSED
	jp 	 nz, GM_OPEN_GAME_MENU

	;ld b, SELECT
	;call IS_CHECK_BPRESSED
	;jr nz, 

	ret

;==============================================================
; Function: Press Start
; Description: Waits for the user to press the Start button.
; Modified registers: a
; Input: -
;==============================================================

IS_PRESS_START:

	call RS_WAIT_VBLANK
	
	call IS_READ_PAD

	ld 	 a, [_PAD]
	and  START 				;check for the start button

	jr 	 z, IS_PRESS_START

	call IS_INIT			;restart the input register

	ret

;==============================================================
; Function: Check Button Pressed
; Description: Checks if the input button is pressed and
; returns a boolean (1 = true, 0 = false) in a.
; Modified registers: a
; Input: b
; Output: a
;==============================================================

IS_CHECK_BPRESSED:

	ld 	 a, [_PAD]
	and  b
	ret

;==============================================================
; Function: Change Movement
; Description:
; Modified registers: a
; Input: b
; Output: -
;==============================================================

IS_CHANGE_MOVEMENT:

	ld 	 e, pl_movementd
	call EM_GET_PLAYER_VARIABLE

	ld 	 c, b 								;new direction of movement
	ld 	 b, a 								;last direction of movement

	ld 	 e, pl_lastmov
	call EM_SET_PLAYER_VARIABLE
	ld 	 e, pl_movementd
	ld 	 b, c
	call EM_SET_PLAYER_VARIABLE

	ld 	 e, pl_action
	ld 	 b, MOVE_ACTION
	jp 	 EM_SET_PLAYER_VARIABLE

;==============================================================
; Function: Check Menu Buttons
; Description:
; Modified registers:
; Output: 
;==============================================================

IS_CHECK_MENU_BUTTONS:
	
	call RS_WAIT_VBLANK
	call IS_READ_PAD
	call AS_UPDATE
	
	ld 	 c, 0

	ld 	 b, UP_JP
	call IS_CHECK_BPRESSED
	ret  nz

	inc  c

	ld 	 b, DOWN_JP
	call IS_CHECK_BPRESSED
	ret  nz

	inc  c

	ld 	 b, A_BUTTON
	call IS_CHECK_BPRESSED
	ret  nz

	jr 	 IS_CHECK_MENU_BUTTONS

;==============================================================
; Function: Check B and A Buttons
; Description:
; Modified registers: a, b
; Output: 
;==============================================================

IS_CHECK_PRESS_AB:

	call RS_WAIT_VBLANK
	CALL IS_READ_PAD
	call AS_UPDATE
	
	ld 	 b, A_BUTTON
	call IS_CHECK_BPRESSED
	ret  nz
	ld 	 b, B_BUTTON
	call IS_CHECK_BPRESSED
	ret  nz
	jr 	 IS_CHECK_PRESS_AB