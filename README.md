CUT&Tag
=======

This repository contains all of the tools required to run CUT&Tag/RUN data from raw fastq files through to analyzable output. Additionally, it contains information about each step and how to determine appropriate options.  

The pipeline is currently being revised. This README should describe the current state of affairs, but there may be slight discrepancies.  

Note on Working on Exacloud
===========================

We will be running our analyses in the `MaxsonLab` directory on exacloud. If you are unfamiliar with exacloud, please take a look at ACC's [documentation](https://accdoc.ohsu.edu/exacloud/). Information on requesting an account can be found [here](https://accdoc.ohsu.edu/exacloud/guide/getting-started/), and a brief introduction to the Slurm job scheduler can be found [here](https://accdoc.ohsu.edu/exacloud/guide/job-scheduler/).

The Slurm job scheduler is used to submit jobs to compute nodes. If you are working on something interactively, please set up an interactive job so that you are not clogging up resources on the head node. For example:  

`~$ srun --mincpus 4 --mem 4G --time 1-00 --pty bash`  

Additionally, many of the executables used in this pipeline are located in the BioCoders workspace on exacloud. You can contact ACC and request to be added to this group, or you can modify the executable locations.  

Project Setup
=============

1. Log into exacloud:  

	```
	~$ ssh userName@exahead1.ohsu.edu
	~$ <enter password>
	```

1. Create a location for your project:  

	```
	~$ mkdir /path/to/MaxsonLab/myProject
	```

1. Create environment variables for commonly-used paths:  

	a. Open your `~/.bash_profile` or `~/.bashrc`

	`~$ nano .bash\_profile` or `~$ nano .bashrc`

	b. Enter these lines:  

	```
	export mlproj="/path/to/MaxsonLab/myProject"
	export mltool="/path/to/this/repo/installation"
	```

	c. If you haven't done so already, download this repository and make sure `mltool` points there:  

	`~$ git clone git@github.com:maxsonBraunLab/cuttag.git`

	d. Don't forget to source your file to update these variables:  

	`~$ source ~/.bash\_profile`

1. Transfer files. This will change depending on where the raw files originated from. Refer to the file source for instructions on how to transfer them.  

1. Follow the submit scripts in numerical order, making sure the paths are correct and any filename substitutions.

Submission Strategy
===================

A majority of the steps in this pipeline must be run on every file in a batch individually. The array functionality of slurm sbatch scripts allow us to submit one job per file to run simultaneously. There are likely many ways to accomplish this, but I have chosen to use "todo" files to specify which files should be run.  

Each submission script will have a "todo" file with one line per run. This most often contains the file name that will be used as input, but can also contain other arguments. To generate a textfile with a list of all files in the directory, change to the directory of interest and enter "dir > 20_bowtieTodo.txt". 

Within the sbatch script, the array argument (`#SBATCH --array <values>`) specifies how many jobs to run. As an example, `#SBATCH --array 1-5` will submit 5 jobs. These will all share the same built-in variable `$SLURM_ARRAY_JOB_ID` and each will have a unique `$SLURM_ARRAY_TASK_ID` that ranges from 1 to 5.  

We can use this task id to reference a specific line (i.e. file) in our todo file. The expression `awk -v line=$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}' todo.txt` will grab the line of the todo file that corresponds with the current task id. In some cases, instead of a todo file, the submission will read from the input directory, in which case `ls $IN |` will prepend the awk statement. The same principle applies.  

Align
=====

1. Use `10_sbatchTrimSeq.sh` to trim the reads using trimmomatic. This step was taken from the [CUT&RUNTools](https://genomebiology.biomedcentral.com/articles/10.1186/s13059-019-1802-4) pipeline.  

1. We use bowtie2 to align sequences to the reference, which is found in `20_sbatchMouseBowtie.sh`
	a. Make sure the appropriate reference is set.
	a. Make a todo file: `ls -v /path/to/trim/files > 20_bowtieTodo.txt`
	a. Change array argument to match number of lines in todo
	a. Submit
	a. Things to note:
		i. This script aligns and also converts sam to bam. Should remove the sam files either in this script or soon after.
		i. Other modifications (such as filtering) may want to be added here as well.

1. Use `30_sbatchFilter.sh` to filter misaligned reads. This script contains a brief explanation of what how to use samtools' filter feature if you would like to modify it. As of right now, we keep all reads that have > 1 segment that is properly aligned (i.e. successful paired alignments) and we remove all those where one of the pairs is unmapped.  

1. Convert to bed files using `31_sbatchBam2Bed.sh`. ChromHMM uses either peaks or bed files as input. **I don't think we use bam files for anything, so might include this in the filter command and immediately remove bam files.**

1. Optionally, merge bam replicates using `40_sbatchMergeBam.sh`. When we have more than one replicate for each sample, we can feed them into ChromHMM as individual files, or we can combine them together and then feed them in as one file. As of right now, we are **not** doing this, but have it here for reference.  

Peaks
=====

The numbering system is a little out of order here, at the moment. Right now this is `70_sbatchPeaks.sh` Call peaks before running ChromHMM so that either bed files or peaks may be used as input. The peak-calling script was taken from CUT&RUNTools and modified. There are lots of extra executables that aren't used that need to be removed at some point. This script contains a few processing steps before calling peaks. Additionally, it calls peaks both with and without duplicates. At this point, we are using **with duplicates**, but without is available as well. There are "flags" near the top of the script that turn each step on or off. Set each one to `true` that you want to run and set those you want to skip to `false`.  

A closely-related operation is to convert peaks to bigwig for easy visualization in IGV. Right now this is `71_sbatchBigWig.sh`, but this could be combined with the main peak calling script as well.  

ChromHMM
========

The main step in this pipeline is using ChromHMM to infer chromatin states based on the sequencing data. ChromHMM can take either bed files aligned to the reference or called peaks as input. We're not 100% sure which of these is best at the moment and so both are able to be used.  

1. The first step is to binarize the input. There are multiple different `5*_sbatchBinarize_*` scripts for the various types of input - bam, bed, merged bam, and peaks.
1. Look at the [ChromHMM Protocol](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5945550/) for details on constructing the cell mark file (called `50_cellMark_<filetype>.txt`)
1. After the input is binarized, simply run the `LearnModel` module, which can be found in `6*_sbatchChromHMM_*`. Specify the number of states expected using the `NSTATE` argument. This is dependent on the different chromatin marks used in the experiment.  

Feature Extraction
==================

After chromatin states have been predicted, we must extract the states of interest and compare them among groups. The majority of this section was adapted from a method developed by Mariam Okhovat for ChromHMM output generated from ChIP-Seq data. This section uses all of the scripts that start with 8. I have opted to record as much information as possible in the output files. To accomplish this without changing anything in the actual submission scripts, I've created a configuration file (`featureConfig.sh`) that defines the variables for a specific run.

1. The four variables that need to be defined are:
	1. `TYPE` - generally "bed" or "peak". This specifies the input type
	1. `NSTATE` - this is the number of states used in the ChromHMM call
	1. `STATE` - this is the emission state of the feature of interest (explained below)
	1. `NAME` - this is a user-specified name to label all the output files (e.g. actEnh, activeEnhancer, prom, promoter, etc.)

1. In order to determine the value for `STATE`, look at the heatmap found in `emissions_NSTATE.png` and determine which state corresponds to your feature of interest. For us, this is usually active enhancers, but could also be promoter or something else.  

1. First, extract the feature of interest from each sample using `80_sbatch_filterFeatures.sh`

1. Next, create a "union feature peak" file to merge similar, but non-overlapping peaks using `81_sbatch_featureUnion.sh` The default is to merge everything within 500-bp, but this can be modified. This step creates the largest possible peak at a given location by combining the evidence from all of the samples. For example:
	1. Sample A has a peak from 5000-5500
	1. Sample B has a peak from 4700-5200
	1. Sample C has a peak from 3800-4100
	1. The peaks from samples A and B will create a consensus peak from 4700 to 5500, but the peak in sample C will remain independent.

1. Each input file's peaks need to be extended to match up with the union peaks created above. `82_sbatch_featureIntersect.sh` does this.

1. Finally, a summary table can be created using `83_sbatch_featureMultiIntersect.sh` which has one row for each peak and a column for each sample. The corresponding cell has a 1 if that peak is found in that sample and a 0 if it is not. `84_sbatch_featureGeneMap.sh` can additionally search for the closest feature. Be sure to create the appropriate reference file for this step.  

Metrics
=======

We came up with a few metrics to try and determine which input is better out of peaks and bed files. These are of varying utility and should be modified or new tools should be added as we continue to figure out what the best ways to evaluate our results are.

1. `90_distanceToTSS.sh` uses bedops' closest-features to find the nearest TSS (this is the same as 84, but TSS instead of genes)
1. `91_featureLength.sh` determines the length of each feature
1. `countFeatures.sh` simply counts the lines in each file to get the number of features.
