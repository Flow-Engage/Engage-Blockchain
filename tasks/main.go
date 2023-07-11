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

	// Adminitrator should be able to create a new Platform
	color.Red("Should be able to create new Platform")
	o.Tx(
		"create_platform",
		WithSigner("account"),
		WithArg("platformName", "Sports"),
	)
	color.Green("-----------------------------PASSED---------------------")

	color.Red("Should be able to read the new Platform's data with any account")
	o.Script("getPlatformData", WithArg("platformID", "0"))
	color.Green("-----------------------------PASSED---------------------")

	// Adminitrator should be able to create a new Category
	color.Red("Should be able to create new Category")
	o.Tx(
		"create_category",
		WithSigner("account"),
		WithArg("categoryName", "Soccer"),
		WithArg("platformID", "0"),
	)
	color.Green("-----------------------------PASSED---------------------")

	color.Red("New Category should be in the platform's data")
	o.Script("getPlatformData", WithArg("platformID", "0"))
	color.Green("-----------------------------PASSED---------------------")

	// Adminitrator should be able to create a new Match
	color.Red("Should be able to create new Match")
	o.Tx(
		"create_match",
		WithSigner("account"),
		WithArg("matchName", "Champion League"),
		WithArg("categoryName", "Soccer"),
		WithArg("platformID", "0"),
	)
	color.Green("-----------------------------PASSED---------------------")

	color.Red("New Match should be in the category's data")
	o.Script("getCategoryData", WithArg("categoryID", "0"))
	color.Green("-----------------------------PASSED---------------------")

}
