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
#import "JSONStoreQueryOptions.h"
#import "JSONStoreAddOptions.h"

typedef enum {
    JSONStore_Boolean = 1,
    JSONStore_Integer = 2,
    JSONStore_Number = 3,
    JSONStore_String = 4
} JSONStoreSearchFieldType;

/**
 Contains JSONStore methods that operate on a single collection.
 */
@interface JSONStoreCollection : NSObject

/**
 Name of the collection.
 */
@property (nonatomic, strong) NSString* collectionName;

/**
 Search fields that are tied to a collection.
 */
@property (nonatomic, strong) NSMutableDictionary* searchFields;

/**
 Additional Search fields that are tied to the collection.
 */
@property (nonatomic, strong) NSMutableDictionary* additionalSearchFields;

/**
 Boolean that shows if the collection was reopened (true) or newly created (false).
 */
@property (nonatomic, getter = wasReopened) BOOL reopened;

/**
 Private. Remove the collection (drop table [collection]) before initializing.
 @private
 */
@property (nonatomic) BOOL _dropFirst;

/**
 Creates a new JSONStoreCollection instance for the collection with the given name.
 @param collectionName the name of the collection
 @return new instance
 */
-(JSONStoreCollection*) initWithName: (NSString*) collectionName;

/**
 Sets the given search field for the collection. Must be called before opening the collection. Cannot be changed after the collection is opened.
 @param searchField the name of the search field
 @param type the type of the search field
 */
-(void) setSearchField: (NSString*) searchField
              withType: (JSONStoreSearchFieldType) type;

/**
 Sets the given additional search field for the collection. Must be called before opening the collection. Cannot be changed after the collection is opened.
 @param additionalSearchField the name of the additional search field
 @param type the type of the additional search field
 */
-(void) setAdditionalSearchField: (NSString*) additionalSearchField
                        withType: (JSONStoreSearchFieldType) type;

/**
 Permanently deletes all the documents stored in a collection and removes the accessor for that collection.
 @param error Error
 @return Boolean that indicates the operation failed (false) or succeeded (true)
 */
-(BOOL) removeCollectionWithError:(NSError**) error;

/**
 Permanently deletes all the documents stored in a collection while preserving the accessor for the collection.
 @param error Error
 @return Boolean that indicates the operation failed (false) or succeeded (true)
 */
-(BOOL) clearCollectionWithError:(NSError**) error;

/**
 Stores data as documents in the collection.
 @param data NSArray of JSON data represented as NSDictionaries
 @param markDirty Determines if the documents that are added should be marked dirty (true) or not (false)
 @param options Options for handling things like additional search fields
 @param error Error
 @return Number data added, nil if there is a failure
 */
-(NSNumber*) addData: (NSArray*) data
  andMarkDirty: (BOOL) markDirty
   withOptions: (JSONStoreAddOptions*) options
         error: (NSError**) error;

/**
This method is used to modify documents inside a collection by replacing existing documents with given documents. The field that is used to perform the replacement is the document's unique identifier (_id).
 @param documents Array of documents represented as NSDictionaries with the following key value pairs: _id (integer) and json (NSDictionary).
 @param markDirty Determines if the documents that are replaced should be marked dirty (true) or not (false)
 @param error Error
 @return Number documents replaced, nil if there is a failure
 */
-(NSNumber*) replaceDocuments: (NSArray*) documents
           andMarkDirty: (BOOL) markDirty
                  error: (NSError**) error;

/**
 Locates documents inside a collection by using one or more query parts.
 @param queryParts Array of JSONStoreQueryPart objects
 @param options Options such as filter, sort, limit, and offset
 @param error Error
 @return All documents in the collection that matched the query parts, nil if there is a failure
 */
-(NSArray*) findWithQueryParts:(NSArray*) queryParts
                       andOptions:(JSONStoreQueryOptions*) options
                            error:(NSError**) error;

/**
 Returns all documents in the collection.
 @param options Options such as filter, sort, limit, and offset
 @param error Error
 @return All documents in the collection, nil if there is a failure
 */
-(NSArray*) findAllWithOptions:(JSONStoreQueryOptions*) options
                         error:(NSError**) error;

/**
 Returns all documents that match the _id values passed.
 @param ids array of _id field values that is represented as an integers
 @param options Options such as filter, sort, limit, and offset
 @param error Error
 @return Documents found with matching _id fields, nil if there is a failure
 */
-(NSArray*) findWithIds:(NSArray*) ids
             andOptions:(JSONStoreQueryOptions*) options
                  error:(NSError**) error;

/**
 Returns the total number of documents that exist in the collection.
 @param error Error
 @return Number of documents in the collection, nil if there is a failure
 */
-(NSNumber*) countAllDocumentsAndReturnError:(NSError**) error;

/**
 Returns the total number of documents that match the query parts.
 @param queryParts Array of JSONStoreQueryPart objects
 @param error Error
 @return Number of documents that matched the query parts, nil if there is a failure
 */
-(NSNumber*) countWithQueryParts:(NSArray*)queryParts
                         error:(NSError**) error;

/**
 Returns the total number of dirty documents in the collection.
 @param error Error
 @return Number of documents that are dirty in the collection, nil if there is a failure
 */
-(NSNumber*) countAllDirtyDocumentsWithError:(NSError**) error;

/**
 Takes input from allDirtyAndReturnError: (which returns documents with an _operation key value pair) and marks documents as clean.
 @param documents NSArray of documents that are represented as NSDictionaries
 @param error Error
 @return Number of documents marked clean, nil if there is a failure
 */
-(NSNumber*) markDocumentsClean:(NSArray*) documents
                    error:(NSError**) error;

/**
 Get all documents that are marked dirty in the collection.
 @param error Error
 @return NSArray of all dirty documents in the collection, nil if there is a failure
 */
-(NSArray*) allDirtyAndReturnError:(NSError**) error;

/**
 Returns whether the document represented by the given _id value is dirty or not.
 @param _id The _id field value of the document
 @param error Error
 @return True if the document is dirty, false otherwise
 */
-(BOOL) isDirtyWithDocumentId: (int) _id
                        error:(NSError**) error;

/**
 Uses a replacement criteria to locate documents for a targeted replacement, if no existing document is found it checks the addNew flag to determine if a new document should be added.
 @param data NSArray of JSON objects as NSDictionary
 @param addNew Determines if new JSON objects are added to the store if they are not already inside (true) or not (false)
 @param markDirty Determines if the operation marks changes as dirty (true) or not (false)
 @param error Error
 @return Number of documents changed, nil if there is a failure
 */
-(NSNumber*) changeData: (NSArray*) data
withReplaceCriteria: (NSArray*) replaceCriteriaSearchFields
           addNew: (BOOL) addNew
        markDirty: (BOOL) markDirty
            error: (NSError**) error;

/**
 Removes documents from the collection by using one or more _id values. Removed documents are not returned by the different find operations and they do not affect count operations.
 @param ids NSArray of _id values represented as integers
 @param markDirty Determines if the documents that are removed are marked as dirty (true) or not (false)
 @param error Error
 @return Number documents removed, nil if there is a failure
 */
-(NSNumber*) removeWithIds: (NSArray*) ids
                   andMarkDirty: (BOOL) markDirty
                          error: (NSError**) error;


/**
 Privae. Removes documents from the collection using one or more queries. Removed documents are not returned by the different find operations and they do not affect count operations.
 @param queries Array of queries represented as NSDictionaries
 @param markDirty Determines if the documents that are removed are marked as dirty (true) or not (false)
 @param exactMatch Determines if an exact match (true) or a fuzzy search (false) is performed
 @param error Error
 @return Number documents removed, nil if there's a failure
 @private
 */
-(NSNumber*) _removeWithQueries: (NSArray*) queries
                   andMarkDirty: (BOOL) markDirty
                     exactMatch: (BOOL) exactMatch
                          error: (NSError**) error;

/**
 Private. Get all dirty documents in the collection from the given document array.
 @param documents Array of documents that are represented as NSDictionaries
 @param error Error
 @return Array of dirty documents, nil if there's a failure
 @private
 */
-(NSArray*) _allDirtyWithDocuments:(NSArray*) documents
                             error:(NSError**) error;


@end
