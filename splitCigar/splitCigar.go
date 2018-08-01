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
	tlen   int
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

	seconds := 0 // Number of secondary alignments

	for _, rIn := range readIn {

		// Set information.
		r := constructAStruct(rIn)

		flags := r.flags
		paired, mateOne, mateTwo, sAlign := getMateInformation(flags)
		mate := getMateNumber(mateOne, mateTwo)

		// Quality checks
		if sAlign == "_" {
			seconds++
		}
		if paired != "p" {
			fmt.Println("Read unpaired..SOEMTHINGSEIHPWWRTRROOOOONNGGGGG", r.name)
		}

		// Change the Alignment score formatting
		aScore := strings.Replace(r.aScore, "AS:i:", "", -1) // -1 so it replaces all instances

		// Count the number of cigar operators, crudely
		numCO := countCigarOps(r.cigar)

		// Variable cCurrent is the number operator currently working on
		var cCurrent int
		cCurrent = 1

		// cigar specific coordinates:
		var (
			start int
			end   int
		)

		mapped := false
		for _, co := range r.cigar {

			cStatus := getCigarStatus(numCO, cCurrent)
			typeC := co.Type()
			lenC := co.Len()

			mapped = checkIfMappedYet(typeC, mapped)

			// adjust r.Pos if first value is soft clipped
			if typeC == sam.CigarSoftClipped && mapped == false {
				start = r.start - lenC
				end = r.start
			}
			//%v\t%v\t%v\t%v\t%v\t%v\t

			fmt.Printf("%v\t%v\t%v\t%v\t%v\t%v\t%v\t%v\n",
				// r.name,
				start,
				end,
				// r.width,
				// r.bin,
				// r.mScore,
				mate,
				aScore,
				// r.tlen,
				// numCO,
				cStatus,
				r.cigar,
				typeC,
				lenC,
			)

			cCurrent++
		}

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
	rTlenS, _ := strconv.ParseFloat(rsplit[9], 1)

	rStart := int(rStartS)
	rEnd := int(rEndS)
	rWidth := int(rWidthS)
	rTlen := int(rTlenS)

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
		tlen:   rTlen,
	}

	return r
}

func getMateInformation(flags string) (paired, mateOne, mateTwo, secAlign string) {

	pairVal := strings.Split(flags, "")[0]
	mateOneVal := strings.Split(flags, "")[6]
	mateTwoVal := strings.Split(flags, "")[7]
	secondaryAlign := strings.Split(flags, "")[8]
	return pairVal, mateOneVal, mateTwoVal, secondaryAlign
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
func countCigarOps(cigar sam.Cigar) int {
	// Hi if anyone finds this I know it's garbage don't judge too harshly.
	var numCO int
	for numCO = range cigar {
	}
	numCO++
	return numCO
}

func getCigarStatus(numberCOs, currentCO int) string {
	var status string

	if numberCOs == 1 {
		status = "single"
	} else {
		switch {
		case currentCO == 1:
			status = "first"
		case currentCO == 2:
			status = "second"
		case currentCO == numberCOs:
			status = "last"
		default:
			status = "middle"
		}
	}
	return status
}
func checkIfMappedYet(typeC sam.CigarOpType, mappedStatus bool) bool {
	if mappedStatus == false {
		if typeC != sam.CigarSoftClipped && typeC != sam.CigarHardClipped {
			mappedStatus = true
		}
	}
	return mappedStatus
}
