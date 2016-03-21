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

#import "JSONStoreValidator.h"

@implementation JSONStoreValidator

+(BOOL) isArray:(id) object
{
    return [object isKindOfClass:[NSArray class]];
}

+(BOOL) isDictionary:(id) object
{
    return [object isKindOfClass:[NSDictionary class]];
}

+(NSString*) getDatabaseSafeSearchField:(NSString*) searchField
{
    // Remove special characters that break SQLite queries
    // If any other characters are found that break queries, add them to this array
    NSArray* databaseReservedKeys = @[@"'"];
    
    if ([searchField isKindOfClass:[NSString class]]) {
        
        for (NSString* reservedKey in databaseReservedKeys) {
            searchField = [searchField stringByReplacingOccurrencesOfString:reservedKey withString:@""];
        }
    }
    return searchField;
}


@end
