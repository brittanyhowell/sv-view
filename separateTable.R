library('optparse')


## Set flags
option_list = list(
  make_option(c("-d", "--inDIR"), type="character", default=NULL,
              help="dataset file DIR", metavar="character"),
  make_option(c("-f", "--inTab"), type="character", default=NULL,
              help="dataset file name", metavar="character"),
  make_option(c("-i", "--sample"), type="character", default=NULL,
              help="dataset file DIR", metavar="character"),
  make_option(c("-s", "--software"), type="character", default=NULL,
              help="dataset file name", metavar="character"),
  make_option(c("-o", "--outDIR"), type="character", default=NULL,
              help="output DIR", metavar="character"),
  make_option(c("-w", "--whichSV"), type="character", default="all",
              help="output DIR", metavar="character")
);
opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);




# GenomeSTRiP CNV Pipeline
# Interprets zygosity based on depth. 
# 0 = no reads hence deletion etc. 
  CNVConvert <- function(x) {
    if (x == 0) {
      val <- "homDel"
    } else if (x == 1){
      val <- "hetDel"
    } else if (x == 2){
      val <- "ref"
    } else if (x > 2){
      val <- "Dup"
    }
    return(val)
  }

# Genome STRiP discovery Pipeline
# Interprets zygosity based on Read Pair analysis
# 0/0 is ref, 0/1 is hetDel etc. 
DISCConvert <- function(x) {
  if (x == "0/0") {
    val <- "ref"
  } else if (x == "0/1" || x == "1/0"){
    val <- "hetDel"
  } else if (x == "1/1"){
    val <- "homDel"
  } else if (x == "."){
    val <- "missing"
  }
  return(val)
} # What is a duplication? Are there other things?

# Which SVs to give
whichSVs <- opt$whichSV
  
# Directories
wkDIR <- opt$inDIR
oDIR  <- opt$outDIR

# Raw table
inFile <-   opt$inTab 
inFile.noext <- gsub(".txt", "", inFile) 
tableFile <- paste(wkDIR,inFile, sep = "/")

sample.name <-  opt$sample               # Sample name, no extensions

outTable.name <- paste(inFile.noext, sample.name, sep = "_")
outTable.file.noext <- paste(oDIR, outTable.name, sep = "/")
outTable.file <- paste (outTable.file.noext, ".txt", sep= "")

inputType <- opt$software # Options include CNV right now. # 

# Read full table
  full <- read.table(tableFile, header = T)

# Which column contains the sample, identify name and then which number column
  sample.col <- grep(sample.name, names(full), value = TRUE)
  sample.ind <- which( colnames(full)==sample.col)

# bind together the info plus the sample
  sample.bind <- full[,c(1:5,sample.ind)]
  full <- NULL
  colnames(sample.bind) <- c("chr", "start", "stop", "ID", "len", sample.name)

# Run function based on software type
  if (inputType=="CNV"){
    converted <- as.data.frame(sapply(sample.bind[,6], CNVConvert))
  } else if (inputType=="discovery"){
    converted <- as.data.frame(sapply(sample.bind[,6], DISCConvert))
  }
  

  # Drop the numerical column and replace with column with names
  sample.bind <- sample.bind[,-6]
  colnames(converted) <- "type"
  sample.bind <- cbind(sample.bind, converted)
  converted <- NULL

  # # Replace 1 with chr1
  # chr.convert <-  as.data.frame(sapply(sample.bind$chr,function(x) paste("chr",x,sep = "")))
  # colnames(chr.convert) <- "chr"
  # sample.nochr <- sample.bind[,-1]
  # sample.bind <- cbind(chr.convert,sample.nochr)
  # sample.nochr <- NULL

  chr.convert <- NULL
  
  if (whichSVs=="noRef"){
  sample.bind <-sample.bind[!(sample.bind$type =="ref"),]
  print(paste("whichSV:",whichSVs,sep=""))
  } else if  (whichSVs=="delsAndDups"){
    sample.bind <-sample.bind[(sample.bind$type =="hetDel" | sample.bind$type =="homDel" | sample.bind$type =="Dup"),] 
  }
  
# Save to file
write.table(sample.bind, outTable.file, quote=F, row.names=F,  sep="\t")

