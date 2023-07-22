import Engage_2 from "../contracts/Engage.cdc"

// This script returns all the metadata about the specified NFTMetadata Struct
// Parameters:
//
// metadataID: The unique ID for the struct whose data needs to be read

// Returns: Engage_2.NFTMetadata

pub fun main(metadataID: UInt64): Engage_2.NFTMetadata? {

    return Engage_2.getNFTMetadata(metadataID)
}