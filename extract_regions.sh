#!/bin/bash

## what I need to do: 
# Make files per sample
# add a reporting thing, to count how many SVs of each type in the CNV thing. please. 

# Maybe it's better to make a folder per sample, work in there, and then at the end, move the plots into a directory with all samples. 


##Extract specified regions from bamfile

## This script takes output from Genome STRiP - CNV pipeline (more to be added later) and prints a plot of reads in the SVs per sample. 
## Why? Because it's nice to visualise what the SV caller saw, and therefore what it calls as an SV, to train yourself on what a "real" one might be.

## Input files needed: 
# Interval table from CNV, with columns as arranged in github.com/brittanyhowell/sv-detect/blob/master/genomestrip/extract_genotyped_cnv.sh
# Bam file used, with index

## IniTiALisE

    # Raw inputs
    bamDIR=/lustre/scratch115/projects/interval_wgs/testBams/
    STinDIR=/Users/bh10/Documents/Rotations/Rotation3/data/testView/
    STinTab="GS_filtered_DEL_CNV.txt"                                   ## Name of the raw table
    sample="EGAN00001214492" 


    # Scripts and junk
    scriptDIR=/lustre/scratch115/projects/interval_wgs/analysis/sv/viewSV/scripts/
    # wkDIR=/lustre/scratch115/projects/interval_wgs/analysis/sv/viewSV/viewSV-out/
    wkDIR="/Users/bh10/Documents/testView/aug13"
    
    # settings
    software="CNV" 
    whichSVs="refOnly" # options include "noRef" or "all" (actually right now it's noRef or nothing..)

    # Software and location
    R_version="/software/R-3.5.0/bin/"
    go_version="/software/team151/gcc-8.1.0/bin/"

    ## A number of folders need to be created for the intermediate file steps. 
    ## This statement will delete EVERYTHING, and will replace it with new ones. 

    # The root folder. 
        if [ -d "${wkDIR}_${sample}" ]; then
            echo "your directory ${wkDIR}_${sample} already existed.... ...I have replaced it. All." 
            rm -rf "${wkDIR}_${sample}"
            mkdir -p "${wkDIR}_${sample}"
        else
            mkdir -p "${wkDIR}_${sample}"
            echo "Folder ${wkDIR}_${sample} didn't exist ... creating it for you!"
        fi
        
    #### Make the output tables: 
   
        # separateTable.R - makes one SV coord table per sample
            SToutDIR="${wkDIR}_${sample}/${software}-raw_tables"
        # readBamChunks.go - makes one file of reads per SV, per sample
            RBCoutDIR="${wkDIR}_${sample}/${software}-reads"
        # assignBins.R - gives reads height for a plot
            ABoutDIR="${wkDIR}_${sample}/${software}-binned"
        # splitCigar - splits constructs into cigar constituents
            SCoutDIR="${wkDIR}_${sample}/${software}-cigar_split"
        # viewRegions - makes the plots. 
            VRoutDIR="${wkDIR}_${sample}/${software}-plots"

            mkdir -p ${SToutDIR}
            mkdir -p ${RBCoutDIR}
            mkdir -p ${ABoutDIR}
            mkdir -p ${SCoutDIR}
            mkdir -p ${VRoutDIR}


        
        ## Use raw GS table, separate out the relevant colums for the current sample. Can only have non-reference, or all. 


        STinDIR=${rawTabDIR}  ## Where the raw table is
        STsample=${sample}
        STsoftware=${software}
        # made in the R script, rather than for an argument
        stOutInterValTable="${STinTab%.txt}_${sample}.txt" 

        # File with original data
        if [ -f ${STinDIR}/${STinTab} ]; then
            echo "file $STinDIR exists ...continuing" 
        else
            echo "Folder $STinDIR does not exist ... exiting"     
            exit
        fi

            echo "running separateTable.R to pull out ${whichSVs} SVs from the original table"
            echo "call: ${Rversion}/Rscript ${scriptDIR}/separateTable.R   -f ${STinDIR} -d ${STinDIR} -i ${STsample} -o ${SToutDIR} -s ${STsoftware} -w ${whichSVs}"
            
            ${Rversion}/Rscript ${scriptDIR}/separateTable.R   -f ${STinDIR} -d ${STinDIR} -i ${STsample} -o ${SToutDIR} -s ${STsoftware} -w ${whichSVs}

        ## Retrieve list of intervals for the sample from SToutDIR and withdraw the reads
        ## Put output in RBCout/sample
        ## This is the script which makes several files, one per SV for the current sample

            RBCindex="${bamDIR}/${sample}.bam.bai"
            RBCbam="${bamDIR}/${sample}.bam"
            RBCint="${SToutDIR}/${stOutInterValTable}"
            RBCsampleName=${sample} 

            echo "running readBamChunks.go to get reads per SV"
            echo "Call: ${go_version}/go run ${scriptDIR}/readBamChunks/readBamChunks.go -index=${RBCindex} -bam=${RBCbam}
            -intFile=${RBCint} -outPath=${RBCout} -sampleName=${RBCsampleName}"
            
            ${go_version}/go run ${scriptDIR}/readBamChunks/readBamChunks.go -index=${RBCindex} -bam=${RBCbam}
            -intFile=${RBCint} -outPath=${RBCout} -sampleName=${RBCsampleName}


        ## Retrieve list of read tables from RBCout and assign them a bin value
        ## Put output in ABoutDIR/sample

            ABinDIR=${RBCout}
            listReads=$(ls ${ABinDIR}/*.txt)

            for readTable in ${listReads} ; do 
                ABinTab=${readTable}

                echo "running assignBins.R to assign the reads a height for ${ABinTab}"
                echo "Call: Rscript assignBins.R -d ${ABinDIR} -f ${ABinTab} -o ${ABoutDIR}"

                ${Rversion}/Rscript ${scriptDIR}/assignBins.R -d ${ABinDIR} -f ${ABinTab} -o ${ABoutDIR}
            done

        ## Retrieve binned tables from ABoutDIR and split the records into their cigar constituents
        ## Put output in SCoutDIR/sample

            SCbinDIR=${ABoutDIR}   ## source files in ABoutDIR
            listBinnedReads=$(ls ${SCbinDIR}/*.txt)
        
            for binnedReadTable in ${listBinnedReads} ; do
                SCbinFile=${binnedReadTable}

                echo "running splitCigar.go to expand the cigar strings for ${SCbinFile}"
                echo "Call: ${go_version}/go run ${scriptDIR}/splitCigar/splitCigar.go -inDIR=${SCbinDIR} -binFile=${SCbinFile} -outPath=${SCoutDIR}"
                ${go_version}/go run ${scriptDIR}/splitCigar/splitCigar.go -inDIR=${SCbinDIR} -binFile=${SCbinFile} -outPath=${SCoutDIR}
            done

        ## Retrieve split tables from SCoutDIR and plot them. 
        ## Put output in VRoutDIR/sample

            VRinDIR=${SCoutDIR}                         ## source files in SC outDIR
            listSplitTables=$(ls ${VRinDIR}/*.txt)     ## Lists all files without absolute path

            for splitTable in ${listSplitTables} ; do
                VRinTab=${splitTable}
                echo "running viewRegions.R to produce plots for ${VRinTab}"
                echo "Call: ${Rversion}/Rscript ${scriptDIR}/viewRegions.R -d ${VRinDIR} -f ${VRinTab} -o ${VRoutDIR}"
                ${Rversion}/Rscript ${scriptDIR}/viewRegions.R -d ${VRinDIR} -f ${VRinTab} -o ${VRoutDIR}
            done

