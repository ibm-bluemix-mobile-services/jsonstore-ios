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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#import "JSONStoreCollection.h"
#import "JSONStoreQueue.h"
#import "JSONStore.h"
#import "JSONStore+Private.h"
#import "JSONStoreQueryPart.h"
#import "NSData+WLJSON.h"


@implementation JSONStoreCollection

-(instancetype) initWithName: (NSString*) collectionName
{
    if (self = [super init]) {
        self.collectionName = collectionName;
        self.searchFields = [[NSMutableDictionary alloc] init];
        self.additionalSearchFields = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

-(void) setSearchField: (NSString*) searchField
              withType: (JSONStoreSearchFieldType) type
{
    
    NSString* typeStr = [JSONStoreCollection _typeStringFromJSONStoreSeachFieldType:type];
    [self.searchFields setObject:typeStr forKey:searchField];
}

-(void) setAdditionalSearchField: (NSString*) additionalSearchField
                        withType: (JSONStoreSearchFieldType) type
{
    NSString* typeStr = [JSONStoreCollection _typeStringFromJSONStoreSeachFieldType:type];
    [self.additionalSearchFields setObject:typeStr forKey:additionalSearchField];
}

-(NSNumber*) addData: (NSArray*) data
  andMarkDirty: (BOOL) markDirty
   withOptions:(JSONStoreAddOptions*) options
         error:(NSError**) error
{
    int rc = 0;
    int numAdded = 0;
    
    @try {
        JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
        
        if (! accessor) {
            
            rc = JSON_STORE_DATABASE_NOT_OPEN;
            
            NSLog(@"Error: JSON_STORE_DATABASE_NOT_OPEN, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
            
        } else {
            
            numAdded = [accessor store:data
                          inCollection:self.collectionName
                                 isAdd:markDirty
                     additionalIndexes:options.additionalSearchFields
                                 error:error];
        }
        
        
    }
    @catch (NSException *exception) {
        rc = JSON_STORE_PERSISTENT_STORE_FAILURE;
        NSLog(@"Exception %@", exception);
    }

    return numAdded >= 0 ? @(numAdded) : nil;
}

-(BOOL) isDirtyWithDocumentId: (int) _id
                        error:(NSError**) error
{
    BOOL dirty = NO;
    int rc = 0;
    
    @try {
        JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
        
        if (! accessor) {
            
            dirty = NO;
            rc = JSON_STORE_DATABASE_NOT_OPEN;
            
            NSLog(@"Error: JSON_STORE_DATABASE_NOT_OPEN, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
            
        } else {
            
            dirty = [accessor isDirty:_id
                         inColleciton:self.collectionName];
        }
    }
    @catch (NSException *exception) {
        rc = JSON_STORE_PERSISTENT_STORE_FAILURE;
        NSLog(@"Exception: %@", exception);
    }
    
    return dirty;
}

-(NSNumber*) countAllDirtyDocumentsWithError:(NSError**) error
{
    int rc = 0;
    int countResult = 0;
    
    @try {
        JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
        
        if (! accessor) {
            
            rc = JSON_STORE_DATABASE_NOT_OPEN;
            
            NSLog(@"Error: JSON_STORE_DATABASE_NOT_OPEN, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
            
        } else {
            
            countResult = [accessor dirtyCount:self.collectionName];
        }
    }
    @catch (NSException *exception) {
        rc = JSON_STORE_PERSISTENT_STORE_FAILURE;
        NSLog(@"Exception: %@", exception);
    }
    
    return countResult >= 0 ? @(countResult) : nil;
}

-(NSArray*) allDirtyAndReturnError:(NSError**) error
{
    return [self _allDirtyWithDocuments:nil error:error];
}

-(NSNumber*) markDocumentsClean:(NSArray*) documents
                    error:(NSError**) error
{
    int rc = 0;
    int numMarkedClean = 0;
    
    @try {
        
        JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
        
        if (! accessor) {
            
            rc = JSON_STORE_DATABASE_NOT_OPEN;
            
            NSLog(@"Error: JSON_STORE_DATABASE_NOT_OPEN, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
            
        } else {
            
            NSMutableArray* failedDocs = [[NSMutableArray alloc] init];
            
            for (NSDictionary* doc in documents) {
                
                int docId = [[doc objectForKey:JSON_STORE_FIELD_ID] intValue];
                NSString* operation = [doc objectForKey:JSON_STORE_FIELD_OPERATION];
                
                BOOL worked = [accessor markClean:docId
                                     inCollection:self.collectionName
                                     forOperation:operation];
                
                if (worked) {
                    numMarkedClean++;
                } else {
                    [failedDocs addObject:doc];
                }
            }
            
            if ([failedDocs count]) {
                
                rc = JSON_STORE_COULD_NOT_MARK_DOCUMENT_PUSHED;
                
                NSLog(@"Error: JSON_STORE_COULD_NOT_MARK_DOCUMENT_PUSHED, code: %d, collection name: %@, accessor username: %@, failedDocs count: %lu, failedDocs: %@", rc, self.collectionName, accessor != nil ? accessor.username : @"nil", (unsigned long)[failedDocs count], failedDocs);
                
                if (error != nil) {
                    *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                 code:rc
                                             userInfo:@{JSON_STORE_ERROR_OBJ_KEY_DOCS : failedDocs}];
                }
            }
        }
    }
    @catch (NSException *exception) {
        rc = JSON_STORE_PERSISTENT_STORE_FAILURE;
        NSLog(@"Exception: %@", exception);
    }
    
    return numMarkedClean >= 0 ? @(numMarkedClean) : nil;
}

-(BOOL) removeCollectionWithError:(NSError**) error
{
    BOOL worked = YES;
    int rc = 0;
    
    @try {
        if ([[JSONStore sharedInstance] _isTransactionInProgress]) {
            
            worked = NO;
            rc = JSON_STORE_TRANSACTION_FAILURE_DURING_REMOVE_COLLECTION;
            
            NSLog(@"Error: JSON_STORE_TRANSACTION_FAILURE_DURING_REMOVE_COLLECTION, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
            
        } else {
            
            JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
            
            if (! accessor) {
                
                worked = NO;
                rc = JSON_STORE_DATABASE_NOT_OPEN;
                
                NSLog(@"Error: JSON_STORE_DATABASE_NOT_OPEN, code: %d", rc);
                
                if (error != nil) {
                    *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                 code:rc
                                             userInfo:nil];
                }
                
            } else {
                
                worked = [accessor dropTable:self.collectionName];
                
                if (! worked) {
                    
                    rc = JSON_STORE_ERROR_CLEARING_COLLECTION;
                    
                    NSLog(@"Error: JSON_STORE_ERROR_CLEARING_COLLECTION, code: %d, collection name: %@, accessor username: %@", rc, self.collectionName, accessor != nil ? accessor.username : @"nil");
                    
                    if (error != nil) {
                        *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                     code:rc
                                                 userInfo:nil];
                    }
                    
                } else {
                    [[JSONStore sharedInstance] _removeAccessor:self.collectionName];
                }
                
            }
        }
    }
    @catch (NSException *exception) {
        worked = NO;
        rc = JSON_STORE_PERSISTENT_STORE_FAILURE;
        NSLog(@"Exception: %@", exception);
    }
    
    return worked;
}

-(NSNumber*) countAllDocumentsAndReturnError:(NSError**) error
{

    NSNumber* countResult = [self countWithQueryParts:nil error:error];
    
    return countResult;
}

-(NSNumber*) countWithQueryParts:(NSArray*)queryParts
                           error:(NSError**) error
{
    int rc = 0;
    int countResult = 0;
    
    @try {
        JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
        
        if (! accessor) {
            
            rc = JSON_STORE_DATABASE_NOT_OPEN;
            
            NSLog(@"Error: JSON_STORE_DATABASE_NOT_OPEN, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
            
        } else {
            
            if (queryParts != nil && [queryParts count] > 0) {
                
                JSONStoreQueryOptions* options = [[JSONStoreQueryOptions alloc] init];
                
                options._count = YES;
                
                NSArray* results = [self findWithQueryParts:queryParts
                                                    andOptions:options
                                                         error:error];
                
                if (results != nil) {
                    countResult = [[results firstObject] intValue];
                } else {
                    countResult = -1;
                }
                
                
            } else {
                countResult = [accessor count:self.collectionName];
            }
        }
    }
    @catch (NSException *exception) {
        rc = JSON_STORE_PERSISTENT_STORE_FAILURE;
        NSLog(@"Exception: %@", exception);
    }

    return countResult >= 0 ? @(countResult) : nil;
}

-(NSNumber*) removeWithIds: (NSArray*) ids
              andMarkDirty: (BOOL) markDirty
                     error: (NSError**) error
{
    NSMutableArray* queries = [[NSMutableArray alloc] initWithCapacity:ids.count];
    
    for(int i = 0; i < (int)ids.count; i++) {
        [queries addObject:@{JSON_STORE_FIELD_ID : ids[i]}];
    }
    
    NSNumber* docsRemoved = [self _removeWithQueries:queries andMarkDirty:markDirty exactMatch:YES error:error];
    
    return docsRemoved;
}

-(NSNumber*) _removeWithQueries: (NSArray*) queries
            andMarkDirty: (BOOL) markDirty
              exactMatch: (BOOL) exactMatch
                   error: (NSError**) error
{
    int rc = 0;
    int numRemoved = 0;
    
    @try {
        JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
        
        if (! accessor) {
            
            rc = JSON_STORE_DATABASE_NOT_OPEN;
            
            NSLog(@"Error: JSON_STORE_DATABASE_NOT_OPEN, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
            
        } else {
            
            NSMutableArray* failures = [NSMutableArray new];
            
            for (NSDictionary* query in queries) {
                
                int lastUpdatedNum = 0;
                
                lastUpdatedNum = [accessor removeFromCollection:self.collectionName
                                                      withQuery:query
                                                          exact:exactMatch
                                                      markDirty:markDirty];
                
                if (lastUpdatedNum < 0) {
                    
                    [failures addObject:query];
                    
                } else {
                    
                    numRemoved += lastUpdatedNum;
                }
            }
            
            if ([failures count] != 0 ) {
                
                rc = JSON_STORE_REMOVE_WITH_QUERIES_FAILURE;
                
                NSLog(@"Error: JSON_STORE_REMOVE_WITH_QUERIES_FAILURE, code: %d, collection name: %@, accessor username: %@, failures count: %lu, query failures: %@", rc, self.collectionName, accessor != nil ? accessor.username : @"nil", (unsigned long)[failures count], failures);
                
                if (error != nil) {
                    *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                 code:rc
                                             userInfo:@{JSON_STORE_ERROR_OBJ_KEY_DOCS: failures}];
                }
            }
        }
    }
    @catch (NSException *exception) {
        rc = JSON_STORE_PERSISTENT_STORE_FAILURE;
        NSLog(@"Exception: %@", exception);
    }
    
    return numRemoved >= 0 ? @(numRemoved) : nil;
}

-(NSNumber*) replaceDocuments: (NSArray*) documents
           andMarkDirty: (BOOL) markDirty
                  error: (NSError**) error
{
    int rc = 0;
    int numReplaced = 0;
    
    @try {
        JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
        
        if (! accessor) {
            
            rc = JSON_STORE_DATABASE_NOT_OPEN;
            
            NSLog(@"Error: JSON_STORE_DATABASE_NOT_OPEN, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
            
        } else {
            
            NSMutableArray* failures = [NSMutableArray new];
            
            numReplaced = [accessor replaceDocument:documents
                                       inCollection:self.collectionName
                                           failures:failures
                                          markDirty:markDirty];
        
            if (numReplaced < 0 ) {
                
                rc = JSON_STORE_REPLACE_DOCUMENTS_FAILURE;
                
                NSLog(@"Error: JSON_STORE_REPLACE_DOCUMENTS_FAILURE, code: %d, collection name: %@, accessor username: %@, failures count: %lu, query failures: %@", rc, self.collectionName, accessor != nil ? accessor.username : @"nil", (unsigned long)[failures count], failures);
                
                
                if (error != nil) {
                    *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                 code:rc
                                             userInfo:@{JSON_STORE_ERROR_OBJ_KEY_DOCS: failures}];
                }
            }
        }
    }
    @catch (NSException *exception) {
        rc = JSON_STORE_PERSISTENT_STORE_FAILURE;
        NSLog(@"Exception: %@", exception);
    }

    return numReplaced >= 0 ? @(numReplaced) : nil;
}

-(NSArray*) findWithIds:(NSArray*) ids
             andOptions:(JSONStoreQueryOptions*) options
                  error:(NSError**) error
{
    JSONStoreQueryPart* queryPart = [[JSONStoreQueryPart alloc] init];
    queryPart._ids = (NSMutableArray*) ids;
    
    NSArray* results = [self findWithQueryParts:@[queryPart]
                                        andOptions:options
                                             error:error];
    
    return results;
}

-(NSArray*) findAllWithOptions:(JSONStoreQueryOptions*) options
                         error:(NSError**) error
{
 
    NSArray* results = [self findWithQueryParts:@[]
                                        andOptions:options
                                             error:error];
    
    return results;
}

-(NSArray*) findWithQueryParts:(NSArray*) queryParts
                       andOptions:(JSONStoreQueryOptions*) options
                            error:(NSError**) error
{
    int rc = 0;
    NSArray* results = nil;
    
    @try {
        JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
        
        if (! accessor) {
            
            rc = JSON_STORE_DATABASE_NOT_OPEN;
            
            NSLog(@"Error: JSON_STORE_DATABASE_NOT_OPEN, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
            
        } else {
            
            results = [accessor searchCollection:self.collectionName
                                  withQueryParts:queryParts
                                 andQueryOptions:options];
            
            
            if (results != nil) {
                
                [JSONStoreCollection _changeJSONBlobToDictionaryWithOptions:options
                                                                   andArray:results];
                
            } else {
                rc = JSON_STORE_INVALID_SEARCH_FIELD;
                
                NSLog(@"Error: JSON_STORE_INVALID_SEARCH_FIELD, code: %d, collection name: %@, accessor username: %@, currentQuery: %@, JSONStoreQueryOptions: %@", rc, self.collectionName, accessor != nil ? accessor.username : @"nil", nil, options);
                
                if (error != nil) {
                    *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                 code:rc
                                             userInfo:nil];
                }
            }    
        }
    }
    @catch (NSException *exception) {
        rc = JSON_STORE_PERSISTENT_STORE_FAILURE;
        NSLog(@"Exception: %@", exception);
    }

    return results;
}

-(BOOL) clearCollectionWithError:(NSError**) error
{
    BOOL worked = YES;
    int rc = 0;
    
    @try {
        JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
        
        if (! accessor) {
            
            worked = NO;
            rc = JSON_STORE_DATABASE_NOT_OPEN;
            
            NSLog(@"Error: JSON_STORE_DATABASE_NOT_OPEN, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
            
        } else {
            
            worked = [accessor.store clearTable:self.collectionName];
            
            if (! worked) {
                
                rc = JSON_STORE_ERROR_CLEARING_COLLECTION;
                
                NSLog(@"Error: JSON_STORE_ERROR_CLEARING_COLLECTION, code: %d, collection name: %@, accessor username: %@", rc, self.collectionName, accessor != nil ? accessor.username : @"nil");
                
                if (error != nil) {
                    *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                 code:rc
                                             userInfo:nil];
                }
            }
        }
    }
    @catch (NSException *exception) {
        worked = NO;
        rc = JSON_STORE_PERSISTENT_STORE_FAILURE;
        NSLog(@"Exception: %@", exception);
    }

    return worked;
}

-(NSNumber*) changeData: (NSArray*) data
withReplaceCriteria: (NSArray*) replaceCriteriaSearchFields
           addNew: (BOOL) addNew
        markDirty: (BOOL) markDirty
            error:(NSError**) error
{
    int rc = 0;
    int numUpdatedOrAdded = 0;
    
    @try {
        NSError* localError = nil;
        
        JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
        
        if (! accessor) {
            
            rc = JSON_STORE_DATABASE_NOT_OPEN;
            
            NSLog(@"Error: JSON_STORE_DATABASE_NOT_OPEN, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
            
        } else {
            
            for (NSDictionary* dict in data ) {
                
                NSMutableDictionary* query = [[NSMutableDictionary alloc] init];
                
                for (NSString* sf in replaceCriteriaSearchFields) {
                    
                    id value = dict[sf];
                    
                    if (value) {
                        [query setObject:value forKey:sf];
                    }
                    
                }
                
                NSArray* results = nil;
                
                if ([query count]) {
                    
                    JSONStoreQueryPart* queryPart = [[JSONStoreQueryPart alloc] init];
                    queryPart._equal = (NSMutableArray*) @[query];
                    
                    results = [self findWithQueryParts:@[queryPart]
                                               andOptions:nil
                                                    error:&localError];
                }
                
                if (results && [results count] > 0) {
                    
                    NSMutableArray* docsToReplace = [[NSMutableArray alloc] initWithCapacity:1];
                    
                    for (int i = 0; i < (int)[results count]; i++) {
                        
                        NSDictionary* doc = @{JSON_STORE_FIELD_ID : [results objectAtIndex:i][JSON_STORE_FIELD_ID], JSON_STORE_FIELD_JSON : dict };
                        [docsToReplace addObject:doc];
                    }
                    
                    int numReplaced = [[self replaceDocuments:docsToReplace
                                                 andMarkDirty:markDirty
                                                        error:&localError] intValue];
                    
                    if (numReplaced > 0) {
                        numUpdatedOrAdded += numReplaced;
                    }
                    
                } else {
                    
                    if (addNew) {
                        
                        int numAdded = [[self addData:@[dict]
                                         andMarkDirty:markDirty
                                          withOptions:nil
                                                error:error] intValue];
                        
                        numUpdatedOrAdded += numAdded;
                    }
                }
            }
            
            if (localError != nil) {
                *error = localError;
                rc = (int)localError.code;
            }
        }
    }
    @catch (NSException *exception) {
        rc = JSON_STORE_PERSISTENT_STORE_FAILURE;
        NSLog(@"Exception: %@", exception);
    }
    
    return numUpdatedOrAdded >= 0 ? @(numUpdatedOrAdded) : nil;
}

#pragma mark Private Helpers

+(NSString*) _typeStringFromJSONStoreSeachFieldType:(JSONStoreSearchFieldType) type
{
    NSString* typeStr;
    
    switch (type) {
        case JSONStore_Boolean:
            typeStr = @"boolean";
            break;
        case JSONStore_Integer:
            typeStr = @"integer";
            break;
        case JSONStore_Number:
            typeStr = @"number";
            break;
        default:
            typeStr = @"string";
    }
    
    return typeStr;
}

+(void) _changeJSONBlobToDictionaryWithOptions:(JSONStoreQueryOptions*) options
                                        andArray:(id) array
{
    if (options._filter == nil || [options._filter count] == 0 || [options._filter indexOfObject:@"json"] != NSNotFound) {
        for (NSMutableDictionary* md in array) {
            if ([md isKindOfClass:[NSDictionary class]]) {
                [JSONStoreCollection _changeJSONBlobToDictionaryWithDictionary:md];
            }
        }
    }
}

+(void) _changeJSONBlobToDictionaryWithDictionary:(NSMutableDictionary*) md
{
    NSData* data =[md objectForKey:JSON_STORE_FIELD_JSON];
    [md setObject:[data WLJSONValue] forKey:JSON_STORE_FIELD_JSON];
}

-(NSArray*) _allDirtyWithDocuments:(NSArray*) documents
                             error:(NSError**) error
{
    int rc = 0;
    NSMutableArray* docsToReturn = nil;

    
    @try {
        JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
        
        if (! accessor) {
            
            rc = JSON_STORE_DATABASE_NOT_OPEN;
            
            NSLog(@"Error: JSON_STORE_DATABASE_NOT_OPEN, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
            
        } else {
            
            docsToReturn = [[NSMutableArray alloc] init];
            
            NSArray* retArr = [accessor allDirtyInColleciton:self.collectionName];
            
            if ([retArr count]) {
                
                for (NSMutableDictionary* md in retArr) {
                    
                    //If we are passed an array of docs from pushSelected, we
                    //only want to return those that are actually dirty in the database.
                    if ([documents count]) {
                        
                        int dirtyId = [[md objectForKey:JSON_STORE_FIELD_ID] intValue];
                        [
                         documents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             NSDictionary* d = (NSDictionary*) obj;
                             if ([[d objectForKey:JSON_STORE_FIELD_ID] intValue] == dirtyId) {
                                 [docsToReturn addObject:md];
                                 *stop = YES;
                             }
                         }];
                        
                    } else {
                        [docsToReturn addObject:md];
                    }
                    
                    [JSONStoreCollection _changeJSONBlobToDictionaryWithDictionary:md];
                }
            }
        }
    }
    @catch (NSException *exception) {
        rc = JSON_STORE_PERSISTENT_STORE_FAILURE;
        NSLog(@"Exception: %@", exception);
    }
    
    return docsToReturn;
}

@end
