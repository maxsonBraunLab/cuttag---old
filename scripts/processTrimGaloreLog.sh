#!/bin/sh

: '
Extract info from the trim log output file. 

Makes two files
     One containing the summary information of reads and basepairs trimmed.
     One containing the number and lengths of trimmed reads.

Usage: 

cd $sdata/02_trimLog
for file in *_report.txt; do name=${file%%_L005*}; sh $sdata/code/qc/01_processTrimLog.sh $file $name $sdata/data/qc/trimLogProcessed/; done


'

### Arguments
FILE=$1    # Log file
NAME=$2    # Output name. Example: File - DNA180319MS_CM_IP_1_S28_L005_R1_001.fastq_trimming_report.txt
           #                       Name - DNA180319MS_CM_IP_1_S28
OUT=$3     # output directory

### Update
printf "Working on file %s. \nWriting output to %s with base name %s\n\n" "$FILE" "$OUT" "$NAME"


###
### Extract summary
###

### Update
echo "Working on Summary"
echo ""

### Make new directory
mkdir -p $OUT/summary

### Get the appropriate lines
grep -A 8 "=== Summ" $FILE | grep -v "^$" | grep -v "^=" > temp

### Turn spaces to underscore
sed 's/ /_/g' temp > temp2

### Remove big space
sed 's/:_*/ /' temp2 > temp

### Remove parenthetical names, percentages, and _bp
sed 's/_([a-z_]*)//' temp | sed 's/_([0-9.%]*)//' | sed 's/_bp//' > temp2

### Move to final file
mv temp2 $OUT/summary/$NAME\_summary.txt

###
### Values
###

### Update
echo "Working on trim distribution"
echo ""

### Make new directory

mkdir -p $OUT/trimDist

### Grab the title row and all of the trim length rows
awk -F '\t' '{if (($1 == "length") || (($1 ~ /^[0-9]+$/) && ($2 ~ /^[0-9]+$/))) print $0}' $FILE > $OUT/trimDist/$NAME\_trimDist.txt

rm temp
