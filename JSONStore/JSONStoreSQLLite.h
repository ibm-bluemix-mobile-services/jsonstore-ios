/*
 *     Copyright 2016 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */

#import <Foundation/Foundation.h>
#import "JSONStoreSchema.h"
#import "JSONStoreQueryOptions.h"

/**
 Query builder that communicates with the Database Manager.
 */
@interface JSONStoreSQLLite : NSObject

/**
 Current user name that is using the query builder.
 */
@property (nonatomic, strong) NSString* username;

/**
 Instance of a Database Manager object.
 */
@property (nonatomic, strong) id dbMgr;

/**
 True when a valid key has been passed to the store.
 */
@property (nonatomic) BOOL dbHasBeenKeyed;


/**
True when using encryption
*/
@property (nonatomic) BOOL isEncrypt;

/**
 Returns an instance of self that is initialized with a specific user name.
 @param username User name that is tied to the singleton
 @param withEncryption True when using encryption
 @return self
 */
-(instancetype) initWithUsername:(NSString*) username
                  withEncryption:(BOOL) encrypt;

/**
 Adds data to a collection as documents.
 @param jsonObj JSON object
 @param collection Name of the collection
 @param idx Search fields
 @param isAdd When true document is marked as dirty
 @return Number of documents stored
 */
-(int) store:(id) jsonObj
inCollection:(NSString*) collection
  withIdexes:(NSDictionary*) idx
       isAdd:(BOOL) isAdd;

/**
 Provisions a collection with a search fields (schema).
 @param collection Name of the collection
 @param schema Search fields
 @return Return code
 */
-(int) provision:(JSONStoreSchema*) schema
      inDatabase:(NSString*) collection;

/**
 Locates documents inside a collection using query parts.
 @param queryParts Array of JSONStoreQuery objects
 @param collection Name of the collection
 @param options Options
 @return Array of documents as results
 */
-(NSArray*) findWithQueryParts:(NSArray*) queryParts
                  inCollection:(NSString*) collection
                   withOptions:(JSONStoreQueryOptions*) options;

/**
 Replaces a document inside a collection.
 @param document Documents as a dictionary
 @param collection Name of the collection
 @param idx Search fields
 @param markDirty Determines if the documents that are replaced are marked as dirty (true) or not (false)
 @return Number of documents replaced
 */
-(BOOL) replace:(NSDictionary*) document
   inCollection:(NSString*) collection
   usingIndexes:(NSDictionary*) idx
      markDirty:(BOOL) markDirty;

/**
 Removes documents that match the query from a collection.
 @param query Query
 @param collection Name of the collection
 @param markDirty Determines if the documents that are added are marked as dirty (true) or not (false)
 @param exact Exact match (true) or fuzzy search (false)
 @return Number of documents removed
 */
-(int) remove:(NSDictionary*) query
 inCollection:(NSString*) collection
    markDirty:(BOOL) markDirty
        exact: (BOOL) exact;

/**
 Checks if a document is dirty using its _id field.
 @param docId The _id field
 @param collection Name of the collection
 @return True if the document is dirty, false otherwise
 */
-(BOOL) isDirty:(int) docId
   inCollection:(NSString*) document;

/**
 Returns all dirty documents inside a collection.
 @param collection Name of the collection
 @return Array of dirty documents
 */
-(NSArray*) allDirtyInCollection:(NSString*) collection;

/**
 Counts all dirty documents inside a collection.
 @param collection Name of the collection
 @return Number of dirty documents
 */
-(int) dirtyCount:(NSString*) collection;

/**
 Counts all documents inside a collection.
 @param collection Name of the collection
 @return Number of documents
 */
-(int) count:(NSString*) collection;

/**
 Marks a document clean using its _id field.
 @param docId The _id field
 @param collection Name of the collection
 @param operation The operation
 @return Success (true) or failure (false)
 */
-(BOOL) markClean:(int) docId
     inCollection:(NSString*) collection
     forOperation:(NSString*) operation;

/**
 Removes a collection accessor and all data inside.
 @param collection Name of the collection
 @return Success (true) or failure (false)
 */
-(BOOL) dropTable:(NSString*) collection;

/**
 Removes all data inside a collection.
 @param collection Name of the collection
 @return Success (true) or failure (false)
 */
-(BOOL) clearTable:(NSString*) collection;

/**
 Sets an encryption key to access the store.
 @param encKey Encryption key
 @return Success (true) or failure (false)
 */
-(BOOL) setDatabaseKey:(NSString*) encKey;

/**
 Closes the store.
 @return Success (true) or failure (false)
 */
-(BOOL) close;

/**
 Checks if the store is opened.
 @return True if the store is opened, false otherwise
 */
-(BOOL) isOpen;

/**
 Removes the directory that is used to keep data for the stores.
 @return Return code
 */
-(int) destroyDbDirectory;

/**
 Checks if the store is encrypted or not.
 @return True if the store is encrypted, false otherwise
 */
-(BOOL) isStoreEncrypted;

/**
 Starts a transaction.
 @return Success (true) or failure (false)
 */
-(BOOL) startTransaction;

/**
 Commits a transaction.
 @return Success (true) or failure (false)
 */
-(BOOL) commitTransaction;

/**
 Rolls back a transaction.
 @return Success (true) or failure (false)
 */
-(BOOL) rollbackTransaction;

@end
