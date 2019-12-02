#!/bin/sh

#SBATCH --job-name           trimDistr              # A single job name for the array
#SBATCH --partition          exacloud            # best partition for single core small jobs
#SBATCH --ntasks             1                   # one core
#SBATCH --nodes              1                   # on one node
#SBATCH --time               0-24:00              # Running time of 4 hours
#SBATCH --mem                12000                # Memory request of 4 GB
#SBATCH --output             trimDistr_%A_%a.out    # Standard output
#SBATCH --error              trimDistr_%A_%a.err    # Standard error
#SBATCH --array              1-120


### Arguments
#IN="$mlproj/process/scratch/trimmed"
#OUT="$mlproj/process/scratch/trimDistr"

IN="$mlproj/process/scratch/trimmed3"
OUT="$mlproj/process/scratch/trimDistr3"

TODO=$mltool/todo/trimLogTodo.txt

FILE=`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`

### Make directory
mkdir -p $OUT

### Get file name
name=${FILE%%.paired.fastq.gz}

### Get distribution of sequences
zcat $IN/$FILE | awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' > $OUT/$name\.trimDist.txt
