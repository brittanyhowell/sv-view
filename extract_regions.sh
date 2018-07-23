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
# Folder for reads per interval
svReadsDIR="/lustre/scratch115/projects/interval_wgs/analysis/sv/viewSV/reads_${software}"


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

        # Run separate table to get summary table for sample
        /software/R-3.4.0/bin/Rscript ${scriptDIR}/separateTable.R # enter arguments

        # Run read extraction program to get folder of read files per SV
        go run ${scriptDIR}/readBamChunks.go -index=/lustre/scratch115/projects/interval_wgs/testBams/EGAN00001207556.bam.bai -bam=/lustre/scratch115/projects/interval_wgs/testBams/EGAN00001207556.bam -intFile=smolInt.txt -outPath=${svReadsDIR} -sampleName=${sample}

        # sample for testing
        # go run readBamChunks.go -index=/lustre/scratch115/projects/interval_wgs/testBams/EGAN00001207556.bam.bai -bam=/lustre/scratch115/projects/interval_wgs/testBams/EGAN00001207556.bam -intFile=/lustre/scratch115/projects/interval_wgs/analysis/sv/viewSV/GS_filtered_DEL_CNV_EGAN00001214492.txt -outPath=/lustre/scratch115/projects/interval_wgs/analysis/sv/viewSV/reads/ -sample="EGAN00001214492"






    ## Look up coordinates of SV

    chr=1
    start=86643
    end=90107

