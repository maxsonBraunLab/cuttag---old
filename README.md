CUT&Tag
=======

This repository contains all of the tools required to run CUT&Tag/RUN data from raw fastq files through to analyzable output. Additionally, it contains information about each step and how to determine appropriate options.  

Note on Working on Exacloud
===========================

We will be running our analyses in the `MaxsonLab` directory on exacloud. If you are unfamiliar with exacloud, please take a look at ACC's [documentation](https://accdoc.ohsu.edu/exacloud/). Information on requesting an account can be found [here](https://accdoc.ohsu.edu/exacloud/guide/getting-started/), and a brief introduction to the Slurm job scheduler can be found [here](https://accdoc.ohsu.edu/exacloud/guide/job-scheduler/).

The Slurm job scheduler is used to submit jobs to compute nodes. If you are working on something interactively, please set up an interactive job so that you are not clogging up resources on the head node. For example:  

`~$ srun --mincpus 4 --mem 4G --time 1-00 --pty bash`

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

Align
=====


