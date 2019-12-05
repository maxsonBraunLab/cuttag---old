#!/usr/bin/Rscript

###
### Bowtie2 Alignment Summary
###

### DESCRIPTION - Extract run statistics from slurm error files created from 10_run_bowtie2.sh
###               Will get number aligned, multi-mapped, and unaligned (and also percentages)

####################
### Dependencies ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

library(optparse)

####################
### COMMAND LINE ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

optlist <- list(
  make_option(
    c("-i", "--inputDir"),
    type = "character",
    help = "Directory containing all bowtie2_<cluster.num>.err files. Should be $sdata/logs/10_bowtie (or similar)."),
  make_option(
    c("-o", "--outDir"),
    type = "character",
    help = "Directory to output data. Should be $sdata/data/qc/summary.")
)

### Parse command line
p <- OptionParser(usage = "%prog -i inputDir -o outDir",
	option_list = optlist)

args <- parse_args(p)
opt <- args$options

input.dir <- args$inputDir
out.dir <- args$outDir

###############
### WRANGLE ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###############

### Examine the current directory for the files to process
files.in.dir <- list.files(input.dir, pattern="*.err");

### Sort them (shouldn't need this, but just in case)
files.in.dir <- files.in.dir[order(as.numeric(gsub("bowtie2_[0-9]+_|\\.err", "", files.in.dir)))]

### Create output data.frame of appropriate fields
output.df <- data.frame(sample=character(),                 # 1
                        total.reads=integer(),
                        no.alignment=integer(),
                        no.alignment.pct=integer(),
                        single.alignment=integer(),         # 5
                        single.alignment.pct=integer(),
			multiple.alignment=integer(),
                        multiple.alignment.pct=integer(),
                        overall.alignment.pct=integer(),
                        stringsAsFactors=FALSE);

#############
### PARSE ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#############

### Parse each file and update fields
for(i in 1:length(files.in.dir))	{
    ## Get file
    curr.file <- file.path(input.dir, files.in.dir[i]);
    
    ## Read file
    curr.record <- readLines(curr.file);

    ## Make sure it's the right file
    if(length(curr.record) != 7)   {
        stop("Unexpected length of report for file: ", curr.file, "\n", sep="");
    }   #   fi

    ## Get name
    curr.name <- curr.record[1]

    ## Total number of reads
    curr.total <- strsplit(curr.record[2], " ")[[1]][1]

    ## Number NOT aligned
    curr.no.align.full <- unlist(strsplit(trimws(curr.record[4]), " "))
    curr.no.align <- curr.no.align.full[1]
    curr.pct.no.align <- as.numeric(gsub("\\(|\\)|%", '', curr.no.align.full[2]))

    ## Number UNIQUE alignment
    curr.one.align.full <- unlist(strsplit(trimws(curr.record[5]), " "))
    curr.one.align <- curr.one.align.full[1]
    curr.pct.one.align <- as.numeric(gsub("\\(|\\)|%", '', curr.one.align.full[2]))

    curr.mult.align.full <- unlist(strsplit(trimws(curr.record[6]), " "))
    curr.mult.align <- curr.mult.align.full[1]
    curr.pct.mult.align <- as.numeric(gsub("\\(|\\)|%", '', curr.mult.align.full[2]))

    curr.overall <- gsub("%", "", unlist(strsplit(trimws(curr.record[7]), " "))[1])

    ## Add to output
    output.df[i,]$sample <- curr.name
    output.df[i,]$total.reads <- curr.total
    output.df[i,]$no.alignment <- curr.no.align
    output.df[i,]$no.alignment.pct <- curr.pct.no.align 
    output.df[i,]$single.alignment <- curr.one.align
    output.df[i,]$single.alignment.pct <- curr.pct.one.align 
    output.df[i,]$multiple.alignment <- curr.mult.align
    output.df[i,]$multiple.alignment.pct <- curr.pct.mult.align 
    output.df[i,]$overall.alignment.pct <- curr.overall 
     
}	#	for i

##############
### OUTPUT ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##############

### Write Output
write.table(output.df, 
            file=file.path(out.dir, "bowtie2.alignment.QC.summary.txt"),
            quote=FALSE,
            sep="\t",
            row.names=FALSE)

