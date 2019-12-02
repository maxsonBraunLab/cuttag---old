#!/bin/bash

#SBATCH --partition          exacloud                # partition (queue)
#SBATCH --nodes              1                       # number of nodes
#SBATCH --ntasks             9                       # number of "tasks" to be allocated for the job
#SBATCH --ntasks-per-core    1                       # Max number of "tasks" per core.
#SBATCH --cpus-per-task      1                       # Set if you know a task requires multiple processors
#SBATCH --mem-per-cpu        8000                    # Memory required per allocated CPU (mutually exclusive with mem)
##SBATCH --mem                16000                  # memory pool for each node
#SBATCH --time               0-24:00                 # time (D-HH:MM)
#SBATCH --output             trim_%A_%a.out          # Standard output
#SBATCH --error              trim_%A_%a.err          # Standard error
#SBATCH --array              1-60                     # sets number of jobs in array

### SET I/O VARIABLES

IN=$mlproj/process/00_fastqs                             # Directory containing all input files. Should be one job per file
OUT=$mlproj/process/10_trim                              # Directory where output files should be written
trimmomaticbin=/home/groups/MaxsonLab/software/cnrTools/dependencies/Trimmomatic-0.36
trimmomaticjarfile=trimmomatic-0.36.jar
adapterpath=/home/groups/MaxsonLab/software/cnrTools/adapters
TRIM="/usr/bin/java -jar $trimmomaticbin/$trimmomaticjarfile"
mkdir -p $OUT

### Record slurm info

echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID
echo ""

### Get a file using the task ID
R1=`ls $IN/*.R1.fq.gz | awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}'`
R2=`echo $R1 | sed 's/\.R1\./\.R2\./'`

### Split file
FILE=`basename $R1`
BASE=${FILE%%.R1.fq.gz}

### Run trim bash script with input directory, input file and output directory
cd $IN

cmd="$TRIM PE -threads 1 -phred33 $R1 $R2 $OUT/$BASE\_1.paired.fastq.gz $OUT/$BASE\_1.unpaired.fastq.gz $OUT/$BASE\_2.paired.fastq.gz $OUT/$BASE\_2.unpaired.fastq.gz ILLUMINACLIP:$adapterpath/Truseq3.PE.fa:2:15:4:4:true LEADING:20 TRAILING:20 SLIDINGWINDOW:4:15 MINLEN:25" 

echo $cmd
eval $cmd
