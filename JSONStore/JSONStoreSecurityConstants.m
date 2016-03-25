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

#import "JSONStoreSecurityConstants.h"

@implementation JSONStoreSecurityConstants

int const JSONStorekChosenCipherIVSize = 16;
int const JSONStorekChosenCipherKeySize = 32;

NSString *const JSONStore_BASE64_REGEX = @"^[a-zA-Z0-9\\+=\\/]{%u}$";

NSString *const JSONStore_ERROR_LABEL_KEYGEN = @"KEYGEN_ERROR";
NSString *const JSONStore_ERROR_LABEL_ENCRYPT = @"ENCRYPT_ERROR";
NSString *const JSONStore_ERROR_LABEL_DECRYPT = @"DECRYPT_ERROR";
NSString *const JSONStore_ERROR_LABEL = @"ERROR";

NSString *const JSONStore_ERROR_MSG_INVALID_IV_LENGTH = @"IV must be 32 hex characters or 16 bytes (128 bits)";

NSString *const JSONStore_ERROR_MSG_EMPTY_TEXT = @"Cannot encrypt empty/nil plaintext";
NSString *const JSONStore_ERROR_MSG_EMPTY_CIPHER = @"Cannot decrypt empty/nil cipher";
NSString *const JSONStore_ERROR_MSG_EMPTY_KEY = @"Cannot work with an empty/nil key";
NSString *const JSONStore_ERROR_MSG_EMPTY_IV = @"Cannot encrypt with empty/nil iv";
NSString *const JSONStore_ERROR_MSG_INVALID_ITERATIONS = @"Number of iterations must greater than 0";
NSString *const JSONStore_ERROR_MSG_EMPTY_PASSWORD = @"Password cannot be nil/empty";
NSString *const JSONStore_ERROR_MSG_EMPTY_SALT = @"Salt cannot be nil/empty";

@end
