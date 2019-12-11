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
#SBATCH --array 1-12

### SET I/O VARIABLES
IN=$mlproj/process/41_seacr
OUT=$mlproj/process/42_intersectSEACR
TODO=$mltool/todo/42_intersectTodo.txt
mkdir -p $OUT

### Executable
BEDTOOLS=/home/groups/MaxsonLab/smithb/KLHOXB_TAG_09_19/Dense_ChromHMM/bedtools2/bin/bedtools

### Get file
FILE=`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`
BASE=${FILE%%.*}
BASE=`echo $BASE | sed 's/1_/_/'`
REF=`echo $FILE | sed 's/1_/2_/'`

### Intersect
### Careful for legacy todo files that don't have feature state in the file names.
cmd="$BEDTOOLS intersect -a $IN/$FILE -b $IN/$REF > $OUT/$BASE\_intersect.bed"
echo $cmd
eval $cmd
