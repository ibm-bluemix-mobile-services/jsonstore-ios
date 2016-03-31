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
 Contains JSONStore methods to handle security.
 */
@interface JSONStoreSecurityManager : NSObject

/**
 User name that is tied to the JSONStoreSecurityManager instance.
 */
@property (nonatomic, readonly, strong) NSString* username;

/**
 Initialization method.
 @param username User name that is tied to the instance
 @return self
 */
-(instancetype) initWithUsername:(NSString*) username;

/**
 Returns the decrypted Data Protection Key (DPK) from the keychain.
 @param password Password used to decrypt the DPK
 @return The DPK
 */
-(NSString*) getDPK:(NSString*) password;

/**
 Encrypts and stores the encrypted Data Protection Key (DPK) inside the keychain. Used when a secure random is received from the server (default). This method generates the DPK and CBK (Client Based Key), and then encrypts the DPK using the CBK.
 The salt and IV that is created is also stored in the keychain.
 @param clearDPK the DPK in clear text, this comes from the /random service on the server
 @param password Password used to encrypt the DPK, it is the derived user password in clear text
 @param salt The salt
 @return Success (true) or failure (false)
 */
-(BOOL) storeDPK:(NSString*) clearDPK
   usingPassword:(NSString*) password
        withSalt:(NSString*) salt;

/**
 Generates the Data Protection Key (DPK) locally, encrypts it, and stores it inside the keychain.
 @param password Password used for the Client Based Key (CBK) to encrypt the DPK
 @param salt The salt
 @return Success (true) or failure (false)
 */
-(BOOL) generateAndStoreDpkUsingPassword:(NSString*) password
                                withSalt:(NSString*) salt;

/**
 Checks if the encrypted Data Protection Key (DPK) is inside the keychain.
 If an old DPK identifier is found without the Bundle ID appended, it is copied to a new DPK with the new naming scheme.
 @return True if the encrypted DPK is inside the keychain, false otherwise
 */
-(BOOL) isKeyChainFullyPopulated;

/**
 Clears JSONStore security metadata from the keychain.
 @return Success (true) or failure (false)
 */
-(BOOL) clearKeyChain;

/**
 Changes the password that is used to encrypt the Data Protection Key (DPK).
 @param oldPW Old password
 @param newPW New password
 @return Success (true) or failure (false)
 */
-(BOOL) changeOldPassword:(NSString*) oldPW
            toNewPassword:(NSString*) newPW;

/**
 Private. Returns the salt.
 @return Salt
 @private
 */
-(NSString*) _getSalt;

/**
 Private. Returns the IV.
 @return IV
 @private
 */
-(NSString*) _getIV;

/**
 Returns the data protection key with the app Bundle ID appended.
 Used to create unique Data Protection Keys to prevent collision of identical jsonstore usernames on shared keychains.
 @param username The jsonstore name to append to
 @return NSString The new jsonstore username with the app ID appended
 @private
 */
+(NSString*) _dpkIdentifierWithBundleId;

@end
