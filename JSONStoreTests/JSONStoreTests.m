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

#import <XCTest/XCTest.h>
#import "JSONStore.h"
#import "JSONStoreQueryPart.h"
#import "JSONStore+Private.h"
#import "JSONStoreConstants.h"
#import "JSONStoreCollection.h"
#import "JSONStoreCollection+Private.h"



@interface JSONStoreTest : XCTestCase

@end


@implementation JSONStoreTest

+(void)setUp
{
    
    //Try to cleanup the database directory before we get started
    NSError* error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray* urls = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL* u = [urls objectAtIndex:0];
    u = [u URLByAppendingPathComponent:JSON_STORE_DEFAULT_FOLDER_FOR_SQLITE_FILES];
    
    //Destory the existing dir
    NSString *dbPath = [u path];
    
    if([fileManager fileExistsAtPath:dbPath]) {
        
        if(![fileManager removeItemAtPath:dbPath error:&error]){
            if(error != nil){
                NSLog(@"Removal error information code: [%@]",
                      error
                      );
            }
        }
    }
    //Create new dir for databases
    if (![fileManager createDirectoryAtPath:[u path]
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&error])
    {
        NSLog(@"Unable to create directory error: %@", error);
    }
}

//Tests fail ('test could not finish') if we don't sleep for a short time
-(void) tearDown
{
    [[JSONStore sharedInstance] destroyDataAndReturnError:nil];
}

-(void) testSomeBasics
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"people"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    [col1 setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    ops.username = @"shin";
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    NSDictionary* carlos = @{ @"name" : @"masao", @"age" : @99 };
    NSDictionary* dgonz = @{ @"name" : @"#enzan", @"age" : @9001 };
    
    int numAdded = [[col1 addData:@[carlos, dgonz] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertEqual(numAdded, 2, @"Should add correct amount of docs");
    
    NSArray* resArr = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue(resArr != nil, @"should find results");
    
    NSDictionary* firstObj = [resArr objectAtIndex:0];
    
    NSString* name = [firstObj valueForKeyPath:@"json.name"];
    int age = [[firstObj valueForKeyPath:@"json.age"] intValue];
    
    XCTAssertTrue([name isEqualToString:@"masao"], @"should get correct name");
    XCTAssertTrue(age == 99, @"should get correct age as int");
    
    NSDictionary* secondObject = [resArr objectAtIndex:1];
    
    NSString* name2 = [secondObject valueForKeyPath:@"json.name"];
    int age2 = [[secondObject valueForKeyPath:@"json.age"] intValue];
    
    XCTAssertTrue([name2 isEqualToString:@"#enzan"], @"should get correct name");
    XCTAssertTrue(age2 == 9001, @"should get correct age as int");
}

-(void) testDropFirst
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"people"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    [col1 setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    NSDictionary* iyo = @{ @"name" : @"iyo", @"age" : @99 };
    NSDictionary* hoshikata = @{ @"name" : @"#hoshikata", @"age" : @9001 };
    
    int numAdded = [[col1 addData:@[iyo, hoshikata] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == 2, @"add count check");
    XCTAssertTrue([[col1 countAllDocumentsAndReturnError:nil] intValue] == 2, @"count check");
    
    [[JSONStore sharedInstance] closeAllCollectionsAndReturnError:nil];
    
    col1._dropFirst = true;
    
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    XCTAssertTrue([[col1 countAllDocumentsAndReturnError:nil] intValue] == 0, @"count check after dropfirst");
    
    XCTAssertTrue([[col1 findAllWithOptions:nil error:nil] count] == 0, @"findAll count");
}

-(void)testJSONStoreCollectionSetSearchField
{
    
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"people"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    [col1 setSearchField:@"age" withType:JSONStore_Integer];
    [col1 setSearchField:@"gpa" withType:JSONStore_Number];
    [col1 setSearchField:@"active" withType:JSONStore_Boolean];
    
    XCTAssertTrue([col1.searchFields isKindOfClass:[NSDictionary class]], @"should be NSDictionary");
    
    XCTAssertTrue( [[col1.searchFields objectForKey:@"name"]     isEqualToString:@"string"], @"string type for name key");
    XCTAssertTrue( [[col1.searchFields objectForKey:@"age"]      isEqualToString:@"integer"], @"integer type for age key");
    XCTAssertTrue( [[col1.searchFields objectForKey:@"gpa"]      isEqualToString:@"number"], @"number type for gpa key");
    XCTAssertTrue( [[col1.searchFields objectForKey:@"active"]   isEqualToString:@"boolean"], @"bool type for active key");
    
    NSDictionary* expectedSF = @{@"name": @"string", @"age" : @"integer", @"gpa" : @"number", @"active" : @"boolean"};
    
    XCTAssertTrue([col1.searchFields isEqualToDictionary:expectedSF], @"should create the same dict");
}

-(void)testJSONStoreCollectionSetAdditionalSearchFields
{
    
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"people"];
    [col1 setAdditionalSearchField:@"name" withType:JSONStore_String];
    [col1 setAdditionalSearchField:@"age" withType:JSONStore_Integer];
    [col1 setAdditionalSearchField:@"gpa" withType:JSONStore_Number];
    [col1 setAdditionalSearchField:@"active" withType:JSONStore_Boolean];
    
    XCTAssertTrue([col1.additionalSearchFields isKindOfClass:[NSDictionary class]], @"should be NSDictionary");
    
    XCTAssertTrue( [[col1.additionalSearchFields objectForKey:@"name"]     isEqualToString:@"string"], @"string type for name key");
    XCTAssertTrue( [[col1.additionalSearchFields objectForKey:@"age"]      isEqualToString:@"integer"], @"integer type for age key");
    XCTAssertTrue( [[col1.additionalSearchFields objectForKey:@"gpa"]      isEqualToString:@"number"], @"number type for gpa key");
    XCTAssertTrue( [[col1.additionalSearchFields objectForKey:@"active"]   isEqualToString:@"boolean"], @"bool type for active key");
    
    NSDictionary* expectedASF = @{@"name": @"string", @"age" : @"integer", @"gpa" : @"number", @"active" : @"boolean"};
    
    XCTAssertTrue([col1.additionalSearchFields isEqualToDictionary:expectedASF], @"should create the same dict");
}

-(void)testBasicSearchFieldsAddInitAndFindAll
{
    
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"people"];
    [col1 setSearchField:@"sfname" withType:JSONStore_String];
    [col1 setSearchField:@"sfage" withType:JSONStore_Integer];
    [col1 setSearchField:@"sfgpa" withType:JSONStore_Number];
    [col1 setSearchField:@"sfactive" withType:JSONStore_Boolean];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    NSDictionary* data1 = @{@"sfname": @"shin", @"sfage" : @10, @"sfgpa" : @3.22, @"sfactive" : @YES};
    NSDictionary* data2 = @{@"sfname": @"shu", @"sfage" : @12, @"sfgpa" : @4.01, @"sfactive" : @NO};
    
    int numAdded = [[col1 addData:@[data1, data2] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == 2, @"add worked");
    
    NSArray* results = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.sfname"] isEqualToString:@"shin"], @"sfname");
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.sfage"] intValue] == 10, @"sfage");
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.sfgpa"] doubleValue] == 3.22, @"sfage");
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.sfactive"] boolValue], @"sfactive");
    
    XCTAssertTrue([[[results objectAtIndex:1] valueForKeyPath:@"json.sfname"] isEqualToString:@"shu"], @"sfname");
    XCTAssertTrue([[[results objectAtIndex:1] valueForKeyPath:@"json.sfage"] intValue] == 12, @"sfage");
    XCTAssertTrue([[[results objectAtIndex:1] valueForKeyPath:@"json.sfgpa"] doubleValue] == 4.01, @"sfage");
    XCTAssertTrue(![[[results objectAtIndex:1] valueForKeyPath:@"json.sfactive"] boolValue], @"sfactive");
}

-(void)testBasicAdditionalSearchFieldsAddInitAndFindAll
{
    
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"people"];
    [col1 setSearchField:@"sfname" withType:JSONStore_String];
    [col1 setSearchField:@"sfage" withType:JSONStore_Integer];
    [col1 setSearchField:@"sfgpa" withType:JSONStore_Number];
    [col1 setSearchField:@"sfactive" withType:JSONStore_Boolean];
    
    [col1 setAdditionalSearchField:@"asfname" withType:JSONStore_String];
    [col1 setAdditionalSearchField:@"asfage" withType:JSONStore_Integer];
    [col1 setAdditionalSearchField:@"asfgpa" withType:JSONStore_Number];
    [col1 setAdditionalSearchField:@"asfactive" withType:JSONStore_Boolean];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    NSDictionary* data1 = @{@"sfname": @"junko", @"sfage" : @10, @"sfgpa" : @3.22, @"sfactive" : @YES};
    
    NSDictionary* addSearchFields = @{ @"asfname" : @"Adaki", @"asfage" : @10, @"asfgpa" : @4.01, @"asfactive" : @NO };
    
    JSONStoreAddOptions* aops = [[JSONStoreAddOptions alloc] init];
    aops.additionalSearchFields = (NSMutableDictionary*) addSearchFields;
    
    int numAdded = [[col1 addData:@[data1] andMarkDirty:NO withOptions:aops error:nil] intValue];
    
    XCTAssertTrue(numAdded == 1, @"add worked 1");
    
    NSDictionary* data2 = @{@"sfname": @"c", @"sfage" : @100, @"sfgpa" : @4.22, @"sfactive" : @YES};
    NSDictionary* data3 = @{@"sfname": @"ddd", @"sfage" : @13423, @"sfgpa" : @4.11, @"sfactive" : @NO};
    
    int numAdded2 = [[col1 addData:@[data2, data3] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded2 == 2, @"add worked 2");
    
    NSArray* results = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.sfname"] isEqualToString:@"junko"], @"sfname");
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.sfage"] intValue] == 10, @"sfage");
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.sfgpa"] doubleValue] == 3.22, @"sfage");
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.sfactive"] boolValue], @"sfactive");
    
    //Search for additional search field as string:
    
    NSDictionary* query1 = @{@"asfname" : @"Adaki"};
    
    JSONStoreQueryOptions* qops = [[JSONStoreQueryOptions alloc] init];
    qops.limit = nil;
    qops.offset = nil;
    
    JSONStoreQueryPart* q1 = [[JSONStoreQueryPart alloc] init];
    q1._equal = (NSMutableArray*) @[query1];
    
    NSArray* results2 = [col1 findWithQueryParts:@[q1] andOptions:qops error:nil];
    
    XCTAssertTrue([results2 count] == 1, @"results2 count");
    
    XCTAssertTrue([[[results2 objectAtIndex:0] valueForKeyPath:@"json.sfname"] isEqualToString:@"junko"], @"sfname");
    XCTAssertTrue([[[results2 objectAtIndex:0] valueForKeyPath:@"json.sfage"] intValue] == 10, @"sfage");
    XCTAssertTrue([[[results2 objectAtIndex:0] valueForKeyPath:@"json.sfgpa"] doubleValue] == 3.22, @"sfage");
    XCTAssertTrue([[[results2 objectAtIndex:0] valueForKeyPath:@"json.sfactive"] boolValue], @"sfactive");
    
    //Search for additional search field as integer:
    
    NSDictionary* query2 = @{@"asfage" : @10};
    
    JSONStoreQueryOptions* qops2 = [[JSONStoreQueryOptions alloc] init];
    qops2.limit = nil;
    qops2.offset = nil;
    
    JSONStoreQueryPart* q2 = [[JSONStoreQueryPart alloc] init];
    q2._equal = (NSMutableArray*) @[query2];
    
    NSArray* results3 = [col1 findWithQueryParts:@[q2] andOptions:qops2 error:nil];
    
    XCTAssertTrue([results3 count] == 1, @"results3 count");
    
    XCTAssertTrue([[[results3 objectAtIndex:0] valueForKeyPath:@"json.sfname"] isEqualToString:@"junko"], @"sfname");
    XCTAssertTrue([[[results3 objectAtIndex:0] valueForKeyPath:@"json.sfage"] intValue] == 10, @"sfage");
    XCTAssertTrue([[[results3 objectAtIndex:0] valueForKeyPath:@"json.sfgpa"] doubleValue] == 3.22, @"sfage");
    XCTAssertTrue([[[results3 objectAtIndex:0] valueForKeyPath:@"json.sfactive"] boolValue], @"sfactive");
    
    //Search for additional search field as number:
    
    NSDictionary* query3 = @{@"asfgpa" : @4.01};
    
    JSONStoreQueryOptions* qops3 = [[JSONStoreQueryOptions alloc] init];
    qops3.limit = nil;
    qops3.offset = nil;
    
    JSONStoreQueryPart* q3 = [[JSONStoreQueryPart alloc] init];
    q3._equal = (NSMutableArray*) @[query3];
    
    NSArray* results4 = [col1 findWithQueryParts:@[q3] andOptions:qops3 error:nil];
    
    XCTAssertTrue([results4 count] == 1, @"results4 count");
    
    XCTAssertTrue([[[results4 objectAtIndex:0] valueForKeyPath:@"json.sfname"] isEqualToString:@"junko"], @"sfname");
    XCTAssertTrue([[[results4 objectAtIndex:0] valueForKeyPath:@"json.sfage"] intValue] == 10, @"sfage");
    XCTAssertTrue([[[results4 objectAtIndex:0] valueForKeyPath:@"json.sfgpa"] doubleValue] == 3.22, @"sfage");
    XCTAssertTrue([[[results4 objectAtIndex:0] valueForKeyPath:@"json.sfactive"] boolValue], @"sfactive");
    
    //Search for additional search field as number:
    
    NSDictionary* query4 = @{@"asfactive" : @YES};
    
    JSONStoreQueryOptions* qops4 = [[JSONStoreQueryOptions alloc] init];
    qops4.limit = nil;
    qops4.offset = nil;
    
    JSONStoreQueryPart* q4 = [[JSONStoreQueryPart alloc] init];
    q4._equal = (NSMutableArray*) @[query4];
    
    NSArray* results5 = [col1 findWithQueryParts:@[q4] andOptions:qops4 error:nil];
    
    XCTAssertTrue([results5 count] == 0, @"results5 count");
    
    NSDictionary* query5 = @{@"asfactive" : @NO};
    
    JSONStoreQueryOptions* qops5 = [[JSONStoreQueryOptions alloc] init];
    qops5.limit = nil;
    qops5.offset = nil;
    
    JSONStoreQueryPart* q5 = [[JSONStoreQueryPart alloc] init];
    q5._equal = (NSMutableArray*) @[query5];
    
    NSArray* results6 = [col1 findWithQueryParts:@[q5] andOptions:qops5 error:nil];
    
    XCTAssertTrue([[[results6 objectAtIndex:0] valueForKeyPath:@"json.sfname"] isEqualToString:@"junko"], @"sfname");
    XCTAssertTrue([[[results6 objectAtIndex:0] valueForKeyPath:@"json.sfage"] intValue] == 10, @"sfage");
    XCTAssertTrue([[[results6 objectAtIndex:0] valueForKeyPath:@"json.sfgpa"] doubleValue] == 3.22, @"sfage");
    XCTAssertTrue([[[results6 objectAtIndex:0] valueForKeyPath:@"json.sfactive"] boolValue], @"sfactive");
}

-(void)testGet
{
    JSONStoreCollection* c = [[JSONStoreCollection alloc] initWithName:@"c"];
    [c setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[c] withOptions:ops error:nil];
    
    JSONStoreCollection* cget = [[JSONStore sharedInstance] getCollectionWithName:@"c"];
    
    XCTAssertTrue(c == cget, @"get should return the right instance");
}

-(void)testCloseAll
{
    XCTAssertNoThrow([[JSONStore sharedInstance] closeAllCollectionsAndReturnError:nil], @"should not throw exception");
    
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"people"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    [col1 addData:@[ @{@"name": @"ayumu"} ] andMarkDirty:NO withOptions:nil error:nil];
    
    [[JSONStore sharedInstance] closeAllCollectionsAndReturnError:nil];
    
    @try {
        [col1 addData:@[ @{@"name": @"kahako"} ] andMarkDirty:NO withOptions:nil error:nil];
    }
    @catch (NSException *exception) {
        
        NSString* name = exception.reason;
        
        XCTAssertTrue([name isEqualToString:JSON_STORE_DATABASE_NOT_OPEN_LABEL], @"exception name");
        
        int errorCode = [[exception.userInfo objectForKey:JSON_STORE_ERROR_OBJ_KEY_ERR] integerValue];
        
        XCTAssertTrue(errorCode == JSON_STORE_DATABASE_NOT_OPEN, @"exception rc");
    }
    
    JSONStoreOpenOptions* ops2 = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops2 error:nil];
    
    NSArray* results = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([results count] == 1, @"result amount");
    
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"ayumu"], @"result content");
}

-(void)testGetException
{
    JSONStoreCollection* ppl = nil;
    
    @try {
        ppl = [[JSONStore sharedInstance] getCollectionWithName:@"people"];
    }
    @catch (NSException *exception) {
        
        ppl = nil;
        
        NSString* name = exception.reason;
        
        XCTAssertTrue([name isEqualToString:JSON_STORE_DATABASE_NOT_OPEN_LABEL], @"exception name");
        
        int errorCode = [[exception.userInfo objectForKey:JSON_STORE_ERROR_OBJ_KEY_ERR] integerValue];
        
        XCTAssertTrue(errorCode == JSON_STORE_DATABASE_NOT_OPEN, @"exception rc");
    }
}

-(void)testInitWithUsernameAndPassword
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"people"];
    [col1 setSearchField:@".1name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    ops.username = @"clos";
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    int numAdded = [[col1 addData:@[ @{ @".1name" : @"kitsune"} ] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == 1, @"add worked");
    
    NSArray* results = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([results count] == 1, @"count results");
    
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json..1name"] isEqualToString:@"kitsune"], @"name");
    
    [[JSONStore sharedInstance] closeAllCollectionsAndReturnError:nil];
    
    @try {
        [col1 addData:@[ @{@".1name": @"daisuke"} ] andMarkDirty:NO withOptions:nil error:nil];
    }
    @catch (NSException *exception) {
        
        NSString* name = exception.reason;
        
        XCTAssertTrue([name isEqualToString:JSON_STORE_DATABASE_NOT_OPEN_LABEL], @"exception name");
        
        int errorCode = [[exception.userInfo objectForKey:JSON_STORE_ERROR_OBJ_KEY_ERR] integerValue];
        
        XCTAssertTrue(errorCode == JSON_STORE_DATABASE_NOT_OPEN, @"exception rc");
    }
    
    @try {
        
        JSONStoreOpenOptions* ops2 = [[JSONStoreOpenOptions alloc] init];
        ops2.username = @"clos";
        [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops2 error:nil];
    }
    @catch (NSException *exception) {
        
        NSString* name = exception.reason;
        
        XCTAssertTrue([name isEqualToString:@"JSON_STORE_PROVISION_FAILURE"], @"exception name");
        
        int errorCode = [[exception.userInfo objectForKey:JSON_STORE_ERROR_OBJ_KEY_ERR] integerValue];
        
        XCTAssertTrue(errorCode == JSON_STORE_PROVISION_KEY_FAILURE, @"exception rc");
    }
    
    JSONStoreOpenOptions* ops3 = [[JSONStoreOpenOptions alloc] init];
    ops3.username = @"clos";
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops3 error:nil];
    
    NSArray* results2 = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([results2 count] == 1, @"count results");
    
    XCTAssertTrue([[[results2 objectAtIndex:0] valueForKeyPath:@"json..1name"] isEqualToString:@"kitsune"], @"name");
}

//TODO: Need to store the collection instances with the username
-(void) testInitWithTwoUsersUsernameMismatchException
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"people"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    ops.username = @"userA";
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    int numAdded = [[col1 addData:@[ @{ @"name" : @"KEIJI"} ] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == 1, @"add worked");
    
    JSONStoreCollection* col2 = [[JSONStoreCollection alloc] initWithName:@"people"];
    [col2 setSearchField:@"age" withType:JSONStore_Integer];
    
    @try {
        
        JSONStoreOpenOptions* ops2 = [[JSONStoreOpenOptions alloc] init];
        ops2.username = @"userB";
        [[JSONStore sharedInstance] openCollections:@[col2] withOptions:ops2 error:nil];
    }
    @catch (NSException *exception) {
        NSString* name = exception.reason;
        
        XCTAssertTrue([name isEqualToString:@"JSON_STORE_USERNAME_MISMATCH"], @"exception name");
        
        int errorCode = [[exception.userInfo objectForKey:JSON_STORE_ERROR_OBJ_KEY_ERR] integerValue];
        
        XCTAssertTrue(errorCode == JSON_STORE_USERNAME_MISMATCH, @"exception rc");
    }
}

-(void) testInitWithTwoUsersHappyPath
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"people"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    ops.username = @"userA";
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    int numAdded = [[col1 addData:@[ @{ @"name" : @"SHIORI"} ] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == 1, @"add worked");
    
    [[JSONStore sharedInstance] closeAllCollectionsAndReturnError:nil];
    
    JSONStoreCollection* col2 = [[JSONStoreCollection alloc] initWithName:@"people"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops2 = [[JSONStoreOpenOptions alloc] init];
    ops2.username = @"userB";
    [[JSONStore sharedInstance] openCollections:@[col2] withOptions:ops2 error:nil];
    
    int numAdded2 = [[col2 addData:@[ @{ @"name" : @"REIKO"} ] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded2 == 1, @"add worked");
    
    NSArray* results = [col2 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([results count] == 1, @"count results");
    
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"REIKO"], @"name");
    
    [[JSONStore sharedInstance] closeAllCollectionsAndReturnError:nil];
    
    JSONStoreOpenOptions* ops3 = [[JSONStoreOpenOptions alloc] init];
    ops3.username = @"userA";
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops3 error:nil];
    
    NSArray* results2 = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([results2 count] == 1, @"count results");
    
    XCTAssertTrue([[[results2 objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"SHIORI"], @"name");
    
    [[JSONStore sharedInstance] closeAllCollectionsAndReturnError:nil];
    
    JSONStoreOpenOptions* ops4 = [[JSONStoreOpenOptions alloc] init];
    ops4.username = @"userB";
    [[JSONStore sharedInstance] openCollections:@[col2] withOptions:ops4 error:nil];
    
    NSArray* results3 = [col2 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([results3 count] == 1, @"count results");
    
    XCTAssertTrue([[[results3 objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"REIKO"], @"name");
}

-(void) testReplaceHappyPathWithDirtyCleanOperations
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"peeps"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    int numAdded = [[col1 addData:@[ @{ @"name" : @"oldName"} ] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == 1, @"add worked");
    
    NSArray* results = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"oldName"], @"check old name");
    
    XCTAssertTrue([results count] == 1, @"find count");
    
    //Check dirty doc that was added
    int allDirtyCount = [[col1 countAllDirtyDocumentsWithError:nil] intValue];
    
    XCTAssertTrue(allDirtyCount == 0, @"all dirty count result");
    
    NSArray* allDirtyResult = [col1 allDirtyAndReturnError:nil];
    
    XCTAssertTrue([allDirtyResult count] == 0, @"all dirty result");
    
    int idField = [[[results objectAtIndex:0] valueForKeyPath:@"_id"] intValue];
    
    XCTAssertTrue(idField == 1, @"check _id field");
    
    BOOL isDirtyDocResult = [col1 isDirtyWithDocumentId:idField error:nil];
    
    XCTAssertTrue(!isDirtyDocResult, @"dirty doc bool result");
    
    NSDictionary* newDoc = @{ @"_id" : @1, @"json" : @{ @"name" : @"newName" }};
    
    int numReplaced = [[col1 replaceDocuments:@[newDoc] andMarkDirty:YES error:nil] intValue];
    
    XCTAssertTrue(numReplaced == 1, @"replace worked");
    
    NSArray* results2 = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([results2 count] == 1, @"find count 2");
    
    XCTAssertTrue([[[results2 objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"newName"], @"check old name");
    
    //Check dirty doc that was replaced
    int allDirtyCount2 = [[col1 countAllDirtyDocumentsWithError:nil] intValue];
    
    XCTAssertTrue(allDirtyCount2 == 1, @"all dirty count result");
    
    NSArray* allDirtyResult2 = [col1 allDirtyAndReturnError:nil];
    
    XCTAssertTrue([allDirtyResult2 count] == 1, @"all dirty result");
    
    XCTAssertTrue([[[allDirtyResult2 objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"newName"], @"check dirty result");
    
    int idField2 = [[[results2 objectAtIndex:0] valueForKeyPath:@"_id"] intValue];
    
    XCTAssertTrue(idField2 == 1, @"check _id field");
    
    BOOL isDirtyDocResult2 = [col1 isDirtyWithDocumentId:idField error:nil];
    
    XCTAssertTrue(isDirtyDocResult2, @"dirty doc bool result");
    
    //Mark document clean
    NSDictionary* dirtyDoc = [allDirtyResult2 objectAtIndex:0];
    
    XCTAssertTrue([[dirtyDoc valueForKeyPath:@"json.name"] isEqualToString:@"newName"], @"check dirty doc contains the updates");
    
    [col1 markDocumentsClean:@[dirtyDoc] error:nil];
    
    //Check that dirty doc is now clean
    int allDirtyCount3 = [[col1 countAllDirtyDocumentsWithError:nil] intValue];
    
    XCTAssertTrue(allDirtyCount3 == 0, @"all dirty count result");
    
    NSArray* allDirtyResult3 = [col1 allDirtyAndReturnError:nil];
    
    XCTAssertTrue([allDirtyResult3 count] == 0, @"all dirty result");
    
    int idField3 = [[[results2 objectAtIndex:0] valueForKeyPath:@"_id"] intValue];
    
    XCTAssertTrue(idField3 == 1, @"check _id field");
    
    BOOL isDirtyDocResult3 = [col1 isDirtyWithDocumentId:idField error:nil];
    
    XCTAssertTrue(!isDirtyDocResult3, @"dirty doc bool result");
}

-(void) testRemoveHappyPathWithDirtyCleanOperations
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"peeps"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    int numAdded = [[col1 addData:@[ @{ @"name" : @"oldName"} ] andMarkDirty:YES withOptions:nil error:nil]intValue];
    
    XCTAssertTrue(numAdded == 1, @"add worked");
    
    NSArray* results = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"oldName"], @"check old name");
    
    XCTAssertTrue([results count] == 1, @"find count");
    
    //Check dirty doc that was added
    int allDirtyCount = [[col1 countAllDirtyDocumentsWithError:nil] intValue];
    
    XCTAssertTrue(allDirtyCount == 1, @"all dirty count result");
    
    NSArray* allDirtyResult = [col1 allDirtyAndReturnError:nil];
    
    XCTAssertTrue([[[allDirtyResult objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"oldName"], @"check old name");
    
    XCTAssertTrue([allDirtyResult count] == 1, @"all dirty result");
    
    int idField = [[[results objectAtIndex:0] valueForKeyPath:@"_id"] intValue];
    
    XCTAssertTrue(idField == 1, @"check _id field");
    
    BOOL isDirtyDocResult = [col1 isDirtyWithDocumentId:idField error:nil];
    
    XCTAssertTrue(isDirtyDocResult, @"dirty doc bool result");
    
    //Mark document clean
    NSDictionary* dirtyDoc = [allDirtyResult objectAtIndex:0];
    
    [col1 markDocumentsClean:@[dirtyDoc] error:nil];
    
    //Check dirty
    int allDirtyCount2 = [[col1 countAllDirtyDocumentsWithError:nil] intValue];
    
    XCTAssertTrue(allDirtyCount2 == 0, @"all dirty count result");
    
    //remove it
    [col1 _removeWithQueries:@[dirtyDoc] andMarkDirty:YES exactMatch:YES error:nil];
    
    //search wont find it
    NSArray* results2 = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([results2 count] == 0, @"find all after clean");
    
    //check dirty
    int allDirtyCount3 = [[col1 countAllDirtyDocumentsWithError:nil] intValue];
    
    XCTAssertTrue(allDirtyCount3 == 1, @"all dirty count result");
    
    NSArray* allDirtyResult2 = [col1 allDirtyAndReturnError:nil];
    
    NSDictionary* dirtyDoc2 = [allDirtyResult2 objectAtIndex:0];
    
    XCTAssertTrue([[dirtyDoc2 valueForKeyPath:@"json.name"] isEqualToString:@"oldName"], @"check dirty doc content");
    
    //mark clean
    
    [col1 markDocumentsClean:@[dirtyDoc2] error:nil];
    
    //check dirty
    int allDirtyCount4 = [[col1 countAllDirtyDocumentsWithError:nil] intValue];
    
    XCTAssertTrue(allDirtyCount4 == 0, @"all dirty count result");
}

-(void) testCount
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"peeps"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    int numAdded = [[col1 addData:@[ @{ @"name" : @"name1"}, @{ @"name" : @"name2"} ] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == 2, @"check added");
    
    NSArray* results = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([results count] == 2, @"find all count");
    
    int docsInCollection = [[col1 countAllDocumentsAndReturnError:nil] intValue];
    
    XCTAssertTrue(docsInCollection == 2, @"count all");
    
    JSONStoreQueryPart *cqp1 = [[JSONStoreQueryPart alloc] init];
    cqp1._like = (NSMutableArray*) @[@{ @"name" : @"name"}];
    
    int docsThatMatchQuery1 = [[col1 countWithQueryParts:@[cqp1] error:nil] intValue];
    
    XCTAssertTrue(docsThatMatchQuery1 == 2, @"query match all");
    
    JSONStoreQueryPart *cqp2 = [[JSONStoreQueryPart alloc] init];
    cqp2._equal = (NSMutableArray*) @[@{ @"name" : @"name1"}];
    
    int docsThatMatchQuery2 = [[col1 countWithQueryParts:@[cqp2] error:nil] intValue];
    
    XCTAssertTrue(docsThatMatchQuery2 == 1, @"query1");
    
    JSONStoreQueryPart *cqp3 = [[JSONStoreQueryPart alloc] init];
    cqp3._like = (NSMutableArray*) @[@{ @"name" : @"name2"}];
    
    int docsThatMatchQuery3 = [[col1 countWithQueryParts:@[cqp3] error:nil] intValue];
    
    XCTAssertTrue(docsThatMatchQuery3 == 1, @"query2");
}

-(void) testFindById
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"peeps"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    int numAdded = [[col1 addData:@[ @{ @"name" : @"hello-world"}, @{ @"name" : @"hey-world"} ] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == 2, @"check added");
    
    NSArray* doc1 = [col1 findWithIds:@[@1] andOptions:nil error:nil][0];
    
    XCTAssertTrue([[doc1 valueForKeyPath:@"json.name"] isEqualToString:@"hello-world"], @"find1");
    
    NSArray* doc2 = [col1 findWithIds:@[@2] andOptions:nil error:nil][0];
    
    XCTAssertTrue([[doc2 valueForKeyPath:@"json.name"] isEqualToString:@"hey-world"], @"find2");
}

-(void) testRemoveCollection
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"peeps"];
    [col1 setSearchField:@"first*Name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    int numAdded = [[col1 addData:@[ @{ @"first*Name" : @"hello-*world"}, @{ @"first*Name" : @"hey*-world"} ] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == 2, @"add count");
    
    NSArray* results = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([results count] == 2, @"findAll count");
    
    XCTAssertTrue([[col1 countAllDocumentsAndReturnError:nil] intValue] == 2, @"count");
    
    [col1 removeCollectionWithError:nil];
    
    @try {
        [col1 addData:@[ @{ @"first*Name" : @"hello-*world"}, @{ @"first*Name" : @"hey*-world"} ] andMarkDirty:NO withOptions:nil error:nil];
    }
    @catch (NSException *exception) {
        NSString* name = exception.reason;
        
        XCTAssertTrue([name isEqualToString:@"JSON_STORE_ADD_FAILURE"], @"exception name");
        
        int errorCode = [[exception.userInfo objectForKey:JSON_STORE_ERROR_OBJ_KEY_ERR] integerValue];
        
        XCTAssertTrue(errorCode == JSON_STORE_PERSISTENT_STORE_FAILURE, @"exception rc");
    }
    
    JSONStoreOpenOptions* ops2 = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops2 error:nil];
    
    int numAdded2 = [[col1 addData:@[ @{ @"first*Name" : @"hello-*world"} ] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded2 == 1, @"add count");
    
    NSArray* results2 = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([results2 count] == 1, @"findAll count");
    
    XCTAssertTrue([[col1 countAllDocumentsAndReturnError:nil] intValue] == 1, @"count");
}

-(void) testFindWithLimit
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"peeps"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    int numAdded = [[col1 addData:@[ @{ @"name" : @"world1"}, @{ @"name" : @"world2"} ] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == 2, @"add count");
    
    JSONStoreQueryOptions* qops = [[JSONStoreQueryOptions alloc] init];
    qops.limit = @2;
    qops.offset = @0;
    
    JSONStoreQueryPart* q1 = [[JSONStoreQueryPart alloc] init];
    q1._like = (NSMutableArray*) @[@{ @"name" : @"world"}];
    
    NSArray* results0 = [col1 findWithQueryParts:@[q1] andOptions:qops error:nil];
    
    XCTAssertTrue([results0 count] == 2, @"results0 count");
    
    XCTAssertTrue([[[results0 objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"world1"], @"results0 name1");
    XCTAssertTrue([[[results0 objectAtIndex:1] valueForKeyPath:@"json.name"] isEqualToString:@"world2"], @"results0 name2");
    
    JSONStoreQueryOptions* qops2 = [[JSONStoreQueryOptions alloc] init];
    qops2.limit = @1;
    qops2.offset = @0;
    
    JSONStoreQueryPart* q2 = [[JSONStoreQueryPart alloc] init];
    q2._like = (NSMutableArray*) @[@{ @"name" : @"world"}];
    
    NSArray* results1 = [col1 findWithQueryParts:@[q2] andOptions:qops2 error:nil];
    
    XCTAssertTrue([results1 count] == 1, @"results0 count");
    
    XCTAssertTrue([[[results1 objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"world1"], @"results0 name1");
    
    JSONStoreQueryOptions* qops3 = [[JSONStoreQueryOptions alloc] init];
    qops3.limit = @1;
    qops3.offset = @1;
    
    JSONStoreQueryPart* q3 = [[JSONStoreQueryPart alloc] init];
    q3._like = (NSMutableArray*) @[@{ @"name" : @"world"}];
    
    NSArray* results2 = [col1 findWithQueryParts:@[q3] andOptions:qops3 error:nil];
    
    XCTAssertTrue([results2 count] == 1, @"results2 count");
    
    XCTAssertTrue([[[results2 objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"world2"], @"results2 name1");
    
    JSONStoreQueryOptions* qops4 = [[JSONStoreQueryOptions alloc] init];
    qops4.limit = @1;
    qops4.offset = nil;
    
    JSONStoreQueryPart* q4 = [[JSONStoreQueryPart alloc] init];
    q4._like = (NSMutableArray*) @[@{ @"name" : @"world"}];
    
    NSArray* results3 = [col1 findWithQueryParts:@[q4] andOptions:qops4 error:nil];
    
    XCTAssertTrue([results3 count] == 1, @"results3 count");
    
    XCTAssertTrue([[[results3 objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"world1"], @"results3 name1");
    
    JSONStoreQueryOptions* qops5 = [[JSONStoreQueryOptions alloc] init];
    qops5.limit = @-1;
    qops5.offset = nil;
    
    JSONStoreQueryPart* q5 = [[JSONStoreQueryPart alloc] init];
    q5._like = (NSMutableArray*) @[@{ @"name" : @"world"}];
    
    NSArray* results4 = [col1 findWithQueryParts:@[q4] andOptions:qops5 error:nil];
    
    XCTAssertTrue([results4 count] == 1, @"results4 count");
    
    XCTAssertTrue([[[results4 objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"world2"], @"results4 name1");
}

-(void) testRemoveWithMarkDirtyTrueAndClean
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"ppl"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    int numAdded = [[col1 addData:@[ @{ @"name" : @"hey1"}, @{ @"name" : @"hello2"} ] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col1 countAllDocumentsAndReturnError:nil] intValue], @"count");
    
    NSDictionary* newDoc = @{ @"_id" : @1, @"json" : @{ @"name" : @"HEYO" }};
    
    int numReplaced = [[col1 replaceDocuments:@[newDoc] andMarkDirty:NO error:nil] intValue];
    
    XCTAssertTrue(numReplaced == 1, @"replacement count");
    
    XCTAssertTrue([[col1 countAllDirtyDocumentsWithError:nil] intValue] == 0, @"all dirty count");
    
    NSArray* results = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"HEYO"], @"should have updated name");
}

-(void) testReplaceWithMarkDirtyTrueAndCleanDirtyFalse
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"ppl"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    int numAdded = [[col1 addData:@[ @{ @"name" : @"hey1"}, @{ @"name" : @"hello2"} ] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col1 countAllDocumentsAndReturnError:nil] intValue], @"count");
    
    NSDictionary* newDoc = @{ @"_id" : @1, @"json" : @{ @"name" : @"HEYO" }};
    
    int numReplaced = [[col1 replaceDocuments:@[newDoc] andMarkDirty:NO error:nil] intValue];
    
    XCTAssertTrue(numReplaced == 1, @"replacement count");
    
    XCTAssertTrue([[col1 countAllDirtyDocumentsWithError:nil] intValue] == 0, @"all dirty count");
    
    NSArray* results = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"HEYO"], @"should have updated name");
}

-(void) testRemoveWithMarkDirtyTrueAndCleanDirtyFalse
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"ppl"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    int numAdded = [[col1 addData:@[ @{ @"name" : @"hey1"}, @{ @"name" : @"hello2"} ] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col1 countAllDocumentsAndReturnError:nil] intValue], @"count");
    
    NSArray* results = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"hey1"], @"should have updated name");
    
    int numRemoved = [[col1 _removeWithQueries:results andMarkDirty:NO exactMatch:NO error:nil] intValue];
    
    XCTAssertTrue(numRemoved == 2, @"remove count");
    
    XCTAssertTrue([[col1 countAllDirtyDocumentsWithError:nil] intValue] == 0, @"all dirty count");
    
    XCTAssertTrue([[col1 countAllDocumentsAndReturnError:nil] intValue] == (int)[[col1 findAllWithOptions:nil error:nil] count], @"count all");
}

-(void) testAllDirtyWithDocs
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"ppl"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    int numAdded = [[col1 addData:@[ @{ @"name" : @"hey1"}, @{ @"name" : @"hello2"} ] andMarkDirty:YES withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col1 countAllDocumentsAndReturnError:nil] intValue], @"count");
    
    NSArray* results = [col1 findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"hey1"], @"should have updated name");
    
    XCTAssertTrue([[col1 countAllDirtyDocumentsWithError:nil] intValue] == 2, @"all dirty count");
    
    NSDictionary* firstDoc = [results objectAtIndex:0];
    
    NSArray* res1 = [col1 _allDirtyWithDocuments:@[firstDoc] error:nil];
    
    XCTAssertTrue([[[res1 objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"hey1"], @"check res1 name");
    
    XCTAssertTrue([res1 count] == 1, @"all dirty with docs count");
    
    NSDictionary* secondDoc = [results objectAtIndex:1];
    
    NSArray* res2 = [col1 _allDirtyWithDocuments:@[secondDoc] error:nil];
    
    XCTAssertTrue([[[res2 objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"hello2"], @"check res1 name");
    
    XCTAssertTrue([res1 count] == 1, @"all dirty with docs count");
    
    XCTAssertTrue([[col1 countAllDirtyDocumentsWithError:nil] intValue] == 2, @"all dirty count");
}

-(void) testWith255DocsAdd
{
    NSMutableArray* data = [NSMutableArray new];
    
    for (int i = 1; i < 256; i++) {
        [data addObject:@{@"a":[NSString stringWithFormat:@"%d", i]}];
    }
    
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"ppl"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:ops error:nil];
    
    int numAdded = [[col1 addData:data andMarkDirty:YES withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col1 countAllDocumentsAndReturnError:nil] intValue], @"added count");
    
    XCTAssertTrue([[col1 countAllDocumentsAndReturnError:nil] intValue] == [[col1 countAllDirtyDocumentsWithError:nil] intValue], @"dirty count");
    
    NSMutableArray* arrOfIds = [NSMutableArray new];
    
    for (int i=1; i< 255; i++) {
        [arrOfIds addObject:[NSString stringWithFormat:@"%d",i]];
    }
    
    NSArray* res = [col1 findWithIds:arrOfIds andOptions:nil error:nil];
    
    int count = [res count];
    
    XCTAssertTrue(count == 254, @"count found ids");
    
    XCTAssertTrue([[[res objectAtIndex:0] valueForKeyPath:@"json.a"] isEqualToString:@"1"], @"correct value");
}

-(void) testAddingObjectsWithArrays
{
    JSONStoreCollection* col = [[JSONStoreCollection alloc] initWithName:@"heyo"];
    [col setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col] withOptions:ops error:nil];
    
    int numAdded = [[col addData:@[ @{ @"arr" : @[@"hello", @"world", @{@"myKey": @"myObj", @"myArr": @[@1,@2,@3]}, @3.14], @"name" : @"carlos", @"obj" : @{ @"hello" : @"world" } } ]
                    andMarkDirty:YES withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col countAllDocumentsAndReturnError:nil] intValue], @"count added");
    
    JSONStoreQueryPart *cqp1 = [[JSONStoreQueryPart alloc] init];
    cqp1._equal = (NSMutableArray*) @[@{}];
    
    XCTAssertTrue([col countAllDirtyDocumentsWithError:nil] == [col countWithQueryParts:@[cqp1] error:nil], @"count");
    
    NSArray* res = [col findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([res count] == 1, @"should find 1");
    
    NSString* name1 = [[[res objectAtIndex:0] valueForKeyPath:@"json.arr"] objectAtIndex:0];
    
    XCTAssertTrue([name1 isEqualToString:@"hello"], @"check first arr obj");
    
    XCTAssertTrue([[[[res objectAtIndex:0] valueForKeyPath:@"json.arr"] objectAtIndex:1] isEqualToString:@"world"], @"check second arr obj");
    
    NSString* obj = [[res objectAtIndex:0] valueForKeyPath:@"json.obj"];
    
    XCTAssertTrue([[obj valueForKey:@"hello"] isEqualToString:@"world"], @"check obj name");
    
    NSArray* theArr = [[res objectAtIndex:0] valueForKeyPath:@"json.arr"];
    
    XCTAssertTrue([[theArr objectAtIndex:0] isEqualToString:@"hello"], @"hello matched");
    XCTAssertTrue([[theArr objectAtIndex:1] isEqualToString:@"world"], @"world matched");
    
    XCTAssertTrue([[[theArr objectAtIndex:2] valueForKey:@"myKey"] isEqualToString:@"myObj"], @"myObj matched");
    
    XCTAssertTrue([[[[theArr objectAtIndex:2] valueForKey:@"myArr"] objectAtIndex:0] intValue] == 1, @"arr1 matched");
    XCTAssertTrue([[[[theArr objectAtIndex:2] valueForKey:@"myArr"] objectAtIndex:1] intValue] == 2, @"arr2 matched");
    XCTAssertTrue([[[[theArr objectAtIndex:2] valueForKey:@"myArr"] objectAtIndex:2] intValue] == 3, @"arr3 matched");
    
    XCTAssertTrue([[theArr objectAtIndex:3] doubleValue] == 3.14, @"world matched");
}

-(void) testSort
{
    JSONStoreCollection* col = [[JSONStoreCollection alloc] initWithName:@"heyo"];
    [col setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col] withOptions:ops error:nil];
    
    int numAdded = [[col addData:@[@{@"name" : @"aiko"},
                                   @{@"name" : @"katzumi"},
                                   @{@"name" : @"akira"}]
                    andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col countAllDocumentsAndReturnError:nil] intValue], @"check count");
    
    //NO Sort:
    
    JSONStoreQueryOptions* qops = [[JSONStoreQueryOptions alloc] init];
    qops.limit = @10;
    qops.offset = @0;
    
    JSONStoreQueryPart* q1 = [[JSONStoreQueryPart alloc] init];
    q1._like = (NSMutableArray*) @[@{@"name" : @"a"}];
    
    NSArray* res = [col findWithQueryParts:@[q1] andOptions:qops error:nil];
    
    XCTAssertTrue([res count] == 3, @"find count");
    
    XCTAssertTrue([[res[0] valueForKeyPath:@"json.name"] isEqualToString:@"aiko"], @"check find 1");
    XCTAssertTrue([[res[1] valueForKeyPath:@"json.name"] isEqualToString:@"katzumi"], @"check find 2");
    XCTAssertTrue([[res[2] valueForKeyPath:@"json.name"] isEqualToString:@"akira"], @"check find 3");
    
    //With Sort ASC:
    
    JSONStoreQueryOptions* qops2 = [[JSONStoreQueryOptions alloc] init];
    qops2.limit = @10;
    qops2.offset = @0;
    qops2._filter = nil;
    qops2._sort = (NSMutableArray*) @[@{@"name" : @"ASC"}];
    
    JSONStoreQueryPart* q2 = [[JSONStoreQueryPart alloc] init];
    q2._like = (NSMutableArray*) @[@{@"name" : @"a"}];
    
    NSArray* res2 = [col findWithQueryParts:@[q2] andOptions:qops2 error:nil];
    
    XCTAssertTrue([[res2[0] valueForKeyPath:@"json.name"] isEqualToString:@"aiko"], @"check find 1");
    XCTAssertTrue([[res2[1] valueForKeyPath:@"json.name"] isEqualToString:@"akira"], @"check find 2");
    XCTAssertTrue([[res2[2] valueForKeyPath:@"json.name"] isEqualToString:@"katzumi"], @"check find 3");
    
    //With Sort DESC:
    
    JSONStoreQueryOptions* qops3 = [[JSONStoreQueryOptions alloc] init];
    qops3.limit = @10;
    qops3.offset = @0;
    qops3._filter = nil;
    qops3._sort = (NSMutableArray*) @[@{@"name" : @"DESC"}];
    
    JSONStoreQueryPart* q3 = [[JSONStoreQueryPart alloc] init];
    q3._like = (NSMutableArray*) @[@{@"name" : @"a"}];
    
    NSArray* res3 = [col findWithQueryParts:@[q3] andOptions:qops3 error:nil];
    
    XCTAssertTrue([[res3[0] valueForKeyPath:@"json.name"] isEqualToString:@"katzumi"], @"check find 1");
    XCTAssertTrue([[res3[1] valueForKeyPath:@"json.name"] isEqualToString:@"akira"], @"check find 2");
    XCTAssertTrue([[res3[2] valueForKeyPath:@"json.name"] isEqualToString:@"aiko"], @"check find 3");
    
}

-(void) testFindQuery
{
    JSONStoreCollection* col = [[JSONStoreCollection alloc] initWithName:@"test"];
    [col setSearchField:@"name" withType:JSONStore_String];
    [col setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col] withOptions:ops error:nil];
    
    int numAdded = [[col addData:@[@{@"name" : @"akira", @"age" : @10},
                                   @{@"name" : @"kouta", @"age" : @20},
                                   @{@"name" : @"akane", @"age" : @2},
                                   @{@"name" : @"saito", @"age" : @1}]
                    andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col countAllDocumentsAndReturnError:nil] intValue], @"check count");
    
    JSONStoreQueryOptions* opts = [JSONStoreQueryOptions new];
    
    JSONStoreQueryPart* q1 = [[JSONStoreQueryPart alloc] init];
    q1._like = (NSMutableArray*) @[ @{ @"name" : @"a" } ];
    
    NSArray* res = [col findWithQueryParts:@[q1] andOptions:opts error:nil];
    
    XCTAssertTrue((int)[res count] == [[col countAllDocumentsAndReturnError:nil] intValue], @"found all");
    
    XCTAssertTrue([[res[0] valueForKeyPath:@"json.name"] isEqualToString:@"akira"], @"check nfind 1");
    XCTAssertTrue([[res[1] valueForKeyPath:@"json.name"] isEqualToString:@"kouta"], @"check nfind 2");
    XCTAssertTrue([[res[2] valueForKeyPath:@"json.name"] isEqualToString:@"akane"], @"check nfind 3");
    XCTAssertTrue([[res[3] valueForKeyPath:@"json.name"] isEqualToString:@"saito"], @"check nfind 4");
    
    XCTAssertTrue([[res[0] valueForKeyPath:@"json.age"] intValue] == 10, @"check afind 1");
    XCTAssertTrue([[res[1] valueForKeyPath:@"json.age"] intValue] == 20, @"check afind 2");
    XCTAssertTrue([[res[2] valueForKeyPath:@"json.age"] intValue] == 2, @"check afind 3");
    XCTAssertTrue([[res[3] valueForKeyPath:@"json.age"] intValue] == 1, @"check afind 4");
    
    JSONStoreQueryOptions* opts2 = [JSONStoreQueryOptions new];
    [opts2 setLimit:@10];
    [opts2 setOffset:@0];
    [opts2 sortBySearchFieldDescending:@"name"];
    [opts2 sortBySearchFieldAscending:@"age"];
    
    JSONStoreQueryPart* q2 = [[JSONStoreQueryPart alloc] init];
    q2._like = (NSMutableArray*) @[ @{ @"name" : @"a" } ];
    
    NSArray* res2 = [col findWithQueryParts:@[q2] andOptions:opts2 error:nil];
    
    XCTAssertTrue((int)[res2 count] == [[col countAllDocumentsAndReturnError:nil] intValue], @"found all 2");
    
    XCTAssertTrue([[res2[0] valueForKeyPath:@"json.name"] isEqualToString:@"saito"], @"check nfind 1");
    XCTAssertTrue([[res2[1] valueForKeyPath:@"json.name"] isEqualToString:@"kouta"], @"check nfind 2");
    XCTAssertTrue([[res2[2] valueForKeyPath:@"json.name"] isEqualToString:@"akira"], @"check nfind 3");
    XCTAssertTrue([[res2[3] valueForKeyPath:@"json.name"] isEqualToString:@"akane"], @"check mfind 4");
    
    XCTAssertTrue([[res2[0] valueForKeyPath:@"json.age"] intValue] == 1, @"check afind 1");
    XCTAssertTrue([[res2[1] valueForKeyPath:@"json.age"] intValue] == 20, @"check afind 2");
    XCTAssertTrue([[res2[2] valueForKeyPath:@"json.age"] intValue] == 10, @"check afind 3");
    XCTAssertTrue([[res2[3] valueForKeyPath:@"json.age"] intValue] == 2, @"check afind 4");
}

-(void) testFilterPickNoSort
{
    JSONStoreCollection* col = [[JSONStoreCollection alloc] initWithName:@"test"];
    [col setSearchField:@"name" withType:JSONStore_String];
    [col setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col] withOptions:ops error:nil];
    
    int numAdded = [[col addData:@[@{@"name" : @"donatsu", @"age" : @10},
                                   @{@"name" : @"deta", @"age" : @20},
                                   @{@"name" : @"daiki", @"age" : @2},
                                   @{@"name" : @"daki", @"age" : @1}]
                    andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col countAllDocumentsAndReturnError:nil] intValue], @"add res");
    
    JSONStoreQueryOptions* opts = [JSONStoreQueryOptions new];
    opts._filter = (NSMutableArray*) @[@"name", @"age"];
    
    JSONStoreQueryPart* q1 = [[JSONStoreQueryPart alloc] init];
    q1._like = (NSMutableArray*) @[ @{ @"name" : @"a" } ];
    
    NSArray* res = [col findWithQueryParts:@[q1] andOptions:opts error:nil];
    
    XCTAssertTrue((int)[res count] == [[col countAllDocumentsAndReturnError:nil] intValue], @"found all check");
    
    XCTAssertTrue([res[0][@"name"] isEqualToString:@"donatsu"], @"check name 1");
    XCTAssertTrue([res[1][@"name"] isEqualToString:@"deta"], @"check name 2");
    XCTAssertTrue([res[2][@"name"] isEqualToString:@"daiki"], @"check name 3");
    XCTAssertTrue([res[3][@"name"] isEqualToString:@"daki"], @"check name 4");
    
    XCTAssertTrue([res[0][@"age"] intValue] == 10, @"check age 1");
    XCTAssertTrue([res[1][@"age"] intValue] == 20, @"check age 2");
    XCTAssertTrue([res[2][@"age"] intValue] == 2, @"check age 3");
    XCTAssertTrue([res[3][@"age"] intValue] == 1, @"check age 4");
}

-(void) testFilterPickWithSort
{
    JSONStoreCollection* col = [[JSONStoreCollection alloc] initWithName:@"test"];
    [col setSearchField:@"name" withType:JSONStore_String];
    [col setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col] withOptions:ops error:nil];
    
    int numAdded = [[col addData:@[@{@"name" : @"kotaza", @"age" : @10},
                                   @{@"name" : @"aiko", @"age" : @20},
                                   @{@"name" : @"shashu", @"age" : @2},
                                   @{@"name" : @"ango", @"age" : @1}]
                    andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col countAllDocumentsAndReturnError:nil] intValue], @"add res");
    
    JSONStoreQueryOptions* opts = [JSONStoreQueryOptions new];
    [opts filterSearchField:@"name"];
    [opts filterSearchField:@"age"];
    [opts sortBySearchFieldAscending:@"name"];
    [opts sortBySearchFieldDescending:@"age"];
    
    
    JSONStoreQueryPart* q1 = [[JSONStoreQueryPart alloc] init];
    q1._like = (NSMutableArray*) @[ @{ @"name" : @"a" } ];
    
    NSArray* res = [col findWithQueryParts:@[q1] andOptions:opts error:nil];
    
    XCTAssertTrue((int)[res count] == [[col countAllDocumentsAndReturnError:nil] intValue], @"found all check");
    
    XCTAssertTrue([res[0][@"name"] isEqualToString:@"aiko"], @"check name 1");
    XCTAssertTrue([res[1][@"name"] isEqualToString:@"ango"], @"check name 2");
    XCTAssertTrue([res[2][@"name"] isEqualToString:@"kotaza"], @"check name 3");
    XCTAssertTrue([res[3][@"name"] isEqualToString:@"shashu"], @"check name 4");
    
    XCTAssertTrue([res[0][@"age"] intValue] == 20, @"check age 1");
    XCTAssertTrue([res[1][@"age"] intValue] == 1, @"check age 2");
    XCTAssertTrue([res[2][@"age"] intValue] == 10, @"check age 3");
    XCTAssertTrue([res[3][@"age"] intValue] == 2, @"check age 4");
}

-(void) testUpdate
{
    JSONStoreCollection* col = [[JSONStoreCollection alloc] initWithName:@"testing"];
    [col setSearchField:@"name" withType:JSONStore_String];
    [col setSearchField:@"age" withType:JSONStore_Integer];
    [col setSearchField:@"ssn" withType:JSONStore_String];
    [col setSearchField:@"id" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col] withOptions:ops error:nil];
    
    int numAdded = [[col addData:@[@{@"id": @0, @"ssn" : @"123", @"name" : @"sairasu", @"age" : @10},
                                   @{@"id": @1, @"ssn" : @"456", @"name" : @"saitama", @"age" : @20},
                                   @{@"id": @2, @"ssn" : @"782", @"name" : @"aion", @"age" : @2},
                                   @{@"id": @3, @"ssn" : @"101", @"name" : @"akkuma", @"age" : @1}]
                    andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col countAllDocumentsAndReturnError:nil] intValue], @"add res");
    
    JSONStoreQueryOptions* opts = [JSONStoreQueryOptions new];
    
    JSONStoreQueryPart* q1 = [[JSONStoreQueryPart alloc] init];
    q1._like = (NSMutableArray*) @[ @{ @"name" : @"a" } ];
    
    NSArray* res = [col findWithQueryParts:@[q1] andOptions:opts error:nil];
    
    XCTAssertTrue([[col countAllDirtyDocumentsWithError:nil] intValue] == 0, @"dirty count check");
    
    XCTAssertTrue((int)[res count] == [[col countAllDocumentsAndReturnError:nil] intValue], @"found all check");
    
    XCTAssertTrue([[[res objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"sairasu"], @"check name 1");
    XCTAssertTrue([[[res objectAtIndex:1] valueForKeyPath:@"json.name"] isEqualToString:@"saitama"], @"check name 2");
    XCTAssertTrue([[[res objectAtIndex:2] valueForKeyPath:@"json.name"] isEqualToString:@"aion"], @"check name 3");
    XCTAssertTrue([[[res objectAtIndex:3] valueForKeyPath:@"json.name"] isEqualToString:@"akkuma"], @"check name 4");
    
    XCTAssertTrue([[[res objectAtIndex:0] valueForKeyPath:@"json.ssn"] isEqualToString:@"123"], @"check ssn 1");
    XCTAssertTrue([[[res objectAtIndex:1] valueForKeyPath:@"json.ssn"] isEqualToString:@"456"], @"check ssn 2");
    XCTAssertTrue([[[res objectAtIndex:2] valueForKeyPath:@"json.ssn"] isEqualToString:@"782"], @"check ssn 3");
    XCTAssertTrue([[[res objectAtIndex:3] valueForKeyPath:@"json.ssn"] isEqualToString:@"101"], @"check ssn 4");
    
    XCTAssertTrue([[res[0] valueForKeyPath:@"json.id"] intValue] == 0, @"check id 1");
    XCTAssertTrue([[res[1] valueForKeyPath:@"json.id"] intValue] == 1, @"check id 2");
    XCTAssertTrue([[res[2] valueForKeyPath:@"json.id"] intValue] == 2, @"check id 3");
    XCTAssertTrue([[res[3] valueForKeyPath:@"json.id"] intValue] == 3, @"check id 4");
    
    XCTAssertTrue([[res[0] valueForKeyPath:@"json.age"] intValue] == 10, @"check age 1");
    XCTAssertTrue([[res[1] valueForKeyPath:@"json.age"] intValue] == 20, @"check age 2");
    XCTAssertTrue([[res[2] valueForKeyPath:@"json.age"] intValue] == 2,  @"check age 3");
    XCTAssertTrue([[res[3] valueForKeyPath:@"json.age"] intValue] == 1,  @"check age 4");
    
    NSArray* updatedData = @[@{@"id": @0, @"ssn" : @"123", @"name" : @"shin", @"age" : @12},
                             @{@"id": @1, @"ssn" : @"456", @"name" : @"saito", @"age" : @120},
                             @{@"id": @2, @"ssn" : @"782", @"name" : @"shu", @"age" : @2},
                             @{@"id": @3, @"ssn" : @"101", @"name" : @"ango", @"age" : @11},
                             @{@"id": @4, @"ssn" : @"333", @"name" : @"kenshin", @"age" : @100}];
    
    int numUpdated = [[col changeData:updatedData
                  withReplaceCriteria:@[@"id", @"ssn"]
                               addNew:YES
                            markDirty:NO
                                error:nil] intValue];
    
    XCTAssertTrue(numUpdated == 5, @"check num updated");
    
    NSArray* res2 = [col findAllWithOptions:opts error:nil];
    
    XCTAssertTrue([[col countAllDirtyDocumentsWithError:nil] intValue] == 0, @"dirty count check");
    
    XCTAssertTrue((int)[res2 count] == [[col countAllDocumentsAndReturnError:nil] intValue], @"found all check");
    XCTAssertTrue((int)[res2 count] == 5, @"collection size");
    
    XCTAssertTrue([[[res2 objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name 1");
    XCTAssertTrue([[[res2 objectAtIndex:1] valueForKeyPath:@"json.name"] isEqualToString:@"saito"], @"check name 2");
    XCTAssertTrue([[[res2 objectAtIndex:2] valueForKeyPath:@"json.name"] isEqualToString:@"shu"], @"check name 3");
    XCTAssertTrue([[[res2 objectAtIndex:3] valueForKeyPath:@"json.name"] isEqualToString:@"ango"], @"check name 4");
    XCTAssertTrue([[[res2 objectAtIndex:4] valueForKeyPath:@"json.name"] isEqualToString:@"kenshin"], @"check name 5");
    
    XCTAssertTrue([[[res2 objectAtIndex:0] valueForKeyPath:@"json.ssn"] isEqualToString:@"123"], @"check ssn 1");
    XCTAssertTrue([[[res2 objectAtIndex:1] valueForKeyPath:@"json.ssn"] isEqualToString:@"456"], @"check ssn 2");
    XCTAssertTrue([[[res2 objectAtIndex:2] valueForKeyPath:@"json.ssn"] isEqualToString:@"782"], @"check ssn 3");
    XCTAssertTrue([[[res2 objectAtIndex:3] valueForKeyPath:@"json.ssn"] isEqualToString:@"101"], @"check ssn 4");
    XCTAssertTrue([[[res2 objectAtIndex:4] valueForKeyPath:@"json.ssn"] isEqualToString:@"333"], @"check ssn 5");
    
    XCTAssertTrue([[res2[0] valueForKeyPath:@"json.id"] intValue] == 0, @"check id 1");
    XCTAssertTrue([[res2[1] valueForKeyPath:@"json.id"] intValue] == 1, @"check id 2");
    XCTAssertTrue([[res2[2] valueForKeyPath:@"json.id"] intValue] == 2, @"check id 3");
    XCTAssertTrue([[res2[3] valueForKeyPath:@"json.id"] intValue] == 3, @"check id 4");
    XCTAssertTrue([[res2[4] valueForKeyPath:@"json.id"] intValue] == 4, @"check id 5");
    
    XCTAssertTrue([[res2[0] valueForKeyPath:@"json.age"] intValue] == 12, @"check age 1");
    XCTAssertTrue([[res2[1] valueForKeyPath:@"json.age"] intValue] == 120, @"check age 2");
    XCTAssertTrue([[res2[2] valueForKeyPath:@"json.age"] intValue] == 2,  @"check age 3");
    XCTAssertTrue([[res2[3] valueForKeyPath:@"json.age"] intValue] == 11,  @"check age 4");
    XCTAssertTrue([[res2[4] valueForKeyPath:@"json.age"] intValue] == 100,  @"check age 5");
}

-(void) testClearCollectionTestNoPassword
{
    JSONStoreCollection* col = [[JSONStoreCollection alloc] initWithName:@"test"];
    [col setSearchField:@"name" withType:JSONStore_String];
    [col setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [[JSONStore sharedInstance] openCollections:@[col] withOptions:ops error:nil];
    
    int numAdded = [[col addData:@[@{@"name" : @"ringo", @"age" : @10},
                                   @{@"name" : @"aion", @"age" : @20},
                                   @{@"name" : @"karubin", @"age" : @2},
                                   @{@"name" : @"kyo", @"age" : @1}]
                    andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col countAllDocumentsAndReturnError:nil] intValue], @"add res");
    
    NSArray* res = [col findAllWithOptions:nil error:nil];
    XCTAssertTrue([res count] == 4, @"check findAll 2");
    
    [col clearCollectionWithError:nil];
    
    XCTAssertTrue([[col countAllDocumentsAndReturnError:nil] intValue] == 0, @"clear collection check");
    
    NSArray* res2 = [col findAllWithOptions:nil error:nil];
    XCTAssertTrue([res2 count] == 0, @"check findAll 2");
    
    int numAdded2 = [[col addData:@[@{@"name" : @"hey"}] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded2 == [[col countAllDocumentsAndReturnError:nil] intValue], @"check add worked 1");
    XCTAssertTrue([[col countAllDocumentsAndReturnError:nil] intValue] == 1, @"check add worked 1");
}

-(void) testClearCollectionTestWithUserAndPassword
{
    JSONStoreCollection* col = [[JSONStoreCollection alloc] initWithName:@"test111"];
    [col setSearchField:@"name" withType:JSONStore_String];
    [col setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    ops.username = @"hello";
    [[JSONStore sharedInstance] openCollections:@[col] withOptions:ops error:nil];
    
    int numAdded = [[col addData:@[@{@"name" : @"enzan", @"age" : @10},
                                   @{@"name" : @"iyo", @"age" : @20},
                                   @{@"name" : @"kami", @"age" : @2},
                                   @{@"name" : @"kouin", @"age" : @1}]
                    andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col countAllDocumentsAndReturnError:nil] intValue], @"add res");
    
    NSArray* res = [col findAllWithOptions:nil error:nil];
    XCTAssertTrue([res count] == 4, @"check findAll 2");
    
    [col clearCollectionWithError:nil];
    
    XCTAssertTrue([[col countAllDocumentsAndReturnError:nil] intValue] == 0, @"clear collection check");
    
    NSArray* res2 = [col findAllWithOptions:nil error:nil];
    XCTAssertTrue([res2 count] == 0, @"check findAll 2");
    
    int numAdded2 = [[col addData:@[@{@"name" : @"hey"}] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded2 == [[col countAllDocumentsAndReturnError:nil] intValue], @"check add worked 1");
    XCTAssertTrue([[col countAllDocumentsAndReturnError:nil] intValue] == 1, @"check add worked 1");
}

-(void) testClearCollectionTestWithUser
{
    JSONStoreCollection* col = [[JSONStoreCollection alloc] initWithName:@"test111222"];
    [col setSearchField:@"name" withType:JSONStore_String];
    [col setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    ops.username = @"hello";
    [[JSONStore sharedInstance] openCollections:@[col] withOptions:ops error:nil];
    
    int numAdded = [[col addData:@[@{@"name" : @"hitomi", @"age" : @10},
                                   @{@"name" : @"shin", @"age" : @20},
                                   @{@"name" : @"masao", @"age" : @2},
                                   @{@"name" : @"deta", @"age" : @1}]
                    andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col countAllDocumentsAndReturnError:nil] intValue], @"add res");
    
    NSArray* res = [col findAllWithOptions:nil error:nil];
    XCTAssertTrue([res count] == 4, @"check findAll 2");
    
    [col clearCollectionWithError:nil];
    
    XCTAssertTrue([[col countAllDocumentsAndReturnError:nil] intValue] == 0, @"clear collection check");
    
    NSArray* res2 = [col findAllWithOptions:nil error:nil];
    XCTAssertTrue([res2 count] == 0, @"check findAll 2");
    
    int numAdded2 = [[col addData:@[@{@"name" : @"hey"}] andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded2 == [[col countAllDocumentsAndReturnError:nil] intValue], @"check add worked 1");
    XCTAssertTrue([[col countAllDocumentsAndReturnError:nil] intValue] == 1, @"check add worked 1");
}

-(void) testFilterPickWithJSON
{
    JSONStoreCollection* col = [[JSONStoreCollection alloc] initWithName:@"test111222"];
    [col setSearchField:@"name" withType:JSONStore_String];
    [col setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    ops.username = @"hello";
    [[JSONStore sharedInstance] openCollections:@[col] withOptions:ops error:nil];
    
    int numAdded = [[col addData:@[@{@"name" : @"nigami", @"age" : @10},
                                   @{@"name" : @"saruishi", @"age" : @20},
                                   @{@"name" : @"takao", @"age" : @2},
                                   @{@"name" : @"ryuuto", @"age" : @1}]
                    andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col countAllDocumentsAndReturnError:nil] intValue], @"add res");
    
    JSONStoreQueryOptions* qops = [[JSONStoreQueryOptions alloc] init];
    [qops filterSearchField:@"json"];
    [qops filterSearchField:@"name"];
    
    NSArray* res = [col findAllWithOptions:qops error:nil];
    
    XCTAssertTrue([res count] == 4, @"check count findall");
    
    XCTAssertTrue([[res[0] valueForKeyPath:@"json.name"] isEqualToString:@"nigami"], @"found carlos");
}

-(void) testFindWithNegativeLimitAndOffset
{
    JSONStoreCollection* col = [[JSONStoreCollection alloc] initWithName:@"test111222"];
    [col setSearchField:@"name" withType:JSONStore_String];
    [col setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    ops.username = @"hello";
    [[JSONStore sharedInstance] openCollections:@[col] withOptions:ops error:nil];
    
    int numAdded = [[col addData:@[@{@"name" : @"shin", @"age" : @10},
                                   @{@"name" : @"deta", @"age" : @20},
                                   @{@"name" : @"kenshin", @"age" : @2},
                                   @{@"name" : @"shu", @"age" : @1}]
                    andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col countAllDocumentsAndReturnError:nil] intValue], @"add res");
    
    JSONStoreQueryOptions* qops = [[JSONStoreQueryOptions alloc] init];
    [qops setLimit:@-3];
    [qops setOffset:@1];
    
    NSArray* res = [col findAllWithOptions:qops error:nil];
    
    XCTAssertTrue([res count] == 3, @"check count findall");
    
    XCTAssertTrue([[res[0] valueForKeyPath:@"json.name"] isEqualToString:@"kenshin"], @"found name 1");
    XCTAssertTrue([[res[1] valueForKeyPath:@"json.name"] isEqualToString:@"deta"], @"found name 1");
    XCTAssertTrue([[res[2] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"found name 1");
}

-(void) testFindWithNegativeLimitAndNegativeOffset
{
    JSONStoreCollection* col = [[JSONStoreCollection alloc] initWithName:@"test111222333"];
    [col setSearchField:@"name" withType:JSONStore_String];
    [col setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    ops.username = @"hello";
    [[JSONStore sharedInstance] openCollections:@[col] withOptions:ops error:nil];
    
    int numAdded = [[col addData:@[@{@"name" : @"santaru", @"age" : @10},
                                   @{@"name" : @"masaru", @"age" : @20},
                                   @{@"name" : @"hayata", @"age" : @2},
                                   @{@"name" : @"kotaza", @"age" : @1}]
                    andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(numAdded == [[col countAllDocumentsAndReturnError:nil] intValue], @"add res");
    
    JSONStoreQueryOptions* qops = [[JSONStoreQueryOptions alloc] init];
    [qops setLimit:@-3];
    [qops setOffset:@-1];
    
    NSArray* res = [col findAllWithOptions:qops error:nil];
    
    XCTAssertTrue([res count] == 3, @"check count findall");
    
    XCTAssertTrue([[res[0] valueForKeyPath:@"json.name"] isEqualToString:@"hayata"], @"found name 1");
    XCTAssertTrue([[res[1] valueForKeyPath:@"json.name"] isEqualToString:@"masaru"], @"found name 1");
    XCTAssertTrue([[res[2] valueForKeyPath:@"json.name"] isEqualToString:@"santaru"], @"found name 1");
}

-(void) testClosedCollections
{
    JSONStoreCollection* col = [[JSONStoreCollection alloc] initWithName:@"testClosedCollections"];
    [col setSearchField:@"name" withType:JSONStore_String];
    [col setSearchField:@"age" withType:JSONStore_Integer];
    
    [[JSONStore sharedInstance] openCollections:@[col] withOptions:nil error:nil];
    
    [[JSONStore sharedInstance] closeAllCollectionsAndReturnError:nil];
    
    NSError* error = nil;
    
    int docsAdded = [[col addData:@[ @{@"name" : @"shin"} ] andMarkDirty:YES withOptions:nil error:&error] intValue];
    
    XCTAssertTrue(docsAdded == 0, @"check no docs added");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    BOOL removedWorked = [col removeCollectionWithError:&error];
    
    XCTAssertFalse(removedWorked, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    BOOL clearWorked = [col clearCollectionWithError:&error];
    
    XCTAssertFalse(clearWorked, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    int docsRemoved = [[col _removeWithQueries:@[@{@"name": @"carlos"}] andMarkDirty:NO exactMatch:YES error:&error] intValue];
    
    XCTAssertTrue(docsRemoved == 0, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    int docsReplaced = [[col replaceDocuments:@[@{@"name": @"carlos"}] andMarkDirty:NO error:&error] intValue];
    
    XCTAssertTrue(docsReplaced == 0, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    NSArray* findWithQueriesResult = [col findAllWithOptions:nil error:&error];
    
    XCTAssertNil(findWithQueriesResult, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    NSArray* findAllResult = [col findAllWithOptions:nil error:&error];
    
    XCTAssertNil(findAllResult, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    NSArray* findWithIdsResult = [col findWithIds:@[@1, @2] andOptions:nil error:&error];
    
    XCTAssertNil(findWithIdsResult, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    int countResult = [[col countAllDocumentsAndReturnError:&error] intValue];
    
    XCTAssertTrue(countResult == 0, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    JSONStoreQueryPart *cqp1 = [[JSONStoreQueryPart alloc] init];
    cqp1._equal = (NSMutableArray*) @[@{@"name" : @"carlos"}];
    
    int countQueryResult = [[col countWithQueryParts:@[cqp1] error:&error] intValue];
    
    XCTAssertTrue(countQueryResult == 0, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    int markCleanNumWorked = [[col markDocumentsClean:@[] error:&error] intValue];
    
    XCTAssertTrue(markCleanNumWorked == 0, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    NSArray* allDirtyResult = [col allDirtyAndReturnError:&error];
    
    XCTAssertNil(allDirtyResult, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    NSArray* allDirtyResultWithDocs = [col _allDirtyWithDocuments:@[] error:&error];
    
    XCTAssertNil(allDirtyResultWithDocs, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    BOOL isDirtyDocsRes = [col isDirtyWithDocumentId:1 error:&error];
    
    XCTAssertFalse(isDirtyDocsRes, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    int countAllDirtyResult = [[col countAllDirtyDocumentsWithError:&error] intValue];
    
    XCTAssertTrue(countAllDirtyResult == 0, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    BOOL numUpdatedOrAdded = [[col changeData:@[]
                          withReplaceCriteria:@[]
                                       addNew:NO
                                    markDirty:NO
                                        error:&error] intValue];
    
    XCTAssertTrue(numUpdatedOrAdded == 0, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    
    error = nil;
    
    BOOL startTransaction = [[JSONStore sharedInstance] startTransactionAndReturnError:&error];
    
    XCTAssertFalse(startTransaction, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    BOOL commitTransaction = [[JSONStore sharedInstance] commitTransactionAndReturnError:&error];
    
    XCTAssertFalse(commitTransaction, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
    error = nil;
    
    BOOL rollbackTransaction = [[JSONStore sharedInstance] rollbackTransactionAndReturnError:&error];
    
    XCTAssertFalse(rollbackTransaction, @"check operation failed");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"check db closed error code");
    
}

-(void) testOpenReturnValue
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"col1"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    [col1 setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreCollection* col2 = [[JSONStoreCollection alloc] initWithName:@"col2"];
    [col2 setSearchField:@"name2" withType:JSONStore_String];
    [col2 setSearchField:@"age2" withType:JSONStore_Integer];
    
    BOOL ret = [[JSONStore sharedInstance] openCollections:@[col1, col2] withOptions:nil error:nil];
    
    XCTAssertTrue(ret, @"should return true");
    XCTAssertFalse(col1.wasReopened, @"should be newly created, not re opened, col1");
    XCTAssertFalse(col2.wasReopened, @"should be newly created, not re opened, col2");
    
    JSONStoreCollection* col3 = [[JSONStoreCollection alloc] initWithName:@"col3"];
    [col3 setSearchField:@"name3" withType:JSONStore_String];
    [col3 setSearchField:@"age3" withType:JSONStore_Integer];
    
    BOOL ret2 = [[JSONStore sharedInstance] openCollections:@[col1, col2, col3] withOptions:nil error:nil];
    
    XCTAssertTrue(ret2, @"should return true");
    XCTAssertTrue(col1.wasReopened, @"should NOT be newly created, re opened, col1");
    XCTAssertTrue(col2.wasReopened, @"should NOT be newly created, re opened, col2");
    XCTAssertFalse(col3.wasReopened, @"should be newly created, not re opened, col3");
    
    BOOL ret3 = [[JSONStore sharedInstance] openCollections:@[] withOptions:nil error:nil];
    XCTAssertTrue(ret3, @"should return true");
    
    col3.searchFields = nil;
    col3 = [[JSONStoreCollection alloc] initWithName:@"col3"];
    [col3 setSearchField:@"name3" withType:JSONStore_Integer];
    NSError* error = nil;
    
    BOOL ret4 = [[JSONStore sharedInstance] openCollections:@[col3] withOptions:nil error:&error];
    
    XCTAssertFalse(ret4, @"should not work");
    XCTAssertTrue(error.code == -2, @"error code");
    
    BOOL ret5 = [[JSONStore sharedInstance] openCollections:nil withOptions:nil error:nil];
    XCTAssertTrue(ret5, @"should return true");
}

-(void) testAdvFind
{
    JSONStoreCollection* col1 = [[JSONStoreCollection alloc] initWithName:@"peoplez"];
    [col1 setSearchField:@"name" withType:JSONStore_String];
    [col1 setSearchField:@"greetings.language" withType:JSONStore_String];
    [col1 setSearchField:@"age" withType:JSONStore_Integer];
    
    [[JSONStore sharedInstance] openCollections:@[col1] withOptions:nil error:nil];
    
    NSDictionary* carlos = @{ @"name" : @"shin", @"age" : @99, @"greetings" : @[ @{@"language" : @"spanish", @"greet" : @"hola"}, @{@"language" : @"english", @"greet" : @"hey"}] };
    NSDictionary* dgonz = @{ @"name" : @"deta", @"age" : @9001 };
    
    int numAdded = [[col1 addData:@[carlos, dgonz]
                     andMarkDirty:NO
                      withOptions:nil
                            error:nil] intValue];
    
    XCTAssertEqual(numAdded, 2, @"Should add correct amount of docs");
    
    //Find All
    JSONStoreQueryPart* q0 = [[JSONStoreQueryPart alloc] init];
    
    NSArray* res0 = [col1 findWithQueryParts:@[q0] andOptions:nil error:nil];
    XCTAssertTrue([res0 count] == 2, @"found right amount of docs");
    
    NSArray* res01 = [col1 findWithQueryParts:@[] andOptions:nil error:nil];
    XCTAssertTrue([res01 count] == 2, @"found right amount of docs");
    
    NSArray* res02 = [col1 findWithQueryParts:nil andOptions:nil error:nil];
    XCTAssertTrue([res02 count] == 2, @"found right amount of docs");
    
    //Less than
    JSONStoreQueryPart* q1 = [[JSONStoreQueryPart alloc] init];
    [q1 searchField:@"age" lessThan:@100];
    
    NSArray* res1 = [col1 findWithQueryParts:@[q1] andOptions:nil error:nil];
    
    XCTAssertTrue([res1 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res1[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res1[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res1[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    
    //Less than with options filter
    JSONStoreQueryOptions* qops1 = [[JSONStoreQueryOptions alloc] init];
    [qops1 filterSearchField:@"name"];
    
    NSArray* res2 = [col1 findWithQueryParts:@[q1] andOptions:qops1 error:nil];
    
    XCTAssertTrue([res2 count] == 1, @"found right amount of docs");
    XCTAssertTrue([[res2[0] allKeys] count] == 1, @"right amount of keys");
    XCTAssertTrue([res2[0][@"name"] isEqualToString:@"shin"], @"check name");
    
    //Less than with options sort
    JSONStoreQueryOptions* qops2 = [[JSONStoreQueryOptions alloc] init];
    [qops2 sortBySearchFieldDescending:@"age"];
    
    JSONStoreQueryPart* q2 = [[JSONStoreQueryPart alloc] init];
    [q2 searchField:@"age" lessThan:@10000];
    
    NSArray* res3 = [col1 findWithQueryParts:@[q2] andOptions:qops2 error:nil];
    
    XCTAssertTrue([res3 count] == 2, @"found right amount of docs");
    XCTAssertTrue([res3[0][@"_id"] intValue] == 2, @"check _id");
    XCTAssertTrue([[res3[0] valueForKeyPath:@"json.name"] isEqualToString:@"deta"], @"check name");
    XCTAssertTrue([[res3[0] valueForKeyPath:@"json.age"] intValue] == 9001, @"check age");
    XCTAssertTrue([res3[1][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res3[1] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res3[1] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    
    //Less than with options limit
    JSONStoreQueryOptions* qops3 = [[JSONStoreQueryOptions alloc] init];
    [qops3 setLimit:@1];
    
    JSONStoreQueryPart* q3 = [[JSONStoreQueryPart alloc] init];
    [q3 searchField:@"age" lessThan:@9002];
    
    NSArray* res4 = [col1 findWithQueryParts:@[q3] andOptions:qops3 error:nil];
    
    XCTAssertTrue([res4 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res4[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res4[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res4[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    
    //Less than with options limit and offset
    JSONStoreQueryOptions* qops4 = [[JSONStoreQueryOptions alloc] init];
    [qops4 setLimit:@1];
    [qops4 setOffset:@1];
    
    JSONStoreQueryPart* q4 = [[JSONStoreQueryPart alloc] init];
    [q4 searchField:@"age" lessThan:@9002];
    
    NSArray* res5 = [col1 findWithQueryParts:@[q4] andOptions:qops4 error:nil];
    
    XCTAssertTrue([res5 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res5[0][@"_id"] intValue] == 2, @"check _id");
    XCTAssertTrue([[res5[0] valueForKeyPath:@"json.name"] isEqualToString:@"deta"], @"check name");
    XCTAssertTrue([[res5[0] valueForKeyPath:@"json.age"] intValue] == 9001, @"check age");
    
    //Less or Equal than
    JSONStoreQueryPart* q5 = [[JSONStoreQueryPart alloc] init];
    [q5 searchField:@"age" lessOrEqualThan:@9001];
    
    NSArray* res6 = [col1 findWithQueryParts:@[q4] andOptions:qops4 error:nil];
    
    XCTAssertTrue([res6 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res6[0][@"_id"] intValue] == 2, @"check _id");
    XCTAssertTrue([[res6[0] valueForKeyPath:@"json.name"] isEqualToString:@"deta"], @"check name");
    XCTAssertTrue([[res6[0] valueForKeyPath:@"json.age"] intValue] == 9001, @"check age");
    
    //Greater than
    JSONStoreQueryPart* q6 = [[JSONStoreQueryPart alloc] init];
    [q6 searchField:@"age" greaterThan:@9000];
    
    NSArray* res7 = [col1 findWithQueryParts:@[q6] andOptions:nil error:nil];
    
    XCTAssertTrue([res7 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res7[0][@"_id"] intValue] == 2, @"check _id");
    XCTAssertTrue([[res7[0] valueForKeyPath:@"json.name"] isEqualToString:@"deta"], @"check name");
    XCTAssertTrue([[res7[0] valueForKeyPath:@"json.age"] intValue] == 9001, @"check age");
    
    //Greater or equal than
    JSONStoreQueryPart* q7 = [[JSONStoreQueryPart alloc] init];
    [q7 searchField:@"age" greaterOrEqualThan:@9001];
    
    NSArray* res8 = [col1 findWithQueryParts:@[q7] andOptions:nil error:nil];
    
    XCTAssertTrue([res8 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res8[0][@"_id"] intValue] == 2, @"check _id");
    XCTAssertTrue([[res8[0] valueForKeyPath:@"json.name"] isEqualToString:@"deta"], @"check name");
    XCTAssertTrue([[res8[0] valueForKeyPath:@"json.age"] intValue] == 9001, @"check age");
    
    //Between
    JSONStoreQueryPart* q8 = [[JSONStoreQueryPart alloc] init];
    [q8 searchField:@"age" between:@50 and:@100];
    
    NSArray* res9 = [col1 findWithQueryParts:@[q8] andOptions:nil error:nil];
    
    XCTAssertTrue([res9 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res9[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res9[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res9[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    
    //Like
    JSONStoreQueryPart* q9 = [[JSONStoreQueryPart alloc] init];
    [q9 searchField:@"name" like:@"in"];
    
    NSArray* res10 = [col1 findWithQueryParts:@[q9] andOptions:nil error:nil];
    
    XCTAssertTrue([res10 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res10[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res10[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res10[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    
    //Right Like
    JSONStoreQueryPart* q10 = [[JSONStoreQueryPart alloc] init];
    [q10 searchField:@"name" rightLike:@"sh"];
    
    NSArray* res11 = [col1 findWithQueryParts:@[q10] andOptions:nil error:nil];
    
    XCTAssertTrue([res11 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res11[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res11[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res11[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    
    //Right Like 2
    JSONStoreQueryPart* q11 = [[JSONStoreQueryPart alloc] init];
    [q11 searchField:@"name" rightLike:@"in"];
    
    NSArray* res12 = [col1 findWithQueryParts:@[q11] andOptions:nil error:nil];
    
    XCTAssertTrue([res12 count] == 0, @"found right amount of docs");
    
    //Left Like
    JSONStoreQueryPart* q12 = [[JSONStoreQueryPart alloc] init];
    [q12 searchField:@"name" leftLike:@"in"];
    
    NSArray* res13 = [col1 findWithQueryParts:@[q12] andOptions:nil error:nil];
    
    XCTAssertTrue([res13 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res13[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res13[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res13[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    
    //Left Like 2
    JSONStoreQueryPart* q13 = [[JSONStoreQueryPart alloc] init];
    [q13 searchField:@"name" leftLike:@"sh"];
    
    NSArray* res14 = [col1 findWithQueryParts:@[q13] andOptions:nil error:nil];
    
    XCTAssertTrue([res14 count] == 0, @"found right amount of docs");
    
    //Equal
    JSONStoreQueryPart* q14 = [[JSONStoreQueryPart alloc] init];
    [q14 searchField:@"name" equal:@"shin"];
    
    NSArray* res15 = [col1 findWithQueryParts:@[q14] andOptions:nil error:nil];
    
    XCTAssertTrue([res15 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res15[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res15[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res15[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    
    //Equal 2
    JSONStoreQueryPart* q15 = [[JSONStoreQueryPart alloc] init];
    [q15 searchField:@"name" equal:@"hin"];
    
    NSArray* res16 = [col1 findWithQueryParts:@[q15] andOptions:nil error:nil];
    
    XCTAssertTrue([res16 count] == 0, @"found right amount of docs");
    
    //Not Equal
    JSONStoreQueryPart* q16 = [[JSONStoreQueryPart alloc] init];
    [q16 searchField:@"name" notEqual:@"deta"];
    
    NSArray* res17 = [col1 findWithQueryParts:@[q16] andOptions:nil error:nil];
    
    XCTAssertTrue([res17 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res17[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res17[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res17[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    
    //Not Equal 2
    JSONStoreQueryPart* q18 = [[JSONStoreQueryPart alloc] init];
    [q18 searchField:@"name" notEqual:@"kenshin"];
    
    NSArray* res19 = [col1 findWithQueryParts:@[q18] andOptions:nil error:nil];
    
    XCTAssertTrue([res19 count] == 2, @"found right amount of docs");
    
    //Not Equal 3
    JSONStoreQueryPart* q20 = [[JSONStoreQueryPart alloc] init];
    [q20 searchField:@"greetings.language" notEqual:@"spanish"];
    
    NSArray* res20 = [col1 findWithQueryParts:@[q20] andOptions:nil error:nil];
    
    XCTAssertTrue([res20 count] == 1, @"found right amount of docs");
    
    //Not Equal 4
    JSONStoreQueryPart* q21 = [[JSONStoreQueryPart alloc] init];
    [q21 searchField:@"greetings.language" notEqual:@"spanis"];
    
    NSArray* res21 = [col1 findWithQueryParts:@[q21] andOptions:nil error:nil];
    
    XCTAssertTrue([res21 count] == 2, @"found right amount of docs");
    
    //in
    JSONStoreQueryPart* q22 = [[JSONStoreQueryPart alloc] init];
    [q22 searchField:@"name" insideValues:@[@"shin", @"deta", @"test"]];
    
    NSArray* res22 = [col1 findWithQueryParts:@[q22] andOptions:nil error:nil];
    
    XCTAssertTrue([res22 count] == 2, @"found right amount of docs");
    XCTAssertTrue([res22[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res22[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res22[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    XCTAssertTrue([res22[1][@"_id"] intValue] == 2, @"check _id");
    XCTAssertTrue([[res22[1] valueForKeyPath:@"json.name"] isEqualToString:@"deta"], @"check name");
    XCTAssertTrue([[res22[1] valueForKeyPath:@"json.age"] intValue] == 9001, @"check age");
    
    //Long query 1
    JSONStoreQueryPart* q23a = [[JSONStoreQueryPart alloc] init];
    [q23a searchField:@"age" lessThan:@100];
    
    JSONStoreQueryPart* q23b = [[JSONStoreQueryPart alloc] init];
    [q23b searchField:@"age" greaterOrEqualThan:@9001];
    
    NSArray* res23 = [col1 findWithQueryParts:@[q23a, q23b] andOptions:nil error:nil];
    
    XCTAssertTrue([res23 count] == 2, @"found right amount of docs");
    XCTAssertTrue([res23[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res23[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res23[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    XCTAssertTrue([res23[1][@"_id"] intValue] == 2, @"check _id");
    XCTAssertTrue([[res23[1] valueForKeyPath:@"json.name"] isEqualToString:@"deta"], @"check name");
    XCTAssertTrue([[res23[1] valueForKeyPath:@"json.age"] intValue] == 9001, @"check age");
    
    //Long query 2
    JSONStoreQueryPart* q24a = [[JSONStoreQueryPart alloc] init];
    [q24a searchField:@"age" lessThan:@100];
    [q24a searchField:@"name" equal:@"shin"];
    
    JSONStoreQueryPart* q24b = [[JSONStoreQueryPart alloc] init];
    [q24b searchField:@"age" greaterOrEqualThan:@9001];
    [q24b searchField:@"name" notEqual:@"YOLO"];
    
    JSONStoreQueryOptions* qops24 = [[JSONStoreQueryOptions alloc] init];
    [qops24 setLimit:@2];
    [qops24 filterSearchField:@"_id"];
    [qops24 filterSearchField:@"json"];
    [qops24 sortBySearchFieldAscending:@"age"];
    
    /*
     select [_id], [json]
     
     from 'peoplez'
     
     
     where
     [age] < 100
     AND
     ( [name] = 'shin' OR [name] LIKE '%-@-shin-@-%' OR [name] LIKE '%-@-shin' OR [name] LIKE 'shin-@-%' )
     
     -----------------
     OR
     -----------------
     
     [age] >= 9001
     AND
     ( [name] != 'YOLO' AND [name] NOT LIKE '%-@-YOLO-@-%' AND [name] NOT LIKE '%-@-YOLO' AND [name] NOT LIKE 'YOLO-@-%' )
     
     
     ORDER BY [age] ASC
     
     LIMIT 2.000000
     */
    
    NSArray* res24 = [col1 findWithQueryParts:@[q24a, q24b] andOptions:qops24 error:nil];
    
    XCTAssertTrue([res24 count] == 2, @"found right amount of docs");
    XCTAssertTrue([res24[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res24[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res24[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    XCTAssertTrue([res24[1][@"_id"] intValue] == 2, @"check _id");
    XCTAssertTrue([[res24[1] valueForKeyPath:@"json.name"] isEqualToString:@"deta"], @"check name");
    XCTAssertTrue([[res24[1] valueForKeyPath:@"json.age"] intValue] == 9001, @"check age");
    
    
    //not in
    JSONStoreQueryPart* q25 = [[JSONStoreQueryPart alloc] init];
    [q25 searchField:@"name" notInsideValues:@[@"shi", @"hello", @"test"]];
    
    NSArray* res25 = [col1 findWithQueryParts:@[q25] andOptions:nil error:nil];
    
    XCTAssertTrue([res25 count] == 2, @"found right amount of docs");
    XCTAssertTrue([res25[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res25[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res25[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    XCTAssertTrue([res25[1][@"_id"] intValue] == 2, @"check _id");
    XCTAssertTrue([[res25[1] valueForKeyPath:@"json.name"] isEqualToString:@"deta"], @"check name");
    XCTAssertTrue([[res25[1] valueForKeyPath:@"json.age"] intValue] == 9001, @"check age");
    
    //not in with empty array
    JSONStoreQueryPart* q26 = [[JSONStoreQueryPart alloc] init];
    [q26 searchField:@"name" notInsideValues:@[]];
    
    NSArray* res26 = [col1 findWithQueryParts:@[q26] andOptions:nil error:nil];
    
    XCTAssertTrue([res26 count] == 2, @"found right amount of docs");
    XCTAssertTrue([res26[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res26[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res26[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    XCTAssertTrue([res26[1][@"_id"] intValue] == 2, @"check _id");
    XCTAssertTrue([[res26[1] valueForKeyPath:@"json.name"] isEqualToString:@"deta"], @"check name");
    XCTAssertTrue([[res26[1] valueForKeyPath:@"json.age"] intValue] == 9001, @"check age");
    
    //in with empty array
    JSONStoreQueryPart* q27 = [[JSONStoreQueryPart alloc] init];
    [q27 searchField:@"name" insideValues:@[]];
    
    NSArray* res27 = [col1 findWithQueryParts:@[q27] andOptions:nil error:nil];
    
    XCTAssertTrue([res27 count] == 0, @"found right amount of docs");
    
    //Not Between
    JSONStoreQueryPart* q28 = [[JSONStoreQueryPart alloc] init];
    [q28 searchField:@"age" notBetween:@8000 and:@10000];
    
    NSArray* res28 = [col1 findWithQueryParts:@[q28] andOptions:nil error:nil];
    
    XCTAssertTrue([res28 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res28[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res28[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res28[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    
    //Not Like
    JSONStoreQueryPart* q29 = [[JSONStoreQueryPart alloc] init];
    [q29 searchField:@"name" notLike:@"deta"];
    
    NSArray* res29 = [col1 findWithQueryParts:@[q29] andOptions:nil error:nil];
    
    XCTAssertTrue([res29 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res29[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res29[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res29[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    
    //Not Right Like
    JSONStoreQueryPart* q30 = [[JSONStoreQueryPart alloc] init];
    [q30 searchField:@"name" notRightLike:@"de"];
    
    NSArray* res30 = [col1 findWithQueryParts:@[q30] andOptions:nil error:nil];
    
    XCTAssertTrue([res30 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res30[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res30[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res30[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    
    //Not Left Like
    JSONStoreQueryPart* q31 = [[JSONStoreQueryPart alloc] init];
    [q31 searchField:@"name" notLeftLike:@"eta"];
    
    NSArray* res31 = [col1 findWithQueryParts:@[q31] andOptions:nil error:nil];
    
    XCTAssertTrue([res31 count] == 1, @"found right amount of docs");
    XCTAssertTrue([res31[0][@"_id"] intValue] == 1, @"check _id");
    XCTAssertTrue([[res31[0] valueForKeyPath:@"json.name"] isEqualToString:@"shin"], @"check name");
    XCTAssertTrue([[res31[0] valueForKeyPath:@"json.age"] intValue] == 99, @"check age");
    
}

-(void) testGettingStartedInit
{
    
    //-----------------------START
    
    //Create the collections object that will be initialized
    JSONStoreCollection* people = [[JSONStoreCollection alloc] initWithName:@"people"];
    [people setSearchField:@"name" withType:JSONStore_String];
    [people setSearchField:@"age" withType:JSONStore_Integer];
    
    //Optional options object
    JSONStoreOpenOptions* options = [JSONStoreOpenOptions new];
    [options setUsername:@"hayatashin"]; //Optional username, default 'jsonstore'
    
    //This will point to an error if one occurs
    NSError* error = nil;
    
    //Open the collections
    [[JSONStore sharedInstance] openCollections:@[people] withOptions:options error:&error];
    
    //Add data to the collection
    NSArray* data = @[ @{@"name" : @"shin", @"age": @10} ];
    int newDocsAdded = [[people addData:data andMarkDirty:YES withOptions:nil error:&error] intValue];
    
    //-----------------------END
    
    XCTAssertTrue(newDocsAdded == 1, @"add return value check");
    XCTAssertTrue([[people countAllDocumentsAndReturnError:nil] intValue] == 1, @"count check");
}

-(void) testGettingStartedFind
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"kenshin"];
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:nil];
    
    NSArray* data = @[ @{@"name" : @"shu", @"age": @10} ];
    [ppl addData:data andMarkDirty:YES withOptions:nil error:nil];
    
    //-----------------------START
    
    //Get the accessor to an already initialized collection
    JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];
    
    //This will point to an error if one occurs
    NSError* error = nil;
    
    //Add additional find options (optional)
    JSONStoreQueryOptions* options = [JSONStoreQueryOptions new];
    [options setLimit:@10]; //Returns a maximum of 10 documents, default no limit
    [options setOffset:@0]; //Skip 0 documents, default no offset
    
    //Search fields to return, default: ['_id', 'json']
    [options filterSearchField:@"_id"];
    [options filterSearchField:@"json"];
    
    //How to sort the values returned, default no sort
    [options sortBySearchFieldAscending:@"name"];
    [options sortBySearchFieldDescending:@"age"];
    
    //Find all documents that match the query part
    JSONStoreQueryPart* queryPart1 = [[JSONStoreQueryPart alloc] init];
    [queryPart1 searchField:@"name" equal:@"shu"];
    [queryPart1 searchField:@"age" lessOrEqualThan:@10];
    
    NSArray* results = [people findWithQueryParts:@[queryPart1] andOptions:options error:&error];
    
    for (NSDictionary* result in results) {
        
        NSString* name = [result valueForKeyPath:@"json.name"]; //carlos
        int age = [[result valueForKeyPath:@"json.age"] intValue]; //10
        
        NSLog(@"Name: %@, Age: %d", name, age);
    }
    
    //-----------------------END
    
    XCTAssertTrue([[people countAllDocumentsAndReturnError:nil] intValue] == 1, @"count check");
    XCTAssertTrue([[results[0] valueForKeyPath:@"json.name"] isEqualToString:@"shu"], @"name check");
    XCTAssertTrue([[results[0] valueForKeyPath:@"json.age"] integerValue] == 10, @"age check");
}

-(void) testGettingStartedReplace
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"kyo"];
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:nil];
    
    NSArray* data = @[ @{@"name" : @"kagetsu", @"age": @10} ];
    [ppl addData:data andMarkDirty:YES withOptions:nil error:nil];
    
    //-----------------------START
    
    //Get the accessor to an already initialized collection
    JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];
    
    //Find all documents that match the queries
    NSArray* docs = @[ @{@"_id" : @1, @"json" : @{ @"name": @"kagetsu", @"age" : @99}} ];
    
    //This will point to an error if one occurs
    NSError* error = nil;
    
    //Perform the replacement
    int docsReplaced = [[people replaceDocuments:docs andMarkDirty:NO error:&error] intValue];
    
    //-----------------------END
    
    NSArray* results = [people findAllWithOptions:nil error:nil];
    
    XCTAssertTrue(docsReplaced == 1, @"docs replaced check");
    XCTAssertTrue([[people countAllDocumentsAndReturnError:nil] intValue] == 1, @"count check");
    XCTAssertTrue([[results[0] valueForKeyPath:@"json.name"] isEqualToString:@"kagetsu"], @"name check");
    XCTAssertTrue([[results[0] valueForKeyPath:@"json.age"] integerValue] == 99, @"age check");
}

-(void) testGettingStartedRemove
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"jin"];
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:nil];
    
    NSArray* data = @[ @{@"name" : @"kazuma", @"age": @10} ];
    [ppl addData:data andMarkDirty:YES withOptions:nil error:nil];
    
    //-----------------------START
    
    //Get the accessor to an already initialized collection
    JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];
    
    //This will point to an error if one occurs
    NSError* error = nil;
    
    //Find document with _id equal to 1 and remove it
    int docsRemoved = [[people removeWithIds:@[@1] andMarkDirty:NO error:&error] intValue];
    
    //-----------------------END
    
    NSArray* results = [people findAllWithOptions:nil error:nil];
    
    XCTAssertTrue(docsRemoved == 1, @"docs replaced check");
    XCTAssertTrue([[people countAllDocumentsAndReturnError:nil] intValue] == 0, @"count check");
    XCTAssertTrue([results count] == 0, @"check find result");
}

-(void) testGettingStartedCount
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"akia"];
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:nil];
    
    NSArray* data = @[ @{@"name" : @"mojo", @"age": @10} ];
    [ppl addData:data andMarkDirty:YES withOptions:nil error:nil];
    
    //-----------------------START
    
    //Get the accessor to an already initialized collection
    JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];
    
    //Count all documents that match the query.
    //The default query is @{} which will
    //count every document in the collection.
    JSONStoreQueryPart *queryPart = [[JSONStoreQueryPart alloc] init];
    [queryPart searchField:@"name" equal:@"mojo"];
    
    //This will point to an error if one occurs
    NSError* error = nil;
    
    //Perform the count
    int countResult = [[people countWithQueryParts:@[queryPart] error:&error] intValue];
    
    //-----------------------END
    
    NSArray* results = [people findAllWithOptions:nil error:nil];
    
    XCTAssertTrue(countResult == 1, @"docs replaced check");
    XCTAssertTrue([[people countAllDocumentsAndReturnError:nil] intValue] == 1, @"count check");
    XCTAssertTrue([results count] == 1, @"check find result");
}

-(void) testGettingStartedDestroy
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"shin"];
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:nil];
    
    NSArray* data = @[ @{@"name" : @"deta", @"age": @10} ];
    [ppl addData:data andMarkDirty:YES withOptions:nil error:nil];
    
    //-----------------------START
    
    //This will point to an error if one occurs
    NSError* error = nil;
    
    //Perform the destroy
    [[JSONStore sharedInstance] destroyDataAndReturnError:&error];
    
    //-----------------------END
    
    XCTAssertNil(error, @"check error obj");
    
    error = nil;
    NSArray* results = [ppl findAllWithOptions:nil error:&error];
    
    XCTAssertNil(results, @"check closed return value");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"error code check");
}

-(void) testGettingStartedCloseAll
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"akirasaito"];
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:nil];
    
    NSArray* data = @[ @{@"name" : @"shinbatsu", @"age": @10} ];
    [ppl addData:data andMarkDirty:YES withOptions:nil error:nil];
    
    //-----------------------START
    
    //This will point to an error if one occurs
    NSError* error = nil;
    
    //Close access to all collections in the store
    [[JSONStore sharedInstance] closeAllCollectionsAndReturnError:&error];
    
    //-----------------------END
    
    XCTAssertNil(error, @"check error obj");
    
    error = nil;
    NSArray* results = [ppl findAllWithOptions:nil error:&error];
    
    XCTAssertNil(results, @"check closed return value");
    XCTAssertTrue(error.code == JSON_STORE_DATABASE_NOT_OPEN, @"error code check");
}


-(void) testGettingStartedPush
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"hayatashin"];
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:nil];
    
    NSArray* data = @[ @{@"name" : @"shin", @"age": @10} ];
    [ppl addData:data andMarkDirty:YES withOptions:nil error:nil];
    
    //-----------------------START
    
    //Get the accessor to an already initialized collection
    JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];
    
    //This will point to an error if one occurs
    NSError* error = nil;
    
    //Return all documents marked dirty
    NSArray* dirtyDocs = [people allDirtyAndReturnError:&error];
    
    //ACTION REQUIRED: Handle the dirty documents here (e.g. send them to a server)
    
    //Mark dirty documents as clean
    int numCleaned = [[people markDocumentsClean:dirtyDocs error:&error] intValue];
    
    //-----------------------END
    
    XCTAssertNil(error, @"check error obj");
    
    XCTAssertTrue([dirtyDocs count] == 1, @"check dirty count");
    XCTAssertTrue(numCleaned == 1, @"check clean count");
    XCTAssertTrue([[people allDirtyAndReturnError:nil] count] == 0, @"all dirty check");
    XCTAssertTrue([[people countAllDirtyDocumentsWithError:nil] intValue] == 0, @"all dirty count check");
}

-(void) testGettingStartedPull
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"id" withType:JSONStore_Integer];
    [ppl setSearchField:@"ssn" withType:JSONStore_String];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"shin"];
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:nil];
    
    NSArray* d = @[ @{@"id" : @1, @"ssn": @"111-22-3333", @"name": @"hayata"} ];
    [ppl addData:d andMarkDirty:NO withOptions:nil error:nil];
    
    //-----------------------START
    
    //Get the accessor to an already initialized collection
    JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];
    
    //This will point to an error if one occurs
    NSError* error = nil;
    
    //ACTION REQUIRED: Get data from server. For this example, it is hardcoded.
    NSArray* data = @[ @{@"id" : @1, @"ssn": @"111-22-3333", @"name": @"hayata"} ];
    
    int numChanged = [[people changeData:data withReplaceCriteria:@[@"id", @"ssn"] addNew:YES markDirty:NO error:&error] intValue];
    
    //-----------------------END
    
    XCTAssertNil(error, @"check error obj");
    XCTAssertTrue(numChanged == 1, @"check change");
    XCTAssertTrue([[people countAllDirtyDocumentsWithError:nil] intValue] == 0, @"all dirty count check");
    XCTAssertTrue([[people countAllDocumentsAndReturnError:nil] intValue] == 1, @"count all check");
    
    NSArray* results = [ppl findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([results count] == 1, @"count check");
    XCTAssertTrue([[results[0] valueForKeyPath:@"json.id"] integerValue] == 1, @"name check");
    XCTAssertTrue([[results[0] valueForKeyPath:@"json.name"] isEqualToString:@"hayata"], @"name check");
    XCTAssertTrue([[results[0] valueForKeyPath:@"json.ssn"]  isEqualToString:@"111-22-3333"], @"age check");
}

-(void) testGettingStartedIsDirty
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"kenshin"];
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:nil];
    
    NSArray* d = @[ @{@"id" : @1, @"ssn": @"111-22-3333", @"name": @"shin"} ];
    [ppl addData:d andMarkDirty:YES withOptions:nil error:nil];
    
    //-----------------------START
    
    //Get the accessor to an already initialized collection
    JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];
    
    //This will point to an error if one occurs
    NSError* error = nil;
    
    //Check if document with _id '1' is dirty
    BOOL isDirtyResult = [people isDirtyWithDocumentId:1 error:&error];
    
    //-----------------------END
    
    XCTAssertNil(error, @"check error obj");
    XCTAssertTrue(isDirtyResult, @"check isdirty result");
    XCTAssertTrue([[people countAllDirtyDocumentsWithError:nil] intValue] == 1, @"all dirty count check");
    XCTAssertTrue([[people countAllDocumentsAndReturnError:nil] intValue] == 1, @"count all check");
}

-(void) testGettingStartedAllDirtyCount
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:nil];
    
    NSArray* d = @[ @{@"id" : @1, @"ssn": @"111-22-3333", @"name": @"deta"} ];
    [ppl addData:d andMarkDirty:NO withOptions:nil error:nil];
    
    //-----------------------START
    
    //Get the accessor to an already initialized collection
    JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];
    
    //This will point to an error if one occurs
    NSError* error = nil;
    
    //Check if document with _id '1' is dirty
    int dirtyDocsCount = [[people countAllDirtyDocumentsWithError:&error] intValue];
    
    //-----------------------END
    
    XCTAssertNil(error, @"check error obj");
    XCTAssertTrue(dirtyDocsCount == 0, @"check dirty count result");
    XCTAssertTrue([[people countAllDirtyDocumentsWithError:nil] intValue] == 0, @"all dirty count check");
    XCTAssertTrue([[people countAllDocumentsAndReturnError:nil] intValue] == 1, @"count all check");
}

-(void) testGettingStartedRemoveCollection
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"rin"];
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:nil];
    
    NSArray* d = @[ @{@"age" : @10, @"name": @"santaru"} ];
    [ppl addData:d andMarkDirty:NO withOptions:nil error:nil];
    
    //-----------------------START
    
    //Get the accessor to an already initialized collection
    JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];
    
    //This will point to an error if one occurs
    NSError* error = nil;
    
    //Remove the collection
    [people removeCollectionWithError:&error];
    
    //-----------------------END
    
    XCTAssertNil(error, @"check error obj");
    XCTAssertNil([[JSONStore sharedInstance] getCollectionWithName:@"people"], @"check accessor");
    
    error = nil;
    NSArray* results = [ppl findAllWithOptions:nil error:&error];
    
    XCTAssertNil(results, @"check closed return value");
    XCTAssertTrue(error.code == JSON_STORE_INVALID_SEARCH_FIELD, @"error code check");
}

-(void) testGettingStartedClear
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"masao"];
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:nil];
    
    NSArray* d = @[ @{@"age" : @10, @"name": @"aiko"} ];
    [ppl addData:d andMarkDirty:NO withOptions:nil error:nil];
    
    //-----------------------START
    
    //Get the accessor to an already initialized collection
    JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];
    
    //This will point to an error if one occurs
    NSError* error = nil;
    
    //Remove the collection
    [people clearCollectionWithError:&error];
    
    //-----------------------END
    
    XCTAssertNil(error, @"check error obj");
    XCTAssertNotNil([[JSONStore sharedInstance] getCollectionWithName:@"people"], @"check accessor");
    
    error = nil;
    NSArray* results = [ppl findAllWithOptions:nil error:&error];
    
    XCTAssertNotNil(results, @"check closed return value");
    XCTAssertNil(error, @"error code check");
    
    XCTAssertTrue([results count] == 0, @"check find all count");
}

-(void) testGettingStartedTransactions
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"shin"];

    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:nil];
    
    NSArray* d = @[ @{@"age" : @10, @"name": @"hayatashin"} ];
    [ppl addData:d andMarkDirty:NO withOptions:nil error:nil];
    
    //-----------------------START
    
    //Get the accessor to an already initialized collection
    JSONStoreCollection* people = [[JSONStore sharedInstance] getCollectionWithName:@"people"];
    
    //These will point to errors if they occur
    NSError* error = nil;
    NSError* addError = nil;
    NSError* removeError = nil;
    
    //You can call every JSONStore API method inside a transaction except: open, destroy, removeCollection and closeAll
    [[JSONStore sharedInstance] startTransactionAndReturnError:&error];
    
    [people addData:@[ @{@"name" : @"shin"} ] andMarkDirty:NO withOptions:nil error:&addError];
    
    [people removeWithIds:@[@1] andMarkDirty:NO error:&removeError];
    
    if (addError != nil || removeError != nil) {
        
        //Return the store to the state before start transaction was called
        [[JSONStore sharedInstance] rollbackTransactionAndReturnError:&error];
        
    } else {
        
        //Commit the transaction thus ensuring atomicity
        [[JSONStore sharedInstance] commitTransactionAndReturnError:&error];
    }
    
    //-----------------------END
    
    XCTAssertNil(error, @"check error obj");
    XCTAssertNil(addError, @"check error obj");
    XCTAssertNil(removeError, @"check error obj");
    
    XCTAssertFalse([[JSONStore sharedInstance] _isTransactionInProgress], @"check _isTransactionInProgress");
    
    error = nil;
    NSArray* results = [ppl findAllWithOptions:nil error:&error];
    
    XCTAssertNotNil(results, @"check closed return value");
    XCTAssertNil(error, @"error code check");
    
    XCTAssertTrue([results count] == 1, @"check find all count");
}

-(void) testGettingStartedFileInfo
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"shu"];
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:nil];
    
    NSArray* d = @[ @{@"age" : @10, @"name": @"ango"} ];
    [ppl addData:d andMarkDirty:NO withOptions:nil error:nil];
    
    //-----------------------START
    
    //This will point to an error if one occurs
    NSError* error = nil;
    
    //Returns information about files JSONStore uses to persist data
    NSArray* results = [[JSONStore sharedInstance] fileInfoAndReturnError:&error];
    // => [{@"name" : @"carlos", @"size" : @3072}]
    
    //-----------------------END
    
    XCTAssertNil(error, @"check error obj");
    
    XCTAssertTrue([results count] == 1, @"check find all count");
    XCTAssertNotNil(results[0][@"size"], @"size");
    XCTAssertNotNil(results[0][@"name"], @"name");
}

-(void) testFileInfo
{
    NSArray* results0 = [[JSONStore sharedInstance] fileInfoAndReturnError:nil];
    
    XCTAssertEqualObjects(results0, @[], @"");
    
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"carlos"];
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:nil];
    
    NSArray* d = @[ @{@"age" : @10, @"name": @"carlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitoscarlitos"} ];
    int addResult = [[ppl addData:d andMarkDirty:NO withOptions:nil error:nil] intValue];
    
    XCTAssertTrue(addResult == 1, @"add check");
    
    [[JSONStore sharedInstance] closeAllCollectionsAndReturnError:nil];
    
    JSONStoreCollection* otherppl = [[JSONStoreCollection alloc] initWithName:@"otherpeople"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"num" withType:JSONStore_Number];
    
    JSONStoreOpenOptions* ops2 = [[JSONStoreOpenOptions alloc] init];
    
    [[JSONStore sharedInstance] openCollections:@[otherppl] withOptions:ops2 error:nil];
    
    NSArray* results = [[JSONStore sharedInstance] fileInfoAndReturnError:nil];
    
    //First store
    
    XCTAssertTrue([[results objectAtIndex:0][JSON_STORE_KEY_FILE_NAME] isEqualToString:@"carlos"], @"check file name");
    
    int size = [[results objectAtIndex:0][JSON_STORE_KEY_FILE_SIZE] intValue];
    
    XCTAssertTrue(size < 30000 && size > 18000, @"check size");
    
    //Second store
    
    XCTAssertTrue([[results objectAtIndex:1][JSON_STORE_KEY_FILE_NAME] isEqualToString:@"jsonstore"], @"check file name");
    
    int size2 = [[results objectAtIndex:1][JSON_STORE_KEY_FILE_SIZE] intValue];
    
    XCTAssertTrue(size2 < 15000 && size2 > 10000, @"check size");
}

-(void) testRemoveWithIds
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"ppl"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:nil error:nil];
    
    NSArray* d = @[ @{@"age" : @10, @"name": @"mike"},
                    @{@"age" : @11, @"name": @"carlitos"},
                    @{@"age" : @10, @"name": @"dgonz"} ];
    
    NSNumber* docsAdded = [ppl addData:d andMarkDirty:NO withOptions:nil error:nil];
    
    XCTAssertTrue([docsAdded intValue] == 3, @"add");
    
    NSArray* results = [ppl findAllWithOptions:nil error:nil];
    
    XCTAssertTrue(results.count == 3, @"findAll");
    
    XCTAssertEqualObjects([results[0] valueForKeyPath:@"json.name"], @"mike", @"name1");
    XCTAssertEqualObjects([results[1] valueForKeyPath:@"json.name"], @"carlitos", @"name3");
    XCTAssertEqualObjects([results[2] valueForKeyPath:@"json.name"], @"dgonz", @"name2");
    
    NSArray* ids = @[@1,@2];
    
    NSNumber* numRemoved = [ppl removeWithIds:ids andMarkDirty:YES error:nil];
    
    XCTAssertTrue([numRemoved intValue] == 2, @"remove with ids");
    
    NSArray* results2 = [ppl findAllWithOptions:nil error:nil];
    
    XCTAssertTrue(results2.count == 1, @"findall 2");
    
    XCTAssertEqualObjects([results2[0] valueForKeyPath:@"json.name"], @"dgonz", @"name1");
    
    NSArray* dirtyDocs = [ppl allDirtyAndReturnError:nil];
    
    XCTAssertTrue(dirtyDocs.count == 2, @"dirty count 2");
    
    XCTAssertEqualObjects([dirtyDocs[0] valueForKeyPath:@"json.name"], @"mike", @"name1");
    XCTAssertEqualObjects([dirtyDocs[1] valueForKeyPath:@"json.name"], @"carlitos", @"name1");
}


-(void) testDestroyWithUsernameOpenCollection
{
    //First store - open
    
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"carlos"];
    
    NSError* err = nil;
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:&err];
    XCTAssertNil(err, @"no error from open - carlos");
    
    //First store - add
    
    err = nil;
    int added = [[ppl addData:@[@{@"name" : @"carlos"}] andMarkDirty:NO withOptions:nil error:&err] intValue];
    XCTAssertNil(err, @"no error from add - carlos");
    XCTAssertTrue(added == 1, @"added one");
    
    //Close all
    
    err = nil;
    [[JSONStore sharedInstance] closeAllCollectionsAndReturnError:&err];
    XCTAssertNil(err, @"no error from closeAll - carlos");
    
    //Second store - open
    
    JSONStoreCollection* orders = [[JSONStoreCollection alloc] initWithName:@"orders"];
    [orders setSearchField:@"item" withType:JSONStore_String];
    [orders setSearchField:@"num" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops2 = [[JSONStoreOpenOptions alloc] init];
    [ops2 setUsername:@"mike"];
    
    err = nil;
    [[JSONStore sharedInstance] openCollections:@[orders] withOptions:ops2 error:&err];
    XCTAssertNil(err, @"no error from open - mike");
    
    //Second store - add
    
    err = nil;
    int added2 = [[orders addData:@[@{@"item" : @"yolo"}] andMarkDirty:NO withOptions:nil error:&err] intValue];
    XCTAssertNil(err, @"no error from add - carlos");
    XCTAssertTrue(added2 == 1, @"added one");
    
    //Destroy with username
    
    err = nil;
    BOOL worked = [[JSONStore sharedInstance] destroyWithUsername:@"mike" error:&err];
    XCTAssertNil(err, @"no error from destroy with username - mike");
    XCTAssertTrue(worked, @"should work");
    
    //File Info
    
    err = nil;
    NSArray* res = [[JSONStore sharedInstance] fileInfoAndReturnError:&err];
    XCTAssertNil(err, @"no error from fileInfo - mike");
    XCTAssertTrue([res count] == 1, @"should find one file");
    XCTAssertEqualObjects(res[0][@"name"], @"carlos", @"found carlos db");
    
    //Re-open destroyed collection
    
    err = nil;
    orders.searchFields = (NSMutableDictionary*)@{@"thename": @"string"}; //change SF to make sure it still works
    [[JSONStore sharedInstance] openCollections:@[orders] withOptions:ops2 error:&err];
    XCTAssertNil(err, @"no error from open after destroy - mike");
    
    err = nil;
    int added3 = [[orders addData:@[@{@"thename" : @"heyo"}] andMarkDirty:NO withOptions:nil error:&err] intValue];
    XCTAssertNil(err, @"no error from add - carlos");
    XCTAssertTrue(added3 == 1, @"added one");
    XCTAssertTrue([[orders countAllDocumentsAndReturnError:nil] intValue] == 1, @"collection contains only one doc");
    JSONStoreQueryPart* qp1 = [[JSONStoreQueryPart alloc] init];
    [qp1 searchField:@"thename" equal:@"heyo"];
    NSArray* findResult = [orders findWithQueryParts:@[qp1] andOptions:nil error:nil];
    XCTAssertTrue([findResult count] == 1, @"should find one result");
    XCTAssertEqualObjects([findResult[0] valueForKeyPath:@"json.thename"], @"heyo", @"should find the right result");
    
    //Close all
    
    err = nil;
    [[JSONStore sharedInstance] closeAllCollectionsAndReturnError:&err];
    XCTAssertNil(err, @"no error from closeAll - carlos");
    
    //Check first store still works - open
    
    err = nil;
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:&err];
    XCTAssertNil(err, @"no error from open last time - carlos");
    
    //Check first store still works - find all
    
    err = nil;
    NSArray *results = [ppl findAllWithOptions:nil error:&err];
    XCTAssertNil(err, @"no error from find all - carlos");
    XCTAssertTrue([results count] == 1, @"should have one doc");
    XCTAssertEqualObjects([results[0] valueForKeyPath:@"json.name"], @"carlos", @"found carlos");
}

-(void) testDestroyWithUsernameClosedCollections
{
    //File Info with NO stores
    
    NSError* err = nil;
    NSArray* fileInfoResult = [[JSONStore sharedInstance] fileInfoAndReturnError:&err];
    XCTAssertNil(err, @"no error from fileInfo - carlos");
    XCTAssertTrue([fileInfoResult count] == 0, @"should find one file");
    
    //First store - open
    
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    [ops setUsername:@"carlos"];
    
    err = nil;
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:&err];
    XCTAssertNil(err, @"no error from open - carlos");
    
    //First store - add
    
    err = nil;
    int added = [[ppl addData:@[@{@"name" : @"carlos"}] andMarkDirty:NO withOptions:nil error:&err] intValue];
    XCTAssertNil(err, @"no error from add - carlos");
    XCTAssertTrue(added == 1, @"added one");
    
    //Close all
    
    err = nil;
    [[JSONStore sharedInstance] closeAllCollectionsAndReturnError:&err];
    XCTAssertNil(err, @"no error from closeAll - carlos");
    
    //File Info with one store - BEFORE destroy
    
    err = nil;
    NSArray* res1 = [[JSONStore sharedInstance] fileInfoAndReturnError:&err];
    XCTAssertNil(err, @"no error from fileInfo - carlos");
    XCTAssertTrue([res1 count] == 1, @"should find one file");
    XCTAssertEqualObjects(res1[0][@"name"], @"carlos", @"found carlos db");
    
    //Destroy with username
    
    err = nil;
    BOOL worked = [[JSONStore sharedInstance] destroyWithUsername:@"carlos" error:&err];
    XCTAssertNil(err, @"no error from destroy with username - carlos");
    XCTAssertTrue(worked, @"should work");
    
    //File Info with one store - AFTER destroy
    
    err = nil;
    NSArray* res2 = [[JSONStore sharedInstance] fileInfoAndReturnError:&err];
    XCTAssertNil(err, @"no error from fileInfo - carlos");
    XCTAssertTrue([res2 count] == 0, @"should find one file");
    
    //Re-open destroyed collection
    
    err = nil;
    ppl.searchFields = (NSMutableDictionary*)@{@"thename": @"string"}; //change SF to make sure it still works
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:&err];
    XCTAssertNil(err, @"no error from open after destroy - carlos");
    
    err = nil;
    int added3 = [[ppl addData:@[@{@"thename" : @"heyo"}] andMarkDirty:NO withOptions:nil error:&err] intValue];
    XCTAssertNil(err, @"no error from add - carlos");
    XCTAssertTrue(added3 == 1, @"added one");
    XCTAssertTrue([[ppl countAllDocumentsAndReturnError:nil] intValue] == 1, @"collection contains only one doc");
    JSONStoreQueryPart* qp1 = [[JSONStoreQueryPart alloc] init];
    [qp1 searchField:@"thename" equal:@"heyo"];
    NSArray* findResult = [ppl findWithQueryParts:@[qp1] andOptions:nil error:nil];
    XCTAssertTrue([findResult count] == 1, @"should find one result");
    XCTAssertEqualObjects([findResult[0] valueForKeyPath:@"json.thename"], @"heyo", @"should find the right result");
    
}

-(void) testChangeWithEmptyReplaceCriteriaAddFalse
{
    //First store - open
    
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"id" withType:JSONStore_Integer];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    NSError* err = nil;
    
    err = nil;
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:nil error:&err];
    XCTAssertNil(err, @"no error from open - jsonstore");
    
    NSArray * data = [NSArray arrayWithObjects:@{@"id": @1, @"name" : @"carlos", @"age": @1},@{@"id": @2, @"name" : @"dgonz", @"age": @2}, @{@"id": @3, @"name" : @"nana", @"age":@3}, nil];
    
    NSArray *newData = [NSArray arrayWithObjects:@{@"id": @1, @"name" : @"carlos", @"age": @1}, @{@"id": @2, @"name" : @"#dgonz", @"age": @2},@{@"id": @3, @"name" : @"nana", @"age": @5},@{@"id": @5, @"name" : @"mike", @"age": @4},nil];
    
    //Add 3 docs
    err = nil;
    int added = [[ppl addData:data andMarkDirty:NO withOptions:nil error:&err] intValue];
    XCTAssertNil(err, @"no error from add - carlos");
    XCTAssertTrue(added == 3, @"added three");
    
    //Change no docs
    err = nil;
    
    int numChanged = [[ppl changeData:newData withReplaceCriteria:@[] addNew:NO markDirty:NO error:&err] intValue];
    XCTAssertTrue(numChanged == 0, @"no changes");
    
}

-(void) testChangeWithEmptyReplaceCriteriaAddTrue
{
    //First store - open
    
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"people"];
    [ppl setSearchField:@"id" withType:JSONStore_Integer];
    [ppl setSearchField:@"name" withType:JSONStore_String];
    [ppl setSearchField:@"age" withType:JSONStore_Integer];
    
    NSError* err = nil;
    
    err = nil;
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:nil error:&err];
    XCTAssertNil(err, @"no error from open - jsonstore");
    
    NSArray * data = [NSArray arrayWithObjects:@{@"id": @1, @"name" : @"carlos", @"age": @1},
                      @{@"id": @2, @"name" : @"dgonz", @"age": @2},nil];
    
    NSArray *newData = [NSArray arrayWithObjects: @{@"id": @3, @"name" : @"mike", @"age": @3},
                        @{@"id": @4, @"name" : @"nana", @"age": @4},nil];
    
    //Add 2 docs
    err = nil;
    int added = [[ppl addData:data andMarkDirty:NO withOptions:nil error:&err] intValue];
    XCTAssertNil(err, @"no error from add - carlos");
    XCTAssertTrue(added == 2, @"added two");
    
    //Change 2 docs
    err = nil;
    int numChanged = [[ppl changeData:newData withReplaceCriteria:@[] addNew:YES markDirty:NO error:&err] intValue];
    XCTAssertTrue(numChanged == 2, @"two docs added");
    
    NSArray* results = [ppl findAllWithOptions:nil error:nil];
    
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.id"] intValue] == 1, @"id1");
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.name"] isEqualToString:@"carlos"], @"name1");
    XCTAssertTrue([[[results objectAtIndex:0] valueForKeyPath:@"json.age"] intValue] == 1, @"age");
    
    
    XCTAssertTrue([[[results objectAtIndex:1] valueForKeyPath:@"json.id"] intValue] == 2, @"id1");
    XCTAssertTrue([[[results objectAtIndex:1] valueForKeyPath:@"json.name"] isEqualToString:@"dgonz"], @"name1");
    XCTAssertTrue([[[results objectAtIndex:1] valueForKeyPath:@"json.age"] intValue] == 2, @"age");
    
    XCTAssertTrue([[[results objectAtIndex:2] valueForKeyPath:@"json.id"] intValue] == 3, @"id1");
    XCTAssertTrue([[[results objectAtIndex:2] valueForKeyPath:@"json.name"] isEqualToString:@"mike"], @"name1");
    XCTAssertTrue([[[results objectAtIndex:2] valueForKeyPath:@"json.age"] intValue] == 3, @"age");
    
    XCTAssertTrue([[[results objectAtIndex:3] valueForKeyPath:@"json.id"] intValue] == 4, @"id1");
    XCTAssertTrue([[[results objectAtIndex:3] valueForKeyPath:@"json.name"] isEqualToString:@"nana"], @"name1");
    XCTAssertTrue([[[results objectAtIndex:3] valueForKeyPath:@"json.age"] intValue] == 4, @"age");
}

-(void) testIndexerWithDifferentCases
{
    JSONStoreCollection* ppl = [[JSONStoreCollection alloc] initWithName:@"People"];
    [ppl setSearchField:@"SSN" withType:JSONStore_String];
    [ppl setSearchField:@"Name" withType:JSONStore_String];
    [ppl setSearchField:@"iD" withType:JSONStore_Integer];
    [ppl setSearchField:@"aGe" withType:JSONStore_Number];
    [ppl setSearchField:@"Active" withType:JSONStore_Boolean];
    
    JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
    ops.username = @"PeopleUsername324234";
    
    NSError* err = nil;
    
    [[JSONStore sharedInstance] openCollections:@[ppl] withOptions:ops error:&err];
    
    XCTAssertNil(err, @"check no error is returned - open");
    
    err = nil;
    
    NSArray* d = @[ @{@"iD" : @1, @"SSN": @"111-22-3333", @"Name": @"carlitos", @"aGe" : @10.5, @"Active" : @YES} ];
    [ppl addData:d andMarkDirty:YES withOptions:nil error:&err];
    
    XCTAssertNil(err, @"check no error is returned - add");
    
    int countResult = [[ppl countAllDocumentsAndReturnError:nil] intValue];
    
    XCTAssertTrue(countResult == 1, @"check count");
    
    //SSN
    
    JSONStoreQueryPart* qp1 = [[JSONStoreQueryPart alloc] init];
    [qp1 searchField:@"SSN" equal:@"111-22-3333"];
    
    NSArray* res1 = [ppl findWithQueryParts:@[qp1] andOptions:nil error:nil];
    
    XCTAssertTrue([res1 count] == 1, @"results2 count");
    XCTAssertTrue([[[res1 objectAtIndex:0] valueForKeyPath:@"json.SSN"] isEqualToString:@"111-22-3333"], @"SSN");
    
    //Name
    
    JSONStoreQueryPart* qp2 = [[JSONStoreQueryPart alloc] init];
    [qp2 searchField:@"Name" equal:@"carlitos"];
    
    NSArray* res2 = [ppl findWithQueryParts:@[qp2] andOptions:nil error:nil];
    
    XCTAssertTrue([res2 count] == 1, @"results2 count");
    XCTAssertTrue([[[res2 objectAtIndex:0] valueForKeyPath:@"json.Name"] isEqualToString:@"carlitos"], @"Name");
    
    //iD
    
    JSONStoreQueryPart* qp3 = [[JSONStoreQueryPart alloc] init];
    [qp3 searchField:@"id" equal:@"1"];
    
    NSArray* res3 = [ppl findWithQueryParts:@[qp3] andOptions:nil error:nil];
    
    XCTAssertTrue([res3 count] == 1, @"results2 count");
    XCTAssertTrue([[[res3 objectAtIndex:0] valueForKeyPath:@"json.iD"] isEqualToNumber:@1], @"iD");
    
    //aGe
    
    JSONStoreQueryPart* qp4 = [[JSONStoreQueryPart alloc] init];
    [qp4 searchField:@"age" equal:@"10.5"];
    
    NSArray* res4 = [ppl findWithQueryParts:@[qp4] andOptions:nil error:nil];
    
    XCTAssertTrue([res4 count] == 1, @"results2 count");
    XCTAssertTrue([[[res4 objectAtIndex:0] valueForKeyPath:@"json.aGe"] isEqualToNumber:@10.5], @"aGe");
    
    //Active
    
    JSONStoreQueryPart* qp5 = [[JSONStoreQueryPart alloc] init];
    [qp5 searchField:@"ACTIVE" equal:@"1"];
    
    NSArray* res5 = [ppl findWithQueryParts:@[qp5] andOptions:nil error:nil];
    
    XCTAssertTrue([res5 count] == 1, @"results2 count");
    XCTAssertTrue([[res5 objectAtIndex:0] valueForKeyPath:@"json.Active"], @"Active");
    
    //Close All
    
    err = nil;
    [[JSONStore sharedInstance] closeAllCollectionsAndReturnError:&err];
    XCTAssertNil(err, @"check no error is returned - closeAll");
    
    
    //Dual Search Fields should fail
    
    JSONStoreCollection* ppl2 = [[JSONStoreCollection alloc] initWithName:@"People"];
    [ppl2 setSearchField:@"ssn" withType:JSONStore_String];
    [ppl2 setSearchField:@"name" withType:JSONStore_String];
    [ppl2 setSearchField:@"id" withType:JSONStore_Integer];
    [ppl2 setSearchField:@"age" withType:JSONStore_Number];
    [ppl2 setSearchField:@"active" withType:JSONStore_Boolean];
    [ppl2 setSearchField:@"Active" withType:JSONStore_Boolean];
    
    err = nil;
    [[JSONStore sharedInstance] openCollections:@[ppl2] withOptions:ops error:&err];
    XCTAssertNotNil(err, @"check no error is returned - open 1");
    
    //Search Fields all lower case should work
    
    JSONStoreCollection* ppl3 = [[JSONStoreCollection alloc] initWithName:@"People"];
    [ppl3 setSearchField:@"ssn" withType:JSONStore_String];
    [ppl3 setSearchField:@"name" withType:JSONStore_String];
    [ppl3 setSearchField:@"id" withType:JSONStore_Integer];
    [ppl3 setSearchField:@"age" withType:JSONStore_Number];
    [ppl3 setSearchField:@"active" withType:JSONStore_Boolean];
    
    err = nil;
    [[JSONStore sharedInstance] openCollections:@[ppl3] withOptions:ops error:&err];
    XCTAssertNil(err, @"check no error is returned - open 2");
    
    int countResult1 = [[ppl countAllDocumentsAndReturnError:nil] intValue];
    XCTAssertTrue(countResult1 == 1, @"check count");
    
    //SSN
    
    JSONStoreQueryPart* qp6 = [[JSONStoreQueryPart alloc] init];
    [qp6 searchField:@"sSn" equal:@"111-22-3333"];
    
    NSArray* res6 = [ppl findWithQueryParts:@[qp6] andOptions:nil error:nil];
    
    XCTAssertTrue([res6 count] == 1, @"results2 count");
    XCTAssertTrue([[[res6 objectAtIndex:0] valueForKeyPath:@"json.SSN"] isEqualToString:@"111-22-3333"], @"SSN");
}

@end
