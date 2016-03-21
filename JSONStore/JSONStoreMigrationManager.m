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

#import "JSONStoreMigrationManager.h"
#import "JSONStoreConstants.h"
#import "JSONStore.h"
#import "JSONStore+Private.h"

@implementation JSONStoreMigrationManager

+(instancetype) sharedInstance
{
    static JSONStoreMigrationManager* _sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[JSONStoreMigrationManager alloc] init];
    });
    
    return _sharedInstance;
}

-(instancetype) init
{
    if (self = [super init]) {
        self.checkedForUpgrade = NO;
    }
    
    return self;
}

-(void) checkForUpgrade
{
    if (self.checkedForUpgrade) {
        
        //We only need to check once
        return;
    }
    
    self.checkedForUpgrade = YES;
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* jsVer = [defaults valueForKey:JSON_STORE_VERSION_LABEL];
    
    if (jsVer == nil || ![jsVer isEqualToString:JSON_STORE_VERSION_2_0]) {
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray* urls = [fileManager URLsForDirectory:NSDocumentDirectory
                                            inDomains:NSUserDomainMask];
        
        NSURL* u = [urls objectAtIndex:0];
        
        u = [u URLByAppendingPathComponent:JSON_STORE_DEFAULT_FOLDER_FOR_SQLITE_FILES];
        
        NSError* error = nil;
        
        if (! [fileManager createDirectoryAtPath:[u path]
                     withIntermediateDirectories:NO
                                      attributes:nil
                                           error:&error])
        {
            NSLog(@"Unable to create directory error: %@", error);
        }
        
        NSURL* oldPath = [urls objectAtIndex:0];
        
        oldPath = [oldPath URLByAppendingPathComponent:JSON_STORE_DEFAULT_SQLITE_FILE];
        
        NSString *dbPath = [oldPath path];
        
        if (! [fileManager fileExistsAtPath:dbPath]) {
            
            NSLog(@"Database file does not exist, path: %@", dbPath);
            
        } else {
            
            u = [u URLByAppendingPathComponent:JSON_STORE_DEFAULT_SQLITE_FILE];
            
            NSString* oldDBPath = [oldPath path];
            NSString* newDBPath = [u path];
            
            NSLog(@"Migration JSONStore files to new location, old path: %@, new path: %@", oldDBPath, newDBPath);
            
            if (! [fileManager moveItemAtPath:[oldPath path]
                                      toPath:[u path]
                                       error:&error]) {
                
                NSLog(@"Unable to migrate existing JSONStore: %@", error);
            }
        }
        
        [defaults setValue:JSON_STORE_VERSION_2_0 forKey:JSON_STORE_VERSION_LABEL];
        [defaults synchronize];
    }
    
    //After migration is done, we can log fileInfo if analytics is enabled
    if ([[JSONStore sharedInstance] _isAnalyticsEnabled]) {
        
        NSError* error = nil;    
        
        if (error != nil) {
            NSLog(@"Failure getting jsonstore file information, error: %@", error);
        }
    }
}

@end
