#!/bin/sh

### Input/Output
IN=$mlproj/process/01.5_Reports/processed/summary
OUT=$mlproj/process/01.5_Reports/processed

### Make header
FILE=`ls $IN | head -1`
echo "Sample" > $OUT/finalSummary.txt
awk -F ' ' '{print $1}' $FILE >> $OUT/finalSummary.txt
cat $OUT/finalSummary.txt | tr '\n' '\t' > $OUT/foo
mv -f $OUT/foo $OUT/finalSummary.txt
sed -i -e 's/[\t]*$/\n/' $OUT/finalSummary.txt

### Populate
for file in `ls $IN`; do
	name=${file%%_summary.txt}
	echo $name > $OUT/foo
	awk -F ' ' '{print $2}' $file >> $OUT/foo
	cat $OUT/foo | tr '\n' '\t' > $OUT/boo
	sed -i -e 's/[\t]*$/\n/' $OUT/boo
	cat $OUT/boo >> $OUT/finalSummary.txt
done

rm $OUT/boo
rm $OUT/foo
