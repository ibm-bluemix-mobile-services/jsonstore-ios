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
 Represents a JSONStore Schema, holding indexes (search fields) and additional search fields (additional indexes).
 @private
 */
@interface JSONStoreSchema : NSObject

/**
 Dictionary with search fields. Example: {@"name": @"string"}.
 */
@property (nonatomic,strong) NSDictionary* indexes;

/**
 Dictionary with additional search fields. Example: {@"name": @"string"}.
 */
@property (nonatomic,strong) NSDictionary* additionalIndexes;

/**
 Initialization method.
 @param searchFields Search fields
 @param addSearchFields Additional search fields
 @return self
 */
-(id) initWithSearchFields:(NSDictionary*) searchFields
     additionalSearchFields:(NSDictionary*) addSearchFields;

/**
 Returns all keys from search fields.
 */
-(NSArray*) getKeys;

/**
 Returns a dictionary with search fields and additional search fields merged.
 */
-(NSDictionary*) getCombinedDictionary;

@end
