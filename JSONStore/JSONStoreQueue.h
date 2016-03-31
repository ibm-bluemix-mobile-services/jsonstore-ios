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

#import "JSONStoreSQLLite.h"
#import "JSONStoreConstants.h"
#import "JSONStoreQueryOptions.h"
#import "JSONStoreIndexer.h"

/**
 Executes all JSONStore operations in a serial queue.
 */
@interface JSONStoreQueue : NSObject

/**
 Instance of a JSONStoreIndexer.
 */
@property (nonatomic, strong) JSONStoreIndexer* indexer;

/**
 Instance of a JSONStoreSQLLite object that communicates with the Database Manager.
 */
@property (nonatomic, strong) JSONStoreSQLLite* store;

/**
 Current user name that is using the queue.
 */
@property (nonatomic, strong) NSString* username;

/**
 Holds the schema for the various collections. Example: {collection1: {name: 'string'}}.
 */
@property (nonatomic, strong) NSMutableDictionary* jsonSchemas;

/**
 Executes operation blocks serially.
 */
@property (nonatomic) dispatch_queue_t operationQueue;

/**
 Returns an instance of self that is initialized with a specific user name. This method must be called first to set the user name, otherwise you will get an exception from sharedManager.
 @param username User name that is tied to the singleton
 @param withEncryption True when using encyrption;
 @return self
 */
+(instancetype) sharedManagerWithUsername:(NSString*) username
                                         withEncryption:(BOOL) encrypt;

/**
 Returns an instance of self, this is a singleton that is tied to a specific user name. Use this method to get a singleton instance.
 @return self
 */
+(instancetype) sharedManager;

/**
 Adds data to a collection as documents.
 @param jsonArr Array of JSON objects as dictionaries
 @param collectionName Name of the collection
 @param isAdd When true, the document is marked as dirty
 @param additionalIndexes Additional search fields
 @param error Error
 @return Number of documents stored
 */
-(int) store:(NSArray*) jsonArr
inCollection:(NSString*) collectionName
       isAdd:(BOOL) isAdd
additionalIndexes:(NSDictionary*) additionalIndexes
       error:(NSError**) error;

/**
 Provisions a collection with a search fields (schema) and additional search fields.
 @param collectionName Name of the collection
 @param schema Search fields
 @param additionalSearchFields Additional search fields
 @return Return code
 */
-(int) provisionCollection:(NSString*) collectionName
                withSchema:(NSDictionary*) schema
    additionalSearchFields:(NSDictionary*) addFields;


/**
 Locates documents inside a collection using query parts.
 @param collection Name of the collection
 @param queryParts Array of JSONStoreQuery objects
 @param options Options
 @return Array of documents as results
 */
-(NSArray*) searchCollection: (NSString*) collection
              withQueryParts: (NSArray*) queryParts
             andQueryOptions: (JSONStoreQueryOptions*) options;

/**
 Removes documents that match the query from a collection.
 @param collection Name of the collection
 @param query Query
 @param exact Exact match (true) or fuzzy search (false)
 @param markDirty Determines if the documents that are added are marked as dirty (true) or not (false)
 @return Number of documents removed
 */
-(int) removeFromCollection:(NSString*) collection
                  withQuery:(NSDictionary*) query
                      exact:(BOOL) exact
                  markDirty:(BOOL) markDirty;

/**
 Replaces documents inside a collection.
 @param documents Array of documents as dictionaries
 @param collection Name of the collection
 @param failures Array of documents that failed to be replaced
 @param markDirty Determines if the documents that are replaced are marked as dirty (true) or not (false)
 @return Number of documents replaced
 */
-(int) replaceDocument:(NSArray*) documents
          inCollection:(NSString*) collection
              failures:(NSMutableArray*) failures
             markDirty:(BOOL) markDirty;

/**
 Checks if a document is dirty using its _id field.
 @param docId The _id field
 @param collection Name of the collection
 @return True if the document is dirty, false otherwise
 */
-(BOOL) isDirty:(int) docId
   inColleciton:(NSString*) collection;

/**
 Returns all dirty documents inside a collection.
 @param collection Name of the collection
 @return Array of dirty documents
 */
-(NSArray*) allDirtyInColleciton:(NSString*) collection;

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
 Sets a password to access the store.
 @param password Password
 @return Success (true) or failure (false)
 */
-(BOOL) setDatabaseKey:(NSString*) password;


/**
 Removes all data inside a collection.
 @param collection Name of the collection
 @return Success (true) or failure (false)
 */
-(BOOL) clearTable: (NSString*) collection;

/**
 Closes the store.
 @return Success (true) or failure (false)
 */
-(BOOL) close;

/**
 Changes the password that is used to open the store.
 @param oldPwClear Old password
 @param newPwClear New password
 @param username User name
 @return Success (true) or failure (false)
 */
-(BOOL) changePassword:(NSString*) oldPwClear
           newPassword:(NSString*) newPwClear
               forUser:(NSString*) username;


/**
 Wipes all JSONStore data and metadata.
 @return Return code
 */
-(int) destroy;

/**
 Checks if the store is opened.
 @return True if the store is opened, false otherwise
 */
-(BOOL) isOpen;


/**
 Checks if the store is encrypted.
 @return True if the store is encrypted, false otherwise
 */
-(BOOL) isStoreEncrypted;



@end
