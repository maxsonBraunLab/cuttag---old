#!/usr/binRscript

###
### Create plot of MapQ summaries
###

####################
### DEPENDENCIES ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

library(data.table)
suppressMessages(library(reshape2))
library(ggplot2)
suppressMessages(library(ggpubr))
library(optparse)
myDir_v <- Sys.getenv("sdata")
source(file.path(myDir_v, "code/qc/helperFxns.R"))

####################
### COMMAND LINE ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

optlist <- list(
    make_option(
        c("-u", "--uniqInputFile"),
        type = "character",
        help = "Mapq score distribution for unique reads. Made by 11_bowtie_mapqDistr. Usually $sdata/data/qc/summary/uniq_mapq_summary.txt"
    ),
    make_option(
      c("-m", "--multiInputFile"),
      type = "character",
      help = "Mapq score distribution for multi-map reads. Made by 11_bowtie_mapqDistr. Usually $sdata/data/qc/summary/multi_mapq_summary.txt"
    ),
    make_option(
      c("-t", "--treat"),
      type = "numeric",
      default = 1,
      help = "Element index to extract treatment from file identifier when identifier is split by '_'."
    ),
    make_option(
      c("-y", "--type"),
      type = "numeric",
      default = 2,
      help = "Element index to extract data type from file identifier when identifier is split by '_'."
    ),
    make_option(
      c("-r", "--rep"),
      type = "numeric",
      default = 3,
      help = "Element index to extract replicate from file identifier when identifier is split by '_'."
    ),
    make_option(
      c("-c", "--cutOff"),
      type = "numeric",
      default = 10,
      help = "MAPQ score that was used as a cut-off for good/bad reads. If NULL, reads were simply separated into unique and multi-mappers"
    ),
    make_option(
        c("-o", "--outDir"),
        type = "character",
        help = "Output directory for QC plots. Should be $sdata/data/qc/plots/alignQC/."
    )
)

p <- OptionParser(usage = "%prog -u uniqInputFile -m multiInputFile -t treat -y type -r rep -c cutOff -o outDir",
                  option_list = optlist)
args <- parse_args(p)
opt <- args$options

uniq_file_v <- args$uniqInputFile
multi_file_v <- args$multiInputFile
treat_v <- args$treat
type_v <- args$type
rep_v <- args$rep
cut_v <- args$cutOff
output_dir_v <- args$outDir

####################
### SET UP INPUT ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

### List
files_lsdt <- list("Unique" = uniq_file_v, "Multi" = multi_file_v)

### Read
data_lsdt <- sapply(files_lsdt, function(x) fread(x), simplify = F)

### Get treats
treats_v <- unique(sapply(grep("MapQ.Score", colnames(data_lsdt[[1]]), value = T, invert = T), function(x) strsplit(x, split = "_")[[1]][treat_v]))

####################################
### WRANGLE - MEAN MAPQ AND MELT ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################################

### Get means
mean_lsdt <- sapply(names(data_lsdt), function(z) {
  x <- data_lsdt[[z]]
  means_v <- sapply(treats_v, function(y) {
    cols_v <- grep(y, colnames(x), value = T)
    rm_v <- rowMeans(x[,mget(cols_v)])
    return(rm_v)
  })
  final_dt <- as.data.table(cbind(x$MapQ.Score, means_v))
  final_dt$Map <- z
  colnames(final_dt) <- c("MapQ.Score", treats_v, "Map")
  return(final_dt)
}, simplify = F)

### Melt
melt_lsdt <- sapply(data_lsdt, function(x) melt(x, id.vars = "MapQ.Score"), simplify = F)
meltMean_lsdt <- sapply(mean_lsdt, function(x) melt(x, id.vars = c("MapQ.Score", "Map")), simplify = F)

### Combine melt means
comboMean_dt <- do.call(rbind, meltMean_lsdt)
comboMean_dt$Group <- paste(comboMean_dt$variable, comboMean_dt$Map, sep = "_")

### Groups
### NOTE - THIS IS NOT COMPLETELY GENERALIZED YET
melt_lsdt <- sapply(melt_lsdt, function(x) {
  x$Treat <- sapply(x$variable, function(y) strsplit(as.character(y), split = "_")[[1]][treat_v])
  if (!is.null(type_v)) {x$Type <- sapply(x$variable, function(y) strsplit(as.character(y), split = "_")[[1]][type_v]) }
  if (!is.null(rep_v)) {x$Rep <- sapply(x$variable, function(y) strsplit(as.character(y), split = "_")[[1]][rep_v]) }
  return(x)
}, simplify = F)

##############################
### WRANGLE - MAPQ CUT-OFF ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##############################

if (!is.null(cut_v)){
  
  ## Get scores
  scores_v <- unique(unlist(sapply(melt_lsdt, function(x) unique(x$MapQ.Score))))
  badScore_v <- scores_v[scores_v <= cut_v]
  goodScore_v <- scores_v[scores_v > cut_v]
  
  ## Add seq type
  melt_lsdt <- sapply(names(melt_lsdt), function(x) {
    y <- melt_lsdt[[x]]; y$Seq <- x
    return(y)
  }, simplify = F)
  
  ## Combine
  data_dt <- do.call(rbind, melt_lsdt)
  
  ## Get total reads
  reads_dt <- data_dt[,sum(value), by = variable]
  colnames(reads_dt) <- c("variable", "total")
  
  ## Add good/bad variable
  data_dt$Good <- "good"
  data_dt[MapQ.Score %in% badScore_v, "Good" := "bad"]
  
  ## Get sums
  sum_dt <- data_dt[,sum(value), by = list(variable, Treat, Type, Rep, Good)]
  
  ## Get pct
  setkey(sum_dt, variable)[reads_dt, Pct := V1/total*100]
  
  ## Plot
  filterPlot <- ggplot(aes(x = Treat, y = Pct, color = Good, shape = Rep), data = sum_dt) +
    geom_point(size = 4, position = position_jitter(w=0.1)) +
    scale_y_continuous(breaks = seq(0,100,10), limits=c(0,100)) +
    big_label + labs(y = "Percent of Total Reads", x = "Treatment", color = "ReadType") +
    ggtitle(paste0("Distribution of 'Good' and 'Bad' Reads \n Using a MAPQ filter of ", cut_v))
  
  ## Write
  pdf(file = file.path(output_dir_v, "mapqFilterResults.pdf"))
  print(filterPlot)
  dev.off()
  
}

####################
### CREATE PLOTS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

### Get ymin and y max
ymin <- min(sapply(melt_lsdt, function(x) min(x$value)))
ymax <- max(sapply(melt_lsdt, function(x) max(x$value)))

### Create lists
raw_ls <- list()
log_ls <- list()

for (i in 1:length(melt_lsdt)){
  ## Get name
  currName_v <- names(melt_lsdt)[i]
  
  ## Make plots
  currRaw <- ggplot(aes(y = value, x = factor(MapQ.Score), color = Treat, linetype = Rep, group = variable), data = melt_lsdt[[currName_v]]) +
    geom_line() +
    scale_y_continuous(limits = c(ymin, ymax)) +
    big_label + 
    theme(axis.title.x = element_blank(),
          plot.title = element_text(size = 16)) +
    labs(y = "Read Counts", color = "Treatment", shape = "Rep") +
    ggtitle(paste0(currName_v, "-Mapped"))
  
  currLog <- ggplot(aes(y = value, x = factor(MapQ.Score), color = Treat, linetype = Rep, group = variable), data = melt_lsdt[[currName_v]]) +
    geom_line() +
    scale_y_continuous(trans = "log2", limits = c(ymin, ymax)) +
    big_label + 
    theme(axis.title.x = element_blank(),
          plot.title = element_text(size = 16)) +
    labs(y = "log2 Read Counts", color = "Treatment", shape = "Rep") +
    ggtitle(paste0(currName_v, "-Mapped"))
  
  ## Add to lists
  raw_ls[[currName_v]] <- currRaw
  log_ls[[currName_v]] <- currLog
} # for i

### Combined version
comboPlot <- ggplot(aes(x = factor(MapQ.Score), y = value, color = Map, group = Group, linetype = variable), data = comboMean_dt) + 
  geom_line() + geom_point() + big_label +
  scale_y_continuous(trans = "log2", limits = c(ymin, ymax)) +
  labs(color = "Alignment", linetype = "Treat", x = "MapQ Score", y = "log2 Read Count") +
  ggtitle("MapQ Score Distribution")

### Arrange Raw
finalRaw <- ggarrange(raw_ls$Uniquely, raw_ls$Multi, nrow = 1, ncol = 2,
                      common.legend = T, legend = "right")
finalRawFigure <- annotate_figure(finalRaw,
                                  top = text_grob("MapQ Score Distribution", size = 20),
                                  bottom = text_grob("MapQ Score", size = 18))

### Arrange Log
finalLog <- ggarrange(log_ls$Uniquely, log_ls$Multi, nrow = 1, ncol = 2,
                      common.legend = T, legend = "right")
finalLogFigure <- annotate_figure(finalLog,
                                  top = text_grob("MapQ Score Distribution - log2 Counts", size = 20),
                                  bottom = text_grob("MapQ Score", size = 18))

### Output names
rawName_v <- file.path(output_dir_v, paste0("raw_mapqDistr.pdf"))
logName_v <- file.path(output_dir_v, paste0("log2_mapqDistr.pdf"))
comboName_v <- file.path(output_dir_v, "log2_combo_mapqDistr.pdf")

### Print
pdf(file = rawName_v, width = 14)
print(finalRawFigure)
dev.off()

pdf(file = logName_v, width = 14)
print(finalLogFigure)
dev.off()

pdf(file = comboName_v, width = 12)
print(comboPlot)
dev.off()
