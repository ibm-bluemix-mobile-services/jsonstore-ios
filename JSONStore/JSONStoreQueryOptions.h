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

/**
 Contains JSONStore query options.
 */
@interface JSONStoreQueryOptions : NSObject

/**
 Private. Flag to turn a find into a count.
 @private
 */
@property (nonatomic) BOOL _count;

/**
 Private. NSArray with sort criteria (e.g. [{name: @"ASC"}]).
 */
@property (nonatomic,strong) NSMutableArray* _sort;

/**
 Private. NSArray with filter criteria (e.g. [@"name", @"age"]).
 */
@property (nonatomic,strong) NSMutableArray* _filter;

/**
 Determines the maximum number of results to return.
 */
@property (nonatomic,strong) NSNumber* limit;

/**
 Determines the maximum number of documents to skip from the result.
 */
@property (nonatomic,strong) NSNumber* offset;

/**
 Sorts by search field ascending.
 @param searchField Search field
 */
-(void) sortBySearchFieldAscending:(NSString*) searchField;

/**
 Sorts by search field descending.
 @param searchField Search field
 */
-(void) sortBySearchFieldDescending:(NSString*) searchField;

/**
 Filter by search field.
 @param searchField Search field
 */
-(void) filterSearchField:(NSString*) searchField;

/**
 String representation of the object.
 */
-(NSString*) description;

@end
