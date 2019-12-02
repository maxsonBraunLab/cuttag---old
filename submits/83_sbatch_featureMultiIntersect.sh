#!/bin/bash

### Now have each individual file all containing the "same" features
### not in the sense that each one has all the features that the other does,
### but in the sense that each feature's coordinates is the same between files.

### We can create a summary file with one row per feature and one
### column per file. 0 means that feature was not found in that file; 1 means it was

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             1                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        8000                    # Memory required per allocated CPU (mutually exclusive with mem)
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             featureMultiInt_%j.out           # Standard output
#SBATCH --error              featureMultiInt_%j.err           # Standard error

### SET I/O VARIABLES
IN=$mlproj/process/82_featureIntersect
OUT=$mlproj/process/83_featureSummaries

### SOURCE CONFIG FILE - MAKE SURE THIS IS SET UP CORRECTLY!!
source $mltool/submits/featureConfig.sh

### Output
mkdir -p $OUT/$NAME/$TYPE

### Executable
BEDTOOLS=$BIOCODERS/Applications/bedtools

### Get files
FILES=(`ls $IN/$NAME/$TYPE | grep "$NAME$STATE"`)

### Add paths to files and get names
declare -a FULLFILES
declare -a NAMES
for i in "${!FILES[@]}"; do
	NEW=$IN/$NAME/$TYPE/"${FILES[$i]}"
	NNAME=`echo "${FILES[$i]}" | cut -d '_' -f 1`
	FULLFILES[$i]=$NEW
	NAMES[$i]=$NNAME
done

### Intersect
cmd="$BEDTOOLS multiinter -i ${FULLFILES[*]} -names ${NAMES[*]} -header > $OUT/$NAME/$TYPE/$NAME$STATE\GroupsFinal.txt"
echo $cmd
eval $cmd

