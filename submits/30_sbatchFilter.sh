#!/bin/bash

### Filter reads
### -f flag will keep all alignments WITH this setting
### -F flag will keep all alignments WITHOUT this setting
### 3: template has multiple segments in sequencing (1) and each segment is properly aligned (2)
### 4: segment is unmapped
### 8: next segment in the template unmapped
### So we keep multimappers with proper alignments and remove unmapped.

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             1                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem                4000                  # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             filter_%A_%a.out           # Standard output
#SBATCH --error              filter_%A_%a.err           # Standard error
#SBATCH --array              1-32                     # sets number of jobs in array

### SET I/O VARIABLES

IN=$mlproj/process/20_alignments
OUT=$mlproj/process/30_filter     
TODO=$mltool/todo/30_filterTodo.txt
mkdir -p $OUT

### Executable
SAMTOOLS=/home/groups/MaxsonLab/software/miniconda3/bin/samtools

### Record slurm info
echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID

### Get file and info
CURRFILE=`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`

### Execute
cmd="$SAMTOOLS view -b -f 3 -F 4 -F 8 $IN/$CURRFILE > $OUT/$CURRFILE"
echo $cmd
eval $cmd
