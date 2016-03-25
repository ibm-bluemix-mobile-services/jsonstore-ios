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

#import "NSData+WLJSON.h"
#import "JSONStoreMarcos.h"

@implementation NSData (NSData_WLJSON)

- (id) WLJSONValue
{
    NSError *error = nil;
    id jsonValue = [NSJSONSerialization JSONObjectWithData:self
                                                   options:0
                                                     error:&error];
    if (! jsonValue) {
        DLog(@"Error getting JSONObject with Data: %@", error);
    }
    
    return jsonValue;
}

@end