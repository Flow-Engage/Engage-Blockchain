import MetadataViews from "./standard/MetadataViews.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"

pub contract Engage: NonFungibleToken {

    // Engage contract events

    pub event ContractInitialized()

	pub event PlatformCreated(id: UInt64, name: String)
	pub event CategoryAddedToPlatform(platformID: UInt64, categoryID: UInt64)
	pub event CategoryCreated(categoryID: UInt64, platformID:  UInt64, name: String)
    pub event MatchCreated(matchID:UInt64 , categoryID: UInt64?, platformID:  UInt64, name: String)
    pub event MetadataCreated(metadataID: UInt64, platformID: UInt64, categoryID: UInt64, matchID: UInt64)
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
	// -----------------------------------------------------------------------
    // Engage contract-level fields.
    // -----------------------------------------------------------------------

	// Variable size dictionary of Platform resources
    access(self) var platforms: @{UInt64: Platform}
	// Variable size dictionary of Category resources
    access(self) var categories: @{UInt64: Category}
    // Variable size dictionary of Match resources
    access(self) var matches: @{UInt64: Match}
    // Storage to claim NFTs
    access(account) let nftStorage: @{Address: {UInt64: NFT}}
 	// Variable size dictionary of NFTMetadata structs
    // Maps metadataId of NFT to NFTMetadata
	pub let nftMetadatas: {UInt64: NFTMetadata}
	// Maps the metadataId of an NFT to the primary buyer
	//
	// You can also get a list of purchased NFTs
	// by doing `primaryBuyers.keys`
	pub let primaryBuyers: {Address: {UInt64: [UInt64]}}


   // access(self) var categoriesDatas: {UInt64: Category}


	// The ID that is used to create Plaforms, Categories and Matches. 
    // Every time a a new resource is created, an ID is assigned 
    // to the new Resource's ID and then is incremented by 1.
    pub var nextPlatformID: UInt64
    pub var nextCategoryID: UInt64
    pub var nextMatchID: UInt64
    pub var nextMetadataID: UInt64
    // TotalSupply to keep track of all the Engage NFTs 
    // ever minted
    pub var totalSupply: UInt64

	// Paths
	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath
	pub let AdministratorStoragePath: StoragePath


    // -----------------------------------------------------------------------
    // Engage contract-level Composite Type definitions
    // -----------------------------------------------------------------------

    // Platform is a resource type that contains the functions to add
    // Categories to a Platform.

    pub resource Platform {

        // Unique ID for the Platform
        pub let platformID: UInt64
		pub let name: String
        // Array of categories that are a part of this Platform.
        // When a Cateogry is added to the Platform, its ID gets appended here.
        access(contract) var categories: {String: UInt64}

        init(name: String) {
            pre {
                name.length != 0: "New Platform name cannot be empty"
            }
            self.platformID = Engage.nextPlatformID
            self.categories = {}
			self.name = name

            // Create a new PlatformData for this Platform and store it in contract storage
 //           Engage.platformDatas[self.platformID] = PlatformData(name: name)
        }

        // addCategory adds a category to the Platform
        //
        // Parameters: categoryID: The ID of the Category resource that is being added
        pub fun addCategory(categoryName: String): UInt64 {
            pre {
                self.categories[categoryName] == nil: "This category already exists"
            }
            // Create the new Category
            var newCategory <- create Category(name: categoryName, platformID: self.platformID, platformName: self.name)
            let newCategoryID = newCategory.categoryID
            
            emit CategoryCreated(categoryID: newCategory.categoryID, platformID:  self.platformID, name: newCategory.name)
            // Store inside this Platform's list of categories
            self.categories[newCategory.name] = newCategory.categoryID
			// Store it in the categories mapping field inside the contract
            Engage.categories[newCategoryID] <-! newCategory

            return newCategoryID
        }

        pub fun addMatchToCategory(categoryName: String, matchName: String): UInt64 {
            pre {
                self.categories[categoryName] != nil: "This category doesn't exist on this Platform"
            }
            // Create the new Match
            //var newMatch <- create Match(name: matchName, categoryName: categoryName, platformID: self.platformID)
            //let newMatchID = newMatch.matchID
            let categoryID = self.categories[categoryName]!
            let categoryRef = (&Engage.categories[categoryID] as &Category?)!
            // Create and Add new match to this Category
            let newMatchID = categoryRef.addMatch(matchName: matchName)

            return newMatchID 
        }
	}

	pub resource Category {
   		// The unique ID for the Category
		pub let categoryID: UInt64
		pub let name: String
		// ID and Name of the Platform this Category belongs to
		pub let platformID: UInt64
        pub let platformName: String

        // Array of categories that are a part of this Platform.
        // When a Cateogry is added to the Platform, its ID gets appended here.
        access(contract) var matches: {String: UInt64}

		init(name: String, platformID: UInt64, platformName: String) {
			pre {
                name.length != 0: "New Category name cannot be empty"
            }

            self.name = name
			self.platformID = platformID
            self.platformName = platformName
			self.matches = {}
			self.categoryID = Engage.nextCategoryID

            // Increment the ID so that it isn't used again
            Engage.nextCategoryID = Engage.nextCategoryID + 1
		}

        // addCategory adds a category to the Platform
        //
        // Parameters: categoryID: The ID of the Category resource that is being added
        // Returns categoryID to verify transaction
        pub fun addMatch(matchName: String): UInt64 {
            pre {
                self.matches[matchName] == nil: "This match already exists"
            }
            // Create the new Match
            var newMatch <- create Match(
                name: matchName,
                categoryName: self.name,
                categoryID: self.categoryID,
                platformName: self.platformName,
                platformID: self.platformID
                )
            let newMatchID = newMatch.matchID
            
            emit MatchCreated(matchID: newMatch.matchID , categoryID: self.categoryID, platformID:  self.platformID, name: newMatch.name)

            // Store inside this Category's list of matches
            self.matches[newMatch.name] = newMatch.matchID
			// Store it in the matches mapping field inside the contract
            Engage.matches[newMatchID] <-! newMatch

            return self.categoryID
        }
	}

	pub resource Match {

		// The unique ID for the Match
		pub let matchID: UInt64
        pub let name: String
		// ID and Name of the Platform this Match belongs to
		pub let platformID: UInt64
        pub let platformName: String
        // ID and name of the Category this Match belongs to
		pub let categoryID: UInt64 
		pub let categoryName: String 

		init(name: String, categoryName: String, categoryID: UInt64, platformName: String, platformID: UInt64) {
			pre {
                name.length != 0: "New Match name cannot be empty"
            }

            self.name = name
			self.platformID = platformID
            self.platformName = platformName
			self.categoryName = categoryName
            self.categoryID = categoryID
			self.matchID = Engage.nextMatchID

            // Increment the ID so that it isn't used again
            Engage.nextMatchID = Engage.nextMatchID + 1        
		}

        pub fun mintNFTs(
            quantity: UInt64,
            name: String,
            description: String,
            extras: {String: AnyStruct},
            imgURL: String
            ): @Collection {
            let newCollection <- create Collection()

            // Create Metadata for these NFTs 
            // it helps to keep track of serials
            Engage.nftMetadatas[Engage.nextMetadataID] = NFTMetadata(
                _metadataID: Engage.nextMetadataID,
                _name: name,
                _description: description,
                _image: MetadataViews.HTTPFile(
						url: imgURL,
					),
                _extra: extras,
                _matchID: self.matchID,
                _matchName: self.name,
                _categoryName: self.categoryName,
                _platformName: self.platformName
                ) 


            var i: UInt64 = 0
            while i < quantity {
                newCollection.deposit(token: <- create NFT(_metadataID: Engage.nextMetadataID))
                i = i + 1
            }
            // Increment the ID so that it isn't used again
            Engage.nextMetadataID = Engage.nextMetadataID + 1

            return <- newCollection
        }
	}

    // Struct that contains all of the important data about a platform
    // Can be easily queried by instantiating the `QueryPlatformData` object
    // with the desired Platform ID
    // let platformData = Engage.QueryPlatformData(platformID: 12)
    //
    pub struct QueryPlatformData {
        pub let platformID: UInt64
        pub let name: String
        access(self) var categories: {String: UInt64}

        init(platformID: UInt64) {
            pre {
                Engage.platforms[platformID] != nil: "The Platform with the provided ID does not exist"
            }

            let platformRef = (&Engage.platforms[platformID] as &Platform?)!

            self.platformID = platformRef.platformID
            self.name = platformRef.name
            self.categories = platformRef.categories
        }

        pub fun getCategories(): {String: UInt64} {
            return self.categories
        }
    }

    // Same a QueryPlatformData but for categories
    pub struct QueryCategoryData {
        pub let platformID: UInt64
        pub let platformName: String
        pub let name: String
        access(self) var matches: {String: UInt64}

        init(categoryID: UInt64) {
            pre {
                Engage.categories[categoryID] != nil: "The Category with the provided ID does not exist"
            }

            let categoryRef = (&Engage.categories[categoryID] as &Category?)!

            self.platformID = categoryRef.platformID
            self.platformName = categoryRef.platformName
            self.name = categoryRef.name
            self.matches = categoryRef.matches
        }

        pub fun getMatches(): {String: UInt64} {
            return self.matches
        }
    }


    pub struct NFTMetadata {
	pub let metadataID: UInt64
	pub let matchID: UInt64
    pub let matchName: String
    pub let categoryName: String
    pub let platformName: String
    pub let name: String
	pub let description: String
	pub let image: MetadataViews.HTTPFile
	pub let purchasers: {UInt64: Address}
	pub var minted: UInt64
	pub var extra: {String: AnyStruct}

		init(
            _metadataID: UInt64,
            _name: String,
            _description: String,
            _image: MetadataViews.HTTPFile,
            _extra: {String: AnyStruct},
            _matchID: UInt64,
            _matchName: String,
            _categoryName: String,
            _platformName: String,
            ) {
			self.metadataID = _metadataID
			self.matchID = _matchID
			self.matchName = _matchName
			self.categoryName = _categoryName
			self.platformName = _platformName
            self.name = _name
			self.description = _description
			self.image = _image
			self.extra = {}
			self.minted = 0
			self.purchasers = {}

            self.extra["Platform"] = self.platformName
            self.extra["Category"] = self.categoryName
            self.extra["Match"] = self.matchName
		}
        // Function to update the list of buyers
		access(account) fun purchased(nftID: UInt64, buyer: Address) {
			self.purchasers[nftID] = buyer
		}

        access(account) fun updateMinted() {
			self.minted = self.minted + 1
		}
	}

    // The resource that represents the Engage NFTs
    //
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        // Global unique Engage ID
        pub let id: UInt64
        // Serial number of this NFT
        pub let serial: UInt64
        // Struct of Engage NFTs metadata
        pub let metadataID: UInt64
        // Id of the match this NFT belongs to
        pub let matchID: UInt64

        init(_metadataID: UInt64) {
            pre {
				    Engage.nftMetadatas[_metadataID] != nil: "This Metadata doesn't exist"
			    }
            // Increment the global Engage IDs
            // Gotta change this to UUID in the case that we implement burning
            Engage.totalSupply = Engage.totalSupply + 1
            // Assign serial number to the NFT based on the number of minted NFTs
			let metadataRef: &Engage.NFTMetadata = (&Engage.nftMetadatas[_metadataID] as &NFTMetadata?)!
            self.id = Engage.totalSupply
            self.metadataID = _metadataID
            self.matchID = metadataRef.matchID
            self.serial = metadataRef.minted
            // Update the total minted of this MetadataId by 1
			metadataRef.updateMinted()
        }

        pub fun getMetadata(): NFTMetadata {
			return Engage.getNFTMetadata(self.metadataID)!
		}

		pub fun getViews(): [Type] {
			return [
				Type<MetadataViews.Display>(),
				Type<MetadataViews.ExternalURL>(),
				Type<MetadataViews.NFTCollectionData>(),
				Type<MetadataViews.NFTCollectionDisplay>(),
				Type<MetadataViews.Royalties>(),
				Type<MetadataViews.Serial>(),
				Type<MetadataViews.NFTView>()
			]
		}

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                	let metadata = self.getMetadata()
                    return MetadataViews.Display(
                        name: metadata.name,
                        description: metadata.description,
                        thumbnail: metadata.image
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(self.serial)
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties([
                        MetadataViews.Royalty(
                            recepient: getAccount(0x195942c932186412).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver),
                            cut: 0.05, // 5% royalty on secondary sales
                            description: "The Engage address gets 5% of every secondary sale."
                        )
                    ])
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://hackathon.flow.com/")
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let bannerImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://nEngage.com/static/img.svg"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    let squareImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://Engage.com/static/img.png"
                        ),
                        mediaType: "image/png"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Engage",
                        description: "Engage description TBD",
                        externalURL: MetadataViews.ExternalURL("https://Engage.com"),
                        squareImage: squareImage,
                        bannerImage: bannerImage,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/Engage"),
                            "discord": MetadataViews.ExternalURL("https://discord.com/invite/Engage"),
                            "instagram": MetadataViews.ExternalURL("https://www.instagram.com/Engage")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    return MetadataViews.dictToTraits(dict: self.getMetadata().extra, excludedNames: nil)
            }
            return nil
        }   
    }

    // This interface is neccesary for batch deposting
    //
    pub resource interface EngageCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    }

	pub resource Collection: EngageCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {

		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
		// Withdraw removes an NFT from the collection and moves it to the caller(for Trading)
		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

			emit Withdraw(id: token.id, from: self.owner?.address)

			return <-token
		}
		// Deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @NFT

			let id: UInt64 = token.id
			// Add the new token to the dictionary
			self.ownedNFTs[id] <-! token

			emit Deposit(id: id, to: self.owner?.address)
		}
        // batchDeposit takes a Collection object as an argument
        // and deposits each contained NFT into this Collection
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection) {

            // Get an array of the IDs to be deposited
            let keys = tokens.getIDs()

            // Iterate through the keys in the collection and deposit each one
            for key in keys {
                self.deposit(token: <-tokens.withdraw(withdrawID: key))
            }

            // Destroy the empty Collection
            destroy tokens
        }

		// GetIDs returns an array of the IDs that are in the collection
		pub fun getIDs(): [UInt64] {
			return self.ownedNFTs.keys
		}
		// BorrowNFT gets a reference to an NFT in the collection
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
			return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
		}

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			let token = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let nft = token as! &NFT
			return nft
		}

		pub fun claim() {
			if let storage = &Engage.nftStorage[self.owner!.address] as &{UInt64: NFT}? {
				for id in storage.keys {
					self.deposit(token: <- storage.remove(key: id)!)
				}
			}
		}

		init () {
			self.ownedNFTs <- {}
		}

		destroy() {
			destroy self.ownedNFTs
		}
	}
    // Admin is a special authorization resource that 
    // allows the owner to perform important functions to modify the 
    // various aspects of the Engage contract
    //
	pub resource Administrator {
		// createPlatform creates a new Platform resource and stores it
        // in the platforms mapping in the Engage contract
        //
        // Parameters: name: The name of the Platform
        //
        // Returns: The ID of the created platform
        //
        pub fun createPlatform(_name: String): UInt64 {
            // Create the new Platform
            var newPlatform <- create Platform(name: _name)
            let newPlatformID = newPlatform.platformID

            // Increment the ID so that it isn't used again
            Engage.nextPlatformID = Engage.nextPlatformID + 1

            emit PlatformCreated(id: newPlatform.platformID, name: _name)

            // Store it in the platforms mapping field
            Engage.platforms[newPlatformID] <-! newPlatform

            return newPlatformID
        }

        // borrowPlatform returns a reference to a Platform in the Engage
        // contract so that the admin can call methods on it
        //
        // Parameters: PlatformID: The ID of the Platform that you want to
        // get a reference to
        //
        // Returns: A reference to the Platform with all of the fields
        // and methods exposed
        //
        pub fun borrowPlatform(PlatformID: UInt64): &Platform {
            pre {
                Engage.platforms[PlatformID] != nil: "Cannot borrow Platform: The Platform doesn't exist"
            }
            
            // Get a reference to the Platform and return it
            return (&Engage.platforms[PlatformID] as &Platform?)!
        }

		// createCategory creates a new Category resource and stores it
        // in the category mapping in the Engage contract
        //
        // Parameters: name: The name of the Category
        //             platformID: the ID of the platform this category belongs to
        //
        // Returns: The ID of the created category
        //
		pub fun createCategory(_name: String, _platformID: UInt64):UInt64 {
            pre {
                Engage.platforms[_platformID] != nil: "This Platform doesn't exist"
            }
            // Add new Category to the selected Platform
            let platformRef = (&Engage.platforms[_platformID] as &Platform?)!
            let newCategoryID = platformRef.addCategory(categoryName: _name)

            return newCategoryID

		}
		// createMatch creates a new Match resource and stores it
        // in the Match mapping in the Engage contract
        //
        // Parameters: name: The name of the Match
        //             platformID: the ID of the platform this Match belongs to
        //             categoryName: the Name of the category this Match belongs to
        //              inside the specified platform
        //
        // Returns: The ID of the created Match
        //
        pub fun createMatch(_name: String, _platformID: UInt64, _categoryName: String):UInt64 {
            pre {
                Engage.platforms[_platformID] != nil: "This Platform doesn't exist"
            }
            // Add new Match to the selected Category in the selected Platform
            let platformRef = (&Engage.platforms[_platformID] as &Platform?)!
            let newMatchID = platformRef.addMatchToCategory(categoryName: _categoryName, matchName: _name)

            return newMatchID
        }

        pub fun createNFTs(
            _matchID: UInt64,
            _quantity: UInt64,
            _name: String,
            _description: String,
            _extras: {String: AnyStruct},
            _imgURL: String
            ):@Collection {
            pre {
                Engage.matches[_matchID] != nil: "This Match doesn't exist"
            }

            let matchRef = (&Engage.matches[_matchID] as &Match?)!
            let newCollection <- matchRef.mintNFTs(
                quantity: _quantity,
                name: _name,
                description: _description,
                extras: _extras,
                imgURL: _imgURL
                )

            return <- newCollection
        }

        // create a new Administrator resource
		pub fun createAdmin(): @Administrator {
			return <- create Administrator()
		}
	}

    // -----------------------------------------------------------------------
    // Engage contract-level function definitions
    // -----------------------------------------------------------------------

	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

    // getPlatformData returns the data that the specified platform
    //            is associated with.
    // 
    // Parameters: platformID: The id of the platform that is being searched
    //
    // Returns: The QueryPlatformData struct that has all the important information about the platform
    pub fun getPlatformData(_platformID: UInt64): QueryPlatformData? {
        if Engage.platforms[_platformID] == nil {
            return nil
        } else {
            return QueryPlatformData(platformID: _platformID)
        }
    }

    // getPlatformCategories returns the categories inside the specified platform
    // 
    // Parameters: platformID: The id of the platform that is being searched
    //
    // Returns: dictionary of categories names mapped to their ID
    pub fun getPlatformCategories(_platformID: UInt64): {String: UInt64}? {
        if Engage.platforms[_platformID] == nil {
            return nil
        } else {
            return QueryPlatformData(platformID: _platformID).getCategories()
        }
    }

    // Same as getPlatformData but for Category
    pub fun getCategoryData(_categoryID: UInt64): QueryCategoryData? {
        if Engage.platforms[_categoryID] == nil {
            return nil
        } else {
            return QueryCategoryData(categoryID: _categoryID)
        }
    }
    // getCategoryMatches returns the matches inside the specified platform
    // 
    // Parameters: categoryID: The id of the category that is being searched
    //
    // Returns: dictionary of matches names mapped to their ID
    pub fun getCategoryMatches(_categoryID: UInt64): {String: UInt64}? {
        if Engage.platforms[_categoryID] == nil {
            return nil
        } else {
            return QueryCategoryData(categoryID: _categoryID).getMatches()
        }
    }

    // Get information about a NFTMetadata
	pub fun getNFTMetadata(_ metadataID: UInt64): NFTMetadata? {
		return self.nftMetadatas[metadataID]
	}

	init() {
		self.platforms <- {}
		self.categories <- {}
		self.matches <- {}
        self.nftStorage <- {}
        self.nftMetadatas = {}
        self.primaryBuyers = {}
//		self.categoriesDatas = {}
        self.nextPlatformID = 0
        self.nextCategoryID = 0
        self.nextMatchID = 0
        self.nextMetadataID = 0
        self.totalSupply = 0

		// platform the named paths
		self.CollectionStoragePath = /storage/EngageCollection
		self.CollectionPublicPath = /public/EngageCollection
		self.CollectionPrivatePath = /private/EngageCollection
		self.AdministratorStoragePath = /storage/EngageAdministrator

		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.save(<- collection, to: self.CollectionStoragePath)

		// Create a public capability for the collection
		self.account.link<&Collection{EngageCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
			self.CollectionPublicPath,
			target: self.CollectionStoragePath
		)

		// Create a Administrator resource and save it to storage
		let administrator <- create Administrator()
		self.account.save(<- administrator, to: self.AdministratorStoragePath)

		emit ContractInitialized()
	}
}
 