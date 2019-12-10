#!/bin/bash

#SBATCH --job-name           mergeBam              # A single job name for the array
#SBATCH --partition          exacloud            # best partition for single core small jobs
#SBATCH --ntasks             1                   # one core
#SBATCH --nodes              1                   # on one node
#SBATCH --time               0-24:00              # Running time of 4 hours
#SBATCH --mem                4000                # Memory request of 4 GB
#SBATCH --output             mergeBam_%A_%a.out    # Standard output
#SBATCH --error              mergeBam_%A_%a.err    # Standard error
#SBATCH --array		     1-32

### Executable
MYBIN="/home/groups/MaxsonLab/smithb/KLHOXB_TAG_09_19/Dense_ChromHMM/bedtools2/bin/bedtools"

### Paths
IN="$mlproj/process/31_bedgraph"
OUT="$mlproj/process/40_merge"
TODO="$mltool/todo/22_mergeTodo.csv"
mkdir -p $OUT

### Get file info
printf "SLURM ARRAY TASK ID: %s\n" $SLURM_ARRAY_TASK_ID
currINFO=`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`

### Separate
currGRP=`echo $currINFO | awk -F ',' '{print $1}'`
currMARK=`echo $currINFO | awk -F ',' '{print $2}'`

### Update
printf "Working on merging files for: %s\t%s\n" $currGRP $currMARK

## Make files
ONE=$currGRP\1_$currMARK.bedgraph
TWO=$currGRP\2_$currMARK.bedgraph
MERGE=$currGRP\_$currMARK.bedgraph

## Update
printf "\tMerging %s:\n\t\t%s\t%s\n\t\t%s\n\n" $currMARK $ONE $TWO $MERGE

## Add paths
ONE=$IN/$ONE
TWO=$IN/$TWO
MERGE=$OUT/$MERGE

## Build command
cmd="$MYBIN unionbedg -i $ONE $TWO > $MERGE"

## Run
echo $cmd
eval $cmd

