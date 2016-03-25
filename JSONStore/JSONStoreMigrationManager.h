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
 Contains JSONStore migration logic.
 */
@interface JSONStoreMigrationManager : NSObject

/**
 Flag that is set to true after the migration code is executed, so it is only checked once.
 */
@property (nonatomic) BOOL checkedForUpgrade;

/**
 Flag that is set to true after the security migration code is executed, so it is only checked once.
 */
@property (nonatomic) BOOL checkedForSecurityUpgrade;

/**
 Returns a sharedInstance because this is a singleton.
 @return self
 */
+(instancetype) sharedInstance;

/**
 Checks if a migration update is required and executes the migration code.
 */
-(void) checkForUpgrade;

/**
 Checks if a migration update is required and executes the security migration code.
 */
-(int) checkForSecurityUpgrade:(NSString*) username
                   andPassword:(NSString*) pwd;

@end
