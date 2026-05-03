#!/bin/bash
# Linker wrapper that adds JHC C stubs
JHCDIR="/home/bruns/Documents/HanonymOS/jhc-0.8.2"
exec x86_64-linux-gnu-gcc "$@" \
    "$JHCDIR/src/cbits/md5sum.o" \
    "$JHCDIR/src/cbits/lookup3.o" \
    "$JHCDIR/src/StringTable/StringTable_cbits.o"
