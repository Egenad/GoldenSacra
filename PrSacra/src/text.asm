;============================================================;
; Golden Sacra - Proyecto TFG								 ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol Martínez				 			 ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 ;
;============================================================;

INCLUDE "constants.inc"

SECTION "TEXT_ROM", ROM0

;==============================================================
; Function: Add Item
; Description: Adds the item given an input.
; Input: a (name of the item)
; Modified registers: all
;==============================================================

TX_GET_ITEM_NAME::
	
	cp 	 BASIC_APPLE
	jr 	 nz, .get_item_name_na

	ld 	 hl, BasicApple
	ld 	 a, End_Basic_Apple-BasicApple

	ret

.get_item_name_na:

	cp 	 BASIC_POTION
	jr 	 nz, .get_item_name_nbp

	ld 	 hl, BasicPotion
	ld 	 a, End_Basic_Potion-BasicPotion

	ret

.get_item_name_nbp:
	
	ld 	 hl, SuperPotion
	ld 	 a, End_Super_Potion-SuperPotion

	ret

; "Ashia used"
UseItem::
	DB 0, 18, 7, 8, 0, WHITE_TILE, 20, 18, 4, 3
End_UseItem::

; "Ashia got"
Item::
    DB 0, 18, 7, 8, 0, WHITE_TILE, 6, 14, 19
End_Item::

; "Apple!"
BasicApple:	
	DB 0, 15, 15, 11, 4, 37
End_Basic_Apple:

; "Potion!"
BasicPotion:	
	DB 15, 14, 19, 8, 14, 13, 37
End_Basic_Potion:

; "Super Potion!"
SuperPotion:	
	DB 18, 20, 15, 4, 17, WHITE_TILE, 15, 14, 19, 8, 14, 13, 37
End_Super_Potion:

; "Items"
Items_Text::
	DB 8, 19, 4, 12, 18
End_Items_Text::

; "Save"
Save_Text::
	DB 18, 0, 21, 4
End_Save_Text::

; "Exit"
Exit_Text::
	DB 4, 23, 8, 19
End_Exit_Text::

; "Back"
Back_Text::
	DB 1, 0, 2, 10
End_Back_Text::

; "Use"
Use_Text::
	DB 20, 18, 4
End_Use_Text::

; "Ashia is hungry"
Hungry_Text::
	DB 0, 18, 7, 8, 0, WHITE_TILE, 8, 18, WHITE_TILE, 7, 20, 13, 6, 17, 24
End_Hungry_Text::

; "Ashia is starving"
Starving_Text::
	DB 0, 18, 7, 8, 0, WHITE_TILE, 8, 18
End_Starving_Text::

Starving_Text_2::
	DB 18, 19, 0, 17, 21, 8, 13, 6, 37
End_Starving_Text_2::
