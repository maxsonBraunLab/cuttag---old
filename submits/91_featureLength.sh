#!/bin/sh

### Want to find the distance to the nearest TSS of each feature
### Have to create the TSS bed file by taking the start coordinate
### of all positive strand genes and the end coordinate of all negative
### strand genes.

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             1                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem                8000                    # Memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             featureLength_%A_%a.out           # Standard output
#SBATCH --error              featureLength_%A_%a.err           # Standard error
#SBATCH --array              1-8

### SET I/O VARIABLES
IN=$mlproj/process/82_featureIntersect
OUT=$mlproj/process/90_results/featureLength

### SOURCE CONFIG FILE - MAKE SURE THIS IS SET UP CORRECTLY!!
source $mltool/submits/featureConfig.sh

### Assign Paths
IN=$IN/$NAME/$TYPE
OUT=$OUT/$NAME/$TYPE
mkdir -p $OUT

### Get file
FILE=`ls -v $IN | grep "$NAME$STATE\_" | awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}'`
SAMPLE=${FILE%%_*}

### OUTPUT
OUTFILE=$OUT/$SAMPLE\_$NSTATE\_$NAME$STATE\_length.bed

### Command
cmd="awk '{len=\$3-\$2; print \$1, \$2, \$3, len}' $IN/$FILE > $OUTFILE"
echo $cmd
eval $cmd

