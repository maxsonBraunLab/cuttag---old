#!/bin/sh

#DIR=$mlproj/process/80_features
DIR=$mlproj/process/82_featureIntersect
OUT=$mlproj/process/90_results/featureCounts
mkdir -p $OUT

FEATURE=(`ls $DIR`)

for feature in ${FEATURE[@]}; do
	
	printf "Working on: %s\n" $feature

	TYPE=(`ls $DIR/$feature`)

	for t in ${TYPE[@]}; do
		
		printf "\tWorking on: %s\n" $t

		cd $DIR/$feature/$t

		## Output file
		file=$t\_$feature\_counts.txt

		## Get line count and reformat
		wc -l * | grep -v total | sed 's/^ *//' | awk -F ' ' -v OFS='\t' '{print $2, $1}' > $OUT/$file
	done
done

