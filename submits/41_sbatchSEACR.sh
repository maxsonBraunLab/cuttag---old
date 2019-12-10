#!/bin/bash

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             1                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        4000                   # Memory required per allocated CPU (mutually exclusive with mem)
##SBATCH --mem                16000                  # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             seacr_%A_%a.out     # Standard output
#SBATCH --error              seacr_%A_%a.err     # Standard error
#SBATCH --array              1-32                    # sets number of jobs in array

### Executable
MYBIN=/home/groups/MaxsonLab/software/SEACR/SEACR_1.1.sh

### SET I/O VARIABLES
IN=$mlproj/process/31_bedgraph
OUT=$mlproj/process/41_seacr
TODO=$mltool/todo/41_seacrTodo.txt
mkdir -p $OUT

### Other arguments
NORM="norm"
THRESH="stringent"

### Record slurm info
echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID

### Get file info
currINFO=`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`

### Set variables
NAME=${currINFO%%.bedgraph}
CTLNAME=${NAME%%_*}_IgG.bedgraph
DATA=$IN/$currINFO
CTL=$IN/$CTLNAME

### Execute
cmd="$MYBIN $DATA $CTL $NORM $THRESH $OUT/$NAME"
echo $cmd
eval $cmd
