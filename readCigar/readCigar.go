// Comment I guess?
package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/biogo/hts/bam"
	"github.com/biogo/hts/sam"
)

func main() {
	var (
		fSplice    bool
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

	// set chunks - based on intervals
	chunks, err := bai.Chunks(refs[sv.Chr], sv.Start, sv.End)
	if err != nil {
		fmt.Println(chunks, err)
		// continue
	}

	i, err := bam.NewIterator(br, chunks)
	if err != nil {
		log.Fatal(err)
	}

	for i.Next() {

		r := i.Record()
	}

}
