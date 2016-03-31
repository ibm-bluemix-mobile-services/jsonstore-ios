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

#import "JSONStore.h"
#import "JSONStore+Private.h"
#import "JSONStoreQueue.h"
#import "JSONStoreSecurityManager.h"

static JSONStoreQueue* _jsqSingleton = nil;

@implementation JSONStoreQueue

+(instancetype) sharedManager
{
    if (_jsqSingleton == nil && _jsqSingleton.username == nil) {
        return nil;
    }
    
    return _jsqSingleton;
}

+(instancetype) sharedManagerWithUsername:(NSString*) username
                                            withEncryption:(BOOL)encrypt
{
    if (_jsqSingleton == nil) {
        _jsqSingleton = [[JSONStoreQueue alloc] _initWithUsername:username withEncryption:encrypt];
    }
    
    if (! [username isEqualToString:_jsqSingleton.username]) {
        return nil;
        
    }
    return _jsqSingleton;
}

-(int) removeFromCollection:(NSString*) collection
                  withQuery:(NSDictionary*) query
                      exact:(BOOL) exact
                  markDirty:(BOOL) markDirty
{
    __block int rc = 0;
    
    dispatch_sync(self.operationQueue, ^{
        
        rc = [self.store remove:query
                   inCollection:collection
                      markDirty:markDirty
                          exact:exact];
        
    });
    
    return rc;
}

-(BOOL) isOpen
{
    __block BOOL setKeyWorked = NO;
    
    dispatch_sync(self.operationQueue, ^{
        setKeyWorked = [self.store isOpen];
    });
    
    return setKeyWorked;
}

-(BOOL) setDatabaseKey:(NSString*) password
{
    __block BOOL setKeyWorked = NO;
    
    dispatch_sync(self.operationQueue, ^{
        
        //Need to derive the key from clear text
        JSONStoreSecurityManager *jsonsecmanager = [[JSONStoreSecurityManager alloc]
                                                    initWithUsername:self.username];
        
        NSString* key = [jsonsecmanager getDPK:password];
        
        if (key != nil && [key length] > 0) {
            
            setKeyWorked = [self.store setDatabaseKey:key];
            
        } else {
            
            NSLog(@"Invalid password, pwd length: %d, security manager username: %@, username: %@", [password length], jsonsecmanager != nil ? jsonsecmanager.username : @"nil", self.username);
            
            setKeyWorked = NO;
        }
    });
    
    return setKeyWorked;
}


-(int) provisionCollection:(NSString *)collectionName
                withSchema:(NSDictionary *)schema
    additionalSearchFields:(NSDictionary *)addFields
{
    __block int rc = 0;
    
    dispatch_sync(self.operationQueue, ^{
        
        JSONStoreSchema* jsch = [[JSONStoreSchema alloc] initWithSearchFields:schema
                                                       additionalSearchFields:addFields];
        
        [self.jsonSchemas setValue:jsch
                            forKey:collectionName];
        
        rc = [self.store provision:jsch
                        inDatabase:collectionName];
    });
    
    return rc;
}

-(NSArray*) searchCollection: (NSString*) collection
              withQueryParts: (NSArray*) queryParts
             andQueryOptions: (JSONStoreQueryOptions*) options
{
    __block NSArray* results = nil;
    
    dispatch_sync(self.operationQueue, ^{
        results = [self.store findWithQueryParts:queryParts
                                    inCollection:collection
                                     withOptions:options];
    });
    
    return results;
}

-(int) replaceDocument:(NSArray*) documents
          inCollection:(NSString*) collection
              failures:(NSMutableArray*) failures
             markDirty:(BOOL) markDirty
{
    __block int rc = 0;
    
    dispatch_sync(self.operationQueue, ^{
        
        if (! [[JSONStore sharedInstance] _isTransactionInProgress]) {
            [self.store startTransaction];
        }
        
        
        for (NSDictionary* doc in documents) {
            
            JSONStoreSchema* jsonSchema = [self.jsonSchemas objectForKey:collection];
            
            id jsonObj = [doc objectForKey:JSON_STORE_FIELD_JSON];
            
            NSError* error;
            NSDictionary* indexesAndValues = [self.indexer findIndexesFromSchema:jsonSchema
                                                                   forJsonObject:jsonObj
                                                                           error:&error];
            if (error) {
                rc = JSON_STORE_PERSISTENT_STORE_FAILURE;
                break;
            }
            
            BOOL worked = [self.store replace:doc
                                 inCollection:collection
                                 usingIndexes:indexesAndValues
                                    markDirty:markDirty];
            
            
            if (worked) {
                
                //It worked, increment the number of docs replaced
                rc++;
                
            } else {
                
                //If we can't store all the data, we rollback and go
                //to the error callback
                rc = JSON_STORE_PERSISTENT_STORE_FAILURE;
                
                //Pass back the object that we failed on
                if (failures != nil) {
                    
                    [failures addObject:doc];
                }
                
                break;
            }
        }
        
        //if any of the updates failed, we need to rollback the transaction, otherwise commit it
        if (rc == JSON_STORE_PERSISTENT_STORE_FAILURE) {
            
            if (! [[JSONStore sharedInstance] _isTransactionInProgress]) {
                [self.store rollbackTransaction];
            }
        } else {
            
            if (! [[JSONStore sharedInstance] _isTransactionInProgress]) {
                [self.store commitTransaction];
            }
        }
    });
    
    return rc;
}

-(BOOL) isDirty:(int) docId
   inColleciton:(NSString*) collection
{
    __block BOOL isDirty = NO;
    
    dispatch_sync(self.operationQueue, ^{
        isDirty = [self.store isDirty:docId
                         inCollection:collection];
    });
    
    return isDirty;
    
}

-(BOOL) markClean:(int) docId
     inCollection:(NSString*) collection
     forOperation:(NSString*) operation
{
    
    __block BOOL worked = NO;
    
    dispatch_sync(self.operationQueue, ^{
        worked =  [self.store markClean:docId
                           inCollection:collection
                           forOperation:operation];
    });
    
    return worked;
}

-(int) store:(NSArray*)jsonArr
inCollection:(NSString*) collectionName
       isAdd:(BOOL) isAdd
additionalIndexes:(NSDictionary*) additionalIndexes
       error:(NSError**) error
{
    __block int numWorked = 0;
    
    dispatch_sync(self.operationQueue, ^{
        
        if (! [[JSONStore sharedInstance] _isTransactionInProgress]) {
            [self.store startTransaction];
        }
        
        for (NSDictionary* dict in jsonArr) {
            
            BOOL worked =  [self _storeObject: dict
                                 inCollection: collectionName
                                        isAdd: isAdd
                            additionalIndexes: additionalIndexes];
            
            if (worked) {
                
                numWorked++;
                
            } else {
                
                NSLog(@"Error: JSON_STORE_PERSISTENT_STORE_FAILURE, code: %d, collection name: %@, accessor username: %@, numWorked: %d, markDirty: %@, additionalSearchFields: %@, using transaction API: %@",
                                     JSON_STORE_PERSISTENT_STORE_FAILURE,
                                     collectionName,
                                     self.username,
                                     numWorked,
                                     isAdd ? @"YES" : @"NO",
                                     additionalIndexes,
                                     [[JSONStore sharedInstance] _isTransactionInProgress] ? @"YES" : @"NO");
                NSLog(@"Error: JSON_STORE_PERSISTENT_STORE_FAILURE, object to store: %@", dict);
                
                if (error != nil) {
                    *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                 code:JSON_STORE_PERSISTENT_STORE_FAILURE
                                             userInfo:nil];
                }
                
                //If we can't store all the data, we rollback and go
                //to the error callback
                numWorked = -1;
                
                break;
            }
        }
        
        //if any of the inserts failed, we need to rollback the transaction, otherwise commit it
        if (numWorked == JSON_STORE_PERSISTENT_STORE_FAILURE) {
            
            if (! [[JSONStore sharedInstance] _isTransactionInProgress]) {
                [self.store rollbackTransaction];
            }
            
        } else {
            
            if (! [[JSONStore sharedInstance] _isTransactionInProgress]) {
                [self.store commitTransaction];
            }
        }
    });
    
    return numWorked;
}

-(BOOL) changePassword: (NSString*) oldPwClear
           newPassword: (NSString*) newPwClear
               forUser: (NSString*) username
{
    
    __block BOOL result = NO;
    
    dispatch_sync(self.operationQueue, ^{
        result =  [[[JSONStoreSecurityManager alloc] initWithUsername:username]
                   changeOldPassword:oldPwClear
                   toNewPassword:newPwClear];
    });
    
    return result;
}

-(BOOL) dropTable: (NSString*)collection
{
    __block BOOL result = NO;
    
    dispatch_sync(self.operationQueue, ^{
        result =  [self.store dropTable:collection];
    });
    
    return result;
    
}

-(BOOL) clearTable: (NSString*)collection
{
    __block BOOL result = NO;
    
    dispatch_sync(self.operationQueue, ^{
        result =  [self.store clearTable:collection];
    });
    
    return result;
    
}

-(int) dirtyCount: (NSString*) document
{
    __block int result = 0;
    
    dispatch_sync(self.operationQueue, ^{
        result = [self.store dirtyCount:document];
    });
    
    return result;
}

-(int) count: (NSString*) document
{
    __block int result = 0;
    
    dispatch_sync(self.operationQueue, ^{
        result = [self.store count:document];
    });
    
    return result;
}

-(NSArray*) allDirtyInColleciton: (NSString*) collection
{
    __block NSArray* retArr = nil;
    
    dispatch_sync(self.operationQueue, ^{
        retArr = [self.store allDirtyInCollection:collection];
    });
    
    return retArr;
}

-(int) destroy
{
    __block int result = 0;
    
    dispatch_sync(self.operationQueue, ^{
        
     //   clearKeychainWorked = [[JSONStoreSecurityManager new] clearKeyChain];
    
            
            int fileRc = [self.store destroyDbDirectory];
            
            if (fileRc != 0) {
                result = JSON_STORE_DESTROY_REMOVE_FILE_FAILED;
            }
        
    });
    
    return result;
}

-(BOOL) close
{
    __block BOOL connectionClosed = NO;
    
    dispatch_sync(self.operationQueue, ^{
        connectionClosed = [self.store close];
        self.username = nil;
        self.store = nil;
        self.indexer = nil;
        self.jsonSchemas = nil;
        _jsqSingleton = nil;
    });
    
    return connectionClosed;
}

-(BOOL) isStoreEncrypted
{
    __block BOOL isEnc = NO;
    
    dispatch_sync(self.operationQueue, ^{
        isEnc = [self.store isStoreEncrypted];
    });
    
    return isEnc;
}

#pragma mark Helpers

-(BOOL) _storeObject:(id)jsonObj
        inCollection:(NSString*) collectionName
               isAdd:(BOOL) isAdd
   additionalIndexes:(NSDictionary*) additionalIndexes
{
    BOOL worked = YES;
    
    JSONStoreSchema* jsonSchema = [self.jsonSchemas objectForKey:collectionName];
    
    NSError* error = nil;
    
    NSMutableDictionary* indexesAndValues = [self.indexer findIndexesFromSchema:jsonSchema
                                                                  forJsonObject:jsonObj
                                                                          error:&error];
    if (error) {
        return NO;
    }
    
    if (additionalIndexes != nil) {
        
        [additionalIndexes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            
            NSMutableSet* existingValues = [indexesAndValues objectForKey:key];
            
            if (existingValues == nil) {
                
                existingValues = [NSMutableSet setWithObject:obj];
                
            } else {
                
                [existingValues addObject:obj];
            }
            
            [indexesAndValues setValue:existingValues forKey:key];
        }];
    }
    
    int rc = [self.store store:jsonObj
                  inCollection:collectionName
                    withIdexes:indexesAndValues
                         isAdd:isAdd];
    
    if (rc < 0) {
        worked = NO;
    }
    
    return worked;
}

-(instancetype) _initWithUsername:(NSString*) username
                   withEncryption:(BOOL) encrypt

{
    
    if (self = [super init]) {
        self.username = username;
        self.indexer = [[JSONStoreIndexer alloc] init];
        self.jsonSchemas = [[NSMutableDictionary alloc] init];
        self.store = [[JSONStoreSQLLite alloc] initWithUsername:username withEncryption:encrypt];

        self.operationQueue = dispatch_queue_create("com.jsonstore.operation", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

@end
