import Engage from "../contracts/Engage.cdc"

// This transaction is for the admin to create a new Platform resource
// and store it in the Engage smart contract

// Parameters:
//
// platformName: the name of a new platform to be created

transaction(platformName: String) {
    
    // Local variable for the Engage Admin object
    let adminRef: &Engage.Administrator
    let newPlatformID: UInt64

    prepare(acct: AuthAccount) {

        // borrow a reference to the Admin resource in storage
        self.adminRef = acct.borrow<&Engage.Administrator>(from: /storage/EngageAdministrator)
            ?? panic("Could not borrow a reference to the Administrator resource")

        // Create a platform with the specified name        
        self.newPlatformID = self.adminRef.createPlatform(_name: platformName)
    }

    post {
        Engage.getPlatformData(_platformID: self.newPlatformID)?.name == platformName:
          "Could not find the specified set"
    }
}