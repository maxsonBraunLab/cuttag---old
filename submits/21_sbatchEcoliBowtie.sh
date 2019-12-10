#!/bin/bash

#SBATCH --job-name           bowtie              # A single job name for the array
#SBATCH --partition          exacloud            # best partition for single core small jobs
#SBATCH --ntasks             1                   # one core
#SBATCH --nodes              1                   # on one node
#SBATCH --time               0-24:00              # Running time of 4 hours
#SBATCH --mem                12000                # Memory request of 4 GB
#SBATCH --output             Bowtie_%A_%a.out    # Standard output
#SBATCH --error              Bowtie_%A_%a.err    # Standard error
#SBATCH --array		     1-32

### Executable
MYBIN="/opt/installed/bowtie2/bin/bowtie2"
SAMTOOLS=/home/groups/MaxsonLab/software/miniconda3/bin/samtools

### Paths
IN="$mlproj/fastq"
OUT="$mlproj/process/21_ecolialignments"
REF=/home/groups/MaxsonLab/indices/ecoli_EB1/genome
TODO="$mltool/todo/20_bowtieTodo.txt"
mkdir -p $OUT

### Get file info
printf "SLURM ARRAY TASK ID: %s\n" $SLURM_ARRAY_TASK_ID
R1=`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`
R2=`echo $R1 | sed 's/_R1/_R2/'`
NAME=${R1%%_Kasumi*}

### Update
printf "Forward file: %s\nReverse file: %s\n" $R1 $R2
printf "Base name for output file: %s\n" $NAME

### Run
cmd="$MYBIN --local \
	--very-sensitive-local \
	--no-unal \
	--no-mixed \
	--no-discordant \
	--no-overlap \
	--no-dovetail \
	--phred33 \
	-I 10 \
	-X 700 \
	-x $REF \
	-1 $IN/$R1 \
	-2 $IN/$R2 \
	-S $OUT/$NAME\.sam"

echo "Executing alignment:"
echo $cmd
eval $cmd

