import Engage from "../contracts/Engage.cdc"

// This transaction is for the admin to create a new Category resource
// and store it in the Engage smart contract
// Parameters:
//
// categoryName: the name of a new Category to be created
// platformID: the ID of the platform this category belongs to


transaction(categoryName: String, platformID: UInt64) {
    
    // Local variable for the Engage Admin object
    let adminRef: &Engage.Administrator
    let newCategoryID: UInt64

    prepare(acct: AuthAccount) {

        // borrow a reference to the Admin resource in storage
        self.adminRef = acct.borrow<&Engage.Administrator>(from: /storage/EngageAdministrator)
            ?? panic("Could not borrow a reference to the Administrator resource")

        // Create a Category with the specified name        
        self.newCategoryID = self.adminRef.createCategory(_name: categoryName, _platformID: platformID)

    }

    post {
        Engage.getPlatformCategories(_platformID: platformID)?.containsKey(categoryName)!:
          "Could not find the specified category"
    } 
}