#!/bin/bash

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             1                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        4000                   # Memory required per allocated CPU (mutually exclusive with mem)
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             mapqQC_%A_%a.out      # Standard output
#SBATCH --error              mapqQC_%A_%a.err      # Standard error
#SBATCH --array              1-61                     # sets number of jobs in array

### SET I/O VARIABLES
IN=$mlproj/process/20_bam
OUT=$mlproj/qc/multiqc

### Executable
SAMTOOLS=$BIOCODERS/Applications/samtools-1.3.1/bin/samtools

### Record slurm info
echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID

### Get file
CURRFILE=`ls $IN/*_sorted.bam | awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}'`
CURRFILE=`basename $CURRFILE`
BASE=${FILE%.*}

### Execute
mkdir -p $OUT
cmd="$SAMTOOLS view $IN/$CURRFILE | awk -F '\t' '{print \$5}' | sort | uniq -c | sed 's/^ *//' | tr ' ' '\t' | sort -n -k 2 > $OUT/$BASE.txt"
echo $cmd
#eval $cmd

