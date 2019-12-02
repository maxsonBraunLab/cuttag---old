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

pythonlib=`echo $PYTHONPATH | tr : "\n" | grep -v $macs2pythonlib | paste -s -d:`
unset PYTHONPATH
export PYTHONPATH=$macs2pythonlib:$pythonlib

pythonldlibrary=/home/groups/MaxsonLab/software/venv_cnrTools/lib
ldlibrary=`echo $LD_LIBRARY_PATH | tr : "\n" | grep -v $pythonldlibrary | paste -s -d:`
unset LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$pythonldlibrary:$ldlibrary

### I/O VARIABLES
IN=$mlproj/process/30_filter
OUT=$mlproj/process/70_peaks
TEMP=$mlproj/process/intermediates
TODO=$mltool/todo/70_peaksTodo.txt
mkdir -p $OUT
mkdir -p $TEMP

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
for d in logs sorted dup.marked dedup metrics; do
if [ ! -d $TEMP/$d ]; then
mkdir $TEMP/$d
fi
done

### Sort data
>&2 echo "Sorting BAM... ""$BASE".bam
>&2 date
sort="$javabin/java -jar $picardbin/$picardjarfile SortSam INPUT=$IN/$FILE OUTPUT=$TEMP/sorted/$FILE SORT_ORDER=coordinate VALIDATION_STRINGENCY=SILENT"
#>&2 echo $sort
#eval $sort

### Mark duplicates
#>&2 echo "Marking duplicates... ""$BASE".bam
#>&2 date
mdup="$javabin/java -jar $picardbin/$picardjarfile MarkDuplicates INPUT=$TEMP/sorted/$FILE OUTPUT=$TEMP/dup.marked/$FILE VALIDATION_STRINGENCY=SILENT METRICS_FILE=$TEMP/metrics/$BASE\.txt"
#>&2 echo $mdup
#eval $mdup

### Remove duplicates
>&2 echo "Removing duplicates... ""$BASE".bam
>&2 date
rdup="$samtoolsbin/samtools view -bh -F 1024 $TEMP/dup.marked/$FILE > $TEMP/dedup/$FILE"
#>&2 echo $rdup
#eval $rdup

### Index
>&2 echo "Creating bam index files... ""$BASE".bam
>&2 date
i1="$samtoolsbin/samtools index $TEMP/sorted/$FILE"
i2="$samtoolsbin/samtools index $TEMP/dup.marked/$FILE"
i3="$samtoolsbin/samtools index $TEMP/dedup/$FILE"
#>&2 echo $i1
#eval $i1
#>&2 echo $i2
#eval $i2
#>&2 echo $i3
#eval $i3

>&2 echo "Peak calling using MACS2... ""$BASE".bam
>&2 echo "Logs are stored in $TEMP/logs"
>&2 date
bam_file=dup.marked.120bp/"$base".bam
dir=`dirname $bam_file`
base_file=`basename $bam_file .bam`


outdir=$OUT/macs2.narrow #for macs2
outdir2=$OUT/macs2.narrow.dedup #for macs2 dedup version

#outdirbroad=$OUT/macs2.broad #for macs2
#outdirbroad2=$OUT/macs2.broad.dedup #for macs2 dedup version

#outdirseac=$OUT/seacr #for seacr
#outdirseac2=$OUT/seacr.dedup #for seacr dedup version

for d in $outdir $outdir2 $outdirbroad $outdirbroad2 $outdirseac $outdirseac2; do
if [ ! -d $d ]; then
mkdir $d
fi
done

### Narrow Peaks
>&2 echo "Narrow Peaks"
narrow1="$macs2bin/macs2 callpeak -t $TEMP/dup.marked/$FILE -c $TEMP/dup.marked/$CTL -g mm -f BAMPE -n $BASE --outdir $outdir -q 0.01 -B --SPMR --keep-dup all 2> $TEMP/logs/$BASE\.macs2"
narrow2="$macs2bin/macs2 callpeak -t $TEMP/dup.marked/$FILE -c $TEMP/dup.marked/$CTL -g mm -f BAMPE -n $BASE --outdir $outdir2 -q 0.01 -B --SPMR  2> $TEMP/logs/$BASE\.dedup.macs2"
>&2 echo $narrow1
eval $narrow1
>&2 echo $narrow2
eval $narrow2

##broad peak calls
#>&2 echo "Broad Peaks"
#broad1="$macs2bin/macs2 callpeak -t $TEMP/dup.marked/$FILE -g mm -f BAMPE -n $BASE --outdir $outdirbroad --broad --broad-cutoff 0.1 -B --SPMR --keep-dup all 2> $TEMP/logs/$BASE\.broad.macs2"
#broad2="$macs2bin/macs2 callpeak -t $TEMP/dup.marked/$FILE -g mm -f BAMPE -n $BASE --outdir $outdirbroad2 --broad --broad-cutoff 0.1 -B --SPMR  2> $TEMP/logs/$BASE\.broad.dedup.macs2"
#summit1="$pythonbin/python $extratoolsbin/get_summits_broadPeak.py $outdirbroad/$BASE\_peaks.broadPeak | $bedopsbin/sort-bed - > $outdirbroad/$BASE\_summits.bed"
#summit2="$pythonbin/python $extratoolsbin/get_summits_broadPeak.py $outdirbroad2/$BASE\_peaks.broadPeak | $bedopsbin/sort-bed - > $outdirbroad2/$BASE\_summits.bed"

#>&2 echo $broad1
#eval $broad1
#>&2 echo $summit1
#eval $summit1
#>&2 echo $broad2
#eval $broad2
#>&2 echo $summit2
#eval $summit2

##SEACR peak calls
#preseac1="$macs2bin/macs2 callpeak -t $TEMP/dup.marked/$FILE -g mm -f BAMPE -n $BASE --outdir $outdirseac -q 0.01 -B --keep-dup all"
#preseac2="$macs2bin/macs2 callpeak -t $TEMP/dup.marked/$FILE -g mm -f BAMPE -n $BASE --outdir $outdirseac2 -q 0.01 -B"
#
#pileup1="$pythonbin/python $extratoolsbin/change.bdg.py $outdirseac/$BASE\_treat_pileup.bdg > $outdirseac/$BASE\_treat_integer.bdg"
#pileup2="$pythonbin/python $extratoolsbin/change.bdg.py $outdirseac2/$BASE\_treat_pileup.bdg > $outdirseac2/$BASE\_treat_integer.bdg"
#
#seacr1="$extratoolsbin/SEACR_1.1.sh $outdirseac/$BASE\_treat_integer.bdg 0.01 non stringent $outdirseac/$BASE\_treat $Rscriptbin"
#seacr2="$extratoolsbin/SEACR_1.1.sh $outdirseac2/$BASE\_treat_integer.bdg 0.01 non stringent $outdirseac2/$BASE\_treat $Rscriptbin"
#
#sort1="$bedopsbin/sort-bed $outdirseac/$BASE\_treat.stringent.bed > $outdirseac/$BASE\_treat.stringent.sort.bed"
#sort2="$bedopsbin/sort-bed $outdirseac2/$BASE\_treat.stringent.bed > $outdirseac2/$BASE\_treat.stringent.sort.bed"
#
#summitseacr1="$pythonbin/python $extratoolsbin/get_summits_seacr.py $outdirseac/$BASE\_treat.stringent.bed | $bedopsbin/sort-bed - > $outdirseac/$BASE\_treat.stringent.sort.summits.bed"
#summitseacr2="$pythonbin/python $extratoolsbin/get_summits_seacr.py $outdirseac2/$BASE\_treat.stringent.bed | $bedopsbin/sort-bed - > $outdirseac2/$BASE\_treat.stringent.sort.summits.bed"
#
#>&2 echo "Running for keep dup"
#>&2 echo $preseac1
#eval $preseac1
#>&2 echo $pileup1
#eval $pileup1
#>&2 echo $seacr1
#eval $seacr1
#>&2 echo $sort1
#eval $sort1
#>&2 echo $summitseacr1
#eval $summitseacr1

#>&2 echo "Running for remove dup"
#>&2 echo $preseac2
#eval $preseac2
#>&2 echo $pileup2
#eval $pileup2
#>&2 echo $seacr2
#eval $seacr2
#>&2 echo $sort2
#eval $sort2
#>&2 echo $summitseacr2
#eval $summitseacr2

#>&2 echo "Removing macs2 stuff"
#for i in _summits.bed _peaks.xls _peaks.narrowPeak _control_lambda.bdg _treat_pileup.bdg; do 
#rm -rf $outdirseac/"$BASE"$i
#rm -rf $outdirseac2/"$BASE"$i
#done
#
##SEACR relaxed peak calls
#rseacr1="$extratoolsbin/SEACR_1.1.sh $outdirseac/$BASE\_treat_integer.bdg 0.01 non relaxed $outdirseac/$BASE\_treat $Rscriptbin"
#rseacr2="$extratoolsbin/SEACR_1.1.sh $outdirseac2/$BASE\_treat_integer.bdg 0.01 non relaxed $outdirseac2/$BASE\_treat $Rscriptbin"
#
#sort1="$bedopsbin/sort-bed $outdirseac/$BASE\_treat.relaxed.bed > $outdirseac/$BASE\_treat.relaxed.sort.bed"
#sort2="$bedopsbin/sort-bed $outdirseac2/$BASE\_treat.relaxed.bed > $outdirseac2/$BASE\_treat.relaxed.sort.bed"
#
#summit1="pythonbin/python $extratoolsbin/get_summits_seacr.py $outdirseac/$BASE\_treat.relaxed.bed | $bedopsbin/sort-bed - > $outdirseac/$BASE\_treat.relaxed.sort.summits.bed"
#summit2="pythonbin/python $extratoolsbin/get_summits_seacr.py $outdirseac2/$BASE\_treat.relaxed.bed | $bedopsbin/sort-bed - > $outdirseac2/$BASE\_treat.relaxed.sort.summits.bed"
#
#
## Final conversion
#cur=`pwd`
#>&2 echo "Converting bedgraph to bigwig... ""$base".bam
#>&2 date
#cd $outdir
#LC_ALL=C sort -k1,1 -k2,2n $outdir/$BASE\_treat_pileup.bdg > $outdir/$BASE\.sort.bdg
#$extratoolsbin/bedGraphToBigWig $outdir/$BASE\.sort.bdg $chromsizedir/mm10.chrom.sizes $outdir/$BASE\.sorted.bw
#rm -rf "$base_file".sort.bdg
#
#cd $outdir2
#LC_ALL=C sort -k1,1 -k2,2n $outdir2/"$base_file"_treat_pileup.bdg > $outdir2/$BASE\.sort.bdg
#$extratoolsbin/bedGraphToBigWig $outdir2/$BASE\.sort.bdg $chromsizedir/mm10.chrom.sizes $outdir2/$BASE\.sorted.bw
#rm -rf $BASE\.sort.bdg



>&2 echo "Finished"
>&2 date

