package main

import (
	"fmt"
	//if you imports this with .  you do not have to repeat overflow everywhere
	. "github.com/bjartek/overflow"
	"github.com/fatih/color"
)

func main() {
	//start an in memory emulator by default
	o := Overflow(
		WithGlobalPrintOptions(),
	)

	fmt.Println("Testing Contract")
	fmt.Println("Press any key to continue")
	fmt.Scanln()

	// Setup Bob's account to hold a Engange NFT
	color.Red("Should be able to setup Bob's account with Engage collection path")
}
