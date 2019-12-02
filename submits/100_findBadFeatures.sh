#!/bin/sh

### From the distance to nearest TSS plots, we see a small peak
### near the TSS for enhancers (less than 100 bp away) and
### also we see an increase in distant promoters when looking
### at the peak input versus the bed input.

### Want to extract all enhancers within 100 bp of the TSS
### Want to extract all promoters >1000 bp from the TSS

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             1                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem                8000                    # Memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             badFeatures_%A_%a.out           # Standard output
#SBATCH --error              badFeatures_%A_%a.err           # Standard error
#SBATCH --array              1-8

### SET I/O VARIABLES
IN=$mlproj/process/90_results/nearestTSS
OUT=$mlproj/process/100_badFeatures

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
OUTFILE=$OUT/$SAMPLE\_$NSTATE\_$NAME$STATE\_badFeature.bed

### Command
if [[ $NAME == "actEnh" ]]; then
	cmd="awk -F '|' '{if (((\$3 < 0) && (\$3 >= -100)) || ((\$3 > 0) && (\$3 <= 100))) print \$1}' $IN/$FILE > $OUTFILE"
elif [[ $NAME == "prom" ]]; then
	cmd="awk -F '|' '{if ((\$3 < -1000) || (\$3 > 1000)) print \$1}' $IN/$FILE > $OUTFILE"
fi
#cmd="$CLOSEST --closest --dist $IN/$FILE $REF | grep -v "NA" > $OUTFILE"
echo $cmd
eval $cmd

