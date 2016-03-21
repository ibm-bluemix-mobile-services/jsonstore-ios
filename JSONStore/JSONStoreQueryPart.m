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

#import "JSONStoreQueryPart.h"
#import "JSONStoreValidator.h"

@implementation JSONStoreQueryPart

- (instancetype) init {
    
    if (self = [super init]) {
        
    }
    
    return self;
}

-(NSMutableArray*) __ids
{
    if(! __ids) {
        __ids = [[NSMutableArray alloc] init];
    }
    
    return __ids;
}

-(void) searchField:(NSString*) searchField
           lessThan:(NSNumber*) number
{
    if (! __lessThan) {
        __lessThan = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    
    [__lessThan addObject:@{safeSearchField : number}];
}

-(void) searchField:(NSString*) searchField
    lessOrEqualThan:(NSNumber*) number
{
    if (! __lessOrEqualThan) {
        __lessOrEqualThan = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    
    [__lessOrEqualThan addObject:@{safeSearchField : number}];
}

-(void) searchField:(NSString*) searchField
        greaterThan:(NSNumber*) number
{
    if (! __greaterThan) {
        __greaterThan = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    
    [__greaterThan addObject:@{safeSearchField : number}];
}

-(void) searchField:(NSString*) searchField
 greaterOrEqualThan:(NSNumber*) number
{
    if (! __greaterOrEqualThan) {
        __greaterOrEqualThan = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    
    [__greaterOrEqualThan addObject:@{safeSearchField : number}];
}

-(void) searchField:(NSString*) searchField
               like:(NSString*) string
{
    if (! __like) {
        __like = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    NSString* safeString = [JSONStoreValidator getDatabaseSafeSearchField:string];
    
    [__like addObject:@{safeSearchField : safeString}];
}

-(void) searchField:(NSString*) searchField
            notLike:(NSString*) string
{
    if (! __notLike) {
        __notLike = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    NSString* safeString = [JSONStoreValidator getDatabaseSafeSearchField:string];
    
    [__notLike addObject:@{safeSearchField : safeString}];
}

-(void) searchField:(NSString*) searchField
           leftLike:(NSString*) string
{
    if (! __leftLike) {
        __leftLike = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    NSString* safeString = [JSONStoreValidator getDatabaseSafeSearchField:string];
    
    [__leftLike addObject:@{safeSearchField : safeString}];
}

-(void) searchField:(NSString*) searchField
        notLeftLike:(NSString*) string
{
    if (! __notLeftLike) {
        __notLeftLike = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    NSString* safeString = [JSONStoreValidator getDatabaseSafeSearchField:string];
    
    [__notLeftLike addObject:@{safeSearchField : safeString}];
}

-(void) searchField:(NSString*) searchField
          rightLike:(NSString*) string
{
    if (! __rightLike) {
        __rightLike = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    NSString* safeString = [JSONStoreValidator getDatabaseSafeSearchField:string];
    
    [__rightLike addObject:@{safeSearchField : safeString}];
}

-(void) searchField:(NSString*) searchField
       notRightLike:(NSString*) string
{
    if (! __notRightLike) {
        __notRightLike = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    NSString* safeString = [JSONStoreValidator getDatabaseSafeSearchField:string];
    
    [__notRightLike addObject:@{safeSearchField : safeString}];
}

-(void) searchField:(NSString*) searchField
              equal:(NSString*) string
{
    if (! __equal) {
        __equal = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    NSString* safeString = [JSONStoreValidator getDatabaseSafeSearchField:string];
    
    [__equal addObject:@{safeSearchField : safeString}];
}

-(void) searchField:(NSString*) searchField
           notEqual:(NSString*) string
{
    if (! __notEqual) {
        __notEqual = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    NSString* safeString = [JSONStoreValidator getDatabaseSafeSearchField:string];
    
    [__notEqual addObject:@{safeSearchField : safeString}];
}

-(void) searchField:(NSString*) searchField
       insideValues:(NSArray*) values
{
    if (! __inside) {
        __inside = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    
    [__inside addObject:@{safeSearchField : values}];
}

-(void) searchField:(NSString*) searchField
    notInsideValues:(NSArray*) values
{
    if (! __notInside) {
        __notInside = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    
    [__notInside addObject:@{safeSearchField : values}];
}

-(void) searchField:(NSString*) searchField
            between:(NSNumber*) number1
                and:(NSNumber*) number2
{
    if (! __between) {
        __between = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    
    [__between addObject:@{safeSearchField : @[number1, number2]}];
    
}

-(void) searchField:(NSString*) searchField
         notBetween:(NSNumber*) number1
                and:(NSNumber*) number2
{
    if (! __notBetween) {
        __notBetween = [[NSMutableArray alloc] init];
    }
    
    NSString* safeSearchField = [JSONStoreValidator getDatabaseSafeSearchField:searchField];
    
    [__notBetween addObject:@{safeSearchField : @[number1, number2]}];
}


@end