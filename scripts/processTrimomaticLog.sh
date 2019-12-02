#!/bin/sh

: '
Extract info from the trim log output file. 

Makes two files
     One containing the summary information of reads and basepairs trimmed.
     One containing the number and lengths of trimmed reads.

Usage: 

for file in *.err; do sh $mltool/scripts/processTrimomaticLog.sh $file $mlproj/process/scratch/slurmLogs/; done


'

### Arguments
FILE=$1    # Log file (.err)
OUT=$2     # output directory

### Make directory
mkdir -p $OUT

### Get log line and name line
grep 'Input Read Pairs' $FILE > tempLog
grep "Trimming file " $FILE > tempName

### Get name
name=`awk -F ' ' '{print $3}' tempName`

### Reformat log
sed 's/[a-z] [A-Z]/_/g' tempLog | sed -e 's/ ([0-9]*\.[0-9]*%)//g' | sed 's/://g'  > tempLog2

### Start final log file, if empty
if [ ! -f $OUT/trimLog.txt ]; then
	awk -F ' ' -v OFS='\t' '{print "Sample", $1, $3, $5, $7, $9}' tempLog2 > trimLog.txt
fi

### Add to final log
awk -v name="$name" -F ' ' -v OFS='\t' '{print name, $2, $4, $6, $8, $10}' tempLog2 >> trimLog.txt

### Remove others
rm tempLog tempName tempLog2

