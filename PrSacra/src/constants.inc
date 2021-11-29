;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

A_BUTTON 		EQU %00000001
B_BUTTON 		EQU %00000010
SELECT 			EQU %00000100
START 			EQU %00001000
RIGHT_JP 		EQU %00010000
LEFT_JP 		EQU %00100000
UP_JP 			EQU %01000000
DOWN_JP 		EQU %10000000

BCK_PALETTE 	EQU %11100001 			; GB background palette
SPR_PALETTE 	EQU %11100010 			; GB sprite palette

GBC 			EQU $11

ATTACK_ACTION 	EQU %00000001
MOVE_ACTION 	EQU %00000010
SWAP_ACTION 	EQU %00000100
STAND_ACTION 	EQU %00001000
WAIT_ACTION 	EQU %00010000

ANIM_TIME 		EQU 10
ANIM_LR_DEFAULT EQU 63
ANIM_U_DEFAULT  EQU 51
ANIM_D_DEFAULT  EQU 39
ANIM_A_UP 		EQU 71
ANIM_A_LR 		EQU 75
ANIM_A_DOWN 	EQU 79

EN_ANIM_D_DEF 	EQU 0
EN_ANIM_U_DEF 	EQU 4
EN_ANIM_LR_DEF 	EQU 8
EN_ANIM_LR_2 	EQU 12

RIGHT_ATTRIBUTE EQU %00100000
LEFT_ATTRIBUTE  EQU %11011111
AND_LEFT 		EQU 0
OR_RIGHT 		EQU 1
XOR_RIGHT 		EQU 2

FLOOR_TILE 		EQU 119
WALL_TILE 		EQU 118
STAIRS1_TILE	EQU 96
STAIRS2_TILE 	EQU 97
STAIRS3_TILE 	EQU 98
DOOR1_TILE		EQU 104
DOOR2_TILE		EQU 100
WOOD_TILE 		EQU 125
CARPET_TILE 	EQU 142

OVERWORLD_STATE EQU 0
DUNGEON_STATE 	EQU 1
HOUSE_STATE 	EQU 2
TRANSIT_STATE 	EQU 3
ITEMS_STATE 	EQU 4
GAMEMENU_STATE 	EQU 5

MAX_SCROLLX 	EQU 97
MAX_SCROLLY 	EQU 111

FULL_LIFE 		EQU 100
MEDIUM_LIFE 	EQU 101
EMPTY_LIFE 	 	EQU 102

MAX_ENTITIES 	EQU 4
MAX_BLOCKS 		EQU 4
TILE_COORDS 	EQU 2

TILE_LET_A 		EQU 0
TILE_LET_X 		EQU 23
TILE_NUM_0 		EQU 26

BASIC_POTION 	EQU 93
SUPER_POTION 	EQU 94
BASIC_APPLE 	EQU 95

WHITE_TILE 		EQU 83
CROSS_TILE 		EQU 92

CORNER_LU 		EQU 84
CORNER_RU 		EQU 85
CORNER_LD 		EQU 86
CORNER_RD 		EQU 87
WINDOW_UP 		EQU 88
WINDOW_DOWN 	EQU 89
WINDOW_RIGHT 	EQU 90
WINDOW_LEFT 	EQU 91

ATTACK_BOX 		EQU 0
MENU_BOX 		EQU 1
ITEM_BOX 		EQU 2
INVENTORY_BOX 	EQU 3
HABILITIES_BOX 	EQU 4
DAMAGE_BOX 		EQU 5
HUNGRY_BOX 		EQU 6
STARVING_BOX 	EQU 7

PL_MAX_HUNGER 	EQU 100

SKULL_ENEMY 	EQU 120
THIEF_ENEMY 	EQU 136
ORC_ENEMY 		EQU 152
ARMOR_ENEMY 	EQU 168


_TEMPO 			EQU 17
_SILENCE 		EQU %01000000
_KEEPNOTE 		EQU 1
_OCT0			EQU %11000000
_OCT1 			EQU %11000001
_OCT2 			EQU %11000010
_OCT3 			EQU %11000011
_OCT4 			EQU %11000100
_OCT5 			EQU %11000101
_OCT6  			EQU %11000110
_OCT7  			EQU %11000111
_OCT0_NR		EQU %10000000
_OCT1_NR 		EQU %10000001
_OCT2_NR 		EQU %10000010
_OCT3_NR 		EQU %10000011
_OCT4_NR 		EQU %10000100
_OCT5_NR 		EQU %10000101
_OCT6_NR  		EQU %10000110
_OCT7_NR  		EQU %10000111
_C 				EQU $0A
_D 				EQU $42
_E 				EQU $72
_F				EQU $89 				
_G				EQU $B2
_A				EQU $D6
_B				EQU $F7

HIDE_TEXT 		EQU $70
YMIN_INV 		EQU $59
XMIN_INV 		EQU $77
YMIN_MENU 		EQU $68
XMIN_MENU 		EQU $68
PL_YMIN_INV 	EQU $59
PL_XMIN_INV 	EQU $6F
PL_YMIN_MENU 	EQU $68
PL_XMIN_MENU 	EQU $67

SIGHT_RADIUS 	EQU 5

;==============================================================
; Compilation time constants
;==============================================================

player_size 	equ 10 	; Lifes, TileX, TileY, MovementDirection, LastMovement, Action, Hunger, BasicPotions, SuperPotions, BasicApples.
tile_size 		equ 8
enemy_size      equ 12 	; AbsY, AbsX, Lifes, TileX, TileY, MovementDirection, Action, DefaultSprite, Damage, Velocity, DMA Address [x2] (Little Endian)
enemy_noptr 	equ 10
enemy_nodma 	equ 8
entity_dma_size equ 16
block_size  	equ 7 	; AbsY, AbsX, Type, TileX, TileY, DMA Address [x2] (Little Endian).
block_dma_size 	equ 4
block_noptr 	equ 5
block_nodma 	equ 2

pl_lifes 		equ 0
pl_tilex 		equ 1
pl_tiley 		equ 2
pl_movementd 	equ 3
pl_lastmov 		equ 4
pl_action 		equ 5
pl_hunger 	 	equ 6
pl_baspotion 	equ 7
pl_suppotion 	equ 8
pl_basapple 	equ 9

en_abs_y 		equ 0
en_abs_x 		equ 1
en_lifes 		equ 2
en_tilex 		equ 3
en_tiley 		equ 4
en_movementd 	equ 5
en_action 		equ 6
en_defsprite 	equ 7
en_damage 		equ 8
en_velocity 	equ 9
en_dma_l 		equ 10
en_dma_h 		equ 11

pl_sp0y 		equ 0
pl_sp0x 		equ 1
pl_sp0n 		equ 2
pl_sp0a 		equ 3
pl_sp1y 		equ 4
pl_sp1x 		equ 5
pl_sp1n 		equ 6
pl_sp1a 		equ 7
pl_sp2y 		equ 8
pl_sp2x 		equ 9
pl_sp2n 		equ 10
pl_sp2a 		equ 11
pl_sp3y 		equ 12
pl_sp3x 		equ 13
pl_sp3n 		equ 14
pl_sp3a 		equ 15

hud_sp0y 		equ 8
hud_sp0x 		equ 9
hud_sp0n 		equ 10
hud_sp0a 		equ 11
hud_sp1y		equ 12
hud_sp1x 		equ 13
hud_sp1n 		equ 14
hud_sp1a 		equ 15
hud_sp2y 		equ 16
hud_sp2x 		equ 17
hud_sp2n 		equ 18
hud_sp2a 		equ 19
hud_spfy 		equ 24
hud_spfx 		equ 25
hud_spfn 		equ 26
hud_spfa 		equ 27
hud_spf2y 		equ 28
hud_spf2x 		equ 29
hud_spf2n 		equ 30
hud_spf2a 		equ 31

block_abs_y 	equ 0
block_abs_x 	equ 1
block_type 	 	equ 2
block_tilex 	equ 3
block_tiley 	equ 4
block_dma_l 	equ 5
block_dma_h 	equ 6