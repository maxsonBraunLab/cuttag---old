#!/bin/bash

### After the peak union file is made,
### the individual files can then be queried against this file and
### all intersections taken.

### "-wa" is "A intersect B, write original entry for A"
### So any time that something in B intersects with something in A, the "A" version is returned
### In our case:
	### A: peak union file (widest possible peak made by overlapping all samples)
	### B: individual sample file
### Result is that any time that a peak in the individual sample file overlaps
### with the union file, the full union entry is returned.

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             8                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        2000                    # Memory required per allocated CPU (mutually exclusive with mem)
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             featureIntersect_%A_%a.out           # Standard output
#SBATCH --error              featureIntersect_%A_%a.err           # Standard error
#SBATCH --array 1-8

### SET I/O VARIABLES
IN=$mlproj/process/80_features
OUT=$mlproj/process/82_featureIntersect
#TODO=$mltool/todo/82_intersectEnhancerTodo3.txt
TODO=$mltool/todo/82_intersectEnhancerTodo2.txt
#TODO=$mltool/todo/82_intersectPromoterTodo5.txt
#TODO=$mltool/todo/82_intersectPromoterTodo1.txt
#TODO=$mltool/todo/82_intersectPromoterTodo15.txt
REF=$mlproj/process/81_featureUnion

### SOURCE CONFIG FILE - MAKE SURE THIS IS SET UP CORRECTLY!!
source $mltool/submits/featureConfig.sh

### Output
mkdir -p $OUT/$NAME/$TYPE

### Executable
BEDTOOLS=$BIOCODERS/Applications/bedtools

### Get file
FILE=`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`
BASE=`basename $FILE .bed`

### Get reference file
refFILE=(`ls $REF/$NAME/$TYPE | grep "$NAME$STATE\Union"`)

### Intersect
### Careful for legacy todo files that don't have feature state in the file names.
cmd="$BEDTOOLS intersect -wa -a $REF/$NAME/$TYPE/$refFILE -b $IN/$NAME/$TYPE/$BASE\.bed > $OUT/$NAME/$TYPE/$BASE\_intersect.bed"
echo $cmd
eval $cmd

