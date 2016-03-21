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

#import "JSONStoreQueryOptions.h"
#import "JSONStoreConstants.h"

@implementation JSONStoreQueryOptions

-(void) sortBySearchFieldAscending:(NSString*) searchField
{
    if (! __sort) {
        __sort = [[NSMutableArray alloc] init];
    }
    
    [__sort addObject:@{searchField : JSON_STORE_KEY_ASC}];
}

-(void) sortBySearchFieldDescending:(NSString*) searchField
{
    if (! __sort) {
        __sort = [[NSMutableArray alloc] init];
    }
    
    [__sort addObject:@{searchField : JSON_STORE_KEY_DESC}];
}

-(void) filterSearchField:(NSString*) searchField
{
    if (! __filter) {
        __filter = [[NSMutableArray alloc] init];
    }
    
    [__filter addObject:searchField];
}

-(NSString*) description
{
    return [NSString stringWithFormat: @"[JSONStoreQueryOptions: sort=%@ filter=%@, limit=%@, offset=%@]", self._sort, self._filter, self.limit, self.offset];
}

@end
