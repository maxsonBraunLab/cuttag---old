#!/bin/bash

### Now have the summary file with each feature's presence/absence in all the files
### Want to "annotate" the features by searching for the closest gene

### Must be careful in setting up the gene reference - make sure it's the same source as
### everything else

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             8                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        2000                    # Memory required per allocated CPU (mutually exclusive with mem)
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             featureGeneMap_%j.out           # Standard output
#SBATCH --error              featureGeneMap_%j.err           # Standard error

### SET I/O VARIABLES
IO=$mlproj/process/83_featureSummaries
echo $IO

### SOURCE CONFIG FILE - MAKE SURE THIS IS SET UP CORRECTLY!!
source $mltool/submits/featureConfig.sh

### Output
mkdir -p $IO/$NAME/$TYPE

### Executable
CLOSEST=/home/groups/MaxsonLab/software/cnrTools/dependencies/bedops/bin/closest-features

### Assign files
IN=$IO/$NAME/$TYPE/$NAME$STATE\GroupsFinal.txt
OUT=$IO/$NAME/$TYPE/full_$NAME$STATE\Genes.txt
OUT2=$IO/$NAME/$TYPE/$NAME$STATE\Genes.txt
#REF=$mlproj/process/GRCm38.87_genes.bed
REF=$mlproj/process/ref/ucsc.mm10.gene.bed
echo $IN
echo $OUT

### Run
cmd="$CLOSEST --closest --delim '\t' --dist <(tail -n +2 $IN) $REF > $OUT"
echo $cmd
eval $cmd

grep -v "NA" $OUT > $OUT2
