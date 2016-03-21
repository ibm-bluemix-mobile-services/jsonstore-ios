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

#import "JSONStoreIndexer.h"
#import "JSONStoreValidator.h"
#import "JSONStoreConstants.h"
#import "JSONStoreValidator.h"

@implementation JSONStoreIndexer

-(NSMutableDictionary*) findIndexesFromSchema:(JSONStoreSchema*) schema
                                forJsonObject:(id) jsonObj
                                        error:(NSError**) error
{
    self.returnDict = [NSMutableDictionary new];
    
    for (NSString* idx in [schema getKeys]) {
        //idx lowercased for defect 60601
        [self.returnDict setObject:[NSMutableSet new] forKey:[idx lowercaseString]];
    }
    
    NSMutableArray* pathParts = [NSMutableArray new];
    
    //Walk the json tree, and at each stop, see if it matches an index
    if ([jsonObj isKindOfClass:[NSArray class]]) {
        
        [self _handleArray:jsonObj withSchema:schema currentPath:pathParts];
        
    } else if ([jsonObj isKindOfClass:[NSDictionary class]]) {
        
        [self _handleDictionary:jsonObj withSchema:schema currentPath:pathParts];
        
    } else {
        
        
        NSLog(@"Error: JSON_STORE_INVALID_JSON_STRUCTURE, code: %d, schema: %@", JSON_STORE_INVALID_JSON_STRUCTURE, schema);
        NSLog(@"Error: JSON_STORE_INVALID_JSON_STRUCTURE, jsonObject: %@", jsonObj);
        
        if (error != nil) {
            *error = [NSError errorWithDomain:JSON_STORE_EXCEPTION
                                         code:JSON_STORE_INVALID_JSON_STRUCTURE
                                     userInfo:nil];
        }
        
        return nil;
    }
    
    return self.returnDict;
}

#pragma mark Helpers

- (void) _handleSimpleTypeWithKeyValue:(id) value
                           currentPath:(NSArray *) path
{
    NSString* theVal = (NSString*) value;
    theVal = [JSONStoreValidator getDatabaseSafeSearchField:theVal];
    
    NSMutableSet* s = [self.returnDict objectForKey:[path componentsJoinedByString:@"."]];
    
    if (s) {
        
        [s addObject:theVal];
    }
}

-(void) _handleArray:(id) array
          withSchema:(JSONStoreSchema*) schema
         currentPath:(NSArray*) path
{
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([JSONStoreValidator isDictionary:obj]) {
            
            //Just pass path, nothing to append at this point
            [self _handleDictionary:obj withSchema:schema currentPath:path];
            
        } else if ([JSONStoreValidator isArray:obj]) {
            
            [self _handleArray:obj withSchema:schema currentPath:path];
            
        } else {
            //In an array, if we just have a simple type, it can't be indexed.
            //Example: {hobbies: [ 3, {k :v } ] }
            //This case would match the '3', which we can't index.
        }
    }];
}

-(void) _handleDictionary:(id) dict
               withSchema:(JSONStoreSchema*) schema
              currentPath:(NSArray*) path
{
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        key = [key lowercaseString];
        
        if ([JSONStoreValidator isDictionary:obj]) {
            
            NSArray* p = [path arrayByAddingObject:key];
            [self _handleDictionary:obj withSchema:schema currentPath:p];
            
        } else if ([JSONStoreValidator isArray:obj]) {
            
            NSArray* p = [path arrayByAddingObject:key];
            [self _handleArray:obj withSchema:schema currentPath:p];
            
        } else {
            
            NSArray* p = [path arrayByAddingObject:key];
            [self _handleSimpleTypeWithKeyValue:obj currentPath:p];
        }
    }];
}

@end
