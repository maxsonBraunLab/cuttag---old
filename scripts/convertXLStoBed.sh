#!/bin/sh

DIR=$1

for file in `ls $DIR/*_peaks.xls`; do 

	name=`basename $file`
	base=${name%%.xls}

	grep -v "^#" $file | tail -n +3 > $DIR/$base\.bed
done

