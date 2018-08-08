# Load
library(IRanges)
library(ggplot2)
library(grid)
library(ggvis)
library(plyr)
require(zoo)
library(grid)

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

sv.start.round <- round_any(sv.start,1000,f = floor)   ## Gets nice lower coordinate for the plots            

colType <- c("darkturquoise", "orange", "royalblue3", "salmon") ## Could change these based on type if you get keen, future brie

records <- read.table(file.full, sep = "\t")
colnames(records) <- c("name","start","end","bin","mapq","mate","AS", "secondary","cigar","operator","len")

## Viewport: Bottom
vp.Bottom <- viewport(height=unit(.5, "npc"), width=unit(1, "npc"), 
                      just=c("left","top"), 
                      y=0.5, x=0)


# Process intervals as IRanges
start = records$start
end = records$end
intervals <- IRanges(start = start, end = end)

cov <- coverage(intervals)
cov.smooth <- runmean(cov, 25) ## Average over 50bp



# stacked bar plot
p <-  ggplot(records) +
    geom_rect(aes(xmin = start, xmax = end,
                  ymax =bin+0.9, ymin = bin, alpha = mapq,fill = operator))+ 
    guides(alpha=guide_legend(title="Opacity:\nMapping\nQuality",ncol=4),fill=guide_legend(title="Colour:\ncigar\nOperator",ncol=2))  +
    scale_x_continuous(limits = c(sv.start.round-2000, sv.end+2000)) +
    theme_bw() +
    #theme(legend.position = c(.9, .9))  +
    geom_segment(aes(x = sv.start, y = 0, xend = sv.end, yend = 0), colour = "maroon", size=3) +
    scale_fill_manual(values=colType) + 
    xlab("genomic coordinate (bp)") +
    ylab("") +
    # theme(legend.position = c(.9, .9))+
  theme(legend.position="bottom")


## Print the plot
  
pdf(file="/Users/bh10/Documents/Rotations/Rotation3/data/testView/test_combination.pdf", width = 15, height = 10)
   

  par(mfrow=c(2,1))
  par(mar=c(3,2.5,4,1)+.1) # bottom, left, top, and right.

  plot(cov.smooth,type = "l",
  # plot(x=records$start,y=records$mapq, 
       main=paste(sample.name,type.sv,name.sv,sep=" "),
       xlim = c(sv.start.round-2000,  sv.end+2000),
       panel.first={ grid( col ="gray88")  }, 
       xlab = "",ylab= "", las=1)
    segments(sv.start,0,sv.end,0,col ="maroon",lwd=6) # plot the SV coordinates
  
  # Print the stacked bar plot
  print(p, vp=vp.Bottom)  
graphics.off()


