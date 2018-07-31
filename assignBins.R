# Load
library(IRanges)


# Initiate input and output tables
  file.dir <- "~/Documents/Rotations/Rotation3/data/testView/reads/"
  file.read <- "EGAN00001214492-homDel-CNV_chr1_86644_90107-reads.txt"
  file.full <- paste(file.dir,file.read,sep = "/")
  
  
  out.DIR <- "~/Documents/Rotations/Rotation3/data/testView/binnedTables"
  out.File <- "EGAN00001214492-homDel-CNV_chr1_86644_90107-binned.txt"
  out.Table <- paste(out.DIR,out.File,sep = "/")
    

# Read input  
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

# Assign bins
  bins <- disjointBins(IRanges(start(intervals), end(intervals) + 1))
  bin.dat <- cbind(as.data.frame(intervals), bin = bins)
  intervals <- NULL

# Bind together table
  full.table <- cbind(reads$name, bin.dat,reads$cigar, reads$mapq,reads$AS, reads$flags)
  reads <- NULL
  bin.dat <- NULL
  colnames(full.table) <- c("name","start", "end", "width", "bin","cigar", "mapq","AS", "flags")

# Save table
  write.table(full.table,out.Table, quote=F, row.names=F,  sep="\t")