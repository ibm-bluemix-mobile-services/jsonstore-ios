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

#import "JSONStoreConstants.h"
#import "SQLiteDatabase.h"

@implementation SQLiteDatabase : NSObject

-(id) initWithUserName: (NSString*) username
{
    if (self = [super init]) {
        
        self.username = username;
        _db = [self _openOrCreate];
        
        _databaseQueue = dispatch_queue_create("com.jsonstore.database", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

-(BOOL) executeSchemaCreation:(NSString*) createTableStatement
{
    return [self execute: createTableStatement];
}

-(BOOL) closeDB
{
    if (_db == nil) {
        return YES;
    }
    
    if (SQLITE_OK != sqlite3_close(_db)) {
        
        NSLog(@"Close failed, message: [%s]", sqlite3_errmsg(_db));
        
        return NO;
    }
    
    _db =  nil;
    return YES;
}

-(BOOL) startTransaction
{
    __block BOOL mRC = NO;
    
    dispatch_sync(_databaseQueue, ^{
        
        int rc =  sqlite3_exec(_db, [@"BEGIN TRANSACTION" UTF8String] , NULL, NULL, NULL);
        
        if (rc == SQLITE_OK) {
            
            mRC = YES;
            
        } else {
            
            NSLog(@"Unable to BEGIN transaction for JSONStore, rc: %d", rc);
            mRC = NO;
        }
    });
    
    return mRC;
}

-(BOOL) commitTransaction
{
    __block BOOL mRC = NO;
    
    dispatch_sync(_databaseQueue, ^{
        
        int rc =  sqlite3_exec(_db, [@"COMMIT TRANSACTION" UTF8String] , NULL, NULL, NULL);
        
        if (rc == SQLITE_OK) {
            
            mRC = YES;
            
        } else {
            
            NSLog(@"Unable to COMMIT transaction for JSONStore, rc: %d", rc);
            mRC = NO;
        }
    });
    
    return mRC;
}

-(BOOL) rollbackTransaction
{
    __block BOOL mRC = NO;
    
    dispatch_sync(_databaseQueue, ^{
        
        int rc =  sqlite3_exec(_db, [@"ROLLBACK TRANSACTION" UTF8String] , NULL, NULL, NULL);
        
        if (rc == SQLITE_OK) {
            
            mRC = YES;
            
        } else {
            
            NSLog(@"Unable to ROLLBACK transaction for JSONStore, rc: %d", rc);
            mRC = NO;
        }
    });
    
    return mRC;
}

-(BOOL) execute: (NSString*) sql, ...
{
    __block struct {
        va_list args;
    } argsStruct;
    
    va_start(argsStruct.args, sql);
    BOOL mRC = NO;
    BOOL *pRC = &mRC;
    
    dispatch_sync(_databaseQueue, ^{
        
        sqlite3_stmt *stmt = [self _createStatement:sql];
        
        if (nil == stmt) {
            return;
        }
        
        int rc = SQLITE_ERROR;
        
        if ([self _bindStatement: stmt Parameters: argsStruct.args]) {
            rc = sqlite3_step(stmt);
        }
        
        sqlite3_finalize(stmt);
        
        if (SQLITE_DONE == rc) {
            *pRC = YES;
        }
    });
    
    va_end(argsStruct.args);
    return mRC;
}

-(int) update: (NSString *)sql, ...
{
    __block struct {
        va_list args;
    } argsStruct;
    
    va_start(argsStruct.args, sql);
    BOOL mRC = NO;
    BOOL *pRC = &mRC;
    __block int rowsUpdated = 0;
    
    dispatch_sync(_databaseQueue, ^{
        
        sqlite3_stmt *stmt = [self _createStatement:sql];
        
        if (nil == stmt) {
            
            return;
        }
        
        if ([self _bindStatement: stmt Parameters: argsStruct.args]) {
            
            int sqliteRc = sqlite3_step(stmt);
            
            if (SQLITE_DONE == sqliteRc) {
                
                *pRC = YES;
                rowsUpdated = sqlite3_changes(_db);
                
            } else {
                
                rowsUpdated = -1;
            }
            
        } else {
            
            rowsUpdated = -1;
        }
        
        sqlite3_finalize(stmt);
    });
    
    va_end(argsStruct.args);
    
    return rowsUpdated;
}

-(int) deleteFromDatabase: (NSString *)sql, ...
{
    __block struct {
        va_list args;
    } argsStruct;
    
    va_start(argsStruct.args, sql);
    BOOL mRC = NO;
    BOOL *pRC = &mRC;
    __block int rowsDeleted = 0;
    
    dispatch_sync(_databaseQueue, ^{
        
        sqlite3_stmt *stmt = [self _createStatement:sql];
        
        if (nil == stmt) {
            return;
        }
        
        if ([self _bindStatement: stmt Parameters: argsStruct.args]) {
            
            int sqliteRc = sqlite3_step(stmt);
            
            if (SQLITE_DONE == sqliteRc) {
                *pRC = YES;
            }
            
            rowsDeleted = sqlite3_changes(_db);
            
        } else {
            rowsDeleted = -1;
        }
        
        sqlite3_finalize(stmt);
    });
    
    va_end(argsStruct.args);
    
    return rowsDeleted;
}

-(BOOL) selectInto: (NSMutableDictionary *)resultMap
           withSQL:(NSString *)sql, ...
{
    __block struct {
        va_list args;
    } argsStruct;
    
    va_start(argsStruct.args, sql);
    
    BOOL mRC = NO;
    BOOL *pRC = &mRC;
    
    dispatch_sync(_databaseQueue, ^{
        
        sqlite3_stmt *stmt = [self _createStatement:sql];
        
        if(nil == stmt) {
            return;
        }
        
        if ([self _bindStatement: stmt Parameters: argsStruct.args]) {
            
            int sqliteRc = sqlite3_step(stmt);
            
            if (SQLITE_ROW == sqliteRc) {
                if([self _copyResult: stmt IntoDictionaty: resultMap]) {
                    *pRC = YES;
                    
                }
            }
            else if(SQLITE_OK == sqliteRc) {
                *pRC = YES;
            }
            
        }
        
        sqlite3_finalize(stmt);
    });
    
    va_end(argsStruct.args);
    return mRC;
}

-(BOOL) selectAllInto:(NSMutableArray *)resultArray
              withSQL:(NSString *)sql, ...
{
    __block struct {
        va_list args;
    } argsStruct;
    
    va_start(argsStruct.args, sql);
    BOOL mRC = NO;
    BOOL *pRC = &mRC;
    
    dispatch_sync(_databaseQueue, ^{
        
        sqlite3_stmt *stmt = [self _createStatement:sql];
        
        if(nil == stmt) {
            return;
        }
        
        if ([self _bindStatement: stmt Parameters: argsStruct.args]) {
            
            int sqliteRc = sqlite3_step(stmt);
            
            while(SQLITE_ROW == sqliteRc) {
                
                NSMutableDictionary *map = [NSMutableDictionary dictionary];
                
                if([self _copyResult: stmt IntoDictionaty: map]) {
                    [resultArray addObject: map];
                }
                else {
                    break;
                }
                
                sqliteRc = sqlite3_step(stmt);
            }
            
            if(SQLITE_DONE == sqliteRc) {
                *pRC = YES;
            }
        }
        
        sqlite3_finalize(stmt);
    });
    
    va_end(argsStruct.args);
    
    return mRC;
}

-(BOOL) insertStmt: (NSString *)sql, ...
{
    __block struct {
        va_list args;
    } argsStruct;
    
    va_start(argsStruct.args, sql);
    BOOL mRC = NO;
    BOOL *pRC = &mRC;
    
    dispatch_sync(_databaseQueue, ^{
        
        sqlite3_stmt *stmt = [self _createStatement:sql];
        
        if(nil == stmt) {
            return;
        }
        
        if ([self _bindStatement: stmt Parameters: argsStruct.args]) {
            
            int sqliteRc = sqlite3_step(stmt );
            
            if(SQLITE_DONE == sqliteRc) {
                *pRC = YES;
            }
        }
        
        sqlite3_finalize(stmt);
    });
    
    va_end(argsStruct.args);
    
    return mRC;
}

-(NSString*) lastErrorMsg
{
    return [NSString stringWithUTF8String:sqlite3_errmsg(_db)];
}

-(NSString*) getDbFilePath
{
    if (! self.dbfilePath) {
        NSError* error = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSArray* urls = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL* u = [urls objectAtIndex:0];
        
        u = [u URLByAppendingPathComponent:JSON_STORE_DEFAULT_FOLDER_FOR_SQLITE_FILES];
        
        if (![fileManager fileExistsAtPath:[u path]]) {
            
            if (![fileManager createDirectoryAtPath:[u path]
                        withIntermediateDirectories:NO
                                         attributes:nil
                                              error:&error]) {
                
                NSLog(@"Unable to create directory error: %@", error);
            }
        }
        
        u = [u URLByAppendingPathComponent:[self _getDbFileName]];
        
        self.dbfilePath = [u path];
    }
    
    return self.dbfilePath;
}

-(NSString*) getJsonStoreDirectoryPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray* urls = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL* u = [urls objectAtIndex:0];
    
    u = [u URLByAppendingPathComponent:JSON_STORE_DEFAULT_FOLDER_FOR_SQLITE_FILES];
    NSString *dbPath = [u path];
    
    return dbPath;
}

#pragma mark Helpers

-(NSString*) _getDbFileName
{
    //Return the datbase file name from the username (e.g. jsonstore) and default extension (.sqlite)
    return [self.username stringByAppendingString:JSON_STORE_DB_FILE_EXTENSION];
}

-(sqlite3*) _openOrCreate
{
    sqlite3 *_dbHandle;
    
    if (_db == nil) {
        
        NSString* dbPath = [self getDbFilePath];
        
        if (sqlite3_open([dbPath UTF8String], &_dbHandle) != SQLITE_OK) {
            
            NSLog(@"Failed opening JSONStore database, path: %@", dbPath);
            _dbHandle = nil;
        }
        
        return _dbHandle;
        
    } else {
        
        return _db;
    }
}

-(sqlite3_stmt*) _createStatement: (NSString *)sql
{
    int rc = 0;
    sqlite3_stmt *stmt = nil;
    
    rc = sqlite3_prepare_v2(_db, [sql UTF8String], -1, &stmt, 0);
    
    if (rc != SQLITE_OK || stmt == nil) {
        
        sqlite3_finalize(stmt);
        
        NSLog(@"Create statement failed, message: [%s]", sqlite3_errmsg(_db));
        
        return nil;
    }
    
    return stmt;
}

- (int)_bindParameter:(id) obj
                  idx:(int) i
                 stmt:(sqlite3_stmt*) stmt
{
    int sqliteRc = SQLITE_OK;
    
    if (nil == obj || (NSNull*)obj == [NSNull null]) {
        
        //NULL value
        sqliteRc = sqlite3_bind_null(stmt, i+1);
        
    } else if([obj isKindOfClass:[NSDate class]]) {
        
        //Date value
        sqliteRc = sqlite3_bind_double(stmt, i+1, [obj timeIntervalSince1970]);
        
    } else if([obj isKindOfClass:[NSNumber class]]) {
        
        const char *cType = [obj objCType];
        
        if (strcmp(cType, @encode(BOOL)) == 0) {
            
            //BOOL value
            sqliteRc = sqlite3_bind_int(stmt, i+1, [obj boolValue] ? 1 : 0);
            
        } else if (strcmp(cType, @encode(int)) == 0 ||
                   strcmp(cType, @encode(long)) == 0 ||
                   strcmp(cType, @encode(long long)) == 0) {
            
            //Integer value
            sqlite3_bind_int64(stmt, i+1, [obj longValue]);
        }
        else if(strcmp(cType, @encode(float)) == 0 ||
                strcmp(cType, @encode(double)) == 0) {
            
            //Double or float
            sqlite3_bind_double(stmt, i+1, [obj doubleValue]);
        }
        
    } else if ([obj isKindOfClass:[NSData class]]) {
        
        sqlite3_bind_blob(stmt, i+1, [obj bytes], (int)[obj length], NULL);
        
    } else {
        
        // Default to text
        sqliteRc = sqlite3_bind_text(stmt, i+1, [[obj description] UTF8String], -1, SQLITE_STATIC);
    }
    
    return sqliteRc;
}

-(BOOL) _bindStatement: (sqlite3_stmt*) stmt
            Parameters: (va_list) args
{
    int paramCount = sqlite3_bind_parameter_count(stmt);
    int sqliteRc = SQLITE_OK;
    
    for (int i = 0; i < paramCount && sqliteRc == SQLITE_OK; i++) {
        
        id obj = va_arg(args, id);
        
        //Special case where we pass in an array of parameters
        if ([obj isKindOfClass:[NSArray class]]) {
            
            NSArray* theArgs = obj;
            for (NSUInteger j=0; j < [theArgs count]; j++) {
                NSObject* o = [theArgs objectAtIndex:j];
                sqliteRc = [self _bindParameter:o idx:(int)j stmt:stmt];
            }
            break;
            
        } else {
            
            sqliteRc = [self _bindParameter:obj idx:i stmt:stmt];
        }
    }
    
    return (sqliteRc == SQLITE_OK ? YES : NO);
}

-(BOOL) _copyResult:(sqlite3_stmt*) stmt
     IntoDictionaty:(NSMutableDictionary*) map
{
    int colCount = sqlite3_column_count(stmt);
    
    if (colCount <= 0) {
        return NO;
    }
    
    for (int i = 0; i < colCount; i++) {
        
        NSString *colName = [[NSString stringWithUTF8String:sqlite3_column_name(stmt, i)] lowercaseString];
        
        //This should probably be better.  But we basically know that our json column is always a blob, so we force it.
        if ([colName isEqualToString:JSON_STORE_FIELD_JSON]) {
            
            NSData* data = [[NSData alloc] initWithBytes:sqlite3_column_blob(stmt, i)
                                                  length:(NSUInteger) sqlite3_column_bytes(stmt, i)];
            
            if (data) {
                [map setObject:data
                        forKey:colName];
            }
            
        } else if ([colName isEqualToString:JSON_STORE_FIELD_ID]) {
            
            NSNumber* data = [[NSNumber alloc] initWithInt:sqlite3_column_int(stmt,i)];
            
            if (data) {
                [map setObject:data
                        forKey:colName];
            }
            
        } else {
            
            const unsigned char *txt = sqlite3_column_text(stmt, i);
            
            if (txt) {
                [map setObject: [NSString stringWithUTF8String:(char *)txt]
                        forKey: colName];
            }
        }
    }
    
    return YES;
}

@end
