import Engage_2 from "../contracts/Engage.cdc"

// This script returns all the metadata about the specified Platform

// Parameters:
//
// PlatformID: The unique ID for the Platform whose data needs to be read

// Returns: Engage_2.QueryPlatformData

pub fun main(): [Engage_2.QueryPlatformData] {

    let allPlatform: [Engage_2.QueryPlatformData] = []
    let currentId = Engage_2.nextPlatformID
    var  i = 0 as UInt64

    while (i <= currentId) {
        if let data = Engage_2.getPlatformData(_platformID: i){

            allPlatform.append(data)
            i = i + 1 
        } else {
            return allPlatform
        }
    
    }

    return allPlatform
}