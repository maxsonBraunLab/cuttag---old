#!/bin/bash

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             8                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        8000                    # Memory required per allocated CPU (mutually exclusive with mem)
##SBATCH --mem                16000                  # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             mergeBinBam_%j.out           # Standard output
#SBATCH --error              mergeBinBam_%j.err           # Standard error

### SET I/O VARIABLES
CLEN=/home/groups/MaxsonLab/software/ChromHMM/CHROMSIZES/mm10.txt
CMARK=/home/groups/MaxsonLab/hortowe/tools/todo/53_cellMark_mBam.txt
IN=$mlproj/process/40_merge
OUT=$mlproj/process/50_binary/mergeBam

mkdir -p $OUT

### Executable
CHMM=/home/groups/MaxsonLab/software/ChromHMM/ChromHMM.jar
CHROMHMM="java -mx4000M -jar $CHMM BinarizeBam"

### Execute
cmd="$CHROMHMM -c $IN $CLEN $IN $CMARK $OUT"
echo $cmd
eval $cmd
