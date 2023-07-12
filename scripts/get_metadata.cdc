import Engage from "../contracts/Engage.cdc"

// This script returns all the metadata about the specified NFTMetadata Struct
// Parameters:
//
// metadataID: The unique ID for the struct whose data needs to be read

// Returns: Engage.NFTMetadata

pub fun main(metadataID: UInt64): Engage.NFTMetadata? {

    return Engage.getNFTMetadata(metadataID)
}