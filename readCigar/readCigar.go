// Comment I guess?
package main

import (
	"bufio"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/biogo/hts/bam"
	"github.com/biogo/hts/sam"
)

func main() {
	var (
		index   string
		bamFile string
	)

	// For reference,
	//the first is the variable,
	//the second is the flag for the call command,
	//the third is default,
	//the fourth is the description
	flag.StringVar(&index, "index", "", "name index file")
	flag.StringVar(&bamFile, "bam", "", "name bam file")

	flag.Parse()

	fmt.Println("Begin")

	file := fmt.Sprintf("DataDump")
	out, err := os.Create(file)
	if err != nil {
		log.Fatalf("failed to create out %s: %v", file, err)
	}
	defer out.Close()

	// Read in the SV table
	fInt, err := os.Open("readNames.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer fInt.Close()

	var intAll []string
	sInt := bufio.NewScanner(fInt)

	for sInt.Scan() {
		// if i > 0 { // IMPORTANT - ASSUMES THERE IS A HEADER, ELSE IT WILL SKIP THE FIRST SV
		intAll = append(intAll, sInt.Text())
		// }
		// i++
	}
	if err := sInt.Err(); err != nil {
		log.Fatal(err)
	}

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

	// set chunks - based on intervals
	chunks, berr := bai.Chunks(refs["chr17"], 52612, 71880)
	if err != nil {
		fmt.Println("failed to read chunks: ", berr)
		os.Exit(10)
		// You know, I still don't know if this code is user defined.
		// I'm pretty sure it is. I mean, I could put any number there
		// And it would print it, and then in my documentation, I could write
		// yeah, exit code x means THIS.
	}

	i, err := bam.NewIterator(br, chunks)
	if err != nil {
		log.Fatal(err)
	}
	// outCount := 0
	// inCount := 0
	// match := 0
	for i.Next() {
		r := i.Record()
		// outCount++
		flags := r.Flags.String()
		paired, mateOne, mateTwo := getMateInformation(flags)
		mate := getMateNumber(mateOne, mateTwo)

		// for _, thisRead := range intAll {

		// 	if thisRead == r.Name {
		// 		fmt.Printf("list:%v, r.record: %v\n", thisRead, r.Name)
		// 	}
		// }
		for _, co := range r.Cigar {
			typeC := co.Type()
			lenC := co.Len()
			fmt.Printf("%v\t%v\t", typeC, lenC)
			// HEY GUESS WHO CAN ACCESS THE BAM r.CIGAR! BRIE CAN
			// CIGAR PARSER WORKS M8s
			//SO
			// Print type. To line
			// Sum lines. Make TLEN relevant
			// Refer back to notes you made when you were 70% less crazy. <3

		}
		fmt.Fprintf(out, "%v\t%v\t%v\t%v\t%v\t%v\t%v\n", r.Name, r.Pos, r.Pos+r.Seq.Length, paired, r.TempLen, r.Cigar, mate)
		// fmt.Fprintf(out, "%v\n", r.Name)

	}
	// fmt.Println(outCount, inCount, match)
}

func getMateInformation(flags string) (paired, mateOne, mateTwo string) {

	pairVal := strings.Split(flags, "")[0]
	mateOneVal := strings.Split(flags, "")[6]
	mateTwoVal := strings.Split(flags, "")[7]
	return pairVal, mateOneVal, mateTwoVal
}

func getMateNumber(one, two string) string {
	var mate string
	switch {
	case one == "1" && two == "-":
		mate = "one"
	case one == "-" && two == "2":
		mate = "two"
	default:
		mate = "error"
	}
	return mate
}
