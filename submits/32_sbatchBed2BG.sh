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
#SBATCH --output             bed2bg_%A_%a.out           # Standard output
#SBATCH --error              bed2bg_%A_%a.err           # Standard error
#SBATCH --array              1-32                    # sets number of jobs in array

### SET I/O VARIABLES

IN=$mlproj/process/30_filter/bed
IN2=$mlproj/process/21_ecolialignments
OUT=$mlproj/process/31_bedgraph
TODO=$mltool/todo/30_filterTodo.txt
REF=/home/groups/MaxsonLab/software/ChromHMM/CHROMSIZES/hg38.txt
mkdir -p $OUT

### Executable
BEDTOOLS=/home/groups/MaxsonLab/smithb/KLHOXB_TAG_09_19/Dense_ChromHMM/bedtools2/bin/bedtools
SAMTOOLS=/home/groups/MaxsonLab/software/miniconda3/bin/samtools

### Record slurm info
echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID

### Get file and info
CURRFILE=`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`
BASE=${CURRFILE%%.bam}


echo "CURRFILE" $CURRFILE
echo "BASE" $BASE

### Scale-factor
spike_count=`$SAMTOOLS view $IN2/$BASE\.sam | wc -l`
scale=10000
scale_factor=`echo "$scale/$spike_count" | bc -l`

### Commands
cleanBed="awk '\$1==\$4 && \$6-\$2 < 1000 {print \$0}' $IN/$BASE.bed > $IN/$BASE.clean.bed"
getFrag="cut -f 1,2,6 $IN/$BASE.clean.bed > $IN/$BASE.fragments.bed"
sortFrag="sort -k1,1 -k2,2n -k3,3n $IN/$BASE.fragments.bed > $IN/$BASE.sortfragments.bed"
bedgraph="$BEDTOOLS genomecov -bg -scale $scale_factor -i $IN/$BASE.sortfragments.bed -g $REF > $OUT/$BASE.bedgraph"

### Run
echo "Clean bed"
echo $cleanBed
eval $cleanBed

echo "Get fragments"
echo $getFrag
eval $getFrag

echo "Sort fragments"
echo $sortFrag
eval $sortFrag

echo "Convert to bedgraph"
echo $bedgraph
eval $bedgraph
