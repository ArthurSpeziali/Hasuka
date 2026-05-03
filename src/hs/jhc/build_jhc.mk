JHCDIR = /home/bruns/Documents/HanonymOS/jhc-0.8.2
CFILES = $(JHCDIR)/src/cbits/md5sum.o $(JHCDIR)/src/cbits/lookup3.o $(JHCDIR)/src/StringTable/StringTable_cbits.o

.PHONY: jhc

jhc:
	ghc -hide-all-packages \
		-package-db $(HOME)/.cabal/store/ghc-9.4.7/package.db \
		-package base -package zlib -package mtl -package array \
		-package binary -package utf8-string -package bytestring \
		-package syb -package fgl -package containers -package process \
		-package directory -package filepath -package unix \
		-package random -package old-time -package pretty -package regex-compat \
		-package HsSyck \
		-i -i$(JHCDIR)/compat/haskell98 \
		-i$(JHCDIR)/drift_processed \
		-i$(JHCDIR)/src \
		-I$(JHCDIR)/src \
		-o $(JHCDIR)/jhc \
		$(JHCDIR)/src/Main.hs \
		$(CFILES)
