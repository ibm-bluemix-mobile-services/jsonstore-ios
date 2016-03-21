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
#import "JSONStoreQueue.h"
#import "JSONStoreMigrationManager.h"

@implementation JSONStore


+(JSONStore*) sharedInstance
{
    static JSONStore *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[JSONStore alloc] init];
    });
    
    return _sharedInstance;
}

-(BOOL) openCollections: (NSArray*) collections
            withOptions: (JSONStoreOpenOptions*) options
                  error: (NSError**) error
{
    int rc = 0;
    BOOL worked = YES;

    @try {
        
        if (self._accessors == nil) {
            self._accessors = [[NSMutableDictionary alloc] init];
        }
        
        if (self._transactionActive) {
            
            worked = NO;
            rc = JSON_STORE_TRANSACTION_FAILURE_DURING_INIT;
            
            NSLog(@"Error: JSON_STORE_TRANSACTION_FAILURE_DURING_INIT, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
            
        }
        
        if (worked) {
            
            for (JSONStoreCollection *currentCollection in collections) {
                
                rc = [self _provisionCollection:currentCollection.collectionName
                               withSearchFields:currentCollection.searchFields
                     withAdditionalSearchFields:currentCollection.additionalSearchFields
                                   withUsername:options.username
                                  withDropFirst:currentCollection._dropFirst
                                          error:error];
                
                if (rc == JSON_STORE_RC_OK || rc == JSON_STORE_PROVISION_TABLE_EXISTS) {
                    
                    currentCollection.reopened = rc ? YES : NO;
                    
                    JSONStoreCollection* cachedCollection =
                    [self._accessors objectForKey:currentCollection.collectionName];
                    
                    if (! cachedCollection) {
                        [self._accessors setObject:currentCollection
                                            forKey:currentCollection.collectionName];
                    }
                    
                } else {
                    
                    worked = NO;
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

-(JSONStoreCollection*) getCollectionWithName: (NSString*) collectionName
{    
    //Returns nil if the collection does not exist in the hash map
    return [self._accessors objectForKey:collectionName];
}

-(BOOL) closeAllCollectionsAndReturnError:(NSError**) error
{
    BOOL worked = YES;
    int rc = 0;

    @try {
        
        if (self._transactionActive) {
            
            worked = NO;
            rc = JSON_STORE_TRANSACTION_FAILURE_DURING_CLOSE_ALL;
            
            NSLog(@"Error: JSON_STORE_TRANSACTION_FAILURE_DURING_CLOSE_ALL, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
            
        } else {
            
            JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
            
            if (! accessor) {
                
                worked = YES;
                
            } else if (! [accessor isOpen]) {
                
                worked = YES;
                
            } else {
                
                worked = [accessor close];
            }
            
            if (worked) {
                
                self._accessors = nil;
                
            } else {
                
                worked = NO;
                rc = JSON_STORE_ERROR_CLOSING_ALL;
                
                NSLog(@"Error: JSON_STORE_ERROR_CLOSING_ALL, code: %d", rc);
                
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



-(BOOL) destroyWithUsername:(NSString*)username error:(NSError**)error
{
    BOOL worked = YES;
    int rc = 0;
    
    @try {
        if (self._transactionActive) {
            
            worked = NO;
            rc = JSON_STORE_TRANSACTION_FAILURE_DURING_DESTROY;
            
            NSLog(@"Error: JSON_STORE_TRANSACTION_FAILURE_DURING_DESTROY with username, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
        } else {
            
            JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
            
            if (accessor) {
                [accessor close];
            }
            
                 //Removing files from keychain worked
                
                NSFileManager *fileManager = [NSFileManager defaultManager];
                
                NSURL* documentsDirectory = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
                NSString *dbPath = [[documentsDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@%@", JSON_STORE_DEFAULT_FOLDER_FOR_SQLITE_FILES, username, JSON_STORE_DB_FILE_EXTENSION]] path];
                
                if ([fileManager fileExistsAtPath:dbPath]) {
                    
                    //Found DB path for username
                    NSError* err = nil;
                    [fileManager removeItemAtPath:dbPath error:&err];
                    
                    if (err != nil) {
                        
                        //Failed to remove the file, error from fileManager
                        worked = NO;
                        rc = DESTROY_FAILED_FILE_ERROR;
                        
                        if (error != nil) {
                            *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                         code:rc
                                                     userInfo:nil];
                        }
                        
                    } else {
                        
                        //Keychain and file removed succesfully
                        worked = YES;
                    }
                    
                } else {
                    
                    //There is nothing to remove, returning success
                    worked = YES;
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

-(BOOL) destroyDataAndReturnError:(NSError**)error
{
    BOOL worked = YES;
    int rc = 0;

    
    @try {
        if (self._transactionActive) {
            
            worked = NO;
            rc = JSON_STORE_TRANSACTION_FAILURE_DURING_DESTROY;
            
            NSLog(@"Error: JSON_STORE_TRANSACTION_FAILURE_DURING_DESTROY, code: %d", rc);
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
        } else {
            
            JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
            
            if (! accessor) {
                
                accessor = [JSONStoreQueue sharedManagerWithUsername:JSON_STORE_DEFAULT_USER];
            }
            
            if (accessor && [self _destroyClearKeyChainAndCloseWithAccessor:accessor]) {
                
                worked = [self closeAllCollectionsAndReturnError:error];
                
            } else {
                
                worked = NO;
                rc = JSON_STORE_ERROR_DURING_DESTROY;
                
                NSLog(@"Error: JSON_STORE_ERROR_DURING_DESTROY, code: %d, accessor user: %@", rc, accessor != nil ? accessor.username : @"nil");
                
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
        NSLog(@"Exception : %@", exception);
    }
    
    return worked;
}

-(BOOL) startTransactionAndReturnError:(NSError**) error
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
            
            if (self._transactionActive) {
                
                worked = NO;
                rc = JSON_STORE_TRANSACTION_IN_PROGRESS;
                
                NSLog(@"Error: JSON_STORE_TRANSACTION_IN_PROGRESS, code: %d", rc);
                
                if (error != nil) {
                    *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                 code:rc
                                             userInfo:nil];
                }
                
            } else {
                
                worked = [accessor.store startTransaction];
                
                if (! worked) {
                    
                    self._transactionActive = NO;
                    rc = JSON_STORE_TRANSACTION_FAILURE;
                    
                    NSLog(@"Error: JSON_STORE_TRANSACTION_FAILURE, code: %d", rc);
                    
                    if (error != nil) {
                        *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                     code:rc
                                                 userInfo:nil];
                    }
                } else {
                    
                    self._transactionActive = YES;
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

-(BOOL) commitTransactionAndReturnError:(NSError**) error
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
            
            if (! self._transactionActive) {
                
                worked = NO;
                rc = JSON_STORE_NO_TRANSACTION_IN_PROGRESS;
                
                NSLog(@"Error: JSON_STORE_NO_TRANSACTION_IN_PROGRESS, code: %d", rc);
                
                if (error != nil) {
                    *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                 code:rc
                                             userInfo:nil];
                }
                
            } else {
                
                worked = [accessor.store commitTransaction];
                
                if (! worked) {
                    
                    rc = JSON_STORE_TRANSACTION_FAILURE;
                    
                    NSLog(@"Error: JSON_STORE_TRANSACTION_FAILURE, code: %d", rc);
                    
                    if (error != nil) {
                        *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                     code:rc
                                                 userInfo:nil];
                    }
                }
                
                self._transactionActive = NO;
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

-(BOOL) rollbackTransactionAndReturnError:(NSError**) error
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
            
            if (! self._transactionActive) {
                
                worked = NO;
                rc = JSON_STORE_NO_TRANSACTION_IN_PROGRESS;
                
                NSLog(@"Error: JSON_STORE_NO_TRANSACTION_IN_PROGRESS, code: %d", rc);
                
                if (error != nil) {
                    *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                 code:rc
                                             userInfo:nil];
                }
                
            } else {
                
                worked = [accessor.store rollbackTransaction];
                
                if (! worked) {
                    
                    rc = JSON_STORE_TRANSACTION_FAILURE;
                    
                    NSLog(@"Error: JSON_STORE_TRANSACTION_FAILURE, code: %d", rc);
                    
                    if (error != nil) {
                        *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                     code:rc
                                                 userInfo:nil];
                    }
                }
                
                self._transactionActive = NO;
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

-(NSArray*) fileInfoAndReturnError:(NSError**) error
{
    NSMutableArray* results = [[NSMutableArray alloc] init];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray* urls = [fileManager URLsForDirectory:NSDocumentDirectory
                                        inDomains:NSUserDomainMask];
    
    NSURL* folderPath = [[urls firstObject] URLByAppendingPathComponent:JSON_STORE_DEFAULT_FOLDER_FOR_SQLITE_FILES];
    
    NSDirectoryEnumerator* enumerator = [fileManager enumeratorAtPath:[folderPath path]];
    
    NSString* file;

    while ( (file = [enumerator nextObject]) ) {
        
        NSString* currentFilePath = [[folderPath URLByAppendingPathComponent:file] path];
        
        NSDictionary* fileAttributes = [fileManager attributesOfItemAtPath:currentFilePath error:error];
        
        if (fileAttributes) {
        
            //File size
            NSNumber* currentFileSize = @([fileAttributes fileSize]);
            
            //Populate return value
            [results addObject:@{JSON_STORE_KEY_FILE_NAME : [file stringByReplacingOccurrencesOfString:JSON_STORE_DB_FILE_EXTENSION withString:@""],
                                 JSON_STORE_KEY_FILE_SIZE : currentFileSize}];
            
        } else {
            
            NSLog(@"Error getting file attributes: %@", error);
            
            results = nil;
            break;
        }
    }
    
    return results;
}

#pragma mark Private API

-(BOOL) _isAnalyticsEnabled
{
    return self._analytics;
}

-(BOOL) _isTransactionInProgress
{
    return self._transactionActive;
}


-(void) _removeAccessor:(NSString*)collectionName
{
    [self._accessors removeObjectForKey:collectionName];
}

#pragma mark Helpers

-(int) _provisionCollection: (NSString*) collectionName
           withSearchFields: (NSDictionary*) searchFields
 withAdditionalSearchFields: (NSDictionary*) additionalIndexes
               withUsername: (NSString*) username
              withDropFirst: (BOOL) dropFirst
                      error: (NSError**) error
{
    
    [[JSONStoreMigrationManager sharedInstance] checkForUpgrade];
    
    int rc = JSON_STORE_RC_OK;
    JSONStoreQueue* accessor;
    
    if (! [username length]) {
        username = JSON_STORE_DEFAULT_USER;
    }
    
    accessor = [JSONStoreQueue sharedManagerWithUsername:username];
    
    if (! accessor) {
        
        NSLog(@"Error: JSON_STORE_USERNAME_MISMATCH, code: %d, username passed: %@, accessor username: %@, collection name: %@", JSON_STORE_USERNAME_MISMATCH, username, accessor != nil ? accessor.username : @"nil", collectionName);
        
        if(error != nil) {
            *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                         code:JSON_STORE_USERNAME_MISMATCH
                                     userInfo:nil];
        }
        
        return JSON_STORE_USERNAME_MISMATCH;
    }
    
    
    if (rc == 0) {
        
        if (dropFirst) {
            [accessor dropTable:collectionName];
        }
        
        //If we aren't already broken, create the table
        rc = [accessor provisionCollection:collectionName
                                withSchema:searchFields
                    additionalSearchFields:additionalIndexes];
    }
    
    if (rc < 0) {
        
        NSLog(@"Error: JSON_STORE_EXCEPTION, code: %d, username: %@, accessor username: %@, collection name: %@, searchFields: %@, additionalSearchFields: %@", rc, username, accessor != nil ? accessor.username : @"nil", collectionName, searchFields, additionalIndexes);
        
        if (error != nil) {
            *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                         code:rc
                                     userInfo:nil];
        }
    
        [accessor close];
    }
    
    return rc;
}


-(BOOL) _destroyClearKeyChainAndCloseWithAccessor:(JSONStoreQueue*) accessor
{
    int rc = [accessor destroy];
    [self _clearUserDefaults];
    [accessor close];
    
    return (rc == 0) ? true : false;
}

-(BOOL) _checkIfDBIsOpened
{
    @try {
        if (! [[JSONStoreQueue sharedManager] isOpen]) {
            return NO;
        }
    } @catch (NSException* ex) {
        return NO;
    }
    
    return YES;
}


-(void) _clearUserDefaults
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:JSON_STORE_VERSION_LABEL];
    [defaults removeObjectForKey:JSON_STORE_SECURITY_VERSION_LABEL];
    [defaults synchronize];
}

-(void) _updateSecurityVersion
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:JSON_STORE_VERSION_2_0 forKey:JSON_STORE_SECURITY_VERSION_LABEL];
    [defaults synchronize];
}

@end
