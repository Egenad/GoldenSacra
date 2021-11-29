#============================================================#
# Golden Sacra - Proyecto TFG								 #
# Escuela Politécnica Superior de la Universidad de Alicante #
# Autor: Ángel Jesús Terol MArtínez				 			 #
# Contacto: jtm37@alu.ua.es / egenad8@gmail.com				 #
#============================================================#

ASM  = rgbasm
LINK = rgblink
FIX  = rgbfix
MKDIR_P := mkdir -p
OBJ_DIR := ../obj/
GB_DIR  := ../
ROM_NAME = PrSacra
SOURCES = $(wildcard *.asm)
FIX_FLAGS = -v -p 0

OBJECTS = $(SOURCES:%.asm=$(OBJ_DIR)%.o)

all: dirs $(ROM_NAME)
	$(warning Compiled Golden Sacra)

$(ROM_NAME): $(OBJECTS)
	$(LINK) -o $(GB_DIR)$@.gb -m $(OBJ_DIR)$@.map -n $(OBJ_DIR)$@.sym $(OBJECTS)
	$(FIX) $(FIX_FLAGS) $(GB_DIR)$@.gb

$(OBJ_DIR)%.o: %.asm
	$(ASM) -o $@ $<

clean:
	rm -r $(OBJ_DIR)
	$(warning Cleaned Project)

dirs: 
	$(MKDIR_P) $(OBJ_DIR)
	$(warning Obj Folder Make)
