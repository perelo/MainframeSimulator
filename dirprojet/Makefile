
#/**
#*
#* @File : nmakefile
#*
#*
#* @Synopsis : Makefile pour le Projet Systemes 2012
#*
#**/
include ../include/INCLUDE_H
#
COMPILER = g++ -c -I$(INCLUDE) -Wall -O3 -Werror $*.cxx

LIBBUILDER = mkdir -p ../lib; ar -cqs ../lib/libSys.a $*.o


# Edition de liens
#
$(nom) : codeobjsyst  $(nom).o Board.o CPU.o Disk.o DMA.o
	g++ -s -ggdb -o $(nom).run $(nom).o Board.o CPU.o Disk.o DMA.o -L../lib -lSys
# 
#
$(nom).o : $(nom).cxx $(CEXC_H) $(PROJET_H) $(NSSYSTEME_H)
	$(COMPILER) ; $(LIBBUILDER)
#

Board.o : Board.cxx $(NSUTIL_H) $(CEXCEPTION_H) $(NSSYSTEME_H) \
           $(CSEMBASE_H) $(PROJET_H)
	$(COMPILER) ; $(LIBBUILDER)

CPU.o : CPU.cxx $(NSUTIL_H) $(CEXCEPTION_H) $(NSSYSTEME_H) \
           $(CSEMBASE_H) $(PROJET_H)
	$(COMPILER) ; $(LIBBUILDER)

Disk.o : Disk.cxx $(NSUTIL_H) $(CEXCEPTION_H) $(NSSYSTEME_H) \
           $(CSEMBASE_H) $(PROJET_H)
	$(COMPILER) ; $(LIBBUILDER)

DMA.o : DMA.cxx $(NSUTIL_H) $(CEXCEPTION_H) $(NSSYSTEME_H) \
           $(CSEMBASE_H) $(PROJET_H)
	$(COMPILER) ; $(LIBBUILDER)

#
# Code Objet pour la bibliotheque Systemes
# 
codeobjsyst: 
	make general
#
general:    nsSysteme.o   
#

nsSysteme.o : nsSysteme.cxx $(CEXC_H) $(NSSYSTEME_H)
	$(COMPILER); $(LIBBUILDER)

#

#
# Nettoyage (repertoire courant : executables et fichiers .o, etc.)
#
clean : 
	clear; rm -rf *.o *.run ../lib -v *~ ../include/*~
#
