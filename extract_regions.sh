##Extract specified regions from bamfile

# Input files required: 
# Bam files per sample
# Interval table per software. 


# Input callset software type:
software="CNV" 
# DIRs:
# Scripts:
scriptDIR=/lustre/scratch115/projects/interval_wgs/analysis/sv/viewSV/scripts/
# Folder for intervals: 
intDIR="/lustre/scratch115/projects/interval_wgs/analysis/sv/viewSV/intervals_${software}"



# DIR for interval lists per sample
if [ -d $intDIR ]; then
    echo "Folder $intDIR exists ...replacing" 
    rm -rf $intDIR
    mkdir $intDIR
else
    mkdir $intDIR
    echo "Folder $intDIR does not exist ... creating"     
    
fi

# DIR for reads per interval
if [ -d $svReadsDIR ]; then
    echo "Folder $svReadsDIR exists ...replacing" 
    rm -rf $svReadsDIR
    mkdir $svReadsDIR
else
    mkdir $svReadsDIR
    echo "Folder $svReadsDIR does not exist ... creating"     
    
fi

# For sample (in x)  (Probably run one sample per job in an array - maybe list the samples, and then bsub a job array. 
# for now (maybe this will have to be in a sub script?)

    sample="EGAN00001214492"
    software=$software 
    # pass in relevant DIRs

        STinDIR="/Users/bh10/Documents/Rotations/Rotation3/data/testView/"
        STinTab="GS_filtered_DEL_CNV.txt"
        STsample=${sample}
        SToutDIR="/Users/bh10/Documents/Rotations/Rotation3/data/testView/"
        STsoftware=${software}

        /software/R-3.4.0/bin/Rscript ${scriptDIR}/separateTable.R   -f ${STinDIR} -d ${STinDIR} -i ${STsample} -o ${SToutDIR} -s ${STsoftware}

        RBCindex="/lustre/scratch115/projects/interval_wgs/testBams/EGAN00001207556.bam.bai"
        RBCbam="/lustre/scratch115/projects/interval_wgs/testBams/EGAN00001207556.bam"
        RBCint="smolInt.txt"
        RBCout="/lustre/scratch115/projects/interval_wgs/analysis/sv/viewSV/reads_${software}"
        RBCsampleName=${sample}

        echo "running readBamChunks.go to get folder of read files per SV"
        echo "go run ${scriptDIR}/readBamChunks/readBamChunks.go -index=${RBCindex} -bam=${RBCbam}
         -intFile=${RBCint} -outPath=${RBCout} -sampleName=${RBCsampleName}"
        
        go run ${scriptDIR}/readBamChunks/readBamChunks.go -index=${RBCindex} -bam=${RBCbam}
         -intFile=${RBCint} -outPath=${RBCout} -sampleName=${RBCsampleName}

        ABinDIR="/Users/bh10/Documents/Rotations/Rotation3/data/testView/reads/"
        ABinTab="EGAN00001214492-homDel-CNV_chr1_86644_90107-reads.txt"
        ABoutDIR="/Users/bh10/Documents/Rotations/Rotation3/data/testView/binnedTables"

        echo "running assignBins.R to assign the reads a height"
        echo "Rscript assignBins.R -d ${ABinDIR} -f ${ABinTab} -o ${ABoutDIR}"

        Rscript ${scriptDIR}/assignBins.R -d ${ABinDIR} -f ${ABinTab} -o ${ABoutDIR}

        SCbinFile="/Users/bh10/Documents/Rotations/Rotation3/data/testView/binnedTables/EGAN00001214492-homDel-CNV_chr1_86644_90107-binned.txt"
        SCoutDIR="/Users/bh10/Documents/Rotations/Rotation3/data/testView/splitTables/"
        SCoutFile="EGAN00001214492-homDel-CNV_chr1_86644_90107-split.txt"

        echo "running splitCigar.go to expand the cigar strings"
        echo "go run ${scriptDIR}/splitCigar/splitCigar.go -binFile=${SCbinFile} -outPath=${SCoutDIR} -outFile=${SCoutFile}"

        go run ${scriptDIR}/splitCigar/splitCigar.go -binFile=${SCbinFile} -outPath=${SCoutDIR} -outFile=${SCoutFile}


        VRinDIR="/Users/bh10/Documents/Rotations/Rotation3/data/testView/splitTables/"
        VRinTab="EGAN00001214492-homDel-CNV_chr1_86644_90107-split.txt"
        VRoutDIR="/Users/bh10/Documents/Rotations/Rotation3/data/testView/cov_read_plots"

        echo "running viewRegions.R to produce plots"
        echo "Rscript viewRegions.R -d ${VRinDIR} -f ${VRinTab} -o ${VRoutDIR}"
        Rscript ${scriptDIR}/viewRegions.R -d ${VRinDIR} -f ${VRinTab} -o ${VRoutDIR}


