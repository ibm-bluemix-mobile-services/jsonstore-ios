# JSONStore SDK 

JSONStore is a lightweight, document-oriented storage system that enables persistent storage of JSON documents for iOS applications.

# Features
* A simple API that gives developers to add, store, replace, search through documents without memorizing query syntax
* Ability to track local changes

# Installation

The JSONStore SDK is available via [Cocoapods](http://cocoapods.org/). To install, add the JSONStore pod to your Podfile.

```Ruby
platform :ios
pod 'JSONStore'
```

	 
# Usage

**Note**: Import using `#import <JSONStore/JSONStoreFramework.h>`

#### Initialize and open connections, get an Accessor, and add data
```Objective-C
	// Create the collections object that will be initialized.
	JSONStoreCollection* people = [[JSONStoreCollection alloc] initWithName:@"people"];
	[people setSearchField:@"name" withType:JSONStore_String];
	[people setSearchField:@"age" withType:JSONStore_Integer];
	
	// Optional options object.
	JSONStoreOpenOptions* options = [JSONStoreOpenOptions new];
	[options setUsername:@"hayatashin"]; //Optional username, default 'jsonstore'
	[options setPassword:@"deta"]; //Optional password, default no password

	// This object will point to an error if one occurs.
	NSError* error = nil;

	// Open the collections.
	[[JSONStore sharedInstance] openCollections:@[people] withOptions:options error:&error];

	// Add data to the collection
	NSArray* data = @[ @{@"name" : @"saito", @"age": @10} ];
	int newDocsAdded = [[people addData:data andMarkDirty:YES withOptions:nil error:&error] intValue];
```

#### Find - locate documents inside the Store
	
```Objective-C
	// Get the accessor to an already initialized collection.
	JSONStoreCollection* people = [[JSONStore sharedInstance] 	getCollectionWithName:@"people"];

	// This object will point to an error if one occurs.
	NSError* error = nil;
	
	// Add additional find options (optional).
	JSONStoreQueryOptions* options = [JSONStoreQueryOptions new];
	[options setLimit:@10]; // Returns a maximum of 10 documents, default no limit.
	[options setOffset:@0]; // Skip 0 documents, default no offset.

	// Search fields to return, default: ['_id', 'json'].
	[options filterSearchField:@"_id"];
	[options filterSearchField:@"json"];

	// How to sort the returned values , default no sort.
	[options sortBySearchFieldAscending:@"name"];
	[options sortBySearchFieldDescending:@"age"];

	// Find all documents that match the query part.
	JSONStoreQueryPart* queryPart1 = [[JSONStoreQueryPart alloc] init];
	[queryPart1 searchField:@"name" equal:@"shu"];
	[queryPart1 searchField:@"age" lessOrEqualThan:@10];

	NSArray* results = [people findWithQueryParts:@[queryPart1] andOptions:options error:&error];

	// results = @[ @{@"_id" : @1, @"json" : @{ @"name": @"shu", @"age" : @10}} ];

	for (NSDictionary* result in results) {
		 NSString* name = [result valueForKeyPath:@"json.name"]; // shu.
	  	int age = [[result valueForKeyPath:@"json.age"] intValue]; // 10
	  	NSLog(@"Name: %@, Age: %d", name, age);
	}
```

#### Replace - change the documents that are already stored inside a Collection
```Objective-C
	// Get the accessor to an already initialized collection.
	JSONStoreCollection* people = [[JSONStore sharedInstance] 	getCollectionWithName:@"people"];

	// Find all documents that match the queries.
	NSArray* docs = @[ @{@"_id" : @1, @"json" : @{ @"name": @"kenshin", @"age" : @99}} ];

	// This object will point to an error if one occurs.
	NSError* error = nil;

	// Perform the replacement.
	int docsReplaced = [[people replaceDocuments:docs andMarkDirty:NO error:&error] intValue];
```

#### Remove - delete all documents that match the query

```Objective-C
	// Get the accessor to an already initialized collection.
	JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];

	// This object will point to an error if one occurs.
	NSError* error = nil;

	// Find document with _id equal to 1 and remove it.
	int docsRemoved = [[people removeWithIds:@[@1] andMarkDirty:NO error:&error] intValue];
```

	
#### Count - gets the total number of documents that match a query

```Objective-C
	// Get the accessor to an already initialized collection.
	JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];

	// Count all documents that match the query.
	// The default query is @{} which will
	// count every document in the collection.
	JSONStoreQueryPart *queryPart = [[JSONStoreQueryPart alloc] init];
	[queryPart searchField:@"name" equal:@"aiko"];

	// This object will point to an error if one occurs.
	NSError* error = nil;

	// Perform the count.
	int countResult = [[people countWithQueryParts:@[queryPart] error:&error] intValue];
```	

#### Destroy - wipes data for all users, destroys the internal storage, and clears security artifacts

```Objective-C
	// This object will point to an error if one occurs.
	NSError* error = nil;

	// Perform the destroy.
	[[JSONStore sharedInstance] destroyDataAndReturnError:&error];
```	
#### Check whether a document is dirty

```Objective-C
		// Get the accessor to an already initialized collection.
		JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];

		// This object will point to an error if one occurs.
		NSError* error = nil;

		// Check if document with _id '1' is dirty.
		BOOL isDirtyResult = [people isDirtyWithDocumentId:1 error:&error];
```

#### Check the number of dirty documents
```Objective-C
	// Get the accessor to an already initialized collection.
	JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];

	// This object will point to an error if one occurs.
	NSError* error = nil;

	// Check if document with _id '1' is dirty.
	int dirtyDocsCount = [[people countAllDirtyDocumentsWithError:&error] intValue];
```

#### Remove a Collection
```Objective-C
	// Get the accessor to an already initialized collection.
	JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];

	// This object will point to an error if one occurs.
	NSError* error = nil;

	// Remove the collection.
	[people removeCollectionWithError:&error];
```

#### Clear all data that is inside a Collection
```Objective-C
	// Get the accessor to an already initialized collection.
	JSONStoreCollection* people = [[JSONStore sharedInstance] 	getCollectionWithName:@"people"];

	// This object will point to an error if one occurs.
	NSError* error = nil;

	// Remove the collection.
	[people clearCollectionWithError:&error];
```
	
#### Start a transaction, add some data, remove a document, commit the transaction and roll back the transaction if there is a failure
	
```Objective-C
	// Get the accessor to an already initialized collection.
	JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];

	// These objects will point to errors if they occur.
	NSError* error = nil;
	NSError* addError = nil;
	NSError* removeError = nil;

	// You can call every JSONStore API method inside a transaction except:
	// open, destroy, removeCollection and closeAll.
	[[JSONStore sharedInstance] startTransactionAndReturnError:&error];

	[people addData:@[ @{@"name" : @"kyo"} ] andMarkDirty:NO withOptions:nil error:&addError];

	[people removeWithIds:@[@1] andMarkDirty:NO error:&removeError];

	if (addError != nil || removeError != nil) {

		// Return the store to the state before start transaction was called.
		[[JSONStore sharedInstance] rollbackTransactionAndReturnError:&error];
	} else {
		// Commit the transaction thus ensuring atomicity.
		[[JSONStore sharedInstance] commitTransactionAndReturnError:&error];
	}
```


#### Get file information
```Objective-C
	// This object will point to an error if one occurs
	NSError* error = nil;

	// Returns information about files JSONStore uses to persist data.
	NSArray* results = [[JSONStore sharedInstance] fileInfoAndReturnError:&error];
	// => [{@"name" : @"aion", @"size" : @3072}]
```	
	
# License

This project is licensed under the terms of the Apache 2 license.
> You can find the license [here](https://github.com/ibm-bluemix-mobile-services/jsonstore-ios/blob/development/LICENSE).