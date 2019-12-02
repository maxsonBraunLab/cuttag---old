#!/bin/sh

#SBATCH -n 1                               # Request one core
#SBATCH -N 1                               # Request one node (if you request more than one core with -n, also using
                                           # -N 1 means all cores will be on the same node)
#SBATCH -t 0-12:00                         # Runtime in D-HH:MM format
#SBATCH -p exacloud                           # Partition to run in
#SBATCH --mem=32000                        # Memory total in MB (for all cores)
#SBATCH -o peakToBW_%A_%a.out                 # File to which STDOUT will be written, including job ID
#SBATCH -e peakToBW_%A_%a.err                 # File to which STDERR will be written, including job ID
#SBATCH --array 1-60

### VARIABLES
IN=$mlproj/process/70_peaks/macs2.narrow
SUFFIX=".xls"
OUT=$mlproj/process/70_peaks/macs2.narrow

### TOOLS
BEDTOOLS=$BIOCODERS/Applications/bedtools
BDG2BW=$mltool/scripts/bdg2bw
LEN=$ml/software/ChromHMM/CHROMSIZES/mm10.txt

### Get file
CURRFILE=`ls -v $IN | grep $SUFFIX | awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}'` 
CURRNAME=${CURRFILE%$SUFFIX}

### Convert to bed
grep -v "^#" $IN/$CURRFILE | tail -n +3 > $IN/$CURRNAME\.bed

### Sort by chromosome
sort -k 1,1 $IN/$CURRNAME\.bed > $IN/$CURRNAME\_sort.bed

### Convert to bedgraph
$BEDTOOLS genomecov -i $IN/$CURRNAME\_sort.bed -g $LEN -bg > $IN/$CURRNAME\.bdg

### Convert to bigwig
$BDG2BW $IN/$CURRNAME\.bdg $LEN

