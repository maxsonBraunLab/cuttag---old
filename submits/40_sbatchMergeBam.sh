#!/bin/bash

#SBATCH --job-name           mergeBam              # A single job name for the array
#SBATCH --partition          exacloud            # best partition for single core small jobs
#SBATCH --ntasks             1                   # one core
#SBATCH --nodes              1                   # on one node
#SBATCH --time               0-24:00              # Running time of 4 hours
#SBATCH --mem                4000                # Memory request of 4 GB
#SBATCH --output             mergeBam_%A_%a.out    # Standard output
#SBATCH --error              mergeBam_%A_%a.err    # Standard error
#SBATCH --array		     1-28

### Executable
MYBIN="/home/exacloud/lustre1/BioCoders/Applications/samtools-1.3.1/bin/samtools"

### Paths
IN="$mlproj/process/30_filter"
OUT="$mlproj/process/40_merge"
TODO="$mltool/todo/22_mergeTodo.csv"
mkdir -p $OUT

### Set file info
BASE=KLHOXB_TAG_09_19

### Get file info
printf "SLURM ARRAY TASK ID: %s\n" $SLURM_ARRAY_TASK_ID
currINFO=`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`

### Separate
currGRP=`echo $currINFO | awk -F ',' '{print $1}'`
currMARK=`echo $currINFO | awk -F ',' '{print $2}'`

### Update
printf "Working on merging files for: %s\t%s\n" $currGRP $currMARK

## Make files
ONE=$BASE\.$currGRP\1_$currMARK.bam
TWO=$BASE\.$currGRP\2_$currMARK.bam
MERGE=$BASE\.$currGRP\_$currMARK.bam

## Update
printf "\tMerging %s:\n\t\t%s\t%s\n\t\t%s\n\n" $currMARK $ONE $TWO $MERGE

## Add paths
ONE=$IN/$ONE
TWO=$IN/$TWO
MERGE=$OUT/$MERGE

## Build command
cmd="$MYBIN merge \
	$MERGE \
	$ONE $TWO"

## Run
echo $cmd
eval $cmd

