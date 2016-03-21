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
 Contains JSONStore methods that are used for validation.
 */
@interface JSONStoreValidator : NSObject

/**
 Checks if the object that is passed is an array.
 @param object Object
 @return True if the object is an array, false otherwise
 */
+(BOOL) isArray:(id) object;

/**
 Checks if the object that is passed is an dictionary.
 @param object Object
 @return True if the object is an dictionary, false otherwise
 */
+(BOOL) isDictionary:(id) object;

/**
 Remove SQLite reserved characters (like single quotes) from search field
 @param searchField Search field to be modified
 */
+(NSString*) getDatabaseSafeSearchField:(NSString*) searchField;

@end
