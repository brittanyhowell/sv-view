//input: binned reads table, output has been expanded to one cigar record per line

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
	name      string
	start     int
	end       int
	width     int
	bin       string
	cigar     sam.Cigar
	mScore    string
	aScore    string
	flags     string
	tlen      int
	Partnered bool
}

func main() {
	var (
		binFile string
		outPath string
		inDIR   string
		// partnered int
		// solo      int
		readNum int
		r       binnedReadsTable
	)

	// For reference,
	//the first is the variable,
	//the second is the flag for the call command,
	//the third is default,
	//the fourth is the description
	flag.StringVar(&binFile, "binFile", "", "name of the file with read data & bin values")
	flag.StringVar(&inDIR, "inDIR", "", "path to input DIR")
	flag.StringVar(&outPath, "outPath", "", "path to output DIR")
	flag.Parse()

	fmt.Println("Begin the expansion!")

	// Create output filename from input name
	outFile := strings.Replace(binFile, "binned", "split", -1) // -1 so it replaces all instances
	file := fmt.Sprintf("%v/%v", outPath, outFile)
	out, err := os.Create(file)
	if err != nil {
		log.Fatalf("failed to create out %s: %v", file, err)
	}
	defer out.Close()

	// Read in the binned reads table
	nameIn := fmt.Sprintf("%v/%v", inDIR, binFile)
	fIn, err := os.Open(nameIn)
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
		readNum++
		seconds := 0 // Number of secondary alignments
		// Set information.
		r = constructAStruct(rIn)

		flags := r.flags
		paired, mateOne, mateTwo, sAlign := getMateInformation(flags)
		mate := getMateNumber(mateOne, mateTwo)

		// Quality checks
		if sAlign == "_" { // If secondary alignment
			seconds++
		}
		if paired != "p" { // if unpaired
			fmt.Println("Read unpaired..SOEMTHINGSEIHPWWRTRROOOOONNGGGGG", r.name)
		}

		// Change the Alignment score formatting
		aScore := strings.Replace(r.aScore, "AS:i:", "", -1) // -1 so it replaces all instances

		// // RANGE OVER READIN AGAIN, AND FIND THE SECOND READS
		// There is a way to do this I know there is.

		// In the readBamChunks file, generate a list of read names in a separate for loop before the main one. Append this list to a variable.
		// Read through reads as per normal. Each read, loop through this list of names, and determine partnered or not partnered (same ID, different mate), assign "partnered" bool
		// Write two files. One: Constructs, Two: Reads
		// To make reads, read the chunks, print the reads to a file. Append the names, coordinates and mate statuses of each read to a variable - listReads
		// To make constructs: Loop through reads as before. Loop through listReads, search for ljne with same ID, different mate status. success -> partnered field in listReads = true
		// Loop through listReads. 1) if it is partnered and also mate one: set start to be start of R1
		// Loop through listReads, find same ID, mate two . Set end to be end of R2.
		// 2) if partnered and mate two: SKIP
		// 3) if not partnered: start = start, end = end
		// In all cases, print to the file binReference File.
		// Feed binReferenceFile into R and get a column appended that is the bin values
		// Read in the binnedReference file, and the list of reads
		// Process the cigar string as in this file, and for each read, loop through the binnedReferenceFile, and collect the bin value.

		// for _, qIn := range readIn {

		// 	q := constructAStruct(qIn)

		// 	Qflags := q.flags
		// 	Qpaired, QmateOne, QmateTwo, QsAlign := getMateInformation(Qflags)
		// 	Qmate := getMateNumber(QmateOne, QmateTwo)

		// 	// Quality checks
		// 	if QsAlign == "_" {
		// 		seconds++
		// 	}
		// 	if Qpaired != "p" {
		// 		fmt.Println("Read unpaired..SOEMTHINGSEIHPWWRTRROOOOONNGGGGG", r.name)
		// 	}
		// 	if r.name == q.name && Qmate != mate {
		// 		// fmt.Println(q.name, Qmate, r.name, mate)
		// 		partnered++
		// 		r.Partnered = true
		// 	}
		// }

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
			if typeC == sam.CigarHardClipped {
				// I don't want to plot Hard Clipped.
				continue
			}
			// adjust r.Pos if first value is soft clipped
			if typeC == sam.CigarSoftClipped && mapped == false {
				start = r.start - lenC
				end = r.start
			} else if cStatus == "first" || cStatus == "single" {
				start = r.start
				end = start + lenC - 1
			} else {
				start = end + 1
				end = start + lenC - 1
			}

			fmt.Fprintf(out, "%v\t%v\t%v\t%v\t%v\t%v\t%v\t%v\t%v\t%v\t%v\n",
				r.name, // read ID
				start,  // cigar op coordinate
				end,    // cigar op coordinate
				// r.width, // total length of segment
				r.bin,    // Height for plotting
				r.mScore, // mapping quality
				mate,     // mate one or two
				aScore,   // alignment score
				// r.tlen,
				seconds, // If it is a secondary alignment, will be 1
				// cStatus, // first, single, middle, last
				r.cigar, // cigar string
				typeC,   // operator
				lenC,    // length of operator
			)

			cCurrent++
		}
		// start = end + 1
		// end = start + r.tlen
		// if mate == "one" {
		// 	fmt.Printf("%v\t%v\t%v\t%v\t%v\t%v\t%v\t%v\t%v\t%v\t%v\tTEMPLATE\tTEMPLATE\n",
		// 		r.name,
		// 		start,
		// 		end,
		// 		r.width,
		// 		r.bin,
		// 		r.mScore,
		// 		mate,
		// 		aScore,
		// 		r.tlen,
		// 		numCO,
		// 		// cStatus,
		// 		r.cigar,
		// 		// typeC,
		// 		// lenC,
		// 	)
		// 	// COME BACK AND CHECK TO SEE WHAT TLEN ACTUALLY IS BEFORE YOU USE IT.
		// 	// I THINK I MAY HAVE MESSED UP
		// 	//I THINK I NEEDED TO FIND A WAY TO MAKE MATES FIND EACH OTHER.
		// 	// BUT I DON'T KNOW HOW TO DO THAT
		// 	// I DON'T KNOW IF THEIR IDs ARE SUPPOSED TO BE THE SAME
		// 	// I DON'T KNOW IF
		// }

	}
	// fmt.Println(r.Partnered)
	// fmt.Println(readNum, solo, partnered)
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
