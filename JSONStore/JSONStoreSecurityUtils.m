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

#import "JSONStoreSecurityUtils.h"
#import "JSONStoreSecurityConstants.h"

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>




@implementation JSONStoreSecurityUtils

const CCAlgorithm kAlgorithm = kCCAlgorithmAES128;
const NSUInteger kAlgorithmKeySize = kCCKeySizeAES128;
const NSUInteger kAlgorithmBlockSize = kCCBlockSizeAES128;
const NSUInteger kAlgorithmIVSize = kCCBlockSizeAES128;



#pragma mark Random Number Generator

+(NSString*) generateRandomStringWithBytes:(int) bytes
{
    uint8_t randBytes[bytes];
    
    int rc = SecRandomCopyBytes(kSecRandomDefault, (size_t)bytes, randBytes);
    
    if (rc != 0) {
        return nil;
    }
    
    NSMutableString* hexEncoded  = [NSMutableString new];
    for (int i=0; i < bytes; i++) {
        [hexEncoded appendString:[NSString stringWithFormat:@"%02x", randBytes[i]]];
    }
    
    NSString* randomStr = [NSString stringWithFormat:@"%@", hexEncoded];
    
    return randomStr;
}

#pragma mark Encryption and Decryption

/*
 * Caller MUST FREE memory returned from this method
 * Encryption using CommonCrypto encryption aes128
 * Encrypt *len bytes of data
 * All data going in & out is considered binary (unsigned char[])
 */


static NSData *aes_encrypt(NSData *key, NSData *iv, NSData *plaintext)
{

    size_t cipherOutputLenth = 0;
    NSMutableData* ciphertext =  [NSMutableData dataWithLength:kAlgorithmBlockSize + plaintext.length];
    NSData* encryptedData = nil;
    
    
    CCCryptorStatus result = CCCrypt(kCCEncrypt, kAlgorithm, kCCOptionPKCS7Padding, key.bytes, key.length, iv.bytes, plaintext.bytes, plaintext.length, ciphertext.mutableBytes, ciphertext.length, &cipherOutputLenth);
    if(result == kCCSuccess){
        encryptedData = [NSData dataWithBytes:ciphertext.mutableBytes length:cipherOutputLenth];

     
    }
    return encryptedData;
}

/*
 * Caller MUST FREE memory returned from this method
 * Decryption using CommonCrypto decryption aes128
 * Decrypt *len bytes of ciphertext
 */
static NSData *aes_decrypt(NSData *key, NSData *iv, NSData *ciphertext){
    
    size_t cipherOutputLen=0;
    NSMutableData* plaintext = [NSMutableData dataWithLength:kAlgorithmBlockSize + ciphertext.length];
        NSData* decryptedData = nil;
    
    
    CCCryptorStatus result = CCCrypt(kCCDecrypt, kAlgorithm, kCCOptionPKCS7Padding, key.bytes, key.length, iv.bytes, ciphertext.bytes, ciphertext.length, plaintext.mutableBytes, plaintext.length, &cipherOutputLen);
    
    if(result == kCCSuccess){
         decryptedData = [NSData dataWithBytes:plaintext.mutableBytes length:cipherOutputLen];
    }
    return decryptedData;
}

+(NSData*) _doEncrypt:(NSString *) text
                  key:(NSString *) key
               withIV:(NSString *) iv
{
    
    NSData *myText = [text dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData* keyText = [NSMutableData dataWithBytes:[key UTF8String] length:kCCKeySizeAES128];

    
    NSMutableData* ivText = [NSMutableData dataWithBytes:[iv UTF8String] length:kCCKeySizeAES128];

    
    NSData *encryptedData = aes_encrypt(keyText, ivText, myText);

    return encryptedData;
}

+(NSData*) _doDecrypt:(NSString*) ciphertextEncoded
                  key:(NSString*) key
               withIV:(NSString*) iv
{
    
    NSData *cipherText = [JSONStoreSecurityUtils base64DataFromString:ciphertextEncoded];
    
    NSMutableData* keyText = [NSMutableData dataWithBytes:[key UTF8String] length:kCCKeySizeAES128];

    
    NSMutableData* ivText = [NSMutableData dataWithBytes:[iv UTF8String] length:kCCKeySizeAES128];
    
    NSData *decryptedData = aes_decrypt(keyText, ivText, cipherText);


    return decryptedData;
}

+(NSString*) generateKeyWithPassword: (NSString *) pass
                              andSalt: (NSString *) salt
                        andIterations: (NSInteger) iterations
{
    if (iterations < 1) {
        [NSException raise:JSONStore_ERROR_LABEL_KEYGEN format:@"%@", JSONStore_ERROR_MSG_INVALID_ITERATIONS];
    }
    
    if (! [pass isKindOfClass:[NSString class]] || [pass length] < 1) {
        [NSException raise:JSONStore_ERROR_LABEL_KEYGEN format:@"%@", JSONStore_ERROR_MSG_EMPTY_PASSWORD];
    }
    
    if (! [salt isKindOfClass:[NSString class]] || [salt length] < 1) {
        [NSException raise:JSONStore_ERROR_LABEL_KEYGEN format:@"%@", JSONStore_ERROR_MSG_EMPTY_SALT];
    }
    
    NSData* passData = [pass dataUsingEncoding:NSUTF8StringEncoding];
    NSData* saltData = [salt dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData *derivedKey = [NSMutableData dataWithLength:kCCKeySizeAES256];
    
    int retVal = CCKeyDerivationPBKDF(kCCPBKDF2,
                                      passData.bytes,
                                      pass.length,
                                      saltData.bytes,
                                      salt.length,
                                      kCCPRFHmacAlgSHA1,
                                      (int)iterations,
                                      derivedKey.mutableBytes,
                                      kCCKeySizeAES256);
    
    if (retVal != kCCSuccess) {
        [NSException raise:JSONStore_ERROR_LABEL_KEYGEN format:@"Return value: %d", retVal];
    }
    
    NSMutableString *derivedKeyStr = [NSMutableString stringWithCapacity:kCCKeySizeAES256*2];
    const unsigned char *dataBytes = [derivedKey bytes];
    
    for (int idx = 0; idx < kCCKeySizeAES256; idx++) {
        [derivedKeyStr appendFormat:@"%02x", dataBytes[idx]];
    }
    
    derivedKey = nil;
    dataBytes = nil;
    
    return [NSString stringWithString:derivedKeyStr];
}

+(NSDictionary*) _buildErrorObjectWithException:(NSException*) exception
                                      andFormat:(NSString*) format
{
    NSString *msg = [NSString stringWithFormat:format, exception];
    
    NSDictionary* errorObject = @{JSONStore_ERR_MSG_KEY: msg};
    
    return errorObject;
}

+(NSDictionary*) encryptText: (NSString*) text
                     withKey: (NSString*) key
                       error: (NSError**) error
{
    NSDictionary* dict = nil;
    NSString* iv = [self generateRandomStringWithBytes:16];
    
    @try {
        NSString* encryptedText = [self _encryptWithKey:key
                                               withText:text
                                                 withIV:iv
                           covertBase64BeforeEncryption:NO];
        
        dict = @{JSONStore_CIPHER_TEXT_KEY: encryptedText,
                 JSONStore_IV_KEY: iv,
                 JSONStore_KEY_VERSION: @(JSONStore_CURRENT_SEC_VERSION),
                 JSONStore_KEY_SRC: JSONStore_SRC_OBJECTIVE_C};
    }
    @catch (NSException *exception) {
        
        if (error != nil) {
            
            *error = [NSError errorWithDomain:JSONStore_ERROR_LABEL_ENCRYPT
                                         code:-1
                                     userInfo:[self _buildErrorObjectWithException:exception
                                                                         andFormat:JSONStore_ENCRYPT_ERROR_FORMAT_MSG]];
        }
    }
    
    return dict;
    
}

+(NSString*) _encryptWithKey:(NSString*) key
                    withText:(NSString*) text
                      withIV:(NSString*) iv
covertBase64BeforeEncryption:(BOOL) covertBase64BeforeEncryptionFlag
{
    if (! [text isKindOfClass:[NSString class]] || [text length] < 1) {
        [NSException raise:JSONStore_ERROR_LABEL_ENCRYPT format:@"%@", JSONStore_ERROR_MSG_EMPTY_TEXT];
    }
    
    if (! [key isKindOfClass:[NSString class]] || [key length] < 1) {
        [NSException raise:JSONStore_ERROR_LABEL_ENCRYPT format:@"%@", JSONStore_ERROR_MSG_EMPTY_KEY];
    }
    
    if (! [iv isKindOfClass:[NSString class]] || [iv length] < 1) {
        [NSException raise:JSONStore_ERROR_LABEL_ENCRYPT format:@"%@", JSONStore_ERROR_MSG_EMPTY_IV];
    }
    
    if (covertBase64BeforeEncryptionFlag) {
        NSData* data = [text dataUsingEncoding:NSUTF8StringEncoding];
        text = [JSONStoreSecurityUtils _base64StringFromData:data length:(int)text.length isSafeUrl:NO];
    }
    
    NSData* cipherDat = [self _doEncrypt:text key:key withIV:iv];
    
    NSString *encodedBase64CipherString  = [cipherDat base64EncodedStringWithOptions:0];
    
    return encodedBase64CipherString;
}

+(NSString*) decryptWithKey: (NSString*) key
              andDictionary:(NSDictionary*) dict
                      error: (NSError**) error
{
    NSString* plainText = nil;
    
    @try {
        
        if (! [dict[JSONStore_KEY_SRC] isEqualToString:JSONStore_SRC_OBJECTIVE_C]) {
            [NSException raise:JSONStore_ERROR_LABEL_DECRYPT format:@"%@", JSONStore_ERROR_MSG_INVALID_SRC];
        }
        
        if ([dict[JSONStore_KEY_VERSION] intValue] != JSONStore_CURRENT_SEC_VERSION) {
            [NSException raise:JSONStore_ERROR_LABEL_DECRYPT format:@"%@", JSONStore_ERROR_MSG_INVALID_VERSION];
        }
        
        BOOL checkBase64 = [dict objectForKey:JSONStore_KEY_BASE64] ? [[dict objectForKey:JSONStore_KEY_BASE64] boolValue] : NO;
        
        plainText = [self _decryptWithKey:key
                           withCipherText:dict[JSONStore_CIPHER_TEXT_KEY]
                                   withIV:dict[JSONStore_IV_KEY]
              decodeBase64AfterDecryption:NO
                      checkBase64Encoding:checkBase64];
        
    }
    @catch (NSException *exception) {
        
        if (error != nil) {
            
            *error = [NSError errorWithDomain:JSONStore_ERROR_LABEL_DECRYPT
                                         code:-2
                                     userInfo:[self _buildErrorObjectWithException:exception
                                                                         andFormat:JSONStore_DECRYPT_ERROR_FORMAT_MSG]];
        }
    }
    
    return plainText;
}

/**
 * This decrypt will use the correct or incorrect conversion of the IV based on the value of the 'correctConversion' parameter.
 */
+(NSString*) _decryptWithKey:(NSString*) key
              withCipherText:(NSString*) ciphertext
                      withIV:(NSString*) iv
     withCorrectIVConversion:(BOOL) correctIVConversion
    withCorrectKeyConversion:(BOOL) correctKeyConversion
         checkBase64Encoding:(BOOL) checkBase64Encoding
{
    
    NSData* decodedCipher = [self _doDecrypt:ciphertext
                                         key:key
                                      withIV:iv];
    
    NSString *returnText = [[NSString alloc] initWithData:decodedCipher
                                                 encoding:NSUTF8StringEncoding];
    
    if (returnText != nil) {
        
        if (checkBase64Encoding && ![JSONStoreSecurityUtils _isBase64Encoded:returnText]) {
            returnText = nil;
        }
    }
    
    return returnText;
}


+(NSString*) _decryptWithKey:(NSString*) key
              withCipherText:(NSString*) ciphertext
                      withIV:(NSString*) iv
 decodeBase64AfterDecryption:(BOOL) decodeBase64AfterDecryption
         checkBase64Encoding:(BOOL) checkBase64Encoding
{
    if (! [ciphertext isKindOfClass:[NSString class]] || [ciphertext length] < 1) {
        [NSException raise:JSONStore_ERROR_LABEL_DECRYPT format:@"%@", JSONStore_ERROR_MSG_EMPTY_CIPHER];
    }
    
    if (! [key isKindOfClass:[NSString class]] || [key length] < 1) {
        [NSException raise:JSONStore_ERROR_LABEL_DECRYPT format:@"%@", JSONStore_ERROR_MSG_EMPTY_KEY];
    }
    
    if (! [iv isKindOfClass:[NSString class]] || [iv length] < 1) {
        [NSException raise:JSONStore_ERROR_LABEL_DECRYPT format:@"%@", JSONStore_ERROR_MSG_EMPTY_IV];
    }
    
    // First try to decrypt with the correct IV and key conversions.  In 506, both EOC and JSONStore use the
    // correct conversions for both the IV and key when doing encryption.
    NSString *returnText = [self _decryptWithKey:key
                                  withCipherText:ciphertext
                                          withIV:iv
                         withCorrectIVConversion:TRUE
                        withCorrectKeyConversion:TRUE
                             checkBase64Encoding:checkBase64Encoding];
    
    if (returnText != nil && decodeBase64AfterDecryption) {
        NSData* inputBase64Data = [JSONStoreSecurityUtils base64DataFromString:returnText];
        returnText = [[NSString alloc] initWithData:inputBase64Data encoding:NSUTF8StringEncoding];
    }
    
    return returnText;
}

#pragma mark Base64

const static char base64EncodingTable[64] = {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
};

const static char base64EncodingTableUrlSafe[64] = {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-', '_'
};

+ (NSString*) _base64StringFromData:(NSData*) data
                             length:(int)length
                          isSafeUrl:(bool) isSafeUrl
{
    unsigned long ixtext, lentext;
    long ctremaining;
    unsigned char input[3], output[4];
    short i, charsonline = 0, ctcopy;
    const unsigned char *raw;
    NSMutableString *result;
    
    lentext = [data length];
    if (lentext < 1)
        return @"";
    result = [NSMutableString stringWithCapacity: lentext];
    raw = [data bytes];
    ixtext = 0;
    
    while (true) {
        ctremaining = lentext - ixtext;
        if (ctremaining <= 0)
            break;
        for (i = 0; i < 3; i++) {
            unsigned long ix = ixtext + i;
            if (ix < lentext)
                input[i] = raw[ix];
            else
                input[i] = 0;
        }
        output[0] = (input[0] & 0xFC) >> 2;
        output[1] = ((input[0] & 0x03) << 4) | ((input[1] & 0xF0) >> 4);
        output[2] = ((input[1] & 0x0F) << 2) | ((input[2] & 0xC0) >> 6);
        output[3] = input[2] & 0x3F;
        ctcopy = 4;
        switch (ctremaining) {
            case 1:
                ctcopy = 2;
                break;
            case 2:
                ctcopy = 3;
                break;
        }
        
        for (i = 0; i < ctcopy; i++)
            [result appendString: [NSString stringWithFormat: @"%c", isSafeUrl ? base64EncodingTableUrlSafe[output[i]]: base64EncodingTable[output[i]]]];
        
        for (i = ctcopy; i < 4; i++)
            [result appendString: @"="];
        
        ixtext += 3;
        charsonline += 4;
        
        if ((length > 0) && (charsonline >= length))
            charsonline = 0;
    }
    return result;
}

+ (NSData*) base64DataFromString:(NSString*) string
{
    unsigned long ixtext, lentext;
    unsigned char ch;
    unsigned char inbuf[4] = {};
    unsigned char outbuf[3];
    short i, ixinbuf;
    Boolean flignore, flendtext = false;
    const unsigned char *tempcstring;
    NSMutableData *theData;
    
    if (string == nil)
    {
        return [NSData data];
    }
    
    ixtext = 0;
    
    tempcstring = (const unsigned char *)[string UTF8String];
    
    lentext = [string length];
    
    theData = [NSMutableData dataWithCapacity: lentext];
    
    ixinbuf = 0;
    
    while (true)
    {
        if (ixtext >= lentext)
        {
            break;
        }
        
        ch = tempcstring [ixtext++];
        
        flignore = false;
        
        if ((ch >= 'A') && (ch <= 'Z'))
        {
            ch = ch - 'A';
        }
        else if ((ch >= 'a') && (ch <= 'z'))
        {
            ch = ch - 'a' + 26;
        }
        else if ((ch >= '0') && (ch <= '9'))
        {
            ch = ch - '0' + 52;
        }
        else if (ch == '+')
        {
            ch = 62;
        }
        else if (ch == '=')
        {
            flendtext = true;
        }
        else if (ch == '/')
        {
            ch = 63;
        }
        else
        {
            flignore = true;
        }
        
        if (!flignore)
        {
            short ctcharsinbuf = 3;
            Boolean flbreak = false;
            
            if (flendtext)
            {
                if (ixinbuf == 0)
                {
                    break;
                }
                
                if ((ixinbuf == 1) || (ixinbuf == 2))
                {
                    ctcharsinbuf = 1;
                }
                else
                {
                    ctcharsinbuf = 2;
                }
                
                ixinbuf = 3;
                
                flbreak = true;
            }
            
            inbuf [ixinbuf++] = ch;
            
            if (ixinbuf == 4)
            {
                ixinbuf = 0;
                
                outbuf[0] = (inbuf[0] << 2) | ((inbuf[1] & 0x30) >> 4);
                outbuf[1] = ((inbuf[1] & 0x0F) << 4) | ((inbuf[2] & 0x3C) >> 2);
                outbuf[2] = ((inbuf[2] & 0x03) << 6) | (inbuf[3] & 0x3F);
                
                for (i = 0; i < ctcharsinbuf; i++)
                {
                    [theData appendBytes: &outbuf[i] length: 1];
                }
            }
            
            if (flbreak)
            {
                break;
            }
        }
    }
    
    return theData;
}

+ (BOOL) _isBase64Encoded: (NSString *)str
{
    NSString *pattern = [[NSString alloc]initWithFormat:JSONStore_BASE64_REGEX, [str length]];
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSUInteger numMatch = [regex numberOfMatchesInString:str options:0 range:NSMakeRange(0, [str length])];
    if(numMatch != 1 || [error code] != 0){
        return NO;
    }
    return YES;
}

@end
