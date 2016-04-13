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

#import "JSONStoreSecurityManager.h"
#import "JSONStoreSecurityUtils.h"
#import "JSONStoreConstants.h"
#import "NSString+WLJSON.h"
#import "NSObject+WLJSON.h"

@implementation JSONStoreSecurityManager

@synthesize username = _username;

-(instancetype) init
{
    self = [super init];
    if(self){
        _username = JSON_STORE_DEFAULT_USER;
    }
    return self;
}

-(instancetype) initWithUsername:(NSString*) username
{
    if (self = [super init]) {
        
        if (username == nil || [@"" isEqualToString:username]) {
            
            NSString* msg = [NSString stringWithFormat:@"Username was %@", username];
            
            NSLog(@"JSON_STORE_EXCEPTION raised, %@", msg);
            
            [NSException raise:JSON_STORE_EXCEPTION format:@"%@", msg];
        }
        
        //Preserve backwards compatibility, if the user uses the
        //default username, make the acct parameter the old value
        if([username isEqualToString:JSON_STORE_DEFAULT_USER]){
            username = JSON_STORE_KEY_DOCUMENT_ID;
        }
        
        _username = username;
    }
    
    return self;
}

-(BOOL) clearKeyChain
{
    // Need to delete DPK with both old and new naming schemes ("JSONStoreKey" --> "JSONStoreKey_bundleId") in case exist.
    NSMutableDictionary* dpkOld = [self _getDpkDocumentLookupDict];
    NSMutableDictionary* dpkWithBundleId = [self _getGenericPwLookupDict:[JSONStoreSecurityManager _dpkIdentifierWithBundleId]];
    
    BOOL worked = [self clearKeyChainWithDpk:dpkOld] && [self clearKeyChainWithDpk:dpkWithBundleId];
    
    return  worked;
}

-(BOOL) clearKeyChainWithDpk:(NSMutableDictionary*)dpkDict
{
    [dpkDict removeObjectForKey:(__bridge id)(kSecReturnData)];
    [dpkDict removeObjectForKey:(__bridge id)(kSecMatchLimit)];
    [dpkDict removeObjectForKey:(__bridge id)(kSecReturnAttributes)];
    [dpkDict removeObjectForKey:(__bridge id)(kSecAttrAccount)];
    
    OSStatus err = SecItemDelete((__bridge CFDictionaryRef)dpkDict);
    
    if (err == noErr || err ==  errSecItemNotFound) {
        return YES;
    } else {
        NSLog(@"Error getting DPK doc from keychain, SecItemDelete returned: %d", (int)err);
        return NO;
    }
}

-(BOOL) changeOldPassword:(NSString*) oldPW
            toNewPassword:(NSString*) newPW
{
    NSString* decDPK = [self getDPK:oldPW];
    
    if (decDPK == nil) {
        NSLog(@"Unable to get key with old password, old pwd length: %d, new pwd length: %d", [oldPW length], [newPW length]);
        return NO;
    }
    NSString* salt = [self _getSalt];
    
    //We got the old key, now store the new one
    return [self _storeDPK:decDPK
             usingPassword:newPW
                  withSalt:salt
                  isUpdate:YES
  dpkRequiresKeyDerivation:NO];
}

-(NSString*) getDPK: (NSString*) password
{
    NSDictionary* storedDict = [self _getDpKDocFromKeyChain];
    
    if (storedDict == nil) {
        return nil;
    }
    
    NSString* dpk = [storedDict objectForKey:JSON_STORE_KEY_DPK];
    NSString* salt = [storedDict objectForKey:JSON_STORE_KEY_SALT];
    NSString* pwKey = [self _passwordToKey:password withSalt:salt];
    NSString* iv = [storedDict objectForKey:JSON_STORE_KEY_IV];
    NSString* decryptedKey = [JSONStoreSecurityUtils _decryptWithKey:pwKey
                                               withCipherText:dpk
                                                       withIV:iv
                                  decodeBase64AfterDecryption:NO
                                          checkBase64Encoding:YES];
    
    return decryptedKey;
}

-(BOOL) isKeyChainFullyPopulated
{
    // Look for DPK+bundleID. If it does not exist, see if the old version (i.e. no bundle ID appended) exists.
    // If the old DPK exists, copy it to a new DPK with the new identifier naming scheme.
    NSMutableDictionary* dpkDocWithBundleId = [self _getGenericPwLookupDict:[JSONStoreSecurityManager _dpkIdentifierWithBundleId]];
    return [self isKeyChainFullyPopulatedWithDpkDoc:dpkDocWithBundleId usingOldDPK:NO];
}

-(BOOL)isKeyChainFullyPopulatedWithDpkDoc:(NSMutableDictionary*)dpkDoc usingOldDPK:(BOOL)usingOldDPK
{
    NSData* dpkData = nil;
    OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef)dpkDoc, (void*)&dpkData);
    
    if (err == noErr) {
        
        NSString* dpk = [[NSString alloc] initWithBytes:[dpkData bytes] length:[dpkData length] encoding:NSUTF8StringEncoding];
        
        if (usingOldDPK == NO) {
            // If false, a match was found in keychain, but it was empty
            return (dpk != nil && [dpk length] > 0);
        }
        else {
            // We found the DPK using the old identifier. Duplicate the DPK with a unique identifier (e.g. jsonstore_bundleId).
            // If the duplication fails, then we will not open the jsonstore collection because the rest of this class depends on the DPK ID containing the app's bundle ID.
            if (dpk != nil && [dpk length] > 0) {
                
                NSMutableDictionary* jsonDocStoreDict = [self _getGenericPwStoreDict:[JSONStoreSecurityManager _dpkIdentifierWithBundleId] data:dpk];
                
                OSStatus addErr = SecItemAdd((__bridge CFDictionaryRef)jsonDocStoreDict, nil);
                
                if (addErr == noErr){
                    return true;
                }
                else {
                    NSLog(@"Unable to update old Data Protection Key to use a unique identifier. SecItemAdd returned: %d", (int)err);
                    return false;
                }
            }
            else {
                //Found a match in keychain, but it was empty
                return false;
            }
        }
    } else if (err == errSecItemNotFound) {
        
        if (! usingOldDPK) {
            // Since no DPK with an updated identifier was found, we will now search for a DPK with an old identifier (no Bundle ID)
            return [self isKeyChainFullyPopulatedWithDpkDoc:[self _getDpkDocumentLookupDict] usingOldDPK:YES];
        }
        else {
            NSLog(@"DPK doc not found in keychain");
            return false;
        }
    }
    
    else {
        NSLog(@"Error getting DPK doc from keychain, SecItemCopyMatching returned: %d", (int)err);
        return false;
    }
}

-(BOOL) storeDPK:(NSString*)clearDPK usingPassword:(NSString*) password withSalt:(NSString*)salt
{
    
    BOOL worked = [self _storeDPK:clearDPK
                    usingPassword:password
                         withSalt:salt
                         isUpdate:NO
         dpkRequiresKeyDerivation:YES];
    
    return worked;
}

-(BOOL) generateAndStoreDpkUsingPassword:(NSString*) password
                                withSalt:(NSString*)salt
{
    NSString* hexEncodedDpk  = [JSONStoreSecurityUtils generateRandomStringWithBytes:JSON_STORE_DEFAULT_DPK_SIZE];
    
    BOOL worked = [self _storeDPK:hexEncodedDpk
                    usingPassword:password
                         withSalt:salt
                         isUpdate:NO
         dpkRequiresKeyDerivation:NO];
    
    return worked;
}

#pragma mark Helpers

-(NSString*) _passwordToKey:(NSString*) password
                   withSalt:(NSString*) salt
{
    return [JSONStoreSecurityUtils generateKeyWithPassword:password
                                             andSalt:salt
                                       andIterations:JSON_STORE_DEFAULT_PBKDF2_ITERATIONS];
}

-(NSMutableDictionary*) _getGenericPwLookupDict:(NSString*) identifier
{
    
    NSMutableDictionary* genericPasswordQuery = [[NSMutableDictionary alloc] init];
    [genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [genericPasswordQuery setObject:self.username forKey:(__bridge id <NSCopying>)(kSecAttrAccount)];
    [genericPasswordQuery setObject:identifier forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    
    // Use the proper search constants, return only the attributes of the first match.
    [genericPasswordQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id<NSCopying>)(kSecMatchLimit)];
    [genericPasswordQuery setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id<NSCopying>)(kSecReturnAttributes)];
    [genericPasswordQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id<NSCopying>)(kSecReturnData)];
    return genericPasswordQuery;
    
}

-(NSMutableDictionary*) _getGenericPwStoreDict:(NSString*) identifier
                                          data:(NSString*) theData
{
    NSMutableDictionary* genericPasswordQuery = [[NSMutableDictionary alloc] init];
    [genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [genericPasswordQuery setObject:self.username forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
    [genericPasswordQuery setObject:identifier forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    [genericPasswordQuery setObject:[theData dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id<NSCopying>)(kSecValueData)];
    [genericPasswordQuery setObject:(__bridge id)(kSecAttrAccessibleAlways)  forKey:(__bridge id<NSCopying>)(kSecAttrAccessible)];
    
    return genericPasswordQuery;
    
}

-(NSMutableDictionary*) _getDpkDocumentLookupDict
{
    NSMutableDictionary* dpkQuery = [self _getGenericPwLookupDict:JSON_STORE_KEY_DOCUMENT_ID];
    return dpkQuery;
}

-(NSDictionary*) _getDpKDocFromKeyChain
{
    NSMutableDictionary* lookupDict = [self _getGenericPwLookupDict:[JSONStoreSecurityManager _dpkIdentifierWithBundleId]];
    
    NSData* theData = nil;
    OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef)lookupDict, (void*)&theData);
    
    if (err == noErr){
        NSString* jsonStr = [[NSString alloc] initWithBytes:[theData bytes]
                                                     length:[theData length]
                                                   encoding:NSUTF8StringEncoding];
        
        id jsonDoc = [jsonStr WLJSONValue];
        
        if (jsonDoc != nil && [jsonDoc isKindOfClass:[NSDictionary class]]) {
            
            //Ensure the num derivations saved, matches what we have
            int iters = [[(NSDictionary*) jsonDoc objectForKey:JSON_STORE_KEY_ITERATIONS]intValue];
            
            if (iters != JSON_STORE_DEFAULT_PBKDF2_ITERATIONS) {
                
                NSLog(@"Number of iterations stored, does NOT match the constant value %u", JSON_STORE_DEFAULT_PBKDF2_ITERATIONS);
                return nil;
            }
            
            return jsonDoc;
        }
        
    } else {
        
        NSLog(@"Error getting DPK doc from keychain, SecItemCopyMatching returned: %d", (int)err);
    }
    
    return nil;
}

-(NSString*) _getSalt
{
    NSDictionary* storedDict = [self _getDpKDocFromKeyChain];
    
    if (storedDict == nil) {
        return nil;
    }
    
    return [storedDict objectForKey:JSON_STORE_KEY_SALT];
}

-(NSString*) _getIV
{
    NSDictionary* storedDict = [self _getDpKDocFromKeyChain];
    
    if (storedDict == nil) {
        return nil;
    }
    
    return [storedDict objectForKey:JSON_STORE_KEY_IV];
}

-(BOOL) _storeDPK:(NSString*)clearDPK
    usingPassword:(NSString*) password
         withSalt:(NSString*)salt
         isUpdate:(BOOL) isUpdate
dpkRequiresKeyDerivation:(BOOL) dpkRequiresKeyDerivation
{
    BOOL worked;
    
    NSString* dpk = clearDPK;
    
    if (dpkRequiresKeyDerivation) {
        //If it's an update, we already have the derived dpk, if it's an original store, it needs
        //to run through pbkdf2
        dpk = [self _passwordToKey:clearDPK withSalt:salt];
    }
    
    NSString* pwKey = [self _passwordToKey:password withSalt:salt];
    
    NSString* hexEncodedIv  = [JSONStoreSecurityUtils generateRandomStringWithBytes:JSON_STORE_DEFAULT_IV_SIZE];
    
    NSString* encyptedDPK = [JSONStoreSecurityUtils _encryptWithKey:pwKey
                                                    withText:dpk
                                                      withIV:hexEncodedIv
                                covertBase64BeforeEncryption:YES];
    
    NSDictionary* jsonEntriesDict = @{ JSON_STORE_KEY_IV : hexEncodedIv,
                                       JSON_STORE_KEY_SALT : salt,
                                       JSON_STORE_KEY_DPK : encyptedDPK,
                                       JSON_STORE_KEY_ITERATIONS : [NSNumber numberWithInt:JSON_STORE_DEFAULT_PBKDF2_ITERATIONS],
                                       JSON_STORE_KEY_VERSION : JSON_STORE_KEY_VERSION_NUMBER };
    
    NSString* jsonStr = [jsonEntriesDict WLJSONRepresentation];
    NSMutableDictionary* jsonDocStoreDict = [self _getGenericPwStoreDict:[JSONStoreSecurityManager _dpkIdentifierWithBundleId] data:jsonStr];
    
    if (! isUpdate) {
        
        //Just a straight add to keychain
        OSStatus err = SecItemAdd((__bridge CFDictionaryRef)jsonDocStoreDict, nil);
        
        if (err == noErr){
            worked = YES;
        }
        
        else if (err == errSecDuplicateItem){
            NSLog(@"Doc already exists in keychain");
            worked = NO;
        }
        
        else {
            NSLog(@"Unable to store Doc in keychain, SecItemAdd returned: %d", (int)err);
            worked = NO;
        }
        
    } else {
        
        //Need up update the keychain instead of add
        NSDictionary* updateVal = [[NSDictionary alloc]initWithObjectsAndKeys:
                                   [jsonStr dataUsingEncoding:NSUTF8StringEncoding], kSecValueData, nil];
        
        OSStatus err = SecItemUpdate((__bridge CFDictionaryRef)jsonDocStoreDict, (__bridge CFDictionaryRef) updateVal);
        
        if (err == noErr) {
            worked = YES;
            
        }
        else {
            NSLog(@"Unable to update Doc in keychain, SecItemUpdate returned: %d", (int)err);
            worked = NO;
        }
    }
    
    return worked;
}

+(NSString*) _dpkIdentifierWithBundleId
{
    NSString* appIdSuffix = [[[NSBundle mainBundle] bundleIdentifier] stringByReplacingOccurrencesOfString:@"." withString:@""];
    return [NSString stringWithFormat:@"%@_%@", JSON_STORE_KEY_DOCUMENT_ID, appIdSuffix];
}


@end
