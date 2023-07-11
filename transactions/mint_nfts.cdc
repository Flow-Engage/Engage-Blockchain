import Engage from "../contracts/Engage.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"

// This transaction mints multiple NFTs 
// from a single platform/category/match combination

// Parameters:
//
// matchID: the ID of the match to be minted from
// quantity: the quantity of NFTs to be minted
// name: the name of NFTs to be minted
// description: the name of NFTs to be minted
// extras: the traits of NFTs to be minted
// imgURL: the url where the img is hosted
//
transaction(
        matchID: UInt64,
        quantity: UInt64,
        name: String,
        description: String,
        extras: {String: AnyStruct},
        imgURL: String
    ) {
    
    // Local variable for the Engage Admin object
    let adminRef: &Engage.Administrator

    prepare(acct: AuthAccount) {

        // borrow a reference to the Admin resource in storage
        self.adminRef = acct.borrow<&Engage.Administrator>(from: /storage/EngageAdministrator)
            ?? panic("Could not borrow a reference to the Administrator resource")

        // Batch mint the NFTs with this metadata     
        let collection <- self.adminRef.createNFTs(
            _matchID: matchID,
            _quantity: quantity,
            _name: name,
            _description: description,
            _extras: extras,
            _imgURL: imgURL
            )
        
        let receiverRef = acct.getCapability(Engage.CollectionPublicPath).borrow<&Engage.Collection>()
            ?? panic("Cannot borrow a reference to the recipient's collection")
        // deposit the NFT in the receivers collection
        receiverRef.batchDeposit(tokens: <- collection)

    }

    post {
        Engage.nftMetadatas[Engage.nextMetadataID - 1]?.name == name:
          "Could not find the specified metadata inside the match"
    } 
}