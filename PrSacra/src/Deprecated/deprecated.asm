;==============================================================
; Function: Swap Enemy X coordinates
; Description:
; Modified registers: all
; Input: -
;==============================================================

EM_SWAP_EN_X:

	; The HL address we are given is from the ROM array, not the DMA one.

	ld 	 e, en_dma_l
	call EM_GET_ENEMY_VARIABLE 				; a = low byte address
	ld 	 c, a 								; save it in register a
	inc  hl
	ld 	 a, [hl]
	ld 	 h, a 								; a = high byte address
	ld 	 l, c 								; b =  low byte address

	; Now we have the DMA address, so we can look up any variable of this array.
	
	push hl
	ld   e, pl_sp0x
	call EM_GET_ENEMIES_DMA_VAR
	pop  hl

	ld 	 b, a

	push hl
	ld   e, pl_sp1x
	call EM_GET_ENEMIES_DMA_VAR
	ld 	 c, a
	ld 	 [hl], b 							;SPR1_X = SPR0_X
	pop  hl

	push hl
	ld   e, pl_sp0x
	call EM_GET_ENEMIES_DMA_VAR
	ld 	 a, c
	ld 	 [hl], c 							;SPR0_X = SPR1_X
	pop  hl

	push hl
	ld   e, pl_sp2x
	call EM_GET_ENEMIES_DMA_VAR
	ld 	 [hl], c 							;SPR2_X = SPR1_X
	pop  hl

	push hl
	ld   e, pl_sp3x
	call EM_GET_ENEMIES_DMA_VAR
	ld 	 [hl], b							;SPR3_X = SPR0_X
	pop  hl

	ret