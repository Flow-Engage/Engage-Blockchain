import Engage from "../contracts/Engage.cdc"

// createMatch creates a new Match resource and stores it
// in the Match mapping in the Engage contract
//
// Parameters: name: The name of the Match
//             platformID: the ID of the platform this Match belongs to
//             categoryName: the Name of the category this Match belongs to
//              inside the specified platform
//
transaction(matchName: String, categoryName: String, platformID: UInt64) {
    
    // Local variable for the Engage Admin object
    let adminRef: &Engage.Administrator
    let newCategoryID: UInt64

    prepare(acct: AuthAccount) {

        // borrow a reference to the Admin resource in storage
        self.adminRef = acct.borrow<&Engage.Administrator>(from: /storage/EngageAdministrator)
            ?? panic("Could not borrow a reference to the Administrator resource")

        // Create a Match with the specified name        
        self.newCategoryID = self.adminRef.createMatch(
            _name: matchName,
            _platformID: platformID,
            _categoryName: categoryName
        )

    }

    post {
        Engage.getCategoryMatches(_categoryID: self.newCategoryID)?.containsKey(matchName)!:
          "Could not find the specified category"
    } 
}