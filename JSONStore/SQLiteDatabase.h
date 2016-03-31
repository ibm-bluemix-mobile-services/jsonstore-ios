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

#import <sqlite3.h>


/**
 Contains operations that work directly on the database.
 */
@interface SQLiteDatabase : NSObject{
    sqlite3* _db;
    dispatch_queue_t _databaseQueue;
}


/**
 Holds the path to the actual database storage file on disk.
 */
@property (atomic, retain) NSString* dbfilePath;

/**
 User name that is tied to the database manager.
 */
@property (atomic, strong) NSString* username;

/**
 Initialization method.
 @param username The user name that is used to init the database manager
 @return self
 */
-(id) initWithUserName: (NSString*) username;

/**
 Returns the path to the actual database storage file on disk.
 @return Path to the DB file
 */
-(NSString*) getDbFilePath;

/**
 Get the path to the wljsonstore directory on disk.
 @return Path to the DB directory
 */
-(NSString*) getJsonStoreDirectoryPath;

/**
 Closes the database.
 @return Success (true) or failure (false)
 */
-(BOOL) closeDB;

/**
 Executes SQL statements.
 @param sql The SQL statement(s) as a string
 @return Success (true) or failure (false)
 */
-(BOOL) execute: (NSString*) sql, ...;

/**
 Executes SQL statements and adds the result to the result map.
 @param resultMap Mutable dictionary with the result of the sql statement(s)
 @param sql The SQL statement(s) as a string
 @return Success (true) or failure (false)
 */
-(BOOL) selectInto: (NSMutableDictionary*) resultMap
           withSQL: (NSString*) sql, ...;

/**
 Executes SQL statements and adds the results to the result map.
 @param resultArray Mutable array with the results of the sql statement(s)
 @param sql The SQL statement(s) as a string
 @return Success (true) or failure (false)
 */
-(BOOL) selectAllInto: (NSMutableArray*) resultArray
              withSQL: (NSString*) sql, ...;

/**
 Executes insert SQL statements.
 @param sql The SQL statement(s) as a string
 @return Success (true) or failure (false)
 */
-(BOOL) insertStmt: (NSString*) sql, ...;

/**
 Executes update SQL statements.
 @param sql The SQL statement(s) as a string
 @return Number of records updated
 */
-(int) update: (NSString*) sql, ...;

/**
 Executes delete SQL statements.
 @param sql The SQL statement(s) as a string
 @return Number of records deleted
 */
-(int) deleteFromDatabase: (NSString*) sql, ...;

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

/**
 Executes a create SQL statement.
 @param createTableStatement The create SQL statement as a string
 @return Success (true) or failure (false)
 */
-(BOOL) executeSchemaCreation:(NSString*) createTableStatement;

/**
 Returns the last error message from the database.
 @return Last error message from the database as a string
 */
-(NSString*) lastErrorMsg;

@end
