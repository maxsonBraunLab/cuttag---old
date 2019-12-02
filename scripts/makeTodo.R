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
    c("-g", "--groupFile"),
    type = "character",
    help = "Path to file containing group/sample designations. (Ex: KLE, KLT, WE, WT)"
  ),
  make_option(
    c("-m", "--markerFile"),
    type = "character",
    help = "Path to file containing marker designations. (Ex: CEBPa, Stat3, etc.)"
  ),
  make_option(
    c("-o", "--outFile"),
    type = "character",
    help = "Path to output file."
  )
)

### Parse command line
p <- OptionParser(usage = "%prog -g groupFile -m markerFile -o outFile",
                  option_list = optlist)
args <- parse_args(p)
opt <- args$options

### Get arguments
groupFile_v <- args$groupFile
markerFile_v <- args$markerFile
outFile_v <- args$outFile

############
### BODY ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
############

### Read
group_dt <- fread(groupFile_v, header = F)
marker_dt <- fread(markerFile_v, header = F)

### Iterate
out_lsv <- list()
counter_v <- 1

for (i in 1:group_dt[,.N]) {
  
  one_v <- group_dt$V1[i]
  
  for (j in 1:marker_dt[,.N]) {
    
    two_v <- marker_dt$V1[j]
    out_lsv[[counter_v]] <- c(one_v, two_v)
    counter_v <- counter_v + 1
  } # for j
} # for i

### Combine
out_dt <- do.call(rbind, out_lsv)

### Write
write.table(out_dt, file = outFile_v, sep = ',', quote = F, row.names = F, col.names = F)
