#!/bin/sh

### When running chromHMM using peaks as input, we get two different chromatin states
### that may refer to promoters. Current pipeline can only handle one state at a time
### for downstream analysis. Once feature has been extracted for each state individually,
### can concatenate them together for the rest of the downstream stuff.

DIR=$mlproj/process/80_features/prom/peak
cd $DIR
OUT=$mlproj/process/80_features/prom/temp
mkdir -p $OUT

### Unique cell types (should be first field)
FILES=(`ls | cut -d '_' -f 1 | uniq`)

### Number of states from chromHMM call (should be second field)
NSTATE=(`ls | cut -d '_' -f 2 | uniq`)
if [[ ${#NSTATE[@]} > 1 ]]; then
	echo "More than 1 number of states. Recommended to concatenate only results from chromHMM run with same nstate."
	exit
fi

### Type of feature
FEAT="prom"

### Specify new name for new "state"
STATE=15

### Run
for file in ${FILES[@]}; do

	printf "Working on %s\n" $file

	WHICH=(`ls | grep $file`)
	NAME=$file\_$NSTATE\_$FEAT$STATE\.bed

	for w in ${WHICH[@]}; do

		cat $DIR/$w >> $OUT/$NAME

	done
done

