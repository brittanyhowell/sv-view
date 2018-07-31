# Load
library(IRanges)



file.dir <- "~/Documents/Rotations/Rotation3/data/testView/reads/"
file.read <- "EGAN00001214492-homDel-CNV_chr1_86644_90107-reads.txt"
file.full <- paste(file.dir,file.read,sep = "/")

reads <- read.table(file.full, sep = "\t")

colnames(reads) <- c("name", "chr","start","end","cigar","mapq","AS","flags")

## Not currently needed but I want to remember how to do this
# sample.name <- strsplit(file.read, "-")[[1]][1]
# type.sv <- strsplit(file.read, "-")[[1]][2]
# name.sv <- strsplit(file.read, "-")[[1]][3]


# Process as IRanges
start = reads$start
end = reads$end
intervals <- IRanges(start = start, end = end)


bins <- disjointBins(IRanges(start(intervals), end(intervals) + 1))
bin.dat <- cbind(as.data.frame(intervals), bin = bins)
intervals <- NULL
full.table <- cbind(reads$name, bin.dat,reads$cigar, reads$mapq,reads$AS, reads$flags)
colnames(full.table) <- c("name","start", "end", "width", "bin","cigar", "mapq","AS", "flags")

