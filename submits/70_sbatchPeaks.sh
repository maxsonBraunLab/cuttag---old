#!/bin/bash
#SBATCH -n 1                               # Request one core
#SBATCH -N 1                               # Request one node (if you request more than one core with -n, also using
                                           # -N 1 means all cores will be on the same node)
#SBATCH -t 0-12:00                         # Runtime in D-HH:MM format
#SBATCH -p exacloud                           # Partition to run in
#SBATCH --mem=32000                        # Memory total in MB (for all cores)
#SBATCH -o peaks_%A_%a.out                 # File to which STDOUT will be written, including job ID
#SBATCH -e peaks_%A_%a.err                 # File to which STDERR will be written, including job ID
#SBATCH --array 1-60

#####################
### SET VARIABLES ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#####################

source /home/groups/MaxsonLab/software/venv_cnrTools/bin/activate
Rscriptbin=/home/groups/MaxsonLab/software/cnrTools/dependencies/R-3.3.3/bin
pythonbin=/home/groups/MaxsonLab/software/venv_cnrTools/bin/
bedopsbin=/home/groups/MaxsonLab/software/cnrTools/dependencies/bedops/bin/
picardbin=/home/exacloud/lustre1/BioCoders/Applications/picard-tools-2.8.1
picardjarfile=picard.jar
samtoolsbin=/home/exacloud/lustre1/BioCoders/Applications/
macs2bin=/home/groups/MaxsonLab/software/venv_cnrTools/bin
javabin=/usr/bin/
extratoolsbin=/home/groups/MaxsonLab/software/cnrTools
extrasettings=/home/groups/MaxsonLab/software/cnrTools
chromsizedir=`dirname /home/exacloud/lustre1/CompBio/users/hortowe/test/Mus_musculus/UCSC/mm10/Sequence/WholeGenomeFasta/genome.fa`
macs2pythonlib=/home/exacloud/lustre1/BioCoders/Applications/python2.7/site-packages
BEDTOOLS=$BIOCODERS/Applications/bedtools
BDG2BW=$mltool/scripts/bdg2bw

pythonlib=`echo $PYTHONPATH | tr : "\n" | grep -v $macs2pythonlib | paste -s -d:`
unset PYTHONPATH
export PYTHONPATH=$macs2pythonlib:$pythonlib

pythonldlibrary=/home/groups/MaxsonLab/software/venv_cnrTools/lib
ldlibrary=`echo $LD_LIBRARY_PATH | tr : "\n" | grep -v $pythonldlibrary | paste -s -d:`
unset LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$pythonldlibrary:$ldlibrary

#LEN=$mlproj/process/GRCm38.87_chromLen.txt
LEN=$ml/software/ChromHMM/CHROMSIZES/mm10.txt

### I/O VARIABLES
IN=$mlproj/process/30_filter
OUT=$mlproj/process/70_peaks
TEMP=$mlproj/process/intermediates
TODO=$mltool/todo/70_peaksTodo.txt
#TODO=$mltool/todo/70_redoPeaks.txt
mkdir -p $OUT $TEMP

### SELECT WHICH PARTS TO RUN
SORT=false
BG=false
BW=true
MDUP=false
RDUP=false
INDEX=false
PEAKS=false

#############
### SETUP ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#############

### Update
>&2 date

### Get file and info
FILE=`awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' $TODO`
BASE=`basename $FILE .bam`
CTL=${FILE%_*}_IgG.bam
CTL=`echo $CTL | sed 's/2_/1_/'`

### Navigate to input directory
cd $IN

### Make intermediate directories
for d in logs sorted dup.marked dedup metrics bedgraph bigwig; do
if [ ! -d $TEMP/$d ]; then
mkdir $TEMP/$d
fi
done

outdir=$OUT/macs2.narrow #for macs2
outdir2=$OUT/macs2.narrow.dedup #for macs2 dedup version
mkdir -p $outdir $outdir2

############
### SORT ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
############

### Sort data
if $SORT; then
	
	## Update
	>&2 echo "Sorting BAM... ""$BASE".bam
	>&2 date
	## Command
	sort="$javabin/java -jar $picardbin/$picardjarfile SortSam INPUT=$IN/$FILE OUTPUT=$TEMP/sorted/$FILE SORT_ORDER=coordinate VALIDATION_STRINGENCY=SILENT"
	## Run
	>&2 echo $sort
	eval $sort
fi

##########
### BG ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##########

### Convert to bed graph (for visualization)
if $BG; then

	## Update
	>&2 echo "Converting to bedgraph ... ""$BASE".bam
	>&2 echo date
	## Command
	bg="$BEDTOOLS genomecov -ibam $TEMP/sorted/$FILE -bg > $TEMP/bedgraph/$BASE\.bdg"
	>&2 echo $bg
	eval $bg
fi

##############
### BIGWIG ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##############

if $BW; then

	## Update
	>&2 echo "Converting to bigwig ... ""$BASE".bam
	>&2 echo date
	## Command
	bw="$BDG2BW $TEMP/bedgraph/$BASE\.bdg $LEN"
	>&2 echo $bw
	eval $bw
	## Move
	mv $TEMP/bedgraph/$BASE\.bw $TEMP/bigwig/$BASE\.bw
fi	

############
### MDUP ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
############

if $MDUP; then

	## Update
	>&2 echo "Marking duplicates... ""$BASE".bam
	>&2 date
	## Command
	mdup="$javabin/java -jar $picardbin/$picardjarfile MarkDuplicates INPUT=$TEMP/sorted/$FILE OUTPUT=$TEMP/dup.marked/$FILE VALIDATION_STRINGENCY=SILENT METRICS_FILE=$TEMP/metrics/$BASE\.txt"
	## Run
	>&2 echo $mdup
	eval $mdup
fi

############
### RDUP ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
############

if $RDUP; then
	
	## Update
	>&2 echo "Removing duplicates... ""$BASE".bam
	>&2 date
	## Command
	rdup="$samtoolsbin/samtools view -bh -F 1024 $TEMP/dup.marked/$FILE > $TEMP/dedup/$FILE"
	## Run
	>&2 echo $rdup
	eval $rdup
fi

#############
### INDEX ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#############

if $INDEX; then
	## Update
	>&2 echo "Creating bam index files... ""$BASE".bam
	>&2 date
	## Command
	i1="$samtoolsbin/samtools index $TEMP/sorted/$FILE"
	i2="$samtoolsbin/samtools index $TEMP/dup.marked/$FILE"
	i3="$samtoolsbin/samtools index $TEMP/dedup/$FILE"
	## Run
	>&2 echo $i1
	eval $i1
	>&2 echo $i2
	eval $i2
	>&2 echo $i3
	eval $i3
fi

#############
### PEAKS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#############

if $PEAKS; then
	## Update
	>&2 echo "Peak calling using MACS2... ""$BASE".bam
	>&2 echo "Logs are stored in $TEMP/logs"
	>&2 date
	## Variables
	bam_file=dup.marked.120bp/"$base".bam
	dir=`dirname $bam_file`
	base_file=`basename $bam_file .bam`
	## Command
	narrow1="$macs2bin/macs2 callpeak -t $TEMP/dup.marked/$FILE -c $TEMP/dup.marked/$CTL -g mm -f BAMPE -n $BASE --outdir $outdir -q 0.01 -B --SPMR --keep-dup all 2> $TEMP/logs/$BASE\.macs2"
	narrow2="$macs2bin/macs2 callpeak -t $TEMP/dup.marked/$FILE -c $TEMP/dup.marked/$CTL -g mm -f BAMPE -n $BASE --outdir $outdir2 -q 0.01 -B --SPMR  2> $TEMP/logs/$BASE\.dedup.macs2"
	## Run
	>&2 echo $narrow1
	eval $narrow1
	>&2 echo $narrow2
	eval $narrow2
fi

