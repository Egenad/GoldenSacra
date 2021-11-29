;============================================================;
; Golden Sacra - Proyecto TFG                                ;
; Escuela Politécnica Superior de la Universidad de Alicante ;
; Autor: Ángel Jesús Terol MArtínez                          ;
; Contacto: jtm37@alu.ua.es / egenad8@gmail.com              ;
;============================================================;

; If all of these are already defined, don't do it again.
        IF      !DEF(AUDIOSYS_INC)
AUDIOSYS_INC  SET  1
    ;FUNCTIONS
    EXPORT AS_INIT
    EXPORT AS_UPDATE
    EXPORT AS_PLAY_NOTE_CHANNEL_1
    EXPORT AS_PLAY_NOTE_CHANNEL_2
    EXPORT AS_PLAY_NOTE_CHANNEL_4
    EXPORT AS_SET_ID
    ;VARIABLES
    ENDC    ;AUDIOSYS_INC