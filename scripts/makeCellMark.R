#!/usr/bin/Rscript

###
### MAKE SPECIFIC TODO FILES
###

### For certain operations (merge bam, macs2 callpeaks, etc.) the operation
### needs to be run for each group/sample multiple times. Easiest way to make
### the todo file is to make two temporary files that have the unique entries
### for both sections, then combine them.

####################
### DEPENDENCIES ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

library(data.table)
library(optparse)

####################
### COMMAND LINE ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

### Make command line
optlist <- list(
  make_option(
    c("-i", "--inputDir"),
    type = "character",
    help = "Path to directory containing bam files (merged bam) or bed files (peak calling)"
  ),
  make_option(
    c("-c", "--controlGrep"),
    type = "character",
    help = "String used to extract control sample from the others"
  ),
  make_option(
    c("-e", "--excludeGrep"),
    type = "character",
    help = "Used to remove any cell types that aren't wanted"
  ),
  make_option(
    c("-f", "--filePattern"),
    type = "character",
    help = "String used as 'pattern' argument in list.files. If blank, will use all files in inputDir"
  ),
  make_option(
    c("-p", "--prefix"),
    type = "character",
    help = "String that is prefix for each file. Just gets removed"
  ),
  make_option(
    c("-o", "--outFile"),
    type = "character",
    help = "Path to output file."
  )
)

### Parse command line
p <- OptionParser(usage = "%prog -i inputDir -c controlGrep -e excludeGrep -f filePattern -p prefix -o outFile",
                  option_list = optlist)
args <- parse_args(p)
opt <- args$options

### Get arguments
inputDir_v <- args$inputDir
ctlgrep_v <- args$controlGrep
excludeGrep_v <- args$excludeGrep
pattern_v <- args$filePattern
prefix_v <- args$prefix
outFile_v <- args$outFile

############
### BODY ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
############

### Get files
inputFiles_v <- list.files(inputDir_v, pattern = pattern_v)

### Subset
inputFiles_v <- grep(excludeGrep_v, inputFiles_v, value = T, invert = T)

### Remove control files
if (!is.null(ctlgrep_v)) {
	ctlFiles_v <- grep(ctlgrep_v, inputFiles_v, value = T)
	inputFiles_v <- grep(ctlgrep_v, inputFiles_v, value = T, invert = T)
}

### Go through each and format
out_mat <- NULL
for (i in 1:length(inputFiles_v)) {

	currFile_v <- inputFiles_v[i]
	currInfo_v <- strsplit(tools::file_path_sans_ext(gsub(prefix_v, "", currFile_v)), split = "_")[[1]]
	currCell_v <- currInfo_v[1]
	currMark_v <- currInfo_v[2]
	if (!is.null(ctlgrep_v)) {
		currCtl_v <- grep(gsub("2", "1", currCell_v), ctlFiles_v, value = T)
	} else {
		currCtl_v <- "tmp"
	}
	currOut_v <- c(currCell_v, currMark_v, currFile_v, currCtl_v)
	out_mat <- rbind(out_mat, currOut_v)
}

### Remove control column, if specified
if (is.null(ctlgrep_v)) {
	out_mat <- out_mat[,1:3]
}

write.table(out_mat, file = outFile_v, sep = '\t', quote = F, row.names = F, col.names = F)

