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

    ```bash
    chr     start   stop    ID              len     type
    chr1    1288120 1289853 DEL_P0001_56    1317    hetDel
    chr1    1934917 1935701 DEL_P0001_156   782     hetDel
    ```

1. [readBamChunks.go](https://github.com/brittanyhowell/sv-view/blob/master/readBamChunks/readBamChunks.go)

    Output: Table of coordinates and extra information of reads aligned to SV +/- 1.5kb

    ```bash
    HX3_17636:5:2216:22901:43097_1  chr1    1277812 1277963 -424    22M1I128M   60  AS:i:133    pP--r-1-----
    HX2_17657:5:1212:17421:67217_1  chr1    1277819 1277970 -655    151M        60  AS:i:151    pP--r-1-----
    HX7_17624:5:2213:2757:52608_1   chr1    1277830 1277981 0       23M128S     0   AS:i:23     p----R-2----

    ```
1. [assignBins.R](assignBins.R)

    Output: Same table, with appended column with height value for reads, to allow non-overlapping plotting

    ```bash
    name                            start       end     width   bin cigar       mapq    AS          flags           tlen
    HX3_17636:5:2216:22901:43097_1  1277812   1277963    152    1   22M1I128M   60      AS:i:133    pP--r-1-----    -424
    HX2_17657:5:1212:17421:67217_1  1277819   1277970    152    2   151M        60      AS:i:151    pP--r-1-----    -655
    HX7_17624:5:2213:2757:52608_1   1277830    1277981   152    3   23M128S     0       AS:i:23     p----R-2----    0

    ```
1. [splitCigar.go](https://github.com/brittanyhowell/sv-view/blob/master/splitCigar/splitCigar.go)

    Output: Converted table: from one row per read, to one row per cigar operator

    ```bash
    HX3_17636:5:2216:22901:43097_1  1277812 1277833 1   60  one 133 0   22M1I128M   M   22
    HX3_17636:5:2216:22901:43097_1  1277834 1277834 1   60  one 133 0   22M1I128M   I   1
    HX3_17636:5:2216:22901:43097_1  1277835 1277962 1   60  one 133 0   22M1I128M   M   128
    HX2_17657:5:1212:17421:67217_1  1277819 1277969 2   60  one 151 0   151M        M   151
    HX7_17624:5:2213:2757:52608_1   1277830 1277852 3   0   two 23  0   23M128S     M   23
    ```
1. [viewRegions.R](https://github.com/brittanyhowell/sv-view/blob/master/viewRegions.R)

    Output: One plot per SV, coverage and read details

## Why there are so many folders

There are multiple Go scripts in this repo, and Go can only manage one 'main' per directory.

### But doesn't that makes you a really bad Go user

Yes. Yes it does!  
And yet here we are!
