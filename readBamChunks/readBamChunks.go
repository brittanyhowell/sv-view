package main

import (
	"bufio"
	"flag"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"

	"github.com/biogo/hts/bam"
	"github.com/biogo/hts/sam"
)

// SVfile represents SV information file
type SVfile struct {
	Chr      string
	Start    int
	End      int
	Name     string
	Length   int
	TypeofSV string
}

func main() {

	var (
		index      string
		bamFile    string
		intFile    string
		outPath    string
		outName    string
		sampleName string
	)
	var (
		sv SVfile
	)
	// For reference,
	//the first is the variable,
	//the second is the flag for the call command,
	//the third is default,
	//the fourth is the description
	flag.StringVar(&index, "index", "", "name index file")
	flag.StringVar(&bamFile, "bam", "", "name bam file")
	flag.StringVar(&sampleName, "sample", "", "name of sample")
	flag.StringVar(&intFile, "intFile", "", "Interval File")
	flag.StringVar(&outPath, "outPath", "", "path to reads output DIR")

	flag.Parse()

	fmt.Println("Begin")

	// read index
	ind, err := os.Open(index)
	if err != nil {
		log.Printf("error: could not open %v to read %v", ind, err)
	}
	defer ind.Close()
	bai, err := bam.ReadIndex(ind)
	h := bai.NumRefs()

	// Read bam
	f, err := os.Open(bamFile)
	if err != nil {
		log.Printf("error: could not open %v to read %v", f, err)
	}
	defer f.Close()
	var br *bam.Reader
	br, err = bam.NewReader(f, 0)
	if err != nil {
		log.Printf("error: %v, %v", br, err)
	}
	defer br.Close()

	// store bams
	refs := make(map[string]*sam.Reference, h)
	for _, r := range br.Header().Refs() {
		refs[r.Name()] = r
	}

	// Read in the SV table
	fInt, err := os.Open(intFile)
	if err != nil {
		log.Fatal(err)
	}
	defer fInt.Close()

	var intAll []string
	sInt := bufio.NewScanner(fInt)
	i := 0
	for sInt.Scan() {
		if i > 0 { // IMPORTANT - ASSUMES THERE IS A HEADER, ELSE IT WILL SKIP THE FIRST SV
			intAll = append(intAll, sInt.Text())
		}
		i++
	}
	if err := sInt.Err(); err != nil {
		log.Fatal(err)
	}

	var howManyReads int
	// Read intervals line by line
	for _, rInt := range intAll {

		splitInt := strings.Split(rInt, "\t")

		intStart, _ := strconv.ParseFloat(splitInt[1], 1)
		intStop, _ := strconv.ParseFloat(splitInt[2], 1)
		intLen, _ := strconv.ParseFloat(splitInt[4], 1)

		intStartint := int(intStart)
		intStopint := int(intStop)
		intLenint := int(intLen)

		intChr := splitInt[0]
		intID := splitInt[3]
		intType := splitInt[5]

		sv = SVfile{
			Chr:      intChr,
			Start:    intStartint,
			End:      intStopint,
			Name:     intID,
			Length:   intLenint,
			TypeofSV: intType,
		}
		//print the intervals
		fmt.Printf("Interval: %v\t%v\t%v\t%v\t%v\t%v\n", sv.Chr, sv.Start, sv.End, sv.Name, sv.Length, sv.TypeofSV)
		outName = fmt.Sprintf("%v-%v-%v-reads.txt", sampleName, sv.TypeofSV, sv.Name)

		// Creating single file for the current output SV
		file := fmt.Sprintf("%v/%v", outPath, outName)
		out, err := os.Create(file)
		if err != nil {
			log.Fatalf("failed to create out %s: %v", file, err)
		}
		defer out.Close()

		// Currently no reads for this interval
		howManyReads = 0

		// set chunks - based on intervals
		chunks, err := bai.Chunks(refs[sv.Chr], sv.Start, sv.End)
		if err != nil {
			fmt.Println(chunks, err)
			// continue
		}

		i, err := bam.NewIterator(br, chunks)
		if err != nil {
			log.Fatal(err)
			fmt.Println("error: in the iterator there are issues")
		}

		// iterate over reads - print to file
		for i.Next() {
			howManyReads++

			r := i.Record()

			// Perhaps pass the flags.

			// There is an issue with this.
			// r.Pos is the first mapped base.
			// I want to plot not just the mapped bases, but the whole cigar string.
			// I would like to add a switch statement here.
			// If the first argument is a non mapper, then the raw start should be r.Pos - this.
			// However most of my reads are 151M right now, so I am going to deal with those, and come back.
			start := r.Pos
			end := start + r.Seq.Length

			// Report alignment score - from the Aux fields
			// There is no multiple mapping flag in BWA-mem,
			// Reads with 0 MAPQ and high AS are multimapped.
			tagAS := sam.NewTag("AS")
			valAS := r.AuxFields.Get(tagAS)

			// remove hash from read name
			readName := strings.Replace(r.Name, "#", "_", -1) // -1 so it replaces all instances

			flags := r.Flags.String()

			fmt.Fprintf(out, "%v\t%v\t%v\t%v\t%v\t%v\t%v\t%v\t%v\n",
				readName,  // to ID
				sv.Chr,    // Chromosome - yes it is of the SV not the read but if it maps it has to match so it should be fine.
				start,     // first mapped base
				end,       // last mapped base
				r.TempLen, // Length of insert
				r.Cigar,   // cigar string
				r.MapQ,    // read quality
				valAS,     // Alignment score
				flags,     // Flags
			)
		}
		fmt.Printf("There were %v reads in the interval %v\n", howManyReads, sv.Name)

	}
}
