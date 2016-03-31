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
#import "JSONStoreSecurityManager.h"
#import "JSONStoreSecurityUtils.h"
#import "JSONStoreLogger.h"

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
        
        long long startTime = wlGetTimeIntervalSince1970();
        
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
        
        NSString* usr = options.username ? options.username : JSON_STORE_DEFAULT_USER;
        
        if ([options.password length]) {
            
            JSONStoreSecurityManager* secMgr = [[JSONStoreSecurityManager alloc]
                                                initWithUsername:usr];
            
            BOOL keyChainIsFullyPopulated = [secMgr isKeyChainFullyPopulated];
            
            if (! keyChainIsFullyPopulated) {
                
                NSString* salt = [JSONStoreSecurityUtils generateRandomStringWithBytes:JSON_STORE_DEFAULT_SALT_SIZE];
                
                BOOL storeDPKWorked = [self _storeDataProtectionKeyForUsername:options.username
                                                                      withSalt:salt
                                                                  withDPKClear:options.secureRandom
                                                                  withCBKClear:options.password
                                                           withSecurityManager:secMgr];
                
                if (! storeDPKWorked) {
                    
                    worked = NO;
                    rc = JSON_STORE_STORE_DATA_PROTECTION_KEY_FAILURE;
                    
                    NSLog(@"Error: JSON_STORE_STORE_DATA_PROTECTION_KEY_FAILURE, code: %d, username: %@, salt length: %d, dpkClear length: %d, cbkClear length: %d, securityMgr username: %@", rc, options.username, salt != nil ? [salt length] : 0, options.secureRandom != nil ? [options.secureRandom length] : 0, options.password != nil ? [options.password length] : 0, secMgr != nil ? secMgr.username : @"nil");
                    
                    if (error != nil) {
                        *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                                     code:rc
                                                 userInfo:nil];
                    }
                    
                }
                
            }
        }
        
        if (worked) {
            
            for (JSONStoreCollection *currentCollection in collections) {
                
                rc = [self _provisionCollection:currentCollection.collectionName
                               withSearchFields:currentCollection.searchFields
                     withAdditionalSearchFields:currentCollection.additionalSearchFields
                                   withUsername:options.username
                                   withPassword:options.password
                                  withDropFirst:currentCollection._dropFirst
                                          error:error];
                
                NSLog(currentCollection.collectionName, @"open", startTime, rc);
                
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
        NSLog(@"Exception : %@", exception);
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
    
    long long startTime = wlGetTimeIntervalSince1970();

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
    @finally{
        NSLog(@"", @"closeAll", startTime, rc);
    }
    
    return worked;
}


-(BOOL) changeCurrentPassword: (NSString*) oldPassword
              withNewPassword: (NSString*) newPassword
                  forUsername: (NSString*) username
                        error: (NSError**) error
{
    BOOL worked = YES;
    int rc = 0;
    
    long long startTime = wlGetTimeIntervalSince1970();
    
    @try {
        JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
        
        if(! accessor || ![self _checkIfDBIsOpened]) {
            
            worked = NO;
            rc = JSON_STORE_DATABASE_NOT_OPEN;
            
            NSLog(@"Error: JSON_STORE_DATABASE_NOT_OPEN, code: %d, accessor: %@, _checkIfDBIsOpened: %@", rc, accessor, [self _checkIfDBIsOpened] ? @"YES" : @"NO");
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:rc
                                         userInfo:nil];
            }
            
        } else {
            
            worked = [accessor changePassword:oldPassword
                                  newPassword:newPassword
                                      forUser:username];
            
            
            if (! worked) {
                
                rc = JSON_STORE_ERROR_CHANGING_PASSWORD;
                
                NSLog(@"Error: JSON_STORE_ERROR_CHANGING_PASSWORD, code: %d, username: %@, newPwdLength: %d, oldPwdLength: %d", rc, username, [newPassword length], [oldPassword length]);
                
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
    @finally {
        NSLog(@"", @"changePassword", startTime, rc);
        oldPassword = nil;
        newPassword = nil;
    }
    
    return worked;
}



-(BOOL) destroyWithUsername:(NSString*)username error:(NSError**)error
{
    BOOL worked = YES;
    int rc = 0;
    
    long long startTime = wlGetTimeIntervalSince1970();
    
    
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
            
            
            NSString * realUsernameToRemoveDPK = [username isEqualToString:@"jsonstore"] ? JSON_STORE_KEY_DOCUMENT_ID : username;
            
            NSString* jsonstoreKey = [JSONStoreSecurityManager _dpkIdentifierWithBundleId];
            
            //Query to remove security metadata from the keychain
            NSDictionary* removeQuery = @{(__bridge id) kSecClass : (__bridge id) kSecClassGenericPassword,
                                          (__bridge id) kSecAttrAccount : realUsernameToRemoveDPK,
                                          (__bridge id) kSecAttrService : jsonstoreKey};
            
            OSStatus err = SecItemDelete((__bridge CFDictionaryRef) removeQuery);
         
            if (err == noErr || err ==  errSecItemNotFound) {
            
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
                
            } else {
                    
                    //Failure removing keychain item
                    worked = NO;
                    rc = DESTROY_FAILED_METADATA_REMOVAL_FAILURE;
                    
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
    @finally {
        NSLog(@"", @"destroy", startTime, rc);
    }
    
    return worked;
}

-(BOOL) destroyDataAndReturnError:(NSError**)error
{
    BOOL worked = YES;
    int rc = 0;
    
    long long startTime = wlGetTimeIntervalSince1970();

    
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
                
                accessor = [JSONStoreQueue sharedManagerWithUsername:JSON_STORE_DEFAULT_USER withEncryption:self.encryption];
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
    @finally {
        NSLog(@"", @"destroy", startTime, rc);
    }
    
    return worked;
}

-(BOOL) startTransactionAndReturnError:(NSError**) error
{
    BOOL worked = YES;
    int rc = 0;
    
    long long startTime = wlGetTimeIntervalSince1970();
    
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
    @finally{
        NSLog(@"", "startTransaction", startTime, rc);
    }
    
    return worked;
}

-(BOOL) commitTransactionAndReturnError:(NSError**) error
{
    BOOL worked = YES;
    int rc = 0;
    
    long long startTime = wlGetTimeIntervalSince1970();

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
    @finally {
        NSLog(@"", @"commitTransaction", startTime, rc);
    }
    
    return worked;
}

-(BOOL) rollbackTransactionAndReturnError:(NSError**) error
{
    BOOL worked = YES;
    int rc = 0;
    
    long long startTime = wlGetTimeIntervalSince1970();

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
    @finally {
        NSLog(@"", @"rollbackTransaction", startTime, rc);
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
            
            //Check if file is encrypted
            NSData* searchData = [@"SQLite" dataUsingEncoding:NSUTF8StringEncoding];
            
            NSData* fileData = [[NSFileHandle fileHandleForReadingAtPath:currentFilePath]
                                readDataOfLength:16];
            
            NSRange locatedRange = [fileData rangeOfData:searchData
                                                 options:kNilOptions
                                                   range:NSMakeRange(0, [fileData length])];
            
            BOOL isStoreEncrypted = (locatedRange.location == NSNotFound);


            
            //File size
            NSNumber* currentFileSize = @([fileAttributes fileSize]);
            
            //Populate return value
            [results addObject:@{JSON_STORE_KEY_FILE_NAME : [file stringByReplacingOccurrencesOfString:JSON_STORE_DB_FILE_EXTENSION withString:@""],
                                 JSON_STORE_KEY_FILE_SIZE : currentFileSize,
                                 JSON_STORE_KEY_FILE_IS_ENCRYPTED : @(isStoreEncrypted)}];
            
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

-(BOOL) _isStoreEncryptedAndReturnError:(NSError**) error
{
    JSONStoreQueue* accessor = [JSONStoreQueue sharedManager];
    
    if (! accessor) {
        
        NSLog(@"Error: JSON_STORE_DATABASE_NOT_OPEN, code: %d", JSON_STORE_DATABASE_NOT_OPEN);
        
        if (error != nil) {
            *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                         code:JSON_STORE_DATABASE_NOT_OPEN
                                     userInfo:nil];
        }
        
        return NO;
    }
    
    BOOL isEnc = [accessor isStoreEncrypted];
    
    return isEnc;
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
               withPassword: (NSString*) password
              withDropFirst: (BOOL) dropFirst
                      error: (NSError**) error
{
    
    [[JSONStoreMigrationManager sharedInstance] checkForUpgrade];
    
    int rc = JSON_STORE_RC_OK;
    JSONStoreQueue* accessor;
    
    if (! [username length]) {
        username = JSON_STORE_DEFAULT_USER;
    }
    
    accessor = [JSONStoreQueue sharedManagerWithUsername:username withEncryption:self.encryption];
    
    if (! accessor) {
        
        NSLog(@"Error: JSON_STORE_USERNAME_MISMATCH, code: %d, username passed: %@, accessor username: %@, collection name: %@", JSON_STORE_USERNAME_MISMATCH, username, accessor != nil ? accessor.username : @"nil", collectionName);
        
        if(error != nil) {
            *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                         code:JSON_STORE_USERNAME_MISMATCH
                                     userInfo:nil];
        }
        
        return JSON_STORE_USERNAME_MISMATCH;
    }
    
    
    if ([password length]) {
        
        rc = [[JSONStoreMigrationManager sharedInstance] checkForSecurityUpgrade:username
                                                                     andPassword:password];
        
        BOOL setDBKeyWorked = [accessor setDatabaseKey:password];
        
        if (rc == 0 && !setDBKeyWorked) {
            
            NSLog(@"Error: JSON_STORE_PROVISION_KEY_FAILURE, code: %d, checkForSecurityUpgrade return code: %d, setDBKeyWorked: %@", JSON_STORE_PROVISION_KEY_FAILURE, rc, setDBKeyWorked ? @"YES" : @"NO");
            
            if (error != nil) {
                *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                             code:JSON_STORE_PROVISION_KEY_FAILURE
                                         userInfo:nil];
            }
            
            return JSON_STORE_PROVISION_KEY_FAILURE;
        }
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

-(BOOL) _storeDataProtectionKeyForUsername:(NSString*) username
                                  withSalt:(NSString*) salt
                              withDPKClear:(NSString*) dpkClear
                              withCBKClear:(NSString*) cbkClear
                       withSecurityManager:(JSONStoreSecurityManager*) securityMgr
{
    
    BOOL worked;
    
    if (dpkClear != nil && [dpkClear length]) {
        
        worked = [securityMgr storeDPK:dpkClear usingPassword:cbkClear withSalt:salt];
        
    } else {
        
        worked = [securityMgr generateAndStoreDpkUsingPassword:cbkClear withSalt:salt];
    }
    
    if (worked && [JSON_STORE_DEFAULT_USER isEqualToString:username]) {
        
        [self _updateSecurityVersion];
    }
    
    dpkClear = nil;
    cbkClear = nil;
    salt = nil;
    
    return worked;
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
