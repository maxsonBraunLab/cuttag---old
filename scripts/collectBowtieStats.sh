#!/bin/bash
# Jake VanCampen
# vancampe@ohsu.edu
# 
# provide bowtie error dir 
# as first command line argument
usage () {
     echo "Usage: $(basename $0) [-h] /path/to/bowtie/outfiles" >&2
     exit 1
}

# exit if no arguments supplied
if [ $# -eq 0 ]
then
    usage
    exit 1
fi

# handle the help flag and no args
while getopts ":h" opt
do 
    case ${opt} in 
        h ) usage;;
        ? ) usage;;
    esac
done 

shift $((OPTIND -1)) 

# parse command line flags
errdir=$1

getmetrics() {
   # read in the output file
   ofile=$1
   # extract the filename from the output file
   fname=$(cat $1 | grep "Base name" | cut -f 2 -d ":" | sed 's/ //g')
   # find the corresponding error file
   efile=${ofile/.out/.err}
   # if it exists
   if [ -e ${efile} ]; then
       # extract stats
       total=$(sed "s/^[ \t]*//" ${efile} | sed -n 1p | cut -f 1 -d ' ')
       mapped=$(sed "s/^[ \t]*//" ${efile} | awk 'NR==4,NR==5 {sum+=$1}END{print sum}')           percent=$(sed "s/^[ \t]*//" ${efile} | awk 'NR==6 sum{print $1}' | sed 's/%//')
       echo "${fname},${total},${mapped},${percent}"
   else
       echo ${efile}; exit 1
        # if there is no error file for the output
        # write NA's
        echo "${fname},NA,NA,NA" 
   fi
}

# get metrics for each output file
for o in ${errdir}/*.out
    do
        getmetrics ${o}
done

