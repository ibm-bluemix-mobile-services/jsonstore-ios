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
 Contains JSONStore options that are used to open collections.
 */
@interface JSONStoreOpenOptions : NSObject

/**
 The user name.
 */
@property (nonatomic, strong) NSString* username;

/**
 Set to true only if OS security is available (Touch ID or PIN on iOS).
 The JSONStore fails to open on devices without OS Security if this property is set to true.
 */
@property (nonatomic) BOOL requireOperatingSystemSecurity;

/**
 The message to present to the user if OS Security is enabled.
 */
@property (nonatomic) NSString* operatingSystemSecurityMessage;


@end
