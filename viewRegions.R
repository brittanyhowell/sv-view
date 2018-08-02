# Load
library(IRanges)
library(ggplot2)
library(grid)
library(ggvis)
library(plyr)

file.dir <- "/Users/bh10/Documents/Rotations/Rotation3/data/testView/splitTables"
file.read <- "EGAN00001214492-homDel-CNV_chr1_86644_90107-split.txt"
file.full <- paste(file.dir,file.read,sep = "/")
file.name <- gsub("-split.txt","",file.read)


sample.name <- strsplit(file.name, "-")[[1]][1]
type.sv <- strsplit(file.name, "-")[[1]][2]
name.sv <- strsplit(file.name, "-")[[1]][3]

sv.software <- strsplit(name.sv, "_")[[1]][1]
sv.chr <- strsplit(name.sv, "_")[[1]][2]
sv.start <- as.integer(strsplit(name.sv, "_")[[1]][3])
sv.end <- as.integer(strsplit(name.sv, "_")[[1]][4])

sv.start.round <- round_any(sv.start,1000,f = floor)               


records <- read.table(file.full, sep = "\t")
colnames(records) <- c("name","start","end","bin","mapq","mate","AS", "secondary","cigar","operator","len")



# Process as IRanges
start = reads$start
end = reads$end
intervals <- IRanges(start = start, end = end)


# ggplot - stacked bar plot
ggplot(records) + 
  geom_rect(aes(xmin = start, xmax = end,
                ymax =bin+0.9, ymin = bin, alpha = mapq,fill = operator))+ 
  guides(alpha=guide_legend(title="Opacity:\nMapping\nQuality"),fill=guide_legend(title="Colour:\ncigar\nOperator")) +
  scale_x_continuous(limits = c(sv.start.round-2000, sv.end+2000)) +
  theme_bw() +
  #theme(legend.position = c(.9, .9))  +
  geom_segment(aes(x = sv.start, y = 0, xend = sv.end, yend = 0), colour = "maroon", size=4) +
  scale_fill_manual(values=c( "maroon", "purple", "cornflowerblue", "black")) + 
  xlab("genomic coordinate (bp)") +
  ylab("") +
  ggtitle(file.name)
  # Change segment to start and end values



