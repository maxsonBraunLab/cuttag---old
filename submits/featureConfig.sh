#!/bin/sh

### There are four different options at the moment:
	### peak_enh
	### bed_enh
	### peak_prom
	### peak_prom2 (Use state of 1 instead of 5, 1 corresponds to H3K27Ac and H3K4me3)
	### peak_promCombo (Use after running 80_ for both peak versions and concatenating them)
	### bed_prom

WHICH="bed_enh"

if [[ $WHICH == "peak_enh" ]]; then
	TYPE='peak'
	NSTATE=6
	STATE=3
	NAME='actEnh'
fi

if [[ $WHICH == "bed_enh" ]]; then
	TYPE='bed'
	NSTATE=6
	STATE=2
	NAME="actEnh"
fi


if [[ $WHICH == "peak_prom" ]]; then
	TYPE='peak'
	NSTATE=6
	STATE=5
	NAME="prom"
fi


if [[ $WHICH == "bed_prom" ]]; then
	TYPE='bed'
	NSTATE=6
	STATE=5
	NAME="prom"
fi

if [[ $WHICH == "peak_prom2" ]]; then
	TYPE='peak'
	NSTATE=6
	STATE=1
	NAME="prom"
fi

if [[ $WHICH == "peak_promCombo" ]]; then
	TYPE='peak'
	NSTATE=6
	STATE=15
	NAME="prom"
fi

### TESTING
TEST=false

if $TEST; then
	printf "TYPE=%s\n" $TYPE
	printf "NSTATE=%s\n" $NSTATE
	printf "STATE=%s\n" $STATE
	printf "NAME=%s\n" $NAME
fi
