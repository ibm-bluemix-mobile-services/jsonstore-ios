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

#import "JSONStoreSQLLite.h"
#import "JSONStoreConstants.h"
#import "JSONStoreQueryPart.h"
#import "JSONStoreValidator.h"
#import "NSObject+WLJSON.h"
#import "SQLiteDatabase.h"


@implementation JSONStoreSQLLite

#pragma mark Public API

-(instancetype) initWithUsername:(NSString*) username withEncryption:(BOOL)encrypt
{
    if (self = [super init]) {
        self.username = username;
        self.isEncrypt = encrypt;
        if(self.isEncrypt){
            id sqlite = [NSClassFromString(@"SQLCipherDatabase")alloc];
            self.dbMgr = [sqlite performSelector:NSSelectorFromString(@"initWithUserName:") withObject:self.username];
        } else {
            id sqlite = [NSClassFromString(@"SQLiteDatabase")alloc];
            self.dbMgr = [sqlite performSelector:NSSelectorFromString(@"initWithUserName:") withObject:self.username];
        }
    

    }
    
    return self;
}

-(int) provision:(JSONStoreSchema*) schema
      inDatabase:(NSString*) collection
{
    int rc = 0;
    
    if (self.dbMgr == nil) {
        if(self.isEncrypt){
            id sqlite = [NSClassFromString(@"SQLCipherDatabase")alloc];
            self.dbMgr = [sqlite performSelector:NSSelectorFromString(@"initWithUsername:") withObject:self.username];
        } else {
            id sqlite = [NSClassFromString(@"SQLiteDatabase")alloc];
            self.dbMgr = [sqlite performSelector:NSSelectorFromString(@"initWithUsername:") withObject:self.username];
        }
    }
    
    NSString* createPref = [NSString stringWithFormat:@"create table '%@' ( _id INTEGER primary key autoincrement, ", collection];
    NSString* createSuf = @" json BLOB, _dirty REAL default 0, _deleted INTEGER default 0, _operation TEXT)";
    NSString* indexedColumns = [self _schemaFromDict:[schema getCombinedDictionary]];
    NSString* stmt = [NSString stringWithFormat:@"%@%@%@;", createPref, indexedColumns, createSuf];
    

    
    if (! [self.dbMgr executeSchemaCreation:stmt]) {
        
        // If the creation indicates a failure, determine if it is due to the table already existing, which isn't really an error.
        NSString* failedMessage = [self.dbMgr lastErrorMsg];
        NSString* TABLE_EXISTS_STRING = [NSString stringWithFormat:@"table '%@' already exists", collection];
        
        if ([failedMessage rangeOfString:TABLE_EXISTS_STRING].location == NSNotFound) {
            
            if ([failedMessage rangeOfString:JSON_STORE_FILE_ENCRYPTED].location != NSNotFound) {
                
                //This happens when, we weren't passed in a password, but the datatbase was encrypted, so we
                //don't know until we try to provision.
                rc = JSON_STORE_PROVISION_KEY_FAILURE;
                
            } else {
                
                rc = JSON_STORE_PROVISION_TABLE_FAILURE;
            }
            
        } else {
            
            if ([self _validateExistingSchemaAgainst:indexedColumns
                                             inTable:collection
                                          withPrefix:createPref
                                           andSuffix:createSuf]) {
                
                rc = JSON_STORE_PROVISION_TABLE_EXISTS;
                
            } else {
                
                rc = JSON_STORE_PROVISION_TABLE_SCHEMA_MISMATCH;
            }
        }
    }
    
    return rc;
}

-(BOOL) dropTable:(NSString*)collection
{
    // If the database has been closed, re-open it.  We do this because provision could be called
    // after a close and indicate the collection needs to be dropped, so we need to open the
    // collection here.  Note that the API in StoragePlugin does NOT support dropping a closed table
    // This is only supported via provision.
    if (self.dbMgr == nil) {
        if(self.isEncrypt){
            id sqlite = [NSClassFromString(@"SQLCipherDatabase")alloc];
            self.dbMgr = [sqlite performSelector:NSSelectorFromString(@"initWithUsername:") withObject:self.username];
        } else{
            id sqlite = [NSClassFromString(@"SQLiteDatabase")alloc];
            self.dbMgr = [sqlite performSelector:NSSelectorFromString(@"initWithUsername:") withObject:self.username];
        }
    }
    
    NSString* dropStmt = [NSString stringWithFormat:@"drop table if exists '%@'", collection];
    return [self.dbMgr execute:dropStmt];
}

-(BOOL) clearTable:(NSString*)collection
{
    NSString* dropStmt = [NSString stringWithFormat:@"DELETE FROM '%@' WHERE 1", collection];
    return [self.dbMgr execute:dropStmt];
}

-(BOOL) replace:(NSDictionary*) document
   inCollection:(NSString*)collection
   usingIndexes:(NSDictionary*) idx
      markDirty:(BOOL) markDirty
{
    
    int docId = [[document objectForKey:JSON_STORE_FIELD_ID] intValue];
    
    if ([self _isRemoved:docId inCollection:collection]) {
        return NO;
    }
    
    NSMutableDictionary* setClauseDict = [NSMutableDictionary new];
    
    [idx enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        if ([obj isKindOfClass:[NSSet class]]) {
            
            [setClauseDict setObject:[[(NSSet*) obj allObjects] componentsJoinedByString:@"-@-"] forKey:key];
            
        } else {
            
            [setClauseDict setObject:obj forKey:key];
        }
    }];
    
    [setClauseDict setObject:[[document objectForKey:JSON_STORE_FIELD_JSON] WLJSONData]
                      forKey:JSON_STORE_FIELD_JSON];
    
    if (markDirty) {
        
        NSDate *d = [NSDate new];
        [setClauseDict setObject:d forKey:JSON_STORE_FIELD_DIRTY];
        
    } else {
        
        [setClauseDict setObject:[NSNumber numberWithInt:0] forKey:JSON_STORE_FIELD_DIRTY];
    }
    
    // If the previous operation was an add, leave that operation so the Document gets added
    if (! [self _isAdded:docId inCollection:collection]) {
        [setClauseDict setObject:JSON_STORE_OP_UPDATE forKey:JSON_STORE_FIELD_OPERATION];
    }
    
    NSString* whereStr = [self _whereClauseForId:docId];
    NSString* setClauseStr = [self _queryFromDict:setClauseDict delimiter:@", "];
    
    NSString* updateStmt = [NSString stringWithFormat:@"update '%@' set %@ where( %@ )",
                            collection, setClauseStr, whereStr];
    
    int rowsUpdated = [self.dbMgr update:updateStmt, [setClauseDict allValues]];
    
    return rowsUpdated > 0;
}

-(int) destroyDbDirectory
{
    if (self.dbMgr == nil) {
        if(self.isEncrypt){
            id sqlite = [NSClassFromString(@"SQLCipherDatabase")alloc];
            self.dbMgr = [sqlite performSelector:NSSelectorFromString(@"initWithUsername:") withObject:self.username];
        } else {
            id sqlite = [NSClassFromString(@"SQLiteDatabase")alloc];
            self.dbMgr = [sqlite performSelector:NSSelectorFromString(@"initWithUsername:") withObject:self.username];
        }
    }
    
    NSString* dbDirPath = [self.dbMgr getJsonStoreDirectoryPath];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* err = nil;
    
    if ([fileManager fileExistsAtPath:dbDirPath]) {
        
        [fileManager removeItemAtPath:dbDirPath error:&err];
        
        if (err != nil) {
            NSLog(@"Destroy failed removing file at path: %@, error: %@", dbDirPath, err);
            return -1;
        }
        
    }
    
    return 0;
}

//Does the actual delete statement in the database, this should only be called by the code that cleans up the queue,
//if you just want to mark a record as deleted you should call remove:(NSDictionary*)query inCollection:(NSString*) collection
-(int) deleteFromCollection:(NSString*)
collection withDocId:(int) docId
{
    int numDeleted = 0;
    
    NSString* whereClause = [self _whereClauseForId:docId];
    
    NSString* deleteStmt = [NSString stringWithFormat:@"delete from '%@' where ( %@ )",
                            collection, whereClause];
    
    numDeleted  = [self.dbMgr deleteFromDatabase:deleteStmt];
    
    return numDeleted;
}

//If markDirty is true, this method doesn't actually run a delete SQL statement and remove the record from the database,
//instead it sets the _deleted  column in the database to true, meaning the record will no longer
//be returned to the user in find queries, but won't be purged until we send the record to the server.
//If markDirty is false, then the record will be removed from the database.
-(int) remove:(NSDictionary*)query
 inCollection:(NSString*) collection
    markDirty:(BOOL) markDirty
        exact: (BOOL) exact
{
    int numMarkedDeleted = 0;
    
    NSArray* findResult = nil;
    
    //Check for the case where we have a document, if so find only by the Id and not a wildcard match
    NSNumber* currId = [query objectForKey:JSON_STORE_FIELD_ID];
    
    JSONStoreQueryPart* queryPart = [[JSONStoreQueryPart alloc] init];
    
    if (currId != nil) {
        
        queryPart._ids = (NSMutableArray*) @[currId];
        
    } else {
        
        
        if (exact) {
            queryPart._equal = (NSMutableArray*) @[query];
        } else {
            queryPart._like = (NSMutableArray*) @[query];
        }
    }
    
    findResult = [self findWithQueryParts:@[queryPart]
                             inCollection:collection
                              withOptions:nil];
    
    for (NSDictionary* dict in findResult) {
        
        int _id = [[dict objectForKey:JSON_STORE_FIELD_ID] intValue];
        
        // If is marked dirty, then indicate the document should be delete on the next sync.
        // If not marked dirty, that means just remove the document from the local store.
        // If the document has been added to the local store but not yet synced to the server
        // then it should be removed from the local store regardless of what the markDirty
        // flag indicates (the server doesn't know about it yet)
        if (markDirty && ![self _isAdded:_id inCollection:collection]) {
            
            NSMutableDictionary* setClauseDict = [NSMutableDictionary new];
            
            NSDate* currentDate = [NSDate new];
            
            [setClauseDict setObject:currentDate forKey:JSON_STORE_FIELD_DIRTY];
            [setClauseDict setObject:JSON_STORE_OP_DELETE forKey:JSON_STORE_FIELD_OPERATION];
            [setClauseDict setObject:[NSNumber numberWithInt:1] forKey: JSON_STORE_FIELD_DELETED];
            
            NSString* whereClause = [self _whereClauseForId:_id];
            NSString* setClause = [self _queryFromDict:setClauseDict delimiter:@", "];
            
            //Note that we don't actually delete here, we just mark the record as deleted so we can push the change to the adapter.
            NSString* updateStmt = [NSString stringWithFormat:@"update '%@' set %@ where ( %@ )",
                                    collection, setClause, whereClause];
            
            if ([self.dbMgr update:updateStmt, [setClauseDict allValues]]) {
                
                numMarkedDeleted++;
                
            } else {
                NSLog(@"An error occured removing a record from database, collection: %@ _id: %d", collection, _id);
            }
            
        } else {
            
            // Since we are deleting a specific _id, this should always just return 1 unless and
            // error occurred, in which case it will return -1
            int numActualDeleted = [self deleteFromCollection: collection withDocId: _id];
            
            if (numActualDeleted > 0) {
                numMarkedDeleted += numActualDeleted;
            }
        }
    }
    
    return numMarkedDeleted;
}

-(NSArray*) findWithQueryParts: (NSArray*) queryParts
                  inCollection:(NSString*) collection
                   withOptions:(JSONStoreQueryOptions*) options
{
    if (options == nil) {
        options = [[JSONStoreQueryOptions alloc] init];
    }
    
    //Filter:
    NSString* selectStatement ;
    
    if (options._count) {
        selectStatement = @"count(*)";
    } else {
        selectStatement = [self _selectStatement:options._filter];
    }
    
    
    //Limit and Offset:
    NSString* limitAndOffsetClause = [self _limitAndOffsetClauseWithLimit:options.limit
                                                                andOffset:options.offset];
    
    NSString* orderByClause;
    
    if (limitAndOffsetClause == nil) {
        
        //Negative limit edge case
        orderByClause = @"ORDER BY _id DESC ";
        
        if (ceil(abs([options.offset intValue])) > 0) {
            
            limitAndOffsetClause = [self _buildLimitAndOffsetClauseWithLimit:options.limit andOffset:options.offset];
            
        } else {
            
            limitAndOffsetClause = [self _buildLimitClauseWithLimit:options.limit];
        }
        
        
    } else {
        
        orderByClause = [self _orderByClause:options._sort];
    }
    
    NSMutableString* whereClauseStr = [[NSMutableString alloc] init];
    
    //Only add the where if a query was passed
    if ([queryParts count]) {
        [whereClauseStr appendFormat:@"where "];
    } else {
        [whereClauseStr appendString:[NSString stringWithFormat:@"where %@", [JSON_STORE_FIELD_DELETED stringByAppendingString:@" = 0"]]];
    }
    
    NSMutableArray* allQueryParts = [[NSMutableArray alloc] init];
    
    for (JSONStoreQueryPart* queryPart in queryParts) {
        
        NSMutableArray* singleQueryPart = [[NSMutableArray alloc] init];
        
        //LessThan
        NSString* lessThanStr = [self _whereClauseDictWithSymbol:@"<" andArray:queryPart._lessThan];
        if ([lessThanStr length]) {
            [singleQueryPart addObject:lessThanStr];
        }
        
        //lessOrEqualThan
        NSString* lessOrEqualThanStr = [self _whereClauseDictWithSymbol:@"<=" andArray:queryPart._lessOrEqualThan];
        if ([lessOrEqualThanStr length]) {
            [singleQueryPart addObject:lessOrEqualThanStr];
        }
        
        //greaterThan
        NSString* greaterThanStr = [self _whereClauseDictWithSymbol:@">" andArray:queryPart._greaterThan];
        if ([greaterThanStr length]) {
            [singleQueryPart addObject:greaterThanStr];
        }
        
        //greaterOrEqualThan
        NSString* greaterOrEqualThanStr = [self _whereClauseDictWithSymbol:@">=" andArray:queryPart._greaterOrEqualThan];
        if ([greaterOrEqualThanStr length]) {
            [singleQueryPart addObject:greaterOrEqualThanStr];
        }
        
        //like
        NSString* likeStr = [self _whereClauseWithStrFormat:@"[%@] LIKE '%%%@%%'" andArray:queryPart._like exact:NO];
        if([likeStr length]) {
            [singleQueryPart addObject:likeStr];
        }
        
        //not like
        NSString* notLikeStr = [self _whereClauseWithStrFormat:@"[%@] NOT LIKE '%%%@%%'" andArray:queryPart._notLike exact:NO];
        if([notLikeStr length]) {
            [singleQueryPart addObject:notLikeStr];
        }
        
        //rightLike
        NSString* rightLikeStr = [self _whereClauseWithStrFormat:@"[%@] LIKE '%@%%\'" andArray:queryPart._rightLike exact:NO];
        if ([rightLikeStr length]) {
            [singleQueryPart addObject:rightLikeStr];
        }
        
        //not rightLike
        NSString* notRightLikeStr = [self _whereClauseWithStrFormat:@"[%@] NOT LIKE '%@%%\'" andArray:queryPart._notRightLike exact:NO];
        if ([notRightLikeStr length]) {
            [singleQueryPart addObject:notRightLikeStr];
        }
        
        //leftLike
        NSString* leftLikeStr = [self _whereClauseWithStrFormat:@"[%@] LIKE '%%%@'" andArray:queryPart._leftLike exact:NO];
        if ([leftLikeStr length]) {
            [singleQueryPart addObject:leftLikeStr];
        }
        
        //notLeftLike
        NSString* notLeftLikeStr = [self _whereClauseWithStrFormat:@"[%@] NOT LIKE '%%%@'" andArray:queryPart._notLeftLike exact:NO];
        if ([notLeftLikeStr length]) {
            [singleQueryPart addObject:notLeftLikeStr];
        }
        
        //equal
        NSString* equalStr = [self _whereClauseWithStrFormat:@"( [%@] = '%@' OR [%@] LIKE '%%-@-%@-@-%%' OR [%@] LIKE '%%-@-%@' OR [%@] LIKE '%@-@-%%' )" andArray:queryPart._equal exact:YES];
        if ([equalStr length]) {
            [singleQueryPart addObject:equalStr];
        }
        
        //notEqual
        NSString* notEqualStr = [self _whereClauseWithStrFormat:@"( [%@] != '%@' AND [%@] NOT LIKE '%%-@-%@-@-%%' AND [%@] NOT LIKE '%%-@-%@' AND [%@] NOT LIKE '%@-@-%%' )" andArray:queryPart._notEqual exact:YES];
        if ([notEqualStr length]) {
            [singleQueryPart addObject:notEqualStr];
        }
        
        //in
        NSString* inStr = [self _whereClauseInWithArray:queryPart._inside not:NO];
        if ([inStr length]) {
            [singleQueryPart addObject:inStr];
        }
        
        //not in
        NSString* notInStr = [self _whereClauseInWithArray:queryPart._notInside not:YES];
        if ([notInStr length]) {
            [singleQueryPart addObject:notInStr];
        }
        
        //between
        NSString* betweenStr = [self _whereClauseBetweenWithArray:queryPart._between not:NO];
        if ([betweenStr length]) {
            [singleQueryPart addObject:betweenStr];
        }
        
        //not between
        NSString* notBetweenStr = [self _whereClauseBetweenWithArray:queryPart._notBetween not:YES];
        if ([notBetweenStr length]) {
            [singleQueryPart addObject:notBetweenStr];
        }
        
        //ids
        NSString* idsStr = [self _whereClauseForMultipleIds:queryPart._ids];
        if ([idsStr length]) {
            [singleQueryPart addObject:idsStr];
        }
        
        [singleQueryPart addObject:[JSON_STORE_FIELD_DELETED stringByAppendingString:@" = 0"]];
        
        [allQueryParts addObject:[singleQueryPart componentsJoinedByString:@" AND "]];
    }
    
    if ([allQueryParts count]) {
        [whereClauseStr appendFormat:@"%@", [allQueryParts componentsJoinedByString:@" OR "]];
    }
    
    NSString* findQuery = [NSString stringWithFormat:@"select %@ from '%@' %@ %@ %@",
                           selectStatement, collection, whereClauseStr, orderByClause, limitAndOffsetClause];
    
    NSMutableArray* results = [[NSMutableArray alloc] init];
    
    BOOL validSelect = [self.dbMgr selectAllInto:results withSQL:findQuery];
    
    if (! validSelect) {
        return nil;
    }
    
    if (options._count) {
        results = (NSMutableArray*) @[ results[0][@"count(*)"] ];
    }
    
    return results;
}


-(int) store:(id) jsonObj
inCollection:(NSString*) collection
  withIdexes:(NSDictionary*) idx
       isAdd:(BOOL) isAdd
{
    int rc = 0;
    NSData* jsonData = [jsonObj WLJSONData];;
    NSString* fieldsStr = nil;
    
    //Note, these are associative arrays, they need to stay in sync, we don't use a hash because order matters
    //and there are nice tricks we can do with arrays to build our statements
    NSMutableArray* fieldNames = [NSMutableArray new];
    NSMutableArray* fieldValues = [NSMutableArray new];
    
    [idx enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        [fieldNames addObject:[NSString stringWithFormat:@"'%@'" ,key]];
        
        if ([obj isKindOfClass:[NSSet class]]) {
            [fieldValues addObject: [[(NSSet*) obj allObjects] componentsJoinedByString:@"-@-"]];
        }
    }];
    
    [fieldNames addObject:JSON_STORE_FIELD_JSON];
    [fieldValues addObject:jsonData];
    
    //Store operations should not set the dirty flag, add operations should
    if (isAdd) {
        [fieldNames addObject:JSON_STORE_FIELD_DIRTY];
        NSDate *now = [NSDate new];
        [fieldValues addObject:now];
        [fieldNames addObject:JSON_STORE_FIELD_OPERATION];
        [fieldValues addObject:JSON_STORE_OP_ADD];
        
    } else {
        [fieldNames addObject:JSON_STORE_FIELD_OPERATION];
        [fieldValues addObject:JSON_STORE_OP_STORE];
    }
    
    fieldsStr = [fieldNames componentsJoinedByString:@","];
    
    NSString* valuesStr = [self _buildValueStr:[fieldValues count]];
    
    NSString* insertStmt = [NSString stringWithFormat:@"insert into '%@' (%@) values (%@)",
                            collection, fieldsStr, valuesStr];
    
    BOOL worked = [self.dbMgr insertStmt:insertStmt, fieldValues];
    
    if (! worked) {
        NSLog(@"Store operation failed, collection: %@", collection);
        rc =-1;
    } else {
        rc = 0;
    }
    
    return rc;
}

-(int) dirtyCount:(NSString*) collection
{
    int count = 0;
    
    NSString* whereClause = [self _whereClauseForDirty];
    
    NSString* selectStmt =[NSString stringWithFormat:@"select count(*) from '%@' where %@",
                           collection, whereClause];
    
    NSMutableDictionary* results = [NSMutableDictionary new];
    
    [self.dbMgr selectInto:results withSQL:selectStmt];
    
    count = [[results objectForKey:@"count(*)"] intValue];
    
    return count;
}

-(int) count:(NSString*) collection
{
    int count = 0;
    
    NSString* selectStmt =[NSString stringWithFormat:@"select count(*) from '%@' where _deleted = 0", collection];
    
    NSMutableDictionary* results = [[NSMutableDictionary alloc] init];
    
    [self.dbMgr selectInto:results withSQL:selectStmt];
    
    count = [[results objectForKey:@"count(*)"] intValue];
    
    return count;
}

-(BOOL) isDirty:(int) docId
   inCollection:(NSString*) document
{
    NSString* whereClause = [self _whereClauseForId:docId];
    NSString* dirtyWhereClause = [self _whereClauseForDirty];
    
    NSString* dirtyQuery = [NSString stringWithFormat:@"select %@ from '%@' where %@ and %@",
                            JSON_STORE_FIELD_DIRTY, document, dirtyWhereClause, whereClause];
    
    NSMutableDictionary* resultDict = [[NSMutableDictionary alloc] init];
    
    [self.dbMgr selectInto:resultDict withSQL:dirtyQuery];
    
    if ([resultDict count] <= 0 ) {
        return NO;
    } else {
        return [[resultDict objectForKey:JSON_STORE_FIELD_DIRTY] boolValue];
    }
}

-(NSArray*) allDirtyInCollection:(NSString*) collection
{
    
    NSString* whereClause = [self _whereClauseForDirty];
    NSString* orderByClause = [self _orderByDirty];
    
    NSString* selectStmt = [NSString stringWithFormat: @"select %@, %@, %@, %@ from '%@' where %@ %@",
                            JSON_STORE_FIELD_ID,
                            JSON_STORE_FIELD_JSON,
                            JSON_STORE_FIELD_OPERATION,
                            JSON_STORE_FIELD_DIRTY,
                            collection,
                            whereClause,
                            orderByClause];
    
    NSMutableArray* retArr = [NSMutableArray new];
    
    BOOL worked = [self.dbMgr selectAllInto:retArr withSQL:selectStmt];
    
    if (! worked) {
        NSLog(@"All dirty operation failed, collection: %@", collection);
    }
    
    return retArr;
}

-(BOOL) markClean: (int) docId
     inCollection: (NSString*) collection
     forOperation: (NSString*) operation
{
    if ([operation isEqualToString:JSON_STORE_OP_DELETE]) {
        
        return [self deleteFromCollection:collection withDocId:docId] > 0;
        
    } else {
        
        NSDictionary* setClauseDict = @{ JSON_STORE_FIELD_DIRTY : @0,
                                         JSON_STORE_FIELD_DELETED: @0,
                                         JSON_STORE_FIELD_OPERATION: @"" };
        
        NSString* setClauseStr =[self _queryFromDict:setClauseDict delimiter:@", "];
        NSString* whereClauseStr = [self _whereClauseForId:docId];
        
        NSString* updateStmt = [NSString stringWithFormat:@"update '%@' set %@ where %@",
                                collection, setClauseStr, whereClauseStr];
        
        BOOL worked = [self.dbMgr update:updateStmt, [setClauseDict allValues]] > 0;
        
        if (! worked) {
            NSLog(@"markClean operation failed, collection: %@, docId: %d, operation: %@", collection, docId, operation);
        }
        
        return worked;
    }
}

-(BOOL) setDatabaseKey:(NSString*)encKey
{
    BOOL worked = NO;

    if (encKey != nil && [encKey length] > 0) {

        if (!self.dbHasBeenKeyed) {

            if (self.dbMgr == nil) {
                id sqlite = [NSClassFromString(@"SQLCipherDatabase")alloc];
                self.dbMgr = [sqlite performSelector:NSSelectorFromString(@"initWithUserName:") withObject:self.username];
            }

            NSString* pragmaKey = [NSString stringWithFormat:@"PRAGMA key = \"x'%@'\";", encKey];
            worked = [self.dbMgr execute:pragmaKey];

            if (worked) {

                BOOL queryWorked = [self _checkSetKeyWorked];

                if (queryWorked) {
                    self.dbHasBeenKeyed = YES;
                }
            }
        } else {

            //User gave us a good PW, but we've already keyed, so return true and no-op
            worked = YES;
        }
    }
    return  worked;
}

-(BOOL) isOpen
{
    return self.dbMgr != nil;
}

-(BOOL) close
{
    BOOL closed = [self.dbMgr closeDB];
    self.dbMgr = nil;
    self.dbHasBeenKeyed = NO;
    return closed;
}

-(BOOL) isStoreEncrypted
{
    NSData* searchData = [@"sqlite" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString* path = [self.dbMgr getDbFilePath];
    
    NSData* fileData = [NSData dataWithContentsOfFile:path];
    
    NSRange locatedRange = [fileData rangeOfData:searchData
                                         options:NSDataSearchBackwards
                                           range:NSMakeRange(0, [fileData length])];
    
    if (locatedRange.location == NSNotFound) {
        
        return YES;
        
    } else {
        
        return NO;
    }
}

#pragma mark Helpers

-(BOOL) _checkSetKeyWorked
{
    NSMutableDictionary* checkDict = [NSMutableDictionary new];
    BOOL worked = [self.dbMgr selectInto:checkDict withSQL:@"select count(*) from sqlite_master;"];
    return worked;
}

+(NSDictionary*) _getJsonToSqlSchemaDict{
    //SQLLite types taken from here: http://www.sqlite.org/datatype3.html
    //JSON types taken from here: http://tools.ietf.org/html/draft-zyp-json-schema-03#section-5.1
    //Note: No object or array b/c we say you can't index those.
    
    return @{ @"string" : @"TEXT",
              @"number" : @"REAL",
              @"integer" : @"INTEGER",
              @"boolean" : @"INTEGER"};
}


- (NSString *)_schemaFromDict:(NSDictionary *)schema
{
    
    NSDictionary* mapper = [JSONStoreSQLLite _getJsonToSqlSchemaDict];
    
    NSMutableString* retVal = [NSMutableString stringWithString:@""];
    [schema enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        [retVal appendFormat:@" '%@' %@,", key, [mapper objectForKey:obj]];
    }];
    
    return retVal;
}

-(NSString*)_queryFromDict:(NSDictionary *)query
                 delimiter:(NSString *)delimiter
                     exact:(BOOL)exact
{
    __strong NSMutableArray *retArray = [NSMutableArray new];
    
    [query enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        if (! exact) {
            
            [retArray addObject:[NSString stringWithFormat:@"[%@] LIKE \"%%%@%%\"", key, obj]];
            
        } else {
            /*
             (
             [customers.fn] =  "carlos"
             or [customers.fn] like "%-@-carlos-@-%"
             or [customers.fn] like "%-@-carlos"
             or [customers.fn] like "carlos-@-%"
             )
             */
            NSString* exactMatch = @"( [%@] = \"%@\"  or [%@] LIKE \"%%-@-%@-@-%%\" or [%@] LIKE \"%%-@-%@\" or [%@] LIKE \"%@-@-%%\" )";
            [retArray addObject:[NSString stringWithFormat:exactMatch, key, obj, key, obj, key, obj, key, obj]];
        }
    }];
    
    NSString *retVal = [retArray componentsJoinedByString:[NSString stringWithFormat:@" %@ ", delimiter]];
    
    return retVal;
}

-(NSString*) _selectStatement:(NSArray*) filter
{
    if (filter == nil || [filter count] == 0) {
        
        //Default select columns
        return @"[_id], [json]";
        
    }
    
    NSString* last = [filter lastObject];
    
    NSMutableString* mutableSelectStmt = [[NSMutableString alloc] init];
    
    for (NSString* str in filter) {
        [mutableSelectStmt appendString:[NSString stringWithFormat:@"[%@]", str]];
        if (str != last) {
            [mutableSelectStmt appendString:@", "];
        }
    }
    
    return [NSString stringWithString:mutableSelectStmt];
}

-(NSString*)_orderByClause:(NSArray*)sort
{
    if (! [sort count]) {
        return @"";
    }
    
    NSMutableString* sortStr = [NSMutableString new];
    
    [sortStr appendString:@"ORDER BY "];
    
    for (NSDictionary* curr in sort) {
        
        NSString* key = [curr allKeys][0];
        NSString* value = curr[key];
        
        [sortStr appendString:[NSString stringWithFormat:@"[%@] %@", key, value]];
        
        if (curr != [sort lastObject]) {
            [sortStr appendString:@", "];
        }
    }
    
    return sortStr;
}

-(NSString*)_whereClauseNotDeleted:(NSDictionary *)query
                         delimiter:(NSString *)delimiter
                             exact: (BOOL) exact
{
    NSString*queryStr = [self _queryFromDict:query delimiter:delimiter exact:exact];
    NSString* retQuery = nil;
    
    NSString* deletedClause = [JSON_STORE_FIELD_DELETED stringByAppendingString:@" = 0"];
    
    if (queryStr != nil && [queryStr length] > 0 ) {
        
        retQuery = [NSString stringWithFormat:@"%@ and %@", queryStr, deletedClause];
        
    } else {
        
        retQuery = [NSString stringWithFormat:@"%@", deletedClause];
    }
    
    return retQuery;
}

-(BOOL) _validateExistingSchemaAgainst:(NSString *) indexedColumns
                               inTable:(NSString *) db
                            withPrefix:(NSString *) createPref
                             andSuffix:(NSString *) createSuf
{
    BOOL schemasMatch;
    
    // Get the create statement used to create the existing table using a special select statement
    NSString* schemaSelect =
    [NSString stringWithFormat:@"SELECT sql FROM sqlite_master WHERE type='table' AND name = '%@'", db];
    
    NSMutableDictionary* resultsDict = [NSMutableDictionary new];
    
    [self.dbMgr selectInto:resultsDict withSQL:schemaSelect];
    
    NSString* tableSchemaCreate = [resultsDict objectForKey:@"sql"];
    
    //Fix for APAR 50404: I seems older versions of JSONStore store the collection name without quotes.
    //Some string replacements are required to account for sqlite returning the
    //collection name without quotes. Otherwise, NSRage gets -1 (not found) and an
    //exception is thrown for index out of bounds / rage out of bounds.
    NSString* firstPartNoQuotes = [NSString stringWithFormat:@"CREATE TABLE %@", db];
    NSString* firstPartWithQuotes = [NSString stringWithFormat:@"CREATE TABLE '%@'", db];
    if ([tableSchemaCreate rangeOfString:firstPartWithQuotes].location == NSNotFound) {
        NSRange firstPartLocation = [tableSchemaCreate rangeOfString:firstPartNoQuotes];
        tableSchemaCreate  = [tableSchemaCreate stringByReplacingCharactersInRange:firstPartLocation withString:firstPartWithQuotes];
    }
    
    // Remove the table create Prefix and Suffix from the create statement we tried to use to create a new table
    // (and which was rejected because the table already exists).  We want just the part of the statement that specifies
    // the column names and types (e.g. "lastname" TEXT, "firstname" TEXT)
    NSRange prefixRange = [tableSchemaCreate rangeOfString:createPref options:NSCaseInsensitiveSearch];
    NSString* middlePart = [tableSchemaCreate substringFromIndex:NSMaxRange(prefixRange)];
    NSRange suffixRange = [middlePart rangeOfString:createSuf options:NSCaseInsensitiveSearch];
    NSString* tableDefPart = [middlePart substringToIndex:suffixRange.location];
    
    // The column names are separated by "," so break them into arrays where each element is a column name and type
    // Since column names are treated as case insensitive, normalize the string (to uppercase) first
    NSArray* currentTableSchema = [[tableDefPart uppercaseString] componentsSeparatedByString:@","];
    NSArray* requestedTableSchema = [[indexedColumns uppercaseString] componentsSeparatedByString:@","];
    
    //Using sets because when comparing arrays there are cases where the order matters.
    //NSCountedSet is used instead of NSSet because it handles the case
    //when duplicates are found (i.e. imagine [1,2] and [1,1,2] NSCountedSet says they are not equal
    //(expected behavior), NSSet says they are equal)
    NSCountedSet* currentSet = [NSCountedSet setWithArray:currentTableSchema];
    NSCountedSet* requestedSet = [NSCountedSet setWithArray:requestedTableSchema];
    
    // Compare the current table's column names and types to what was requested.  If they have the same
    // column names and types, then the schema is the same.
    if ([currentSet isEqualToSet:requestedSet]) {
        
        schemasMatch = YES;
        
    } else {
        
        schemasMatch = NO;
    }
    
    return schemasMatch;
}

-(NSString*) _whereClauseForId:(int) docId
{
    return [NSString stringWithFormat:@"%@ = %d", JSON_STORE_FIELD_ID, docId];
}

-(NSString*) _whereClauseForMultipleIds:(NSArray*) docId
{
    NSString* whereClauseStr = nil;
    
    if([docId count] > 0) {
        NSMutableArray* returnArray = [NSMutableArray new];
        
        for (NSNumber* i in docId) {
            [returnArray addObject:[NSString stringWithFormat:@"%@ = %@",JSON_STORE_FIELD_ID, i]];
        }
        
        whereClauseStr = [NSString stringWithFormat:@"( %@ )",
                          [returnArray componentsJoinedByString:@" OR "]];
    }
    
    return whereClauseStr;
}

-(NSString*) _whereClauseForDirty
{
    return [NSString stringWithFormat:@"%@ > 0",JSON_STORE_FIELD_DIRTY];
}

-(NSString*) _orderByDirty
{
    return [NSString stringWithFormat:@"order by %@", JSON_STORE_FIELD_DIRTY];
}

-(BOOL) _isRemoved:(int) docId
      inCollection:(NSString*) document
{
    NSString* whereClause = [self _whereClauseForId:docId];
    
    NSString* removedQuery =[NSString stringWithFormat:@"select %@ from '%@' where %@",
                             JSON_STORE_FIELD_DELETED, document, whereClause];
    
    NSMutableDictionary* resultDict = [NSMutableDictionary new];
    
    [self.dbMgr selectInto:resultDict withSQL:removedQuery];
    
    // If no document found, it is deleted or was never there
    
    BOOL isRemoved;
    
    if ([resultDict count] <= 0) {
        
        isRemoved = YES;
        
    } else {
        
        isRemoved = ([[resultDict objectForKey: JSON_STORE_FIELD_DELETED] floatValue]!= 0);
    }
    
    return isRemoved;
}

-(BOOL) _isAdded:(int) docId
    inCollection:(NSString*) document
{
    NSString* whereClause = [self _whereClauseForId:docId];
    
    NSString* addedQuery = [NSString stringWithFormat:@"select %@ from '%@' where %@",
                            JSON_STORE_FIELD_OPERATION, document, whereClause];
    
    NSMutableDictionary* resultDict = [NSMutableDictionary new];
    
    [self.dbMgr selectInto:resultDict withSQL:addedQuery];
    
    BOOL isAdded;
    
    if ([resultDict count ] <= 0) {
        
        isAdded = NO;
        
    } else {
        
        NSString* operation = [resultDict objectForKey: JSON_STORE_FIELD_OPERATION];
        isAdded = [operation isEqualToString:JSON_STORE_OP_ADD];
    }
    
    return isAdded;
}

-(NSString*)_queryFromDict:(NSDictionary *)query
                 delimiter:(NSString*)delimiter
{
    __strong NSMutableArray *retArray = [NSMutableArray new];
    
    [query enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [retArray addObject:[NSString stringWithFormat:@"[%@] = ?", key]];
    }];
    
    NSString *retVal = [retArray componentsJoinedByString:[NSString stringWithFormat:@"%@", delimiter]];
    return retVal;
}

-(NSString*) _buildValueStr:(NSUInteger) size
{
    NSMutableString* s = [NSMutableString new];
    
    for (int i = 0; i < ((int)size); i++) {
        
        [s appendString:@"?"];
        
        if (i < (((int)size) - 1)) {
            [s appendString:@", "];
        }
    }
    
    return s;
}

-(NSString*) _limitAndOffsetClauseWithLimit:(NSNumber*) limit
                                  andOffset:(NSNumber*) offset
{
    NSString* limitOffsetStr;
    
    if (limit == nil) {
        
        //No limit specified
        limitOffsetStr = @"";
        
    } else {
        
        //Limit with no offset
        if ([limit intValue] < 0 ) {
            
            //Negative limit case, get the 'last' limit records:
            //select .... order by _id desc limit <limit opt>
            return nil;
            
            
        } else if (offset == nil)  {
            
            //Normal positive limit case, select .... LIMIT <limit opt>
            limitOffsetStr = [self _buildLimitClauseWithLimit:limit];
            
        } else {
            
            //Limit and offset
            limitOffsetStr = [self _buildLimitAndOffsetClauseWithLimit:limit andOffset:offset];
        }
    }
    
    return limitOffsetStr;
}

-(NSString*) _buildLimitAndOffsetClauseWithLimit:(NSNumber*) limit
                                       andOffset:(NSNumber*) offset
{
    return [NSString stringWithFormat:@"LIMIT %f OFFSET %f",
            ceil(abs([limit intValue])), ceil(abs([offset intValue]))];
}

-(NSString*) _buildLimitClauseWithLimit:(NSNumber*) limit
{
    return [NSString stringWithFormat:@"LIMIT %f", ceil(abs([limit intValue]))];
}

-(NSString*) _whereClauseDictWithSymbol:(NSString*) symbol
                               andArray:(NSArray*) array
{
    NSMutableArray* resultsArr = [[NSMutableArray alloc] init];
    
    for (NSDictionary* dict in array) {
        
        for (NSString *searchField in dict) {
            
            [resultsArr addObject:[NSString stringWithFormat:@"[%@] %@ %@", searchField, symbol, dict[searchField]]];
        }
    }
    
    NSString* str = [resultsArr componentsJoinedByString:@" AND "];
    
    return str;
}

-(NSString*) _whereClauseBetweenWithArray:(NSArray*) array
                                      not:(BOOL) not
{
    NSMutableArray* resultsArr = [[NSMutableArray alloc] init];
    
    for (NSDictionary* dict in array) {
        
        for (NSString *searchField in dict) {
            
            NSArray* betweenValuesArr = dict[searchField];
            
            if ([betweenValuesArr count] == 2) {
                NSString* notStr = not ? @"NOT" : @"";
                
                [resultsArr addObject:[NSString stringWithFormat:@"[%@] %@ BETWEEN %@ AND %@", searchField, notStr, betweenValuesArr[0], betweenValuesArr[1]]];
            }
        }
    }
    
    NSString* str = [resultsArr componentsJoinedByString:@" AND "];
    
    return str;
}

-(NSString*) _whereClauseInWithArray:(NSArray*) array
                                 not:(BOOL) not
{
    NSMutableArray* resultsArr = [[NSMutableArray alloc] init];
    
    for (NSDictionary* dict in array) {
        
        for (NSString *searchField in dict) {
            
            NSMutableArray* valuesMutableArr = [[NSMutableArray alloc] init];
            
            for (NSString* val in dict[searchField]) {
                [valuesMutableArr addObject:[NSString stringWithFormat:@"'%@'", val]];
            }
            
            NSString* values = [valuesMutableArr componentsJoinedByString:@","];
            
            NSString* notStr = not ? @"NOT" : @"";
            [resultsArr addObject:[NSString stringWithFormat:@"[%@] %@ in (%@)", searchField, notStr, values]];
        }
    }
    
    NSString* str = [resultsArr componentsJoinedByString:@" AND "];
    
    return str;
}

-(NSString*) _whereClauseWithStrFormat:(NSString*) strFmt
                              andArray:(NSArray*) array
                                 exact:(BOOL) exact
{
    NSMutableArray* resultsArr = [[NSMutableArray alloc] init];
    
    for (NSDictionary* dict in array) {
        
        for (NSString *searchField in dict) {
            
            NSString* value = [JSONStoreValidator getDatabaseSafeSearchField:dict[searchField]];
            
            if (!exact) {
                
                [resultsArr addObject:
                 [NSString stringWithFormat:strFmt, searchField, value]];
            } else {
                
                [resultsArr addObject:
                 [NSString stringWithFormat:strFmt, searchField, value, searchField, value, searchField, value, searchField, value]];
                
            }
            
        }
    }
    
    NSString* str = [resultsArr componentsJoinedByString:@" AND "];
    
    return str;
}

#pragma mark Internal DB

- (BOOL) startTransaction
{
    return  [self.dbMgr startTransaction];
}

- (BOOL) commitTransaction
{
    return  [self.dbMgr commitTransaction];
}

- (BOOL) rollbackTransaction
{
    return [self.dbMgr rollbackTransaction];
}

@end
