package main

import (
	"bufio"
	"flag"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"

	"github.com/biogo/hts/sam"
)

type binnedReadsTable struct {
	name   string
	start  int
	end    int
	width  int
	bin    string
	cigar  sam.Cigar
	mScore string
	aScore string
	flags  string
}

func main() {
	var (
		binFile string
		outPath string
		outFile string
	)

	// For reference,
	//the first is the variable,
	//the second is the flag for the call command,
	//the third is default,
	//the fourth is the description
	flag.StringVar(&binFile, "binFile", "", "name of the file with read data & bin values")
	flag.StringVar(&outPath, "outPath", "", "path to output DIR")
	flag.StringVar(&outFile, "outFile", "", "Name of output file")
	flag.Parse()

	fmt.Println("Begin the expansion!")

	file := fmt.Sprintf("%v/%v", outPath, outFile)
	out, err := os.Create(file)
	if err != nil {
		log.Fatalf("failed to create out %s: %v", file, err)
	}
	defer out.Close()

	// Read in the binned reads table
	fIn, err := os.Open(binFile)
	if err != nil {
		log.Fatal(err)
	}
	defer fIn.Close()

	var readIn []string
	sIn := bufio.NewScanner(fIn)

	iInt := 0
	for sIn.Scan() {
		if iInt > 0 { // IMPORTANT - ASSUMES THERE IS A HEADER, ELSE IT WILL SKIP THE FIRST LINE
			readIn = append(readIn, sIn.Text())
		}
		iInt++
	}
	if err := sIn.Err(); err != nil {
		log.Fatal(err)
	}

	for _, rIn := range readIn {

		r := constructAStruct(rIn)

		fmt.Printf("%v\t%v\t%v\t%v\t%v\t%v\t%v\t%v\t%v\n",
			r.name,
			r.start,
			r.end,
			r.width,
			r.bin,
			r.cigar,
			r.mScore,
			r.aScore,
			r.flags)

	}

}
func constructAStruct(lineIn string) binnedReadsTable {

	rsplit := strings.Split(lineIn, "\t")
	rName := rsplit[0]
	rBin := rsplit[4]
	rMapq := rsplit[6]
	rAS := rsplit[7]
	rFlags := rsplit[8]

	rCigar, _ := sam.ParseCigar([]byte(rsplit[5]))

	rStartS, _ := strconv.ParseFloat(rsplit[1], 1)
	rEndS, _ := strconv.ParseFloat(rsplit[2], 1)
	rWidthS, _ := strconv.ParseFloat(rsplit[3], 1)

	rStart := int(rStartS)
	rEnd := int(rEndS)
	rWidth := int(rWidthS)

	r := binnedReadsTable{
		name:   rName,
		start:  rStart,
		end:    rEnd,
		width:  rWidth,
		bin:    rBin,
		cigar:  rCigar,
		mScore: rMapq,
		aScore: rAS,
		flags:  rFlags,
	}

	return r
}
