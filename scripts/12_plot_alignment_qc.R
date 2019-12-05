###
### Plot Alignment QC Metrics
###

####################
### DEPENDENCIES ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

suppressMessages(library(data.table))
suppressMessages(library(ggplot2))
suppressMessages(library(ggpubr))
suppressMessages(library(gridExtra))
library(optparse)
#source("~/stable_repos_11_17/BcorePlotting/R/SummaryPlots.R")
myDir_v <- Sys.getenv("sdata")
source(file.path(myDir_v, "code/qc/helperFxns.R"))

####################
### COMMAND LINE ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

optlist <- list(
    make_option(
        c("-i", "--inputFile"),
        type = "character",
        help = "Mapq summary file made by 10_bowtie_alignment_qc.R. Usually $sdata/data/qc/summary/bowtie2.alignment.QC.summary.txt"
    ),
    make_option(
        c("-o", "--outDir"),
        type = "character",
        help = "Output directory for QC plots. Should be data/qc/plots/alignQC."
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
    )
)

p <- OptionParser(usage = "%prog -i inputFile -o outDir -t treat -y type -r rep",
                  option_list = optlist)
args <- parse_args(p)
opt <- args$options

input_file_v <- args$inputFile
out_dir_v <- args$outDir
treat_v <- args$treat
type_v <- args$type
rep_v <- args$rep

####################
### SET UP INPUT ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################

### Get data
input_data_dt <- fread(input_file_v)

### Add treatment, type, and rep columns
input_data_dt$Treat <- sapply(input_data_dt$sample, function(x) unlist(strsplit(x, split = "_"))[treat_v])
input_data_dt$Type <- sapply(input_data_dt$sample, function(x) unlist(strsplit(x, split = "_"))[type_v])
input_data_dt$Rep <- sapply(input_data_dt$sample, function(x) unlist(strsplit(x, split = "_"))[rep_v])

### Update column types
meltCols_v <- c("total.reads", "single.alignment.pct", "multiple.alignment.pct")
for (col_v in meltCols_v) set(input_data_dt, j = col_v, value = as.numeric(input_data_dt[[col_v]]))

### Divide total read by million
input_data_dt$total.reads <- input_data_dt$total.reads / 1000000

### Melt
melt_dt <- melt(input_data_dt[,mget(c("sample", meltCols_v, "Treat", "Type", "Rep"))],
                measure.vars = meltCols_v)

#############
### PLOTS ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#############

### Total reads
totalReads <- ggplot(aes(y = value, x = Treat, color = Treat, shape = Rep), data = melt_dt[variable == "total.reads"]) +
  geom_point(size = 3) +
  ggtitle("Total Reads") +
  big_label + angle_x +
  theme(legend.position = "none",
        axis.title.x = element_blank(),
        plot.title = element_text(size = 16)) +
  labs(y = "Reads (millions)")

pctUniq <- ggplot(aes(y = value, x = Treat, color = Treat, shape = Rep), data = melt_dt[variable == "single.alignment.pct"]) +
  geom_point(size = 3, position = position_jitter(width = 0.1)) +
  ggtitle("Unique Alignments") +
  big_label + angle_x +
  theme(legend.position = "none",
        axis.title.x = element_blank(),
        plot.title = element_text(size = 16)) +
  labs(y = "Percent") +
  scale_y_continuous(lim=c(0,100))

pctMulti <- ggplot(aes(y = value, x = Treat, color = Treat, shape = Rep), data = melt_dt[variable == "multiple.alignment.pct"]) +
  geom_point(size = 3, position = position_jitter(width = 0.1)) +
  ggtitle("Multiple Alignments") +
  big_label + angle_x +
  theme(axis.title.x = element_blank(),
        plot.title = element_text(size = 16)) +
  labs(y = "Percent") +
  scale_y_continuous(lim=c(0,100))

### Arange
finalPlot <- ggarrange(totalReads, pctUniq, pctMulti, nrow = 1, ncol = 3,
                       common.legend = T, legend = "right")

finalFigure <- annotate_figure(finalPlot,
                               top = text_grob("Alignment Results", size = 20),
                               bottom = text_grob("Treatment", size = 18))

### Write
pdf(file = paste0(out_dir_v, "bowtie2_qc_plots.pdf"), width = 10)

print(finalFigure)

dev.off()

