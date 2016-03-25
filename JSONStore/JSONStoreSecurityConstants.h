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

@interface JSONStoreSecurityConstants : NSObject

extern int const JSONStorekChosenCipherIVSize;
extern int const JSONStorekChosenCipherKeySize;

extern NSString *const JSONStore_BASE64_REGEX;

extern NSString *const JSONStore_ERROR_LABEL_KEYGEN;
extern NSString *const JSONStore_ERROR_LABEL_ENCRYPT;
extern NSString *const JSONStore_ERROR_LABEL_DECRYPT;
extern NSString *const JSONStore_ERROR_LABEL;

extern NSString *const JSONStore_ERROR_MSG_INVALID_IV_LENGTH;

extern NSString *const JSONStore_ERROR_MSG_EMPTY_TEXT;
extern NSString *const JSONStore_ERROR_MSG_EMPTY_CIPHER;
extern NSString *const JSONStore_ERROR_MSG_EMPTY_KEY;
extern NSString *const JSONStore_ERROR_MSG_EMPTY_IV;
extern NSString *const JSONStore_ERROR_MSG_INVALID_ITERATIONS;
extern NSString *const JSONStore_ERROR_MSG_EMPTY_PASSWORD;
extern NSString *const JSONStore_ERROR_MSG_EMPTY_SALT;

@end
