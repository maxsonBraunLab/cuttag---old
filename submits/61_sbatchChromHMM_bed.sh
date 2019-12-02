#!/bin/bash

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             1                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem                16000                  # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             chromHMM_bed_%j.out           # Standard output
#SBATCH --error              chromHMM_bed_%j.err           # Standard error

### SET I/O VARIABLES
IN=$mlproj/process/50_binary/bed
OUT=$mlproj/process/60_chromHMM/bed
NSTATE=6
ASSEMBLY=mm10

mkdir -p $OUT

### Executable
CHMM=/home/groups/MaxsonLab/software/ChromHMM/ChromHMM.jar
CHROMHMM="java -mx4000M -jar $CHMM LearnModel"

### Execute
cmd="$CHROMHMM $IN $OUT $NSTATE $ASSEMBLY"
echo $cmd
eval $cmd
