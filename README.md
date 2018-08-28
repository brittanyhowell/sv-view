# Viewing SVs at a read level

## Example plot

Homozygous deletion of region 5,137,301 to 5,139,463 from chromosome X.

![homDel-chrX_5137301_5139463](https://github.com/brittanyhowell/sv-view/blob/master/examplePlot/EGAN00001214506-homDel-chrX_5137301_5139463.png "example")

## Uses

Currently compatible with GenomeSTRiP discovery & CNV output.

***

## How it works

Wrapper [extract_regions.sh](https://github.com/brittanyhowell/sv-view/blob/master/extract_regions.sh) executes 5 steps:

1. [separateTable.R](https://github.com/brittanyhowell/sv-view/blob/master/separateTable.R)

   Input: results table from either Genome STRiP pipeline  
   Output: Coordinates of SVs for each sample and zygosity of SV (ref/het/hom/duplication)
1. [readBamChunks.go](https://github.com/brittanyhowell/sv-view/blob/master/readBamChunks/readBamChunks.go)

    Output: Table of coordinates and extra information of reads aligned to SV +/- 1.5kb
1. [assignBins.R](https://github.com/brittanyhowell/sv-view/blob/master/assignBins.R)

    Output: Same table, with appended column with height value for reads, to allow non-overlapping plotting
1. [splitCigar.go](https://github.com/brittanyhowell/sv-view/blob/master/splitCigar/splitCigar.go)

    Output: Converted table: from one row per read, to one row per cigar operator
1. [viewRegions.R](https://github.com/brittanyhowell/sv-view/blob/master/viewRegions.R)

    Output: One plot per SV, coverage and read details

## Why there are so many folders

There are multiple Go scripts in this repo, and Go can only manage one 'main' per directory.

### But doesn't that makes you a really bad Go user

Yes. Yes it does!  
And yet here we are!
