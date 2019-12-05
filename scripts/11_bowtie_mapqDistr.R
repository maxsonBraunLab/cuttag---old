#!/usr/bin/Rscript

###
### Bowtie2 MapQ Score Distributions
###

### DESCRIPTION - Aggregate mapq scores for all samples into distribution for visualization

####################
### DEPENDENCIES ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

suppressMessages(library(data.table))
library(optparse)

####################
### COMMAND LINE ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

optlist <- list(
  make_option(
    c("-i", "--inputDir"),
    type = "character",
    help = "Directory to mapQ QC data. Should be $sdata/data/qc/[multi/uniq]_mapq/ (or similar)."),
  make_option(
    c("-o", "--outDir"),
    type = "character",
    help = "Path to output directory. Should be $sdata/data/qc/summary/ (or similar)."),
  make_option(
    c("-f", "--fields"),
    type = "character",
    default = "2,3",
    help = "Comma-sep, no spaces. Numbers of fields to extract from file name to use as unique identifier. Separated by '_'.")
)

### Parse command line
p <- OptionParser(usage = "%prog -i inputDir -o outDir -f fileds",
	option_list = optlist)

args <- parse_args(p)
opt <- args$options

input_dir_v <- args$inputDir
output_dir_v <- args$outDir
fields_v <- args$fields

###############
### WRANGLE ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###############

### Handle comma-sep args
fields_v <- as.numeric(unlist(strsplit(fields_v, split = ",")))

### Get type prefix (multi or uniq)
prefix_v <- gsub("_mapq", "", basename(input_dir_v))

### Get list of files
input_files_v <- list.files(input_dir_v)

### Extract pertinent identification fields
file_names_v <- sapply(input_files_v, function(x){
    ## split
    temp.split <- unlist(strsplit(gsub(".txt", "", x), split = "_"))
    ## paste subset
    out.name <- paste(temp.split[fields_v], collapse = "_")
    return(out.name)
}, USE.NAMES=F)

###############
### WRANGLE ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###############

### Create output data.table
total_data_dt <- data.table("Num.Reads" = NA, "MapQ.Score" = NA)

### Extract mapq score from each file
for (i in 1:length(input_files_v)){
    ## Get name
    curr_file_v <- input_files_v[i]
    ## Read data
    curr_data_dt <- fread(file.path(input_dir_v, curr_file_v))
    ## Assign matching column names
    colnames(curr_data_dt) <- c("Num.Reads", "MapQ.Score")
    ## Merge with output
    total_data_dt <- merge(total_data_dt, curr_data_dt, by = "MapQ.Score", all = T, suffixes = c(i, i+1))
} # for i

### Remove 1st row (all NA), which is artifact from data.table creation
total_data_dt <- total_data_dt[2:nrow(total_data_dt),]

### Remove first Num.Reads column (all NA), which is also artifact from data.table creation
total_data_dt <- total_data_dt[,`Num.Reads1`:= NULL]

### Turn NA to 0 (NAs will be present if a certain file doesn't have a mapq score that others do)
total_data_dt[is.na(total_data_dt)] <- 0

### Add new file identifiers
colnames(total_data_dt) <- c("MapQ.Score", file_names_v)

### Write output
write.table(total_data_dt, 
	    file = file.path(output_dir_v, paste0(prefix_v, "_mapq_summary.txt")), 
	    quote = F, sep = '\t', row.names = F)
