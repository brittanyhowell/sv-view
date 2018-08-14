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
    ## Location of bams:
    bamDIR=/lustre/scratch115/projects/interval_wgs/testBams/
    ## Location of raw table:
    STinDIR=/lustre/scratch115/projects/interval_wgs/analysis/sv/kw8/genomestrip/cnv_discovery/cnv_output/results/ 
    ## Name of the raw table
    STinTab="gs_cnv.reduced.genotypes.txt"   
    
    ## Use array job:
    sample="EGAN00001214506" 


    # Scripts and junk
    scriptDIR=/lustre/scratch115/projects/interval_wgs/analysis/sv/viewSV/scripts/
    wkDIR=/lustre/scratch115/projects/interval_wgs/analysis/sv/viewSV/trial-aug13/
    plotDIR="${wkDIR}/plots/${sample}"
    mkdir -p ${plotDIR}
    
    # settings
    software="CNV" 
    whichSVs="noRef" # options include "noRef" or "all" (actually right now it's noRef or nothing..)

    # Software and location
    R_version="/software/R-3.5.0/bin/"
    go_version="/software/team151/gcc-8.1.0/bin/"

    ## A number of folders need to be created for the intermediate file steps. 
    ## This statement will delete EVERYTHING, and will replace it with new ones. 

    # # The root folder. 
    #     if [ -d "${wkDIR}/${sample}" ]; then
    #         echo "your directory ${wkDIR}/${sample} already existed.... ...I have replaced it. All." 
    #         rm -rf "${wkDIR}/${sample}"
    #         mkdir -p "${wkDIR}/${sample}"
    #     else
    #         mkdir -p "${wkDIR}${sample}"
    #         echo "Folder ${wkDIR}${sample} didn't exist ... creating it for you!"
    #     fi
        
    # #### Make the output tables: 
   
    #     # separateTable.R - makes one SV coord table per sample
    #         SToutDIR="${wkDIR}/${sample}/${software}-raw_tables"
        # readBamChunks.go - makes one file of reads per SV, per sample
            RBCoutDIR="${wkDIR}/${sample}/${software}-reads"
        # assignBins.R - gives reads height for a plot
            ABoutDIR="${wkDIR}/${sample}/${software}-binned"
    #     # splitCigar - splits constructs into cigar constituents
    #         SCoutDIR="${wkDIR}/${sample}/${software}-cigar_split"
    #     # viewRegions - makes the plots. 
    #         VRoutDIR="${wkDIR}/${sample}/${software}-plots"

    #         mkdir -p ${SToutDIR}
    #         mkdir -p ${RBCoutDIR}
    #         mkdir -p ${ABoutDIR}
    #         mkdir -p ${SCoutDIR}
    #         mkdir -p ${VRoutDIR}


        
    #     ## Use raw GS table, separate out the relevant colums for the current sample. Can only have non-reference, or all.  
    #     # made in the R script, rather than for an argument
    #     stOutInterValTable="${STinTab%.txt}_${sample}.txt" 

    #     # File with original data
    #     if [ -f ${STinDIR}/${STinTab} ]; then
    #         echo "file $STinDIR exists ...continuing" 
    #     else
    #         echo "Folder $STinDIR does not exist ... exiting"     
    #         exit
    #     fi

    #         echo "running separateTable.R to pull out ${whichSVs} SVs from the original table"
    #         echo "call: ${R_version}/Rscript ${scriptDIR}/separateTable.R    -f ${STinTab}      -d ${STinDIR}      -i ${sample}    -o ${SToutDIR}     -s ${software}    -w ${whichSVs}  "
            
    #         ${R_version}/Rscript ${scriptDIR}/separateTable.R    --inTab=${STinTab}      -d ${STinDIR}      -i ${sample}    -o ${SToutDIR}     -s ${software}    -w ${whichSVs}   

    #     ## Retrieve list of intervals for the sample from SToutDIR and withdraw the reads
    #     ## Put output in RBCout/sample
    #     ## This is the script which makes several files, one per SV for the current sample

    #         RBCindex="${bamDIR}/${sample}.bam.bai"
    #         RBCbam="${bamDIR}/${sample}.bam"
    #         RBCint="${SToutDIR}/${stOutInterValTable}"
    #         RBCsampleName=${sample} 

    #         echo "running readBamChunks.go to get reads per SV"
    #         echo "Call: ${go_version}/go run ${scriptDIR}/readBamChunks/readBamChunks.go -index=${RBCindex} -bam=${RBCbam}
    #         -intFile=${RBCint} -outPath=${RBCout} -sampleName=${RBCsampleName}"
            
    #         ${go_version}/go run ${scriptDIR}/readBamChunks/readBamChunks.go -index=${RBCindex} -bam=${RBCbam} -intFile=${RBCint} -outPath=${RBCoutDIR} -sample=${RBCsampleName}


        ## Retrieve list of read tables from RBCout and assign them a bin value
        ## Put output in ABoutDIR/sample

            ABinDIR=${RBCoutDIR}
            cd ${ABinDIR}
            listReads=$(ls *.txt)

            for readTable in ${listReads} ; do 
                ABinTab=${readTable}

                echo "running assignBins.R to assign the reads a height for ${ABinTab}"
                echo "Call: ${R_version}/Rscript ${scriptDIR}/assignBins.R -d ${ABinDIR} -f ${ABinTab} -o ${ABoutDIR}"

                ${R_version}/Rscript ${scriptDIR}/assignBins.R -d ${ABinDIR} -f ${ABinTab} -o ${ABoutDIR}
            done

        # ## Retrieve binned tables from ABoutDIR and split the records into their cigar constituents
        # ## Put output in SCoutDIR/sample

        #     SCbinDIR=${ABoutDIR}   ## source files in ABoutDIR
        #     listBinnedReads=$(ls ${SCbinDIR}/*.txt)
        
        #     for binnedReadTable in ${listBinnedReads} ; do
        #         SCbinFile=${binnedReadTable}

        #         echo "running splitCigar.go to expand the cigar strings for ${SCbinFile}"
        #         echo "Call: ${go_version}/go run ${scriptDIR}/splitCigar/splitCigar.go -inDIR=${SCbinDIR} -binFile=${SCbinFile} -outPath=${SCoutDIR}"
        #         ${go_version}/go run ${scriptDIR}/splitCigar/splitCigar.go -inDIR=${SCbinDIR} -binFile=${SCbinFile} -outPath=${SCoutDIR}
        #     done

        # ## Retrieve split tables from SCoutDIR and plot them. 
        # ## Put output in VRoutDIR/sample

        #     VRinDIR=${SCoutDIR}                         ## source files in SC outDIR
        #     listSplitTables=$(ls ${VRinDIR}/*.txt)     ## Lists all files without absolute path

        #     for splitTable in ${listSplitTables} ; do
        #         VRinTab=${splitTable}
        #         echo "running viewRegions.R to produce plots for ${VRinTab}"
        #         echo "Call: ${R_version}/Rscript ${scriptDIR}/viewRegions.R -d ${VRinDIR} -f ${VRinTab} -o ${VRoutDIR}"
        #         ${R_version}/Rscript ${scriptDIR}/viewRegions.R -d ${VRinDIR} -f ${VRinTab} -o ${VRoutDIR}
        #     done

