;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol MArtínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

	INCLUDE "hardware.inc"
	INCLUDE "audio_system_h.inc"
    INCLUDE "constants.inc"

SECTION "AS_Data", WRAM0

_NOTA:          DS 2
_NOTA2:         DS 2
_INIT_NOTE:     DS 2
_INIT_NOTE2:    DS 2
_CONTEMPO:      DS 1
_ID:            DS 1

SECTION "AudioSystem", ROM0

;==============================================================
; Function: Init Audio System
; Description:
; Modified registers:
; Input: -
;==============================================================

AS_INIT:

	ld   a, _TEMPO
	ld   [_CONTEMPO], a
	
	ld   a, %01110111 		
	ld   [rNR50], a 			;-LLL-RRR channel max volume

	ld   a, %10011010
	ld   [rNR51], a 			;Mixer LLLLRRRR Channel 1-4L / Channel 1-4R

    ld   hl, TITLE_SCREEN2
    ld   a, h
    ld   [_NOTA2+1], a
    ld   [_INIT_NOTE2+1], a
    ld   a, l
    ld   [_INIT_NOTE2], a
    ld   [_NOTA2], a

    ld   hl, TITLE_SCREEN1
    xor  a
    call AS_SET_ID

    ld   a, _SILENCE
    ld   [rNR14], a             
    ld   [rNR24], a

	ret

;==============================================================
; Function: Set Music ID
; Description:
; Modified registers:
; Input: a, hl (song)
;==============================================================

AS_SET_ID:

    ld   [_ID], a

    ld   a, h
    ld   [_NOTA+1], a
    ld   [_INIT_NOTE+1], a
    ld   a, l
    ld   [_INIT_NOTE], a
    ld   [_NOTA], a

    ; Turn off actual sounds
    ld   hl, RESET_SOUND
    jr   AS_PLAY_NOTE_CHANNEL_1

;==============================================================
; Function: Update Audio System
; Description:
; Modified registers:
; Input: -
;==============================================================

AS_UPDATE:

	ld   a, [_CONTEMPO]          ; vemos si hay que tocar la nota o esperar
    cp   a, _TEMPO
        
    jr   z, as_update_play

    inc  a
    ld   [_CONTEMPO], a
    ret

as_update_play:

    ; reset tempo counter
    xor   a
    ld    [_CONTEMPO], a
    
    ld   a, [_ID]
    or   a
    jr   z, as_update_title_screen

    dec  a
    jr   nz, as_update_dungeon_music

    ret

as_update_title_screen:

    ld   bc, END_TITLE_SCREEN1
    call AS_PLAY_MUSIC_CHANNEL_1

    ld   bc, END_TITLE_SCREEN2
    jp   AS_PLAY_MUSIC_CHANNEL_2

as_update_dungeon_music:

    ld   bc, END_DUNGEON1
    jr   AS_PLAY_MUSIC_CHANNEL_1

;==============================================================
; Function: Play Music On Channel 1
; Description:
; Modified registers:
; Input: -
;==============================================================

AS_PLAY_MUSIC_CHANNEL_1:

    ld   a, [_NOTA]              
    ld   l, a                    
    ld   a, [_NOTA+1]
    ld   h, a
    ld   a, [hl]                 

    cp   _KEEPNOTE
    jr   z, as_note_end_keep

    call AS_PLAY_NOTE_CHANNEL_1

as_note_end_keep:

    inc  hl

    push hl

    ld   a, h
    sub  b
    jr   nz, as_note_end_not_reset

    ld   a, l
    sub  c
    jr   z, as_note_end_reset

as_note_end_not_reset:

    pop  hl
 
    ld   a, l
    ld   [_NOTA], a
    ld   a, h
    ld   [_NOTA+1], a

    ret

as_note_end_reset:

    pop hl

    ld   a, [_INIT_NOTE]
    ld   [_NOTA], a
    ld   a, [_INIT_NOTE+1]
    ld   [_NOTA+1], a

    ret

;==============================================================
; Function: Play Note On Channel 1
; Description:
; Modified registers:
; Input: hl (firts value memory address)
;==============================================================

AS_PLAY_NOTE_CHANNEL_1:

    ld   a, [hl]
    ld   [rNR10], a
    inc  hl
    ld   a, [hl]
    ld   [rNR11], a
    inc  hl
    ld   a, [hl]
    ld   [rNR12], a
    inc  hl
    ld   a, [hl]
    ld   [rNR13], a              
    inc  hl
    ld   a, [hl]
    ld   [rNR14], a

    ret

;==============================================================
; Function: Play Music On Channel 2
; Description:
; Modified registers:
; Input: -
;==============================================================

AS_PLAY_MUSIC_CHANNEL_2:

    ld   a, [_NOTA2]              
    ld   l, a                    
    ld   a, [_NOTA2+1]
    ld   h, a
    ld   a, [hl]                 

    cp   _KEEPNOTE
    jr   z, as_note_end_keep_2

    call AS_PLAY_NOTE_CHANNEL_2

as_note_end_keep_2:

    inc  hl

    push hl

    ld   a, h
    sub  b
    jr   nz, as_note_end_not_reset_2

    ld   a, l
    sub  c
    jr   z, as_note_end_reset_2

as_note_end_not_reset_2:

    pop  hl
 
    ld   a, l
    ld   [_NOTA2], a
    ld   a, h
    ld   [_NOTA2+1], a

    ret

as_note_end_reset_2:

    pop hl

    ld   a, [_INIT_NOTE2]
    ld   [_NOTA2], a
    ld   a, [_INIT_NOTE2+1]
    ld   [_NOTA2+1], a

    ret

;==============================================================
; Function: Play Note On Channel 2
; Description:
; Modified registers:
; Input: hl (firts value memory address)
;==============================================================

AS_PLAY_NOTE_CHANNEL_2:
    
    ld   a, [hl]
    ld   [rNR21], a
    inc  hl
    ld   a, [hl]
    ld   [rNR22], a
    inc  hl
    ld   a, [hl]
    ld   [rNR23], a              
    inc  hl
    ld   a, [hl]
    ld   [rNR24], a

    ret

;==============================================================
; Function: Play Note On Channel 4
; Description:
; Modified registers:
; Input: hl (firts value memory address)
;==============================================================

AS_PLAY_NOTE_CHANNEL_4:
    
    ld   a, [hl]
    ld   [rNR41], a
    inc  hl
    ld   a, [hl]
    ld   [rNR42], a
    inc  hl
    ld   a, [hl]
    ld   [rNR43], a              
    inc  hl
    ld   a, [hl]
    ld   [rNR44], a

    ret

;==============================================================
; Songs data
;==============================================================

TITLE_SCREEN1:
    DB $00, $00, $00, _SILENCE, _SILENCE
    DB $00, $00, $00, _SILENCE, _SILENCE
    DB $00, $81, $4B, _A, _OCT6_NR
    DB _KEEPNOTE
    DB $00, $8A, $47, _G, _OCT6_NR
    DB $00, $00, $00, _SILENCE, _SILENCE
    DB $00, $81, $4B, _C, _OCT7_NR 
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _A, _OCT6_NR
    DB _KEEPNOTE
    DB $00, $81, $4B, _F, _OCT6_NR
    DB $00, $81, $4B, _A, _OCT6_NR
    DB $00, $81, $4B, _E, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _G, _OCT6_NR
    DB _KEEPNOTE
    DB $00, $8A, $47, _F, _OCT6_NR
    DB $00, $00, $00, _SILENCE, _SILENCE
    DB $00, $81, $4B, _B, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _G, _OCT6_NR
    DB _KEEPNOTE
    DB $00, $81, $4B, _E, _OCT6_NR
    DB $00, $81, $4B, _G, _OCT6_NR
    DB $00, $81, $4B, _D, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _A, _OCT6_NR
    DB _KEEPNOTE
    DB $00, $8A, $47, _G, _OCT6_NR
    DB $00, $00, $00, _SILENCE, _SILENCE
    DB $00, $81, $4B, _C, _OCT7_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, $20, _OCT7_NR
    DB $00, $81, $4B, $30, _OCT7_NR
    DB $00, $81, $4B, $20, _OCT7_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _C, _OCT7_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _G, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _C, _OCT6_NR
    DB $00, $81, $4B, _D, _OCT6_NR
    DB $00, $81, $4B, _G, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _D, _OCT6_NR
    DB $00, $81, $4B, _C, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $00, $00, _SILENCE, _SILENCE
    DB $00, $81, $4B, _A, _OCT6_NR
    DB _KEEPNOTE
    DB $00, $8A, $47, _G, _OCT6_NR
    DB $00, $00, $00, _SILENCE, _SILENCE
    DB $00, $81, $4B, _C, _OCT7_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _A, _OCT6_NR
    DB _KEEPNOTE
    DB $00, $8A, $47, _G, _OCT6_NR
    DB $00, $00, $00, _SILENCE, _SILENCE
    DB $00, $81, $4B, _A, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _C, _OCT7_NR
    DB $00, $81, $4B, _D, _OCT7_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, $54, _OCT7_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
END_TITLE_SCREEN1:

TITLE_SCREEN2:
    DB $84, $84, _C, _OCT3
    DB $84, $84, _F, _OCT3 
    DB $84, $84, _G, _OCT3
    DB $84, $84, _C, _OCT3
END_TITLE_SCREEN2:

DUNGEON1::
    DB $00, $81, $4B, _F, _OCT6_NR
    DB $00, $81, $4B, _B, _OCT6_NR
    DB $00, $81, $4B, _F, _OCT6_NR
    DB $00, $81, $4B, _E, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _F, _OCT6_NR
    DB $00, $81, $4B, _B, _OCT6_NR
    DB $00, $81, $4B, _F, _OCT6_NR
    DB $00, $81, $4B, _E, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _D, _OCT6_NR
    DB $00, $81, $4B, _A, _OCT6_NR
    DB $00, $81, $4B, _D, _OCT6_NR
    DB $00, $81, $4B, _C, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _D, _OCT6_NR
    DB $00, $81, $4B, _A, _OCT6_NR
    DB $00, $81, $4B, _D, _OCT6_NR
    DB $00, $81, $4B, _C, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _F, _OCT6_NR
    DB $00, $81, $4B, _B, _OCT6_NR
    DB $00, $81, $4B, _F, _OCT6_NR
    DB $00, $81, $4B, _E, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _F, _OCT6_NR
    DB $00, $81, $4B, _B, _OCT6_NR
    DB $00, $81, $4B, _F, _OCT6_NR
    DB $00, $81, $4B, _E, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _D, _OCT6_NR
    DB $00, $81, $4B, _A, _OCT6_NR
    DB $00, $81, $4B, _D, _OCT6_NR
    DB $00, $81, $4B, _C, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _D, _OCT6_NR
    DB $00, $81, $4B, _A, _OCT6_NR
    DB $00, $81, $4B, _D, _OCT6_NR
    DB $00, $81, $4B, _C, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _A, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _B, _OCT6_NR
    DB _KEEPNOTE
    DB $00, $81, $4B, _G, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _F, _OCT6_NR
    DB _KEEPNOTE
    DB $00, $81, $4B, _G, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _A, _OCT6_NR
    DB _KEEPNOTE
    DB $00, $81, $4B, _F, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _F, _OCT6_NR      ; second chorus
    DB $00, $81, $4B, _B, _OCT6_NR
    DB $00, $81, $4B, _F, _OCT6_NR
    DB $00, $81, $4B, _E, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _F, _OCT6_NR
    DB $00, $81, $4B, _B, _OCT6_NR
    DB $00, $81, $4B, _F, _OCT6_NR
    DB $00, $81, $4B, _E, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _D, _OCT6_NR
    DB $00, $81, $4B, _A, _OCT6_NR
    DB $00, $81, $4B, _D, _OCT6_NR
    DB $00, $81, $4B, _C, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _D, _OCT6_NR
    DB $00, $81, $4B, _A, _OCT6_NR
    DB $00, $81, $4B, _D, _OCT6_NR
    DB $00, $81, $4B, _C, _OCT6_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _C, _OCT7_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _D, _OCT7_NR
    DB _KEEPNOTE
    DB $00, $81, $4B, _E, _OCT7_NR
    DB _KEEPNOTE
    DB $00, $81, $4B, _F, _OCT7_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _E, _OCT7_NR
    DB _KEEPNOTE
    DB $00, $81, $4B, _D, _OCT7_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _D, _OCT7_NR  
    DB _KEEPNOTE
    DB $00, $81, $4B, _C, _OCT7_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _F, _OCT7_NR
    DB _KEEPNOTE
    DB $00, $81, $4B, _E, _OCT7_NR
    DB _KEEPNOTE
    DB $00, $81, $4B, _D, _OCT7_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _F, _OCT7_NR
    DB _KEEPNOTE
    DB $00, $81, $4B, _E, _OCT7_NR
    DB _KEEPNOTE
    DB $00, $81, $4B, _C, _OCT7_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _C, _OCT7_NR
    DB $00, $81, $4B, _D, _OCT7_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB $00, $81, $4B, _E, _OCT7_NR
    DB $00, $81, $4B, _D, _OCT7_NR
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
    DB _KEEPNOTE
END_DUNGEON1::

; CHANNEL 1

RESET_SOUND::
    DB _SILENCE, _SILENCE, _SILENCE, _SILENCE, _SILENCE
END_RESET_SOUND::

; CHANNEL 2

OBJECT_SOUND::
    DB $81, $84, $CD, $87
TEXT_OBJECT_SOUND::

OBSTACLE_SOUND::
    DB $81, $84, $B3, $82
END_OBSTACLE_SOUND::

CROSS_SOUND::
    DB $81, $84, $B9, $86
END_CROSS_SOUND::

TEXT_SOUND::
    DB $81, $84, $95, $87
END_TEXT_SOUND::

; CHANNEL 4

DAMAGE_SOUND::
    DB $00, $F1, $61, $C0
END_DAMAGE_SOUND::

DOOR_SOUND::
    DB $00, $A1, $34, $C0
END_SOUND_SOUND::