#!/bin/bash

### After running chromHMM, need to extract the enhancers
### from the segment files. Determine which state
### corresponds to enhancers and grep for it

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             8                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        2000                    # Memory required per allocated CPU (mutually exclusive with mem)
##SBATCH --mem                16000                  # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             extractFeature_%A_%a.out           # Standard output
#SBATCH --error              extractFeature_%A_%a.err           # Standard error
#SBATCH --array              1-8                     # sets number of jobs in array

### SET I/O VARIABLES
IN=$mlproj/process/60_chromHMM
OUT=$mlproj/process/80_features
TODO=$mltool/todo/80_extractFeatureTodo.txt

### SOURCE CONFIG FILE - MAKE SURE THIS IS SET UP CORRECTLY!!
source $mltool/submits/featureConfig.sh

### Output
mkdir -p $OUT/$NAME/$TYPE

### Executable
BEDTOOLS=$BIOCODERS/Applications/bedtools

### Record slurm info
echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID

### Get file
CURRCELL=`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`
CURRFILE=$CURRCELL\_$NSTATE\_segments.bed

### Execute
cmd="awk -v state=\"E$STATE\" '{if (\$4 == state) print \$0}' $IN/$TYPE/$CURRFILE > $OUT/$NAME/$TYPE/$CURRCELL\_$NSTATE\_$NAME$STATE\.bed"
echo $cmd
eval $cmd
