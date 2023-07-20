package main

import (
	"fmt"
	//if you imports this with .  you do not have to repeat overflow everywhere
	. "github.com/bjartek/overflow"
	"github.com/fatih/color"
)

func main() {
	o := Overflow(

		WithGlobalPrintOptions(),
		WithNetwork("testnet"),
	)

	fmt.Println("Interacting with the Engage contract on Testnet")
	fmt.Println("Press any key to continue")
	fmt.Scanln()

	/********THIS ALREADY PASSED ON TESTNET***********/
	// Adminitrator should be able to create a new Platform
	color.Red("Should be able to create new Platform")
	/*   	o.Tx(
		"create_platform",
		WithSigner("Engage"),
		WithArg("platformName", "Sports"),
	).Print() */
	color.Green("-----------------------------PASSED---------------------")

	color.Red("Should be able to read the new Platform's data with any account")
	o.Script("getPlatformData", WithArg("platformID", "0")).Print()
	color.Green("-----------------------------PASSED---------------------")

	/********THIS ALREADY PASSED ON TESTNET***********/
	// Adminitrator should be able to create a new Category
	color.Red("Should be able to create new Category")
	/* 	o.Tx(
		"create_category",
		WithSigner("Engage"),
		WithArg("categoryName", "Soccer"),
		WithArg("platformID", "0"),
	).Print() */
	color.Green("-----------------------------PASSED---------------------")

	color.Red("New Category should be in the platform's data")
	o.Script("getPlatformData", WithArg("platformID", "0")).Print()
	color.Green("-----------------------------PASSED---------------------")

	/********THIS ALREADY PASSED ON TESTNET***********/
	// Adminitrator should be able to create a new Match
	color.Red("Should be able to create new Match")
	/* 	o.Tx(
		"create_match",
		WithSigner("Engage"),
		WithArg("matchName", "Champion League"),
		WithArg("categoryName", "Soccer"),
		WithArg("platformID", "0"),
	).Print() */
	color.Green("-----------------------------PASSED---------------------")

	color.Red("New Match should be in the category's data")
	o.Script("getCategoryData", WithArg("categoryID", "0")).Print()
	color.Green("-----------------------------PASSED---------------------")

	/********THIS ALREADY PASSED ON TESTNET***********/
	// Adminitrator should be able to create a new NFTs for a match
	color.Red("Should be able to create new NFTs")
	o.Tx(
		"mint_nfts",
		WithSigner("Engage"),
		WithArg("matchID", "0"),
		WithArg("quantity", "10"),
		WithArg("name", "Deutschland"),
		WithArg("description", "Future Five Time Champions"),
		WithArg("extras", `{}`),
		WithArg("imgURL", "https://tmssl.akamaized.net/images/foto/galerie/miroslav-klose-1404897417-1153.jpg?lm=1483605561"),
	).Print()
	color.Green("-----------------------------PASSED---------------------")

	color.Red("New NFTMetadata should be in the contract")
	o.Script("get_metadata", WithArg("metadataID", "2")).Print()
	color.Green("-----------------------------PASSED---------------------")
}
