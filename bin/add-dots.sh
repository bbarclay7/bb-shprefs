#!/bin/bash

for dot in $(ls -1 $BBTB_ROOT/dots/dot.*); do
    temp=$(basename $dot)
    if [[ $temp =~ dot.* ]]; then
	homefile=$HOME/$(echo $temp | sed 's/^dot//')
	if [[ ! -e $homefile ]]; then
	    ln -v -s $dot $homefile
	fi 
    fi
    #echo $dot
done
