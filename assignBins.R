# Load
library(IRanges)

## Set flags
option_list = list(
  make_option(c("-d", "--inDIR"), type="character", default=NULL,
              help="dataset file DIR", metavar="character"),
  make_option(c("-f", "--inTab"), type="character", default=NULL,
              help="dataset file name", metavar="character"),
  make_option(c("-o", "--outDIR"), type="character", default=NULL,
              help="output DIR", metavar="character")
);
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);




# Initiate input and output tables
  file.dir <- opt$inDIR
  file.read <- opt$inTab
  file.full <- paste(file.dir,file.read,sep = "/")

  out.DIR <- opt$outDIR
  out.File <- gsub("reads","binned",file.read)   
  out.Table <- paste(out.DIR,out.File,sep = "/")

# Read input  
  reads <- read.table(file.full, sep = "\t")
  colnames(reads) <- c("name", "chr","start","end","tlen","cigar","mapq","AS","flags")

# Process as IRanges
  start = reads$start
  end = reads$end
  intervals <- IRanges(start = start, end = end)

# Assign bins
  bins <- disjointBins(IRanges(start(intervals), end(intervals) + 1))
  bin.dat <- cbind(as.data.frame(intervals), bin = bins)
  intervals <- NULL

# Bind together table
  full.table <- cbind(reads$name, bin.dat,reads$cigar, reads$mapq,reads$AS, reads$flags,reads$tlen)
  reads <- NULL
  bin.dat <- NULL
  colnames(full.table) <- c("name","start", "end", "width", "bin","cigar", "mapq","AS", "flags","tlen")

# Save table
  write.table(full.table,out.Table, quote=F, row.names=F,  sep="\t")
  