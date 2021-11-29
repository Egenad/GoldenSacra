;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

	INCLUDE "hardware.inc"
	INCLUDE "constants.inc"
	INCLUDE "render_system_h.inc"
	INCLUDE "entity_manager_h.inc"

SECTION "RenderSys_Data",WRAM0

vblank_flag: 	DS 1
_OFFSET: 		DS 1
_SAVER: 		DS 1
_COUNT: 		DS 1
_COUNT2: 		DS 1
_OPTION: 		DS 1
_JUMP: 			DS 1
_CPU: 			DS 1 								; 0 = GB, 1 = GBC
_PAL_STATE: 	DS 1 								; 0 = fade out, 1 = fade in				
_PAL_COLORS: 	DS 1 								; How many colors do we have. Default = 3
_TIMER: 		DS 1
_GBC_PAL_SPR: 	DS 8
_GBC_PAL_BCK: 	DS 8
_GBC_PAL_R: 	DS 1 								; Red component of the GBC palette
_GBC_PAL_G: 	DS 1 								; Green component of the GBC palette
_GBC_PAL_B: 	DS 1 								; Blue component of the GBC palette

SECTION "Render_System", ROM0

;==============================================================
; Function: Initialize Render System
; Description:
; Modified registers:
; Input: -
;==============================================================

RS_INIT:

	;enable vblank interrupt
 	ei
	ld   a,IEF_VBLANK
	ld   [rIE],a

	call RS_TURN_LCD_OFF
	call RS_LOAD_PERSISTENT_TILES

	;Set palettes -> check wether we are playing on an original GB or a GBC

	call GM_GET_TURN
	cp   GBC
	jr   z, .gbc

	xor  a
	ld 	 [_CPU], a

	ld   a, BCK_PALETTE 	;load palette onto a register
	ld   [rBGP],  a  		;background palette
	ld   a, SPR_PALETTE
	ld   [rOBP0], a  		;sprite palette

	jr 	 .keep_init

.gbc:
	
	ld 	 a, 1
	ld 	 [_CPU], a

	call RS_GBC_PAL

.keep_init:

	xor  a
	ld 	 [rSCX], a
    ld 	 [rSCY], a
    ld 	 [_PAL_STATE], a

    call RS_INIT_CPU_COLORS
    call RS_INIT_CPU_TIMER

    call RS_CLEAR_OAM

	jp 	 RS_INIT_DMA

;==============================================================
; Function: Initialize CPU colors counter
; Modified registers: all
; Input: -
;==============================================================

RS_INIT_CPU_COLORS:

    ld 	 a, [_CPU]
    or 	 a
    jr 	 nz, .gbc_counter

    ld   a, 3
    ld 	 [_PAL_COLORS], a

    ret

.gbc_counter:

	ld 	 a, 31
	ld 	 [_PAL_COLORS], a

	ret

;==============================================================
; Function: Initialize CPU colors timer
; Modified registers: all
; Input: -
;==============================================================

RS_INIT_CPU_TIMER:

	ld 	 a, [_CPU]
    or 	 a
    jr 	 nz, .gbc_timer
	
	ld 	 a, 5
    ld 	 [_TIMER], a

    ret

.gbc_timer:

	ld 	 a, 1
	ld 	 [_TIMER], a

	ret

;==============================================================
; Function: Render System Draw
; Modified registers: all
; Input: -
;==============================================================

RS_DRAW:
	jp 	 _HRAM

;==============================================================
; Function:	Update Render System
; Modified registers: all
; Input: -
;==============================================================

RS_UPDATE:
	jp 	 RS_UPDATE_PLAYER

;==============================================================
; Function:	Title Screen
; Description: Initializes the title screen of the game
; Modified registers: all
; Input: -
;==============================================================

RS_TITLE_SCREEN:

	call RS_GET_NONPERSISTENT_TILES_MA
	ld 	 hl, Title_Screen_Tiles
	ld 	 bc, Title_Screen_Tiles_End-Title_Screen_Tiles
	call RS_COPY_MEM
	
	ld	 hl, MenuMapTiles
	ld	 de, _SCRN0
	ld	 bc, Fin_MenuMapTiles-MenuMapTiles
	ld 	 a, 12
	ld   [_OFFSET], a
	ld   a, 20
	ld 	 [_COUNT], a

	jp   RS_COPYMEM_OFFSET

;==============================================================
; Function: Init Background
; Description: initializes the background
; Modified registers: all
; Input: -
;==============================================================

RS_INIT_BACKGROUND:

	call RS_GET_NONPERSISTENT_TILES_MA
	ld 	 hl, Dungeon_Tiles
	ld 	 bc, Dungeon_Tiles_End-Dungeon_Tiles
	call RS_COPY_MEM

	ld 	 a, 80
    ld 	 [rSCX], a
    ld 	 [rSCY], a
	
	ld 	 hl, Floor1
	ld 	 de, _SCRN0
	ld 	 bc, Fin_Floor1-Floor1
	jp 	 RS_COPY_MEM

;==============================================================
; Function: Init Floor
; Description: initializes the actual floor
; Modified registers: all
; Input: HL, BC
;==============================================================

RS_INIT_FLOOR:
	ld 	 de, _SCRN0
	jp 	 RS_COPY_MEM

;==============================================================
; Function: Init House
; Description: initializes the house background
; Modified registers: all
; Input: -
;==============================================================

RS_INIT_HOUSE:

	call RS_GET_NONPERSISTENT_TILES_MA
	ld 	 hl, Overworld_Tiles
	ld 	 bc, Overworld_Tiles_End-Overworld_Tiles
	call RS_COPY_MEM

	ld	 hl, House
	ld	 de, _SCRN0
	ld	 bc, Fin_House-House
	ld 	 a, 12
	ld   [_OFFSET], a
	ld   a, 20
	ld 	 [_COUNT], a

	xor  a
	ld 	 [rSCX], a
    ld 	 [rSCY], a

	jp   RS_COPYMEM_OFFSET

;==============================================================
; Function: Init Overworld
; Description: initializes the overworld
; Modified registers: all
; Input: -
;==============================================================

RS_INIT_OVERWORLD:

	call RS_GET_NONPERSISTENT_TILES_MA
	ld 	 hl, Overworld_Tiles
	ld 	 bc, Overworld_Tiles_End-Overworld_Tiles
	call RS_COPY_MEM

	ld 	 a, 80
    ld 	 [rSCX], a
    ld 	 [rSCY], a
	
	ld 	 hl, Overworld
	ld 	 de, _SCRN0
	ld 	 bc, Fin_Overworld-Overworld
	jp 	 RS_COPY_MEM

;==============================================================
; Function: Delay Frames
; Description: Delays c times frames.
; Input: c
;==============================================================

RS_DELAY_FRAMES:

	ld 	 a, c
	or 	 a
	jr 	 nz, rs_delay_frames_vblank

	jp 	 RS_WAIT_MODE_01

rs_delay_frames_vblank:

	call RS_WAIT_VBLANK
	dec  c
	jr 	 nz, rs_delay_frames_vblank
	ret

;==============================================================
; Function: Wait V-Blank
; Description: Waits for the V-Blank segment
; Modified registers: hl, a, f
; Input: -
;==============================================================

RS_WAIT_VBLANK:

	;//////////////////////////////////////////////////////////
	;Warning!: This code is a BAD practice.
	;It consumes a lot of battery power as the CPU is always on
	;(Also, the VBLANK starts at 144, not 145)
	;ld	a,[rLY]				;get current scanline
	;cp	145					;Are we in v-blank yet?
	;jr	nz,WAIT_VBLANK		;if A-91 != 0 then loop
	;//////////////////////////////////////////////////////////
  	
  	halt
  	nop
  	
  	ld 	 a,[vblank_flag]
  	or 	 a
  	
  	jr 	 z, RS_WAIT_VBLANK

  	xor  a
  	ld   [vblank_flag],a

  	ret


;==============================================================
; Function: Wait Mode 0-1
; Description: 
; Modified registers:  a
; Input: 
;==============================================================

RS_WAIT_MODE_01:

	ld 		a, [rSTAT]
	bit   	1, a 					;If bit 1 from the STAT register is not 0, it means we are not in VBLANK nor HBLANK
	jr 		nz, RS_WAIT_MODE_01
	ret

;==============================================================
; Function: Turn LCD OFF
; Modified registers: a
; Input: -
;==============================================================

RS_TURN_LCD_OFF:

	xor  a      
	ld   [rLCDC],a   			
	ret

;==============================================================
; Function: Turn LCD ON
; Modified registers: a
; Input: -
;==============================================================

RS_TURN_LCD_ON:

	ld   a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON|LCDCF_WIN9C00       ;encendemos nuevamente la pantalla  
	ld   [rLCDC],a 
	ret

;==============================================================
; Function: Set GBC palette
; Description:
; Modified registers:
; Input: -
;==============================================================

RS_GBC_PAL:
	
	call Set_Sprite_Palette
	jp 	 Set_Dungeon_Palette

;==============================================================
; Function: Set Dungeon (Color) palette
; Description:
; Modified registers:
; Input: -
;==============================================================

Set_Dungeon_Palette:

	ld 	 hl, dungeon_palette

set_dp_param:
	
	ld 	 b, 4
	xor  a
	set  7, a 			
	ld 	 [rBCPS], a 		;Auto Increment. This is a Write-Specification register.

set_dbp:

	call RS_WAIT_MODE_01

	ld 	 a, [hl+]
	ld 	 [rBCPD], a 		;This is a Write-Data register.
	ld 	 a, [hl+]
	ld 	 [rBCPD], a

	dec  b
	jr   nz, set_dbp

	ret

;==============================================================
; Function: Set Sprites (Color) palette
; Description:
; Modified registers:
; Input: -
;==============================================================

Set_Sprite_Palette:
	
	ld 	 hl, sprite_palette

set_sbp_param:

	ld 	 b, 4
	xor  a
	set  7, a 			
	ld 	 [rOCPS], a 		;Auto Increment. This is a Write-Specification register.

set_sbp:

	call RS_WAIT_MODE_01

	ld 	 a, [hl+]
	ld 	 [rOCPD], a 		;This is a Write-Data register.
	ld 	 a, [hl+]
	ld 	 [rOCPD], a

	dec  b
	jr 	 nz, set_sbp

	ret

;==============================================================
; Function: Load Persistent Tiles
; Description: Load all the tiles which will always be loaded 
; in RAM memory, no matter what state the game's at.
; Modified registers: hl, de, bc, af
; Input: -
;==============================================================

RS_LOAD_PERSISTENT_TILES:
	ld 	 hl, Persistent_Tiles
	ld	 de, _VRAM
	ld	 bc, Persistent_Tiles_End-Persistent_Tiles
	call RS_COPY_MEM
	ret

;==============================================================
; Function: Get Non Persistent Tiles Memory Adress
; Description: Gets the memory address from which start loading
; another tileset and not override the persistent one.
; Modified registers: hl, de
; Input: -
;==============================================================

RS_GET_NONPERSISTENT_TILES_MA:
	
	ld	 hl, _VRAM
	ld	 de, Persistent_Tiles_End-Persistent_Tiles
	add  hl, de

	ld 	 d, h
	ld 	 e, l

	ret

;==============================================================
; Function: Clear Map
; Description: Changes all the Background (32x32 tiles)
; to wall tiles.
; Modified registers: hl, bc, af
; Input: -
;==============================================================
	
RS_CLEAR_MAP:
	ld 	 a, 71
	ld	 hl, _SCRN0			;loads the address of the bg map ($9800) into HL
	ld	 bc, $400			;since we have 32x32 tiles, we'll need a counter so we can clear all of them
	jp   RS_COPY_DATA

;==============================================================
; Function: Clear OAM
; Description: Cleans the OAM memory
; Modified registers: hl, bc, af
; Input: -
;==============================================================

RS_CLEAR_OAM:
	ld   hl, _OAMRAM
	jr 	 rs_clear

RS_CLEAR_DMA:

	ld 	 hl, $C000

rs_clear:

	ld   bc, $A0
	xor  a
	jp   RS_COPY_DATA

;==============================================================
; Function: Copy Data
; Description: Copies the var parameter to an arrange of memory
; positions.
; Modified registers: hl, bc, af, e
; Input: a(var), hl(origin), bc(number of bytes)
;==============================================================

RS_COPY_DATA:
	ld   e, a
COPY_DATA_LOOP:
	ld   a, e
	ld   [hli],a
	dec  bc
	ld   a,b
	or   c
	jr   nz, COPY_DATA_LOOP
	ret

;==============================================================
; Function: Copy Memory
; Description: Copies the number of bytes (bc) from origen (hl)
; to destiny (de).
; Modified registers: all
; Input: hl (origen), de (destiny), bc (number of bytes)
;==============================================================

RS_COPY_MEM:
	ld 	 a, [hl]				; cargamos el dato en A
	ld	 [de], a				; copiamos el dato al destino
	dec	 bc						; uno menos por copiar
							
	ld	 a, c 					; comprobamos si bc es cero
	or	 b
	ret	 z						; si es cero, volvemos
	
	inc	 hl
	inc	 de
	jr	 RS_COPY_MEM

;==============================================================
; Function: Copy Memory Offset
; Description: Copies the number of bytes (bc) from origen (hl)
; to destiny (de), and makes jumps of [_OFFSET] bytes every
; [_COUNT] times.
; Modified registers: all
; Input: hl, de, bc, [_OFFSET], [_COUNT]
;==============================================================

RS_COPYMEM_OFFSET:

	ld 	 a, [_COUNT]
	ld 	 [_JUMP], a 		;the purpose of this variable is to not lose the _COUNT value

without_offset:

	ld	 a, [hl]			
	ld	 [de], a		
	dec	 bc					
							
	ld	 a, c 			
	or	 b
	ret	 z				
	
	inc	 hl
	inc	 de

	ld 	 a, [_JUMP]
	dec  a
	ld 	 [_JUMP], a

	jr 	 nz, without_offset

	;Here we will add the offset to the destiny address
	
	push hl 				;save the memory address of hl on to the stack

	ld 	 a, e
	ld 	 l, a
	ld 	 a, d 
	ld 	 h, a 				;now hl has the de memory address

	ld 	 a, [_OFFSET] 		;get how much we have to move and put it in to de

	ld 	 e, a
	xor  a
	ld 	 d, a

	add  hl, de 			;add de to hl so we have our new destiny memory address

	ld 	 a, l
	ld 	 e, a
	ld 	 a, h
	ld 	 d, a 				;put the destiny back to de

	pop  hl 				;put in hl its initial value

	jr 	 RS_COPYMEM_OFFSET


;==============================================================
; Function: DMA Copy
; Description: 
; Modified registers: all
; Input: -
;==============================================================

RS_DMA_COPY:
	ld   de, $FF80 															;de contains the destination where we want to copy data, which is HRAM
	rst  $28																;reset the Game Boy to jump to vector 0028
	DB   $00, $0D															;bytes to copy
	DB   $F5, $3E, $C0, $EA, $46, $FF, $3E, $28, $3D, $20, $FD, $F1, $D9 	;13 bytes
	ret

;==============================================================
; Function: Init DMA (Direct Memory Access)
; Description:
; Modified registers: hl, bc, a
; Input: -
;==============================================================

RS_INIT_DMA:
	ld   hl, $C000
	ld   bc, $A0
	xor  a
	call RS_COPY_DATA
	jp 	 RS_DMA_COPY

;==============================================================
; Function: Update Player
; Description:
; Modified registers:
; Input: -
;==============================================================

RS_UPDATE_PLAYER:
	
	ld 	 e, pl_action 						;If the player's not making any action we won't check if we have to update it
	call EM_GET_PLAYER_VARIABLE
	and  MOVE_ACTION
	ret  z

	ld 	 e, pl_movementd 					;Check the actual direction of the movement
	call EM_GET_PLAYER_VARIABLE 			;If the movement is right, we will swap the sprites
	ld 	 b, a
	ld 	 e, pl_lastmov 						;Don't let to change the attributes if the last mov is the same as the actual
	call EM_GET_PLAYER_VARIABLE
	cp   b
	ret  z

	ld   a, b	
	cp   RIGHT_JP						 	
	jr 	 nz, .not_right

	ld 	 b, 1
	jp 	 EM_CHANGE_PL_ATTRIBUTES

.not_right:

	ld   b, 0
	jp 	 EM_CHANGE_PL_ATTRIBUTES

;==============================================================
; Function: Get Palette State
; Description:
; Modified registers:
; Input: -
;==============================================================

RS_GET_PAL_STATE: 
	
	ld 	 a, [_PAL_STATE]
	ret

;==============================================================
; Function: Fade Out
; Description:
; Modified registers:
; Input: -
;==============================================================

RS_FADE_OUT:

	ld 	 a, [_TIMER]
	dec  a
	ld 	 [_TIMER], a
	ret  nz

	call RS_INIT_CPU_TIMER

	ld 	 a, [_CPU] 							; Check if we have to make the fade on the GB or GBC
	or 	 a
	jr 	 z, .fade_out_gb 					; 1 equals GBC

	call RS_FADE_OUT_GBC
	jr 	 .fade_out_check_end

.fade_out_gb:

	ld 	 a, [rBGP] 							; Load Background Palette
	ld 	 b, a
	ld 	 a, [rOBP0] 						; Load Sprites Palette
	ld 	 c, a

	ld 	 d, 4 								; Use d as a counter.
	ld 	 e, 4

.fade_out_gb_loop:

	ld 	 a, b
	and  %00000011
	jr 	 z, .fade_out_gb_spr

	dec  b

.fade_out_gb_spr:
	
	ld 	 a, c
	and  %00000011
	jr 	 z, .fade_out_gb_both

	dec  c

.fade_out_gb_both:	 

	rlc  b 									; Swap 2 bits to the left in both palettes.
	rlc  b

	rlc  c
	rlc  c

	dec  d 									; Check counter
	jr 	 nz, .fade_out_gb_loop

	; Save the resulting palettes.

	ld 	 a, b
    ld   [rBGP], a   

    ld   a, c
    ld   [rOBP0], a

.fade_out_check_end:

    ld 	 a, [_PAL_COLORS]
    dec  a
    ld 	 [_PAL_COLORS], a
    ret  nz

    call RS_INIT_CPU_COLORS

    ld 	 a, 1
    ld 	 [_PAL_STATE], a

	ret

;==============================================================
; Function: Fade In
; Description:
; Modified registers:
; Input: -
;==============================================================

RS_FADE_OUT_GBC:
	
	ld 	 hl, _GBC_PAL_BCK
	call RS_GET_GBC_BCK_PAL 				; Get GBC Background Palette
	ld 	 hl, _GBC_PAL_BCK 					; Get again the initial memory address

	call rs_fade_out_gbc 					; Make a fade iteration on the selected palette

	ld 	 hl, _GBC_PAL_BCK
	call set_dp_param 						; Set the resulting palette.

	ld 	 hl, _GBC_PAL_SPR
	call RS_GET_GBC_SPR_PAL 				; Get GBC Sprites Palette
	ld 	 hl, _GBC_PAL_SPR 					; Get again the initial memory address

	call rs_fade_out_gbc 					; Make a fade iteration on the selected palette

	ld 	 hl, _GBC_PAL_SPR
	jp 	 set_sbp_param 						; Set the resulting Palette.

rs_fade_out_gbc::

    ld   a, 4
    ld   [_COUNT], a

rs_fade_out_gbc_init:

    ld   e, [hl]
    inc  hl
    ld   d, [hl]
    dec  hl

    ld   a, e
    cp   %11111111
    jr   nz, rs_fade_out_gbc_loop
    ld   a, d
    cp   %01111111
    jr   nz, rs_fade_out_gbc_loop

    jr   rs_fade_out_gbc_end

rs_fade_out_gbc_loop:

	; Red component.

    ld      a, e 							; GGGRRRRR
    and     %00011111 						; and = 000RRRRR
    cp      %00011111
    jr      z, rs_fade_out_palette_gbc_g

    inc     e 								; Increment red component.

rs_fade_out_palette_gbc_g:

	; Green component.

    ld      a, e
    swap    a 								; GGGRRRRR -> swap = RRRRGGGR
    rrc     a 								; rrc = RRRRRGGG
    and     %00000111 						; and = 00000GGG
    ld      b, a
    ld      a, d 							; 0BBBBBGG
    swap    a 								; swap = BBGG0BBB
    rrc     a 								; rrc = BBBGG0BB
    and     %00011000 						; and = 000GG000
    or      b 								; or  = 000GGGGG
    cp      %00011111

    jr      z, rs_fade_out_gbc_b
    inc     a 								; Increment green component.
    
    ld      b, a 							; b = 000GGGGG
    swap    a 								; a = GGGG000G
    rlc     a 								; a = GGG000GG
    and     %11100000 						; a = GGG00000
    ld      c, a 							; c = a
    ld      a, e 							; a = GGGRRRRR
    and     %00011111 						; a = 000RRRRR
    or      c 								; or -> a = [GGG]RRRRR
    ld      e, a 							; e = a
    ld      a, b 							; a = b = 000GGGGG
    rrc     a
    rrc     a
    rrc     a 								; a = GGG000GG
    and     %00000011 						; a = 000000GG
    ld      c, a 							; c = a
    ld      a, d 							; a = d = 0BBBBBGG
    and     %11111100 						; a = 0BBBBB00
    or      c 								; or -> a = 0BBBBBB[GG]
    ld      d, a 							; d = a

rs_fade_out_gbc_b:

    rrc     d
    rrc     d 								; d = GG0BBBBB
    ld      a, d 							; a = d
    and     %00011111 						; a = 000BBBBB
    cp      %00011111 						; a != 1? -> Increment d
    jr      z, rs_fade_out_gbc_save

    inc     d 								; Increment blue component.

rs_fade_out_gbc_save:

    rlc     d
    rlc     d 								; d = 0BBBBBGG

    ; Remember: save values in little-endian.

    ld      a, e
    ld      [hl], e 						; Save result in palette -> GGGRRRRR
    inc     hl
    ld      a, d 							; Save result in palette -> 0BBBBBGG
    ld      [hl], d
    inc     hl 								; Increment HL to get the next par of bytes.
    jr      rs_fade_out_gbc_check

rs_fade_out_gbc_end:

    inc     hl
    inc     hl

rs_fade_out_gbc_check:

    ld      a, [_COUNT]
    dec     a
    ld      [_COUNT], a
    jr      nz, rs_fade_out_gbc_init

    ret

;==============================================================
; Function: Fade In
; Description:
; Modified registers:
; Input: -
;==============================================================

RS_FADE_IN:

	ld 	 a, [_TIMER]
	dec  a
	ld 	 [_TIMER], a
	ret  nz

	call RS_INIT_CPU_TIMER

	ld 	 a, [_CPU] 							; Check if we have to make the fade on the GB or GBC
	or 	 a
	jr 	 z, .rs_fade_in_gb 					; 1 equals GBC

	call RS_FADE_IN_GBC
	jr 	 .rs_fade_in_check_end

.rs_fade_in_gb:

	; We have to fade both the background and sprites palettes.

    ld   a, BCK_PALETTE
    ld   c, a
    ld   a, [rBGP]
    ld   b, a

    call .rs_fade_in_start 					; Fade in the background palette
    ld 	 [rBGP], a 							; Set the resulting value

    ld   a, SPR_PALETTE
    ld   c, a
    ld   a, [rOBP0]
    ld   b, a
 	
 	call .rs_fade_in_start 					; Fade in the sprites palette
 	ld 	 [rOBP0], a 						; Set the resulting value

.rs_fade_in_check_end:

 	ld 	 a, [_PAL_COLORS] 					; Check if we have the original palette.
    dec  a
    ld 	 [_PAL_COLORS], a
    ret  nz

    call RS_INIT_CPU_COLORS

    xor  a 									; If we have all colors, set the palette state to 0.
    ld 	 [_PAL_STATE], a

    ret

.rs_fade_in_start:
	
	ld   d, 4        

.fade_in_gb_loop:

    ld 	 a, c
    and  %00000011
    ld   e, a
    
    ld   a, b
    and  %00000011
    cp   e
    jr   z, .fade_in_gb_both

    inc  b           

.fade_in_gb_both:

    rlc  b
    rlc  b

    rlc  c
    rlc  c

    dec  d
    jr   nz, .fade_in_gb_loop

    ld   a, b

    ret

;==============================================================
; Function: Fade In GBC
; Description:
; Modified registers:
; Input: -
;==============================================================

RS_FADE_IN_GBC:

	ld 	 hl, _GBC_PAL_BCK
	call RS_GET_GBC_BCK_PAL 				; Get GBC Background Palette
	ld 	 hl, _GBC_PAL_BCK 					; Get again the initial memory address
	ld 	 de, dungeon_palette

	call fade_in_palette_gbc 				; Make a fade iteration on the selected palette

	ld 	 hl, _GBC_PAL_BCK
	call set_dp_param 						; Set the resulting palette.

	ld 	 hl, _GBC_PAL_SPR
	call RS_GET_GBC_SPR_PAL 				; Get GBC Sprites Palette
	ld 	 hl, _GBC_PAL_SPR 					; Get again the initial memory address
	ld 	 de, sprite_palette

	call fade_in_palette_gbc 				; Make a fade iteration on the selected palette

	ld 	 hl, _GBC_PAL_SPR
	jp 	 set_sbp_param 						; Set the resulting Palette.

fade_in_palette_gbc:
    
 	push de

    ld 	 a, 4
    ld 	 [_COUNT], a

rs_fade_in_gbc_init:

    pop  de 								; de = original palette.
    push hl 								; hl = actual palette.

    ld   h, d 								; hl = original palette.
    ld   l, e

    inc  de
    inc  de 								; get the next 2 bytes of the original palette.

    ; Get original red component.

    ld   a, [hl] 							; a = GGGRRRRR
    and  %00011111 							; and = 000RRRRR
    ld   [_GBC_PAL_R], a 					; save red component in ram.

    ; Get original green component.

    ld   a, [hl] 							; a = GGGRRRRR
    and  %11100000	 						; a = GGG00000
    swap a 									; a = 0000GGG0
    rrc  a 									; a = 00000GGG
    ld   b, a 								; b = a
    inc  hl
    ld   a, [hl] 							; a = 0BBBBBGG
    and  %00000011 							; a = 000000GG
    swap a 									; a = 00GG0000
    rrc  a 									; a = 000GG000
    or   b 									; or = 000GGGGG
    ld   [_GBC_PAL_G], a 					; save green component in ram.

    ; Get original blue component.

    ld   a, [hl] 							; a = 0BBBBGG
    rrc  a 								
    rrc  a 									; a = GG0BBBB
    and  %00011111 							; a = 000BBBB
    ld   [_GBC_PAL_B], a 					; save blue component in ram.

    pop  hl 								; get back on HL the actual palette.

    push de 								; save on the stack the actual memory address of the original palette.
    push hl                                 ; save on the stack the actual memory address of the actual palette.
    
    ld   e, [hl] 							; save the new values on the actual palette.
    inc  hl
    ld   d, [hl]

	; Check red component.

    ld   a, e 								; a = GGGRRRRR
    and  %00011111 							; a = 000RRRRR
    ld   b, a 								; b = a
    
    ; Equal as original?

    ld   a, [_GBC_PAL_R]
    cp   b
    jr   z, rs_fade_in_gbc_g  				; If the component red is not equal as the original one, decrease it.

    dec  b
    ld 	 a, e 								; a = e = GGGRRRRR
    and  %11100000 							; a = GGG00000
    or 	 b 									; a = GGG[RRRRR]
    ld 	 e, a 								; e = a

rs_fade_in_gbc_g:

    ; Check green component.

    ld   a, e 								; a = GGGRRRRR
    swap a 									; a = RRRRGGGR
    rrc  a 									; a = RRRRRGGG
    and  %00000111 							; a = 00000GGG
    ld   b, a 								; b = a
    ld   a, d 								; a = 0BBBBBGG
    swap a 									; a = BBGG0BBB
    rrc  a 									; a = BBBGG0BB
    and  %00011000 							; a = 000GG000
    or   b 									; or -> a = 000GGGGG
    ld   b, a 								; b = a
	
    ; Equal as original?

    ld   a, [_GBC_PAL_G]
    cp   b
    jr   z, rs_fade_in_gbc_b 				; Equal = go to check blue component
    
    ld   a, b
    dec  a 									; Not equal = decrease it.
    
    ld   b, a 							
    swap a 									; a = GGGGG000
    rlc  a 									; a = GGGG000G
    and  %11100000 							; a = GGG00000
    ld   c, a 								; c = a
    ld   a, e 								; a = GGGRRRRR
    and  %00011111 							; a = 000RRRRR
    or   c 									; a = [GGG]RRRR -> saved new value
    ld   e, a 								; e = a
    ld   a, b 								; a = b = GGGGG000
    rrc  a 				
    rrc  a
    rrc  a 					 				; a = 000GGGGG		
    and  %00000011 							; a = 000000GG
    ld   c, a 								; c = a
    ld   a, d 								; a = 0BBBBBGG
    and  %11111100 							; a = 0BBBBB00
    or   c 									; a = 0BBBBB[GG] -> saved new value
    ld   d, a 								; d = a

rs_fade_in_gbc_b:

	; Check blue component.

	ld 	 a, d
    rrc  a							
    rrc  a 									; a = GG0BBBBB
    and  %00011111 							; a = 000BBBBB
    ld   b, a 								; b = a

    ; Equal as original?

    ld   a, [_GBC_PAL_B]
    cp   b
    jr   z, rs_fade_in_gbc_endloop 			; If components are equal don't decrease it.

    dec  b 									; If components are not equal decrease it.
    ld 	 a, d 								; d = 0BBBBBGG
    rrc  a 
    rrc  a 									; a = GG0BBBBB
    and  %11100000 							; a = GG000000
    or 	 b 									; a = GG0[BBBBB]
    rlc  a
    rlc  a 									; a = 0BBBBBGG
    ld 	 d, a 								; d = a

rs_fade_in_gbc_endloop:

    pop  hl

    ld   [hl], e 							; Save the new value on the actual palette.
    inc  hl
    ld   [hl], d 							; Save the new value on the actual palette.
    inc  hl

rs_fade_in_gbc_check:

    ld   a, [_COUNT]
    dec  a
    ld   [_COUNT], a
    jp   nz, rs_fade_in_gbc_init

    pop  de

    ret

;==============================================================
; Function: Get GBC background Palette
; Description:
; Modified registers:
; Input: hl (sprites or background actual palette)
;==============================================================

RS_GET_GBC_BCK_PAL:
	
	xor  a
	ld 	 [rBCPS], a 						; Initialize the array index with a 0
	ld 	 c, 8

.rs_get_gbc_bck_pal_loop:

	call RS_WAIT_MODE_01 					; Wait for H-Blank or V-Blank.
	ld 	 a, [rBCPD] 						; Get the value from the array. In c it would be like this -> value = rBCPD[rBCPS]
	ld 	 [hl+], a 							; Put the value on the input memory address and increase HL.

	dec  c 									; If c is not 0 continue with the loop.
	ret  z

	ld 	 a, [rBCPS] 						; Increment the array index. 
	inc  a
	ld 	 [rBCPS], a

	jr 	 .rs_get_gbc_bck_pal_loop

;==============================================================
; Function: Get GBC sprites Palette
; Description:
; Modified registers:
; Input: hl (sprites or background actual palette)
;==============================================================

RS_GET_GBC_SPR_PAL:
	
	xor  a
	ld 	 [rOCPS], a 						; Initialize the array index with a 0
	ld 	 c, 8

.rs_get_gbc_spr_pal_loop:

	call RS_WAIT_MODE_01 					; Wait for H-Blank or V-Blank.
	ld 	 a, [rOCPD] 						; Get the value from the array. In c it would be like this -> value = rBCPD[rBCPS]
	ld 	 [hl+], a 							; Put the value on the input memory address and increase HL.

	dec  c 									; If c is not 0 continue with the loop.
	ret  z

	ld 	 a, [rOCPS] 						; Increment the array index. 
	inc  a
	ld 	 [rOCPS], a

	jr 	 .rs_get_gbc_spr_pal_loop

;==============================================================
; Function: Update Floor Indicator Hud
; Description: Updates the floor indicator of the hud.
; Input: a (actual level)
; Modified registers: 
;==============================================================

RS_UPDATE_FLOOR_HUD:

	ld 	 b, 10
	ld 	 d, 0

rs_update_fh_dd:

	inc  d
	sub  b
	jr 	 nc, rs_update_fh_dd

	dec  d
	add  b
	ld 	 b, d
	ld 	 c, a

	; b = double digit, c = digit
	
	ld 	 hl, dma_hud
	ld 	 de, hud_spfn 						; double digit

	add  hl, de
	ld 	 a, TILE_NUM_0
	add  b
	ld 	 [hl], a

	ld 	 de, 4
	add  hl, de

	ld 	 a, TILE_NUM_0
	add  c
	ld 	 [hl], a

	ret

;==============================================================
; Function: Init Hud
; Description: Inits the hud with player life.
; Input: -
; Modified registers: 
;==============================================================

RS_INIT_HUD:

	ld 	 de, dma_hud
	ld   hl, hud_entities
	ld 	 bc, 32
	jp 	 RS_COPY_MEM

;==============================================================
; Function: Update Hud
; Description: Updates the hud taking player life as value. It
; uses a range of take-aways to calculate which tile needs to
; be set on each sprite.
; Input: -
; Modified registers: hl, de, bc, a
;==============================================================

RS_UPDATE_HP_HUD:
	
	; First, get the player actual life

	ld 	 e, pl_lifes
	call EM_GET_PLAYER_VARIABLE 			; Returns value in register a
	ld 	 b, a

	; Full Life = 73, Medium Life = 74, Empty Life = 75
	; Ranges are: 42-35 | 34 - 28 | 27 - 21 | 20 - 14 | 13 - 7 | 6 - 1 | 0
	; 			 	3F 		2F1M 	  2F1E 	   1F1M1E 	  1F2E 	 1M2E 	 3E

	ld 	 hl, dma_hud
	ld 	 de, hud_sp0n

	ld 	 a, 35
	sub  b 									; This take-away generates carry if we are above the range.
	jr 	 c, .rs_update_hud_3f

	ld 	 a, 28
	sub  b
	jr 	 c, .rs_update_hud_2f1m

	ld 	 a, 21
	sub  b
	jr 	 c, .rs_update_hud_2f1e

	ld 	 a, 14
	sub  b
	jr 	 c, .rs_update_hud_1f1m1e

	ld 	 a, 7
	sub  b
	jr 	 c, .rs_update_hud_1f2e

	ld 	 a, 1
	sub  b
	jr 	 c, .rs_update_hud_1m2e

	jr 	 .rs_update_hud_3e

.rs_update_hud_3f:

	add  hl, de
	ld 	 [hl], FULL_LIFE 					;spr0_hud_n
	ld 	 de, 4
	add  hl, de
	ld 	 [hl], FULL_LIFE 					;spr1_hud_n
	ld 	 de, 4
	add  hl, de
	ld 	 [hl], FULL_LIFE 					;spr2_hud_n
	ret

.rs_update_hud_2f1m:

	add  hl, de
	ld 	 [hl], FULL_LIFE 					;spr0_hud_n
	ld 	 de, 4
	add  hl, de
	ld 	 [hl], FULL_LIFE 					;spr1_hud_n
	ld 	 de, 4
	add  hl, de
	ld 	 [hl], MEDIUM_LIFE 					;spr2_hud_n
	ret

.rs_update_hud_2f1e:

	add  hl, de
	ld 	 [hl], FULL_LIFE 					;spr0_hud_n
	ld 	 de, 4
	add  hl, de
	ld 	 [hl], FULL_LIFE 					;spr1_hud_n
	ld 	 de, 4
	add  hl, de
	ld 	 [hl], EMPTY_LIFE 					;spr2_hud_n
	ret

.rs_update_hud_1f1m1e:

	add  hl, de
	ld 	 [hl], FULL_LIFE 					;spr0_hud_n
	ld 	 de, 4
	add  hl, de
	ld 	 [hl], MEDIUM_LIFE 					;spr1_hud_n
	ld 	 de, 4
	add  hl, de
	ld 	 [hl], EMPTY_LIFE 					;spr2_hud_n
	ret

.rs_update_hud_1f2e:

	add  hl, de
	ld 	 [hl], FULL_LIFE 					;spr0_hud_n
	ld 	 de, 4
	add  hl, de
	ld 	 [hl], EMPTY_LIFE 					;spr1_hud_n
	ld 	 de, 4
	add  hl, de
	ld 	 [hl], EMPTY_LIFE 					;spr2_hud_n
	ret

.rs_update_hud_1m2e:

	add  hl, de
	ld 	 [hl], MEDIUM_LIFE 					;spr0_hud_n
	ld 	 de, 4
	add  hl, de
	ld 	 [hl], EMPTY_LIFE 					;spr1_hud_n
	ld 	 de, 4
	add  hl, de
	ld 	 [hl], EMPTY_LIFE 					;spr2_hud_n
	ret

.rs_update_hud_3e:

	add  hl, de
	ld 	 [hl], EMPTY_LIFE 					;spr0_hud_n
	ld 	 de, 4
	add  hl, de
	ld 	 [hl], EMPTY_LIFE 					;spr1_hud_n
	ld 	 de, 4
	add  hl, de
	ld 	 [hl], EMPTY_LIFE 					;spr2_hud_n
	ret

;==============================================================
; Function: Draw Text
; Description: Draws the selected text in the second screen 
; (SCRN1) given an address.
; Input: a (box ID), b (item (in case ID = ITEM_BOX))
; Modified registers: all
;==============================================================

RS_DRAW_TEXT_BOX:

	ld   c, a
	ld 	 a, b
	ld 	 [_SAVER], a
	ld 	 a, c

	cp 	 ITEM_BOX
	jr	 nz, .draw_text_box_attack

	xor  a
	ld 	 [_COUNT], a
	jp 	 RS_DRAW_ITEM_BOX 					; Player got an item.

.draw_text_box_attack:

	cp 	 ATTACK_BOX
	jr	 nz, .draw_text_box_menu

	; THE PLAYER ATTACKED

	ret

.draw_text_box_menu:

	cp 	 MENU_BOX
	jr 	 nz, .draw_text_box_hungry

	jp 	 RS_DRAW_MENU_BOX 					; Player openned the menu.

.draw_text_box_hungry:

	cp 	 HUNGRY_BOX
	jr 	 nz, .draw_text_box_starving

	jp 	 RS_DRAW_HUNGRY_BOX

.draw_text_box_starving:

	cp 	 STARVING_BOX
	ret  nz

	jp 	 RS_DRAW_STARVING_BOX

draw_text_box_first_line:

	ld 	 c, 32
	jr 	 draw_text_box_line

draw_text_box_second_line:
	
	ld 	 c, 96
	jr 	 draw_text_box_line

draw_text_box_third_line:

	ld 	 c, 160
	jr 	 draw_text_box_line

draw_text_box_forth_line:

	ld 	 c, 224

draw_text_box_line:

	ld 	 hl, _SCRN1
	ld 	 b, 0
	add  hl, bc
	inc  hl
	inc  hl

	ld 	 d, h
	ld 	 e, l

	ret

;==============================================================
; Function: Draw Text With Sound
; Description: Draws the selected text in the second screen 
; (SCRN1) given an address.
; Input: hl (text ID), [_COUNT] (total bytes to draw),
; de (memory address to start writing), c (timer)
; Modified registers:
;==============================================================

RS_DRAW_TEXT_WS:

	push hl

	ld 	 hl, TEXT_SOUND
	call AS_PLAY_NOTE_CHANNEL_2

	pop  hl

	call RS_DRAW_LETTER

	ld 	 a, [_COUNT]
	dec  a
	ld 	 [_COUNT], a
	jr 	 nz, RS_DRAW_TEXT_WS

	ret

;==============================================================
; Function: Draw Text
; Description: Draws the selected text in the second screen 
; (SCRN1) given an address.
; Input: hl (text ID), [_COUNT] (total bytes to draw),
; de (memory address to start writing), c (timer)
; Modified registers:
;==============================================================

RS_DRAW_TEXT:

	call RS_DRAW_LETTER
	
	ld 	 a, [_COUNT]
	dec  a
	ld 	 [_COUNT], a
	jr 	 nz, RS_DRAW_TEXT

	ret

;==============================================================
; Function: Draw Letter
; Description: Draws the next letter in the second screen 
; (SCRN1) given an address.
; Input: hl (text ID), [_COUNT] (total bytes to draw),
; de (memory address to start writing), c (timer)
; Modified registers:
;==============================================================

RS_DRAW_LETTER:

	push hl

	ld 	 a, [_JUMP]
	ld 	 c, a
	call RS_DELAY_FRAMES

	pop  hl

	ld 	 bc, 1
	call RS_COPY_MEM 						; Input: hl (origen), de (destiny), bc (number of bytes)

	inc	 hl
	inc	 de

	ret


;==============================================================
; Function: Draw Window
; Description: Draws a window in the second screen (SCRN1) 
; given height and width.
; Input: d (height), e (width)
; Modified registers:
;==============================================================

RS_DRAW_WINDOW:

	; Calcule offset with the given width.
	; The total size of the screen is 32x32

	ld 	 a, 33
	sub  e
	ld 	 [_OFFSET], a
	
	ld 	 hl, _SCRN1

	; Each time we save a tile in the Screen we have to be sure we are in H-Blank or V-Blank.
	; Otherwise we will get visible trash.

	; We have to start with the right-up corner.
	call RS_WAIT_MODE_01 					; Modified registers:  a
	ld 	 [hl], CORNER_LU

	inc  hl

	; Now we have to put width - 2 times the WINDOW_UP tile.

	push de

	ld 	 d, e
	dec  d
	dec  d

.rs_draw_window_loop_up:

	ld 	 c, 1
	ld 	 b, 0
	call RS_WAIT_MODE_01 					; Modified registers:  a
	ld 	 a, WINDOW_UP
	call RS_COPY_DATA 						; Input: a(var), hl(origin), bc(number of bytes)
											; Modified registers: hl, bc, af, e
	dec  d
	jr 	 nz, .rs_draw_window_loop_up
	
	call RS_WAIT_MODE_01 					; Modified registers:  a
	ld 	 [hl], CORNER_RU
	
	ld 	 a, [_OFFSET]
	ld 	 e, a
	xor  a
	ld 	 d, a	 
	add  hl, de 							; Get to the next line.

	pop  de

	; For the end of the first line, we put CORNER_RU

	dec  d 									; Decrement b -> first line is done.

	; For the lines between top and bottom, we are gonna loop, because they are exactly the same
	; (WINDOW_LEFT - WHITE_TILE(N times) - WINDOW_RIGHT)
	; Also, for each line, we are gonna wait for H-Blank or V-Blank.


.rs_draw_window_loop:

	call RS_WAIT_MODE_01 					; Modified registers:  a
	ld 	 [hl], WINDOW_LEFT
	inc  hl

	push de
	ld 	 d, e
	dec  d
	dec  d

.rs_draw_window_loop_middle:

	ld 	 c, 1
	ld 	 b, 0
	call RS_WAIT_MODE_01 					; Modified registers:  a
	ld 	 a, WHITE_TILE
	call RS_COPY_DATA 						; Input: a(var), hl(origin), bc(number of bytes)
											; Modified registers: hl, bc, af, e
	dec  d
	jr 	 nz, .rs_draw_window_loop_middle

	call RS_WAIT_MODE_01 					; Modified registers:  a
	ld 	 [hl], WINDOW_RIGHT
	
	ld 	 a, [_OFFSET]
	ld 	 e, a
	xor  a
	ld 	 d, a	 
	add  hl, de 							; Get to the next line.

	pop  de

	dec  d
	ld 	 a, d
	dec  a 									; If a = 1, exit the loop. 
	jr 	 nz, .rs_draw_window_loop

	; Last line.

	call RS_WAIT_MODE_01 					; Modified registers:  a
	ld 	 a, CORNER_LD
	ld 	 [hl], a

	inc  hl

	; Now we have to put width - 2 times the WINDOW_UP tile.

	push de

	ld 	 d, e
	dec  d
	dec  d

.rs_draw_window_loop_down:

	ld 	 c, 1
	ld 	 b, 0
	call RS_WAIT_MODE_01 					; Modified registers:  a
	ld 	 a, WINDOW_DOWN
	call RS_COPY_DATA 						; Input: a(var), hl(origin), bc(number of bytes)
											; Modified registers: hl, bc, af, e
	dec  d
	jr 	 nz, .rs_draw_window_loop_down

	call RS_WAIT_MODE_01 					; Modified registers:  a
	ld 	 [hl], CORNER_RD
	pop  de

	ret

;==============================================================
; Function: Show _SCRN1
; Description: Turns on the second screen and puts it in the
; given XY coordinates
; Modified registers:
; Input: b (Y), c (X)
;==============================================================

RS_SHOW_SCRN1:

	;Turn on the second screen.

	ld a, [rLCDC]
	or LCDCF_WINON
	ld [rLCDC], a

	;Put the screen Y with the input value b.

	ld a, b
	ld [rWY], a

	;Put the screen X with the input value c.

	ld a, c
	ld [rWX], a
	
	ret

;==============================================================
; Function: Hide _SCRN1
; Modified registers: a
; Input: -
;==============================================================

RS_HIDE_SCRN1:
	
	ld 	 a, 1
	call PS_SET_UPDATE_ABSOLUTES

	ld 	 a, [rLCDC]
	and  LCDCF_WINOFFX
	ld   [rLCDC], a
	
	ret

;==============================================================
; Function: Make Text Box
; Modified registers: bc, a, de, hl
; Input: -
;==============================================================

RS_MAKE_TEXT_BOX:

	;Hide sprites

	ld 	 c, HIDE_TEXT
	ld 	 b, 0
	call RS_HIDE_SPRITES 			; Input: c (minimum Y), b (minimum X)

	ld 	 c, HIDE_TEXT
	ld 	 b, 0
	call RS_HIDE_PLAYER_SPRITE

	; Show menus
    
    ld 	 e, 20
    ld 	 d, 6
    call RS_DRAW_WINDOW 			; Input: d (height), e (width)

    ld 	 b, 95 						;Y coordinate
	ld 	 c, 7 						;X coordinate
	jr 	 RS_SHOW_SCRN1

;==============================================================
; Function: Draw Hungry Box
; Modified registers: all
; Input: -
;==============================================================

RS_DRAW_HUNGRY_BOX:

	call RS_MAKE_TEXT_BOX
	call draw_text_box_first_line

	ld 	 hl, Hungry_Text
	ld 	 a, End_Hungry_Text-Hungry_Text

	call rs_draw_text_box_values
	call IS_CHECK_PRESS_AB
	jp   RS_HIDE_SCRN1

rs_draw_text_box_values:

	ld 	 [_COUNT], a
	ld 	 a, 3
	ld 	 [_JUMP], a
	jp 	 RS_DRAW_TEXT_WS

;==============================================================
; Function: Draw Hungry Box
; Modified registers: all
; Input: -
;==============================================================

RS_DRAW_STARVING_BOX:

	call RS_MAKE_TEXT_BOX
	call draw_text_box_first_line

	ld 	 hl, Starving_Text
	ld 	 a, End_Starving_Text-Starving_Text

	call rs_draw_text_box_values

	call draw_text_box_second_line
	ld 	 hl, Starving_Text_2
	ld 	 a, End_Starving_Text_2-Starving_Text_2
	call rs_draw_text_box_values
	call IS_CHECK_PRESS_AB
	jp 	 RS_HIDE_SCRN1

;==============================================================
; Function: Draw Item Box
; Modified registers: all
; Input: [_SAVER], [_COUNT]
;==============================================================

RS_DRAW_ITEM_BOX:

	; THE PLAYER GOT AN ITEM.

	call RS_MAKE_TEXT_BOX

	; Draw the first sentence.
	call draw_text_box_first_line

	ld 	 a, [_COUNT]
	or 	 a 							; 0 = "Ashia got", 1 = "Ashia used"
	jr 	 z, rs_draw_item_box_got

	ld 	 hl, UseItem
	ld 	 a, End_UseItem-UseItem
	jr 	 rs_draw_item_box_second_line

rs_draw_item_box_got:

	ld 	 hl, Item
	ld 	 a, End_Item-Item

rs_draw_item_box_second_line:

	ld 	 [_COUNT], a
	ld 	 a, 3
	ld 	 [_JUMP], a
	call RS_DRAW_TEXT_WS

	; Now draw the name of the item the player got.
	call draw_text_box_second_line

	ld 	 a, [_SAVER]
	call TX_GET_ITEM_NAME
	ld 	 [_COUNT], a
	ld 	 a, 3
	ld 	 [_JUMP], a
	call RS_DRAW_TEXT_WS
	call IS_CHECK_PRESS_AB
	jp 	 RS_HIDE_SCRN1

;==============================================================
; Function: Draw Menu Box
; Modified registers: all
; Input: -
;==============================================================

RS_DRAW_MENU_BOX:

	; THE PLAYER OPENNED THE MENU

	;Hide sprites

	ld 	 c, YMIN_MENU
	ld 	 b, XMIN_MENU
	call RS_HIDE_SPRITES 			; Input: c (minimum Y), b (minimum X)

	ld 	 c, PL_YMIN_MENU
	ld 	 b, PL_XMIN_MENU
	call RS_HIDE_PLAYER_SPRITE

	; Show menus

	ld 	 a, 1
	ld 	 [_OPTION], a

.draw_text_box_menu_loop:

	ld 	 e, 8
    ld 	 d, 7
    call RS_DRAW_WINDOW 	; Input: d (height), e (width)

    ld 	 b, 88 				;Y coordinate
	ld 	 c, 103 			;X coordinate
	call RS_SHOW_SCRN1

	call draw_text_box_first_line 				; First Line = Items

	ld 	 hl, Items_Text
	ld 	 a, End_Items_Text-Items_Text
	ld 	 [_COUNT], a
	xor  a
	ld 	 [_JUMP], a
	call RS_DRAW_TEXT 							; Draw first line

	call draw_text_box_second_line 				; Second line = Save

	ld 	 hl, Save_Text
	ld 	 a, End_Save_Text-Save_Text
	ld 	 [_COUNT], a
	xor  a
	ld 	 [_JUMP], a
	call RS_DRAW_TEXT 							; Draw second line

	call draw_text_box_third_line 				; Third line = Exit

	ld 	 hl, Exit_Text
	ld 	 a, End_Exit_Text-Exit_Text
	ld 	 [_COUNT], a
	xor  a
	ld 	 [_JUMP], a 	
	call RS_DRAW_TEXT 							; Draw third line

	ld 	 a, [_OPTION]
	dec  a
	jr 	 z, .draw_text_cross_fl

	dec  a
	jr 	 z, .draw_text_cross_sl

	; OPTION = 3

	call draw_text_box_third_line
	jr 	 .draw_text_cross_done

.draw_text_cross_sl:

	; OPTION = 2

	call draw_text_box_second_line
	jr 	 .draw_text_cross_done

.draw_text_cross_fl:

	; OPTION = 1

	call draw_text_box_first_line

.draw_text_cross_done:

	dec  hl
	call RS_WAIT_MODE_01
	ld 	 [hl], CROSS_TILE

	; Now wait for inputs.
	ld 	 c, 10
	call RS_DELAY_FRAMES
	call IS_CHECK_MENU_BUTTONS 	; 0 = UP, 1 = DOWN, 2 = A.
	ld 	 a, c
	or 	 a
	jr 	 nz, .draw_text_cross_done_down

	; UP

	ld 	 hl, CROSS_SOUND
	call AS_PLAY_NOTE_CHANNEL_2

	ld 	 a, [_OPTION]
	dec  a
	jr 	 z, .draw_text_cross_reset_3
	jr 	 .draw_text_cross_go_loop

.draw_text_cross_reset_3:

	ld 	 a, 3
	jr 	 .draw_text_cross_go_loop

.draw_text_cross_done_down:
	
	dec  a
	jr 	 nz, .draw_text_cross_done_a

	;DOWN

	ld 	 hl, CROSS_SOUND
	call AS_PLAY_NOTE_CHANNEL_2

	ld 	 a, [_OPTION]
	cp   3
	jr 	 z, .draw_text_cross_reset_1
	inc  a
	jr 	 .draw_text_cross_go_loop

.draw_text_cross_reset_1:

	ld 	 a, 1

.draw_text_cross_go_loop:

	ld 	 [_OPTION], a
	jp 	 .draw_text_box_menu_loop

.draw_text_cross_done_a:

	ld 	 a, [_OPTION]
	cp 	 3
	jp 	 z, RS_HIDE_SCRN1
	cp   1
	jp 	 z, RS_DRAW_INVENTORY
	jp 	 .draw_text_box_menu_loop

;==============================================================
; Function: Draw Menu Box
; Modified registers: all
; Input: -
;==============================================================

RS_DRAW_INVENTORY:

	;Hide sprites

	ld 	 c, YMIN_INV
	ld 	 b, XMIN_INV
	call RS_HIDE_SPRITES 			; Input: c (minimum Y), b (minimum X)

	ld 	 c, PL_YMIN_INV
	ld 	 b, PL_XMIN_INV
	call RS_HIDE_PLAYER_SPRITE

	; Show menus

    ld 	 b, 72 									;Y coordinate
	ld 	 c, 111 								;X coordinate
	call RS_SHOW_SCRN1

	ld 	 a, 1
	ld 	 [_OPTION], a

rs_draw_inventory_loop:

	ld 	 e, 7
    ld 	 d, 9
    call RS_DRAW_WINDOW 						; Input: d (height), e (width)

	call draw_text_box_first_line 				; Get memory address to the forth line.
	; Draw Apple Icon
	ld 	 a, BASIC_APPLE
	call rs_draw_inventory_gettilenumber

	; We have to get the number of apples the player has.
	ld 	 b, d
	ld 	 c, e
	ld 	 e, pl_basapple
	call rs_draw_inventory_addnumber 			; Draw number of apples

	call draw_text_box_second_line 				; Get memory address to the forth line.
	; Draw Potion Icon
	ld 	 a, BASIC_POTION
	call rs_draw_inventory_gettilenumber

	; We have to get the number of potions the player has.
	ld 	 b, d
	ld 	 c, e
	ld 	 e, pl_baspotion
	call rs_draw_inventory_addnumber 			; Draw number of potions

	call draw_text_box_third_line 				; Get memory address to the forth line.
	; Draw Super Potion Icon
	ld 	 a, SUPER_POTION
	call rs_draw_inventory_gettilenumber

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;call RS_WAIT_MODE_01 						; Modified registers:  a

	; We have to get the number of super potions the player has.
	ld 	 b, d
	ld 	 c, e
	ld 	 e, pl_suppotion
	call rs_draw_inventory_addnumber 			; Draw number of potions

	call draw_text_box_forth_line 				; Get memory address to the forth line.
	ld 	 hl, Back_Text 							; Text is "Back"
	ld 	 a, End_Back_Text-Back_Text
	ld 	 [_COUNT], a
	xor  a
	ld 	 [_JUMP], a
	call RS_DRAW_TEXT 							; Draw forth line

	; NOW DRAW THE CROSS/POINTER

	ld 	 a, [_OPTION]
	dec  a
	jr 	 z, .draw_inventory_cross_fl

	dec  a
	jr 	 z, .draw_inventory_cross_sl

	dec  a
	jr 	 z, .draw_inventory_cross_tl

	; OPTION = 4
	call draw_text_box_forth_line
	jr 	 .draw_inventory_cross_done

.draw_inventory_cross_tl:

	; OPTION = 3

	call draw_text_box_third_line
	jr 	 .draw_inventory_cross_done

.draw_inventory_cross_sl:

	; OPTION = 2

	call draw_text_box_second_line
	jr 	 .draw_inventory_cross_done

.draw_inventory_cross_fl:

	; OPTION = 1

	call draw_text_box_first_line

.draw_inventory_cross_done:

	dec  hl
	call RS_WAIT_MODE_01
	ld 	 [hl], CROSS_TILE

	; THE INVENTORY IS DRAWN. Now we have to check for inputs (like we do with the general menu).

	ld 	 c, 10
	call RS_DELAY_FRAMES
	call IS_CHECK_MENU_BUTTONS 	; 0 = UP, 1 = DOWN, 2 = A.

	ld 	 a, c
	or 	 a
	jr 	 nz, .draw_inventory_cross_done_down

	; UP

	ld 	 hl, CROSS_SOUND
	call AS_PLAY_NOTE_CHANNEL_2

	ld 	 a, [_OPTION]
	dec  a
	jr 	 z, .draw_inventory_cross_reset_4
	jr 	 .draw_inventory_cross_go_loop

.draw_inventory_cross_reset_4:

	ld 	 a, 4
	jp 	 .draw_inventory_cross_go_loop

.draw_inventory_cross_done_down:

	dec  a
	jr 	 nz, .draw_inventory_cross_done_a

	; DOWN

	ld 	 hl, CROSS_SOUND
	call AS_PLAY_NOTE_CHANNEL_2

	ld 	 a, [_OPTION]
	cp   4
	jr 	 z, .draw_inventory_cross_reset_1
	inc  a
	jr 	 .draw_inventory_cross_go_loop

.draw_inventory_cross_reset_1:

	ld 	 a, 1

.draw_inventory_cross_go_loop:

	ld 	 [_OPTION], a
	jp 	 rs_draw_inventory_loop

.draw_inventory_cross_done_a:

	; THE PLAYER PRESSED A, so we check at which option he did.

	ld 	 a, [_OPTION]
	cp 	 1
	jp 	 z, rs_draw_inventory_check_apples
	cp   2
	jp 	 z, rs_draw_inventory_check_potions
	cp 	 3
	jp 	 z, rs_draw_inventory_check_spotions
	jp 	 RS_DRAW_MENU_BOX

rs_draw_inventory_check_apples:
	
	ld 	 e, pl_basapple
	call EM_GET_PLAYER_VARIABLE
	or 	 a
	jp 	 z, rs_draw_inventory_loop 				; If we have no apples, we do nothing.

	; We have apples -> decrease number of it.
	ld 	 b, BASIC_APPLE
	call rs_draw_inventory_show_used_window 	; Show that the user used the item selected.

	; Reset Player's Hunger
	jp 	 EM_RESET_PLAYER_HUNGER

rs_draw_inventory_check_potions:

	ld 	 e, pl_baspotion
	call EM_GET_PLAYER_VARIABLE
	or 	 a
	jp 	 z, rs_draw_inventory_loop 				; If we have no potions, we do nothing.

	; We have potions -> make sure the player wants to use them.
	ld 	 b, BASIC_POTION
	call rs_draw_inventory_show_used_window 	; Show that the user used the item selected.

	ld 	 a, 21
	jp 	 EM_ADD_PLAYER_HEALTH

rs_draw_inventory_check_spotions:

	ld 	 e, pl_suppotion
	call EM_GET_PLAYER_VARIABLE
	or 	 a
	jp 	 z, rs_draw_inventory_loop 				; If we have no super potions, we do nothing.

	; We have super potions -> make sure the player wants to use them.
	ld 	 b, SUPER_POTION
	call rs_draw_inventory_show_used_window 	; Show that the user used the item selected.

	ld 	 a, 42
	jp 	 EM_ADD_PLAYER_HEALTH

rs_draw_inventory_show_used_window:

	dec  a
	ld 	 [hl], a 								; We have the memory address of the item.

	ld 	 a, b
	ld 	 [_SAVER], a
	ld 	 a, 1
	ld 	 [_COUNT], a
	jp   RS_DRAW_ITEM_BOX

rs_draw_inventory_gettilenumber:
	
	ld 	 b, a
	call RS_WAIT_MODE_01 						; Modified registers:  a
	ld 	 a, b
	ld 	 [de], a
	inc  de
	ld 	 a, TILE_LET_X
	ld 	 [de], a
	ret

rs_draw_inventory_addnumber:

	call EM_GET_PLAYER_VARIABLE 				; a = Number of apples
	ld 	 d, TILE_NUM_0
	add  d										; Tile_0 + number of apples
	inc  bc
	ld 	 d, a
	call RS_WAIT_MODE_01 						; Modified registers:  a
	ld 	 a, d
	ld 	 [bc], a
	ret

;==============================================================
; Function: Hide Player Sprite
; Description: 255 means hide nothing. 0 means hide everything.
; Modified registers: all
; Input: c (minimum Y), b (minimum X)
;==============================================================

RS_HIDE_PLAYER_SPRITE:
	
	ld 	 de, _OAMRAM
	ld   a, 4
	ld 	 [_COUNT2], a
	ld 	 a, 1

	jr 	 rs_hide_sprites_start

;==============================================================
; Function: Hide Enemy & Blocks Sprites
; Description: 255 means hide nothing. 0 means hide everything.
; Modified registers: all
; Input: c (minimum Y), b (minimum X)
;==============================================================

RS_HIDE_SPRITES:

	xor  a
	call PS_SET_UPDATE_ABSOLUTES

	ld 	 a, 4
	ld 	 [_COUNT2], a
	call EM_GET_ENEMIES_ARRAY 					; Output: a (number of enemies), hl (enemies array), de (dma array)
	call rs_hide_sprites_start

	ld 	 a, 1
	ld 	 [_COUNT2], a
	call EM_GET_BLOCKS_ARRAY
	call rs_hide_sprites_start

	jp 	 RS_DRAW

rs_hide_sprites_start:

	or 	 a
	ret  z

	ld 	 [_JUMP], a
	ld 	 a, [_COUNT2]
	ld 	 [_OFFSET], a

	ld 	 h, d
	ld 	 l, e 									; HL = DMA Enemies

rs_hide_sprites_loop:

	ld 	 a, [hl] 								; HL = Y component
	sub  c 	 									; E_Y - Minimum_Y
	jr 	 c, rs_hide_sprites_next_y

	inc  hl
	ld 	 a, [hl]
	sub  b
	jr 	 c, rs_hide_sprites_next_x

	; We have to hide the sprite

	xor  a
	ld   [hl], a 								; X = 0
	dec  hl
	ld 	 [hl], a 								; Y = 0
	
rs_hide_sprites_next_y:

	ld 	 d, 0
	ld 	 e, 4
	jr 	 rs_hide_sprites_check

rs_hide_sprites_next_x:
	
	ld 	 d, 0
	ld 	 e, 3

rs_hide_sprites_check:

	add  hl, de

	ld 	 a, [_OFFSET]
	dec  a
	ld 	 [_OFFSET], a
	jr 	 z, rs_hide_sprites_next_entity
	jr 	 rs_hide_sprites_loop

rs_hide_sprites_next_entity:

	ld 	 a, [_COUNT2]
	ld 	 [_OFFSET], a

	ld 	 a, [_JUMP]
	dec  a
	ld 	 [_JUMP], a
	jr 	 nz, rs_hide_sprites_loop

	jp 	 RS_WAIT_VBLANK

;==============================================================
; Description: This section of code is for all the tilemaps
; included and palettes. We can copy all the data from these 
; to the screen in a directly manner.
;==============================================================

SECTION "Video_Graphics", ROMX

;==============================================================
; Palettes
;==============================================================

dungeon_palette:
DB  $0F, $0F, $32, $AF, $07, $06, $02, $10

sprite_palette:
DB $00, $00, $FF, $FF, $0F, $05, $02, $10

;==============================================================
; Tiles
;==============================================================

Persistent_Tiles:
	INCLUDE "./TILES/persistent_tiles.z80"
Persistent_Tiles_End:

Overworld_Tiles:
	INCLUDE "./TILES/overworld_tiles.z80"
Overworld_Tiles_End:

Dungeon_Tiles:
	INCLUDE "./TILES/dungeon_tiles.z80"
Dungeon_Tiles_End:

Title_Screen_Tiles:
	INCLUDE "./TILES/title_screen_tiles.z80"
Title_Screen_Tiles_End:


;==============================================================
; Tilemaps
;==============================================================

MenuMapTiles:
	INCLUDE "./TILES/title_screen_map.z80"
Fin_MenuMapTiles:

Floor1:
	INCLUDE "./TILES/floor1.z80"
Fin_Floor1:

Floor2:
	INCLUDE "./TILES/floor2.z80"
Fin_Floor2:

Floor3:
	INCLUDE "./TILES/floor3.z80"
Fin_Floor3:

Overworld:
	INCLUDE "./TILES/overworld_map.z80"
Fin_Overworld:

House:
	INCLUDE "./TILES/house.z80"
Fin_House: