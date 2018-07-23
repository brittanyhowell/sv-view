# Plot reads to visualise SVs


# Load
library(IRanges)
library(ggplot2)
library(grid)
library(ggvis)

file.dir <- "~/Documents/Rotations/Rotation3/data/testView/reads/"
file.read <- "EGAN00001214492-homDel-CNV_chr1_86644_90107-reads.txt"
file.full <- paste(file.dir,file.read,sep = "/")

reads <- read.table(file.full, sep = "\t")
# info <- read.table("/Users/bh10/Documents/Rotations/Rotation3/data/testView/")
colnames(reads) <- c("name", "chr","start","end","cigar","mapq","AS")
reads <- head(n=1500,reads)


sample.name <- strsplit(file.read, "-")[[1]][1]
type.sv <- strsplit(file.read, "-")[[1]][2]
name.sv <- strsplit(file.read, "-")[[1]][3]


# Process as IRanges
start = reads$start
end = reads$end
intervals <- IRanges(start = start, end = end)


# # Plot Coverage
cov <- coverage(intervals)
# par(mar=c(5,6,4,1)+.1)
# plot(cov,type = "l", xlim = c(929000, 933000),panel.first={
#   grid( col ="gray88") 
# }, xlab = "chromosome coordinate",ylab= "", las=1)
# segments(930465,0,932077,0,col ="cornflowerblue",lwd=3) # plot the SV coordinates
# 
# # Function to plot boxy boxes in base R
# plotRanges <- function(x, xlim = x, main = "EGAN00001214492_CNV_chr1_930465_932077_reads.txt",
#                        col = "black", sep = .1,borderStart = SVstart-1000, borderEnd = SVend+1000, ...)
# {
#   height <- .2
#   if (is(xlim, "Ranges"))
#     xlim <- c(929000, 934000)#xlim <- c(min(start(xlim)), max(end(xlim)))
#   bins <- disjointBins(IRanges(start(x), end(x) + 1))
#   plot.new()
#   plot.window(xlim, c(0, max(bins)*(height + sep)))
#   ybottom <- bins * (sep + height) - height
#   rect(start(x)-0.5, ybottom, end(x)+0.5, ybottom + height, col = col, ...)
#   title(main)
#   axis(side=1,at=seq(929000,934000,by=1000),tcl=0.4,lwd.ticks=1,mgp=c(10,.2,0))#    axis(1)
# }

# plotRanges(intervals)


# Plot using ggplot

# Function to classify cigar string
cigarConvert <- function(x) {
  if (x == "151M") {
    val <- "151M"
  } else {
    val <- "other"
  }
  return(val)
}



# ggplot - stacked bar plot
bins <- disjointBins(IRanges(start(intervals), end(intervals) + 1))
dat <- cbind(as.data.frame(intervals), bin = bins)

# Change cigar string to '151M' or 'other'
cigar.bool <- as.data.frame(sapply(reads$cigar,cigarConvert))
dat.withCigar <- cbind(dat,cigar.bool,reads$cigar, reads$mapq,reads$AS)
colnames(dat.withCigar) <- c("start", "end", "width", "bin", "cigarClass","cigar", "mapq","AS")


# Plot the plot - colour by mapq
pdf(file="/Users/bh10/Documents/Rotations/Rotation3/data/testView/colourByQuality.pdf", width = 15, height = 5)
ggplot(dat.withCigar) + 
  geom_rect(aes(xmin = start, xmax = end,
                ymin = bin, ymax = bin + 0.9, fill= mapq))+ 
  guides(fill=guide_legend(title="Alignment\nQuality"))+
  scale_fill_gradient(low="lightblue", high="darkgreen")  +
  scale_x_continuous(limits = c(84000, 92100)) +
  theme_bw() + 
  # theme(legend.position = c(.9, .9))  + 
  geom_segment(aes(x = 86644, y = 0, xend = 90107, yend = 0), colour = "maroon", size=4) + 
  # scale_fill_manual(values=c( "black", "cornflowerblue")) + 
  xlab("genomic coordinate (bp)") +
  ylab("")  #+ 
  # scale_fill_brewer(  palette = "Blues") 
graphics.off()

smol.dat.withCigar <- tail(n=30,head(n=800,dat.withCigar))
# colour by cigar string
ggplot(smol.dat.withCigar) + 
  geom_rect(aes(xmin = start, xmax = end,
                ymin = bin, ymax = bin + 0.9, fill = cigarClass))+ 
  guides(fill=guide_legend(title="Cigar String")) +
  scale_x_continuous(limits = c(84000, 92100)) +
  theme_bw() + 
  theme(legend.position = c(.9, .9))  + 
  geom_segment(aes(x = 86644, y = 0, xend = 90107, yend = 0), colour = "maroon", size=4) + 
  scale_fill_manual(values=c( "black", "cornflowerblue")) + 
  xlab("genomic coordinate (bp)") +
  ylab("") 

## Investigating what "Bins" is
plot(smol.dat.withCigar$start,smol.dat.withCigar$bin)
five <- as.character(head(n=5,smol.dat.withCigar$cigar))
five.df <- as.data.frame(five)
# splitCigar <- 
# this counts the number of cigar bits:
length(strsplit(five[3], "[A-Z]")[[1]])
as.character(five)
# this should do it for them all:
sapply(five.df,function(x) strsplit(as.character(x), "[A-Z]")[[1]])



# strsplit(gsub("([0-9]+)","~\\1~",five[3]), "~" )



## Combine two plots:
# par( ) function, you can include the option mfrow=c(nrows, ncols) 



# Plot Coverage
cov <- coverage(intervals)

vp.Bottom <- viewport(height=unit(.5, "npc"), width=unit(1, "npc"), 
                      just=c("left","top"), 
                      y=0.5, x=0)



pdf(file="/Users/bh10/Documents/Rotations/Rotation3/data/testView/testCoverage.pdf", width = 15, height = 10)

par(mfrow=c(2,1))
par(mar=c(3,2.5,4,1)+.1) # bottom, left, top, and right.
plot(cov,type = "l", main=file.read, xlim = c(84000, 92100),panel.first={
  # plot(x=reads$start,y=reads$mapq, main=file.read,xlim = c(84000, 92100),panel.first={
  grid( col ="gray88") 
}, xlab = "",ylab= "", las=1)
segments(86644,0,90107,0,col ="maroon",lwd=6) # plot the SV coordinates



print(p, vp=vp.Bottom)     
graphics.off()


# Plot the stacked segment
# p <-   
  ggplot(dat.withCigar) + 
  geom_rect(aes(xmin = start, xmax = end,
                ymin = bin, ymax = bin + 0.9, fill = cigarClass))+ 
  guides(fill=guide_legend(title="Cigar String")) +
  scale_x_continuous(limits = c(84000, 92100),) +
  theme_bw() + 
  theme(legend.position = c(.9, .9))  + 
  geom_segment(aes(x = 86644, y = 0, xend = 90107, yend = 0), colour = "maroon", size=4) + 
  scale_fill_manual(values=c( "black", "cornflowerblue")) + 
  xlab("genomic coordinate (bp)") +
  ylab("") 



library(grid)

# ## get ggvis workin'
# # load dataset
# dataset <- read.csv("http://dl.dropboxusercontent.com/u/232839/DO_liver_variability_sex.csv", as.is=TRUE)
# head(dataset)
# 
# # what to do on hover
# on_hover <- function(x) {
#   if(is.null(x)) return(NULL)
#   mgi_symbol <- dataset$Associated.Gene.Name[x$id]
#   mgi_symbol
# }
# 
# # what to do on click
# on_click <- function(x) {
#   if(is.null(x)) return(NULL)
#   ensid <- dataset$Ensembl.Gene.ID[x$id]
#   ensembl_url <- paste0("http://useast.ensembl.org/Mus_musculus/Gene/Summary?db=core;g=", ensid)
#   browseURL(ensembl_url)
#   NULL
# }
# 
# # start ggvis
# point_size = 100 # if dots are too big/small, adjust this parameter
# dataset %>% 
#   ggvis(~protein.Sex, ~mrna.Sex, key := ~id) %>% 
#   layer_points(size := point_size) %>%
#   add_tooltip(on_hover, "hover") %>%
#   add_tooltip(on_click, "click") %>% set_options(width=600, height=600)
# 
# # Here for more ideas: https://ggvis.rstudio.com/layers.html
# 
# reads %>%
#   ggvis(~start, ~end = mapq) %>% 
#   layer_rects(x=start, x2=end,y=1,height=1)
# 
# 
# ggplot(test) + 
#   geom_rect(aes(xmin = start, xmax = end,
#                 ymin = bin, ymax = bin + 0.9, fill = cigarClass)) +
#   scale_x_continuous(limits = c(929000, 934000)) +
#   theme_bw() + 
#   geom_segment(aes(x = 930465, y = 0, xend = 932077, yend = 0)) + 
#   scale_fill_manual(values=c( "black", "cornflowerblue"))
# 

