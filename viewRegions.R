# Load
suppressPackageStartupMessages(library(IRanges))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(grid))
# suppressPackageStartupMessages(library(ggvis))
suppressPackageStartupMessages(library(plyr))
# suppressPackageStartupMessages(library(zoo))
suppressPackageStartupMessages(library(grid))
suppressPackageStartupMessages(library(optparse))

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

## Declare variables
  print("declaring variables")
  file.dir <- opt$inDIR
  file.read <- opt$inTab
  file.full <- paste(file.dir,file.read,sep = "/")
  file.name <- gsub("-split.txt","",file.read)


  out.dir <- opt$outDIR
  out.name <- gsub("-split.txt",".pdf",file.read)
  plot.name <- paste(out.dir,out.name,sep = "/")
  
  sample.name <- strsplit(file.name, "-")[[1]][1]
  type.sv <- strsplit(file.name, "-")[[1]][2]
  name.sv <- strsplit(file.name, "-")[[1]][3]
  
  sv.software <- strsplit(name.sv, "_")[[1]][1]
  sv.chr <- strsplit(name.sv, "_")[[1]][2]
  sv.start <- as.integer(strsplit(name.sv, "_")[[1]][3])
  sv.end <- as.integer(strsplit(name.sv, "_")[[1]][4])

# Gets nice lower coordinate for the plots            
  sv.start.round <- round_any(sv.start,1000,f = floor)   

# Could change these based on type if you get keen, future brie
  colType <- c("darkturquoise", "orange", "royalblue3", "salmon") 

# Viewport: Bottom
  vp.Bottom <- viewport(height=unit(.5, "npc"), width=unit(1, "npc"), 
                      just=c("left","top"), 
                      y=0.5, x=0)

  
## Read input table
  print("reading input table")
  records <- read.table(file.full, sep = "\t")
  colnames(records) <- c("name","start","end","bin","mapq","mate","AS", "secondary","cigar","operator","len")




# Process intervals as IRanges
  start = records$start
  end = records$end
  intervals <- IRanges(start = start, end = end)
  
  cov <- coverage(intervals)
  cov.smooth <- runmean(cov, 100) ## Average over 50bp
  
# save the stacked bar plot
  p <-   ggplot(records) +
          geom_rect(aes(xmin = start, xmax = end,
                        ymax =bin+0.9, ymin = bin, alpha = as.numeric(as.character(mapq)),fill = operator))+ 
          guides(alpha=guide_legend(title="Opacity:\nMapping\nQuality",ncol=4),fill=guide_legend(title="Colour:\ncigar\nOperator",ncol=2))  + 
          scale_x_continuous(limits = c(sv.start.round-2000, sv.end+2000)) +
          theme_bw() +
          geom_segment(aes(x = sv.start, y = 0, xend = sv.end, yend = 0), colour = "maroon", size=2) +
          scale_fill_manual(values=colType) +
          xlab("genomic coordinate (bp)") +
          ylab("") +
        theme(legend.position="bottom")


## Save plot as pdf
  print(paste("printing plot",name.sv,sep=" "))
  pdf(file=plot.name, width = 13, height = 8)
   
    ## Set up coverage plot to print on the top
      par(mfrow=c(2,1))
      par(mar=c(3,2.5,4,1)+.1) # bottom, left, top, and right.
    
      plot(cov.smooth,type = "l",
         main=paste(sample.name,type.sv,name.sv,sep=" "),
         xlim = c(sv.start.round-2000,  sv.end+2000),
         panel.first={ grid( col ="gray88")  }, 
         xlab = "",ylab= "", las=1)
      segments(sv.start,0,sv.end,0,col ="maroon",lwd=6) # plot the SV coordinates
      
    ## Print the stacked bar plot on the bottom
    print(p, vp=vp.Bottom)  
  # dev.off()
  graphics.off()
  
  cov.smooth <- NULL
  

print(paste("Complete",name.sv,sep=" "))
gc(TRUE)

