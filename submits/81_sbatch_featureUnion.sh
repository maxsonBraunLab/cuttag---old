#!/bin/bash

### After extracting enhancers, want to merge them all together
### to create a "union enhancer peak" file that has all peaks merged.
### The individual files can then be queried against this file and
### all intersections taken.

### Will merge all features that are within 500-bp

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             8                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        2000                    # Memory required per allocated CPU (mutually exclusive with mem)
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             featureUnion_%j.out           # Standard output
#SBATCH --error              featureUnion_%j.err           # Standard error

### SET I/O VARIABLES
IN=$mlproj/process/80_features
OUT=$mlproj/process/81_featureUnion

### SOURCE CONFIG FILE - MAKE SURE THIS IS SET UP CORRECTLY!!
source $mltool/submits/featureConfig.sh

### Output
mkdir -p $OUT/$NAME/$TYPE

### Executable
BEDTOOLS=$BIOCODERS/Applications/bedtools

### Get file
FILES=(`ls $IN/$NAME/$TYPE | grep "$STATE\.bed"`)

### Combine all files together
for FILE in "${FILES[@]}"; do
	cat $IN/$NAME/$TYPE/$FILE >> $OUT/$NAME/$TYPE/tempAll
done

### Sort
$BEDTOOLS sort -i $OUT/$NAME/$TYPE/tempAll > $OUT/$NAME/$TYPE/tempSort
#sort -k1,1 -k 2,2n $OUT/$NAME/$TYPE/tempAll > $OUT/$NAME/$TYPE/tempSort

### Merge
$BEDTOOLS merge -i $OUT/$NAME/$TYPE/tempSort -d 500 > $OUT/$NAME/$TYPE/$NAME$STATE\Union_d500.bed

