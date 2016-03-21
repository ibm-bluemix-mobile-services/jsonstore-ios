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

#import "JSONStoreConstants.h"


NSString * const JSON_STORE_EXCEPTION = @"JSON_STORE_EXCEPTION";

NSString * const JSON_STORE_DATABASE_NOT_OPEN_LABEL = @"JSON_STORE_DATABASE_NOT_OPEN";

NSString * const JSON_STORE_ERROR_OBJ_KEY_ERR = @"err";
NSString * const JSON_STORE_ERROR_OBJ_KEY_DOCS = @"docs";

NSString * const JSON_STORE_DEFAULT_USER = @"jsonstore";
NSString * const JSON_STORE_DEFAULT_SQLITE_FILE = @"jsonstore.sqlite";
NSString * const JSON_STORE_DEFAULT_FOLDER_FOR_SQLITE_FILES = @"wljsonstore";
NSString * const JSON_STORE_DB_FILE_EXTENSION = @".sqlite";


NSString * const JSON_STORE_FIELD_DIRTY = @"_dirty";
NSString * const JSON_STORE_FIELD_JSON = @"json";
NSString * const JSON_STORE_FIELD_ID = @"_id";
NSString * const JSON_STORE_FIELD_OPERATION = @"_operation";
NSString * const JSON_STORE_FIELD_DELETED = @"_deleted";

NSString * const JSON_STORE_OP_ADD = @"add";
NSString * const JSON_STORE_OP_STORE = @"store";
NSString * const JSON_STORE_OP_UPDATE = @"replace";
NSString * const JSON_STORE_OP_DELETE = @"remove";

NSString * const JSON_STORE_VERSION_LABEL = @"JSONStoreVersion";
NSString * const JSON_STORE_SECURITY_VERSION_LABEL = @"JSONStoreSecurityVersion";
NSString * const JSON_STORE_VERSION_2_0 = @"2.0";

int const JSON_STORE_DEFAULT_TOUCH_ID_GEN_SIZE = 32;
int const JSON_STORE_DEFAULT_SALT_SIZE = 32;
int const JSON_STORE_DEFAULT_DPK_SIZE = 32;
int const JSON_STORE_DEFAULT_IV_SIZE = 16;
int const JSON_STORE_DEFAULT_PBKDF2_ITERATIONS = 10000;

int const JSON_STORE_RC_OK = 0;
int const JSON_STORE_RC_JS_TRUE = 1; //Emulates a boolean in JavaScript
int const JSON_STORE_RC_JS_FALSE = 0; //Emulates a boolean in JavaScript

int const JSON_STORE_PROVISION_TABLE_EXISTS = 1;
int const JSON_STORE_PROVISION_TABLE_FAILURE = -1;
int const JSON_STORE_PERSISTENT_STORE_FAILURE = -1;
int const JSON_STORE_PROVISION_TABLE_SCHEMA_MISMATCH = -2;
int const JSON_STORE_PROVISION_KEY_FAILURE = -3;
int const JSON_STORE_DESTROY_REMOVE_KEYS_FAILED = -4;
int const JSON_STORE_DESTROY_REMOVE_FILE_FAILED = -5;
int const JSON_STORE_USERNAME_MISMATCH = -6;
int const JSON_STORE_DATABASE_NOT_OPEN = -50;

int const JSON_STORE_TRANSACTION_IN_PROGRESS = -41;
int const JSON_STORE_NO_TRANSACTION_IN_PROGRESS = -42;
int const JSON_STORE_TRANSACTION_FAILURE = -43;
int const JSON_STORE_TRANSACTION_FAILURE_DURING_INIT = -44;
int const JSON_STORE_TRANSACTION_FAILURE_DURING_CLOSE_ALL = -45;
int const JSON_STORE_TRANSACTION_FAILURE_DURING_DESTROY = -46;
int const JSON_STORE_TRANSACTION_FAILURE_DURING_REMOVE_COLLECTION = -47;

int const JSON_STORE_COULD_NOT_MARK_DOCUMENT_PUSHED = 15;
int const JSON_STORE_INVALID_SEARCH_FIELD =22;
int const JSON_STORE_ERROR_CLOSING_ALL =23;
int const JSON_STORE_ERROR_CHANGING_PASSWORD = 24;
int const JSON_STORE_ERROR_DURING_DESTROY = 25;
int const JSON_STORE_ERROR_CLEARING_COLLECTION =26;

int const JSON_STORE_INVALID_JSON_STRUCTURE = -20;
int const JSON_STORE_STORE_DATA_PROTECTION_KEY_FAILURE = -21;
int const JSON_STORE_REMOVE_WITH_QUERIES_FAILURE = -22;
int const JSON_STORE_REPLACE_DOCUMENTS_FAILURE = -23;
int const JSON_STORE_FILE_INFO_ERROR = -24;

int const DESTROY_FAILED_FILE_ERROR = -18;
int const DESTROY_FAILED_METADATA_REMOVAL_FAILURE = -19;

NSString * const JSON_STORE_FLAG_USERNAME = @"username";
NSString * const JSON_STORE_FLAG_ADDITIONAL_SEARCH_FIELDS = @"additionalSearchFields";
NSString * const JSON_STORE_FLAG_COLLECTION_PASSWORD =@"collectionPassword";
NSString * const JSON_STORE_FLAG_DROP_COLLECTION = @"dropCollection";
NSString * const JSON_STORE_FLAG_IS_ADD = @"isAdd";
NSString * const JSON_STORE_FLAG_IS_REFRESH = @"isRefresh";
NSString * const JSON_STORE_FLAG_IS_ERASE = @"isErase";
NSString * const JSON_STORE_FLAG_LIMIT = @"limit";
NSString * const JSON_STORE_FLAG_OFFSET = @"offset";
NSString * const JSON_STORE_FLAG_EXACT = @"exact";
NSString * const JSON_STORE_FLAG_LOCAL_KEYGEN = @"localKeyGen";
NSString * const JSON_STORE_FLAG_SECURE_RANDOM = @"secureRandom";
NSString * const JSON_STORE_FLAG_SORT = @"sort";
NSString * const JSON_STORE_FLAG_FILTER = @"filter";
NSString * const JSON_STORE_FLAG_REPLACE_CRITERIA = @"replaceCriteria";
NSString * const JSON_STORE_FLAG_ADD_NEW = @"addNew";
NSString * const JSON_STORE_FLAG_MARK_DIRTY = @"markDirty";
NSString * const JSON_STORE_FLAG_ANALYTICS = @"analytics";

/* Feature removed from Altair
int const JSON_STORE_OS_SECURITY_FAILURE = -75;
NSString * const JSON_STORE_FLAG_REQUIRE_OS_SECURITY = @"requireOperatingSystemSecurity";
NSString * const JSON_STORE_FLAG_OS_SECURITY_MESSAGE = @"operatingSystemSecurityMessage";
NSString * const JSON_STORE_KEY_TOUCH_ID = @"JSONStoreTouchIdKey";
*/

NSString * const JSON_STORE_KEY_ASC = @"ASC";
NSString * const JSON_STORE_KEY_DESC = @"DESC";

NSString * const JSON_STORE_KEY_DPK = @"dpk";
NSString * const JSON_STORE_KEY_SALT = @"jsonSalt";
NSString * const JSON_STORE_KEY_IV = @"iv";
NSString * const JSON_STORE_KEY_ITERATIONS = @"iterations";
NSString * const JSON_STORE_KEY_VERSION = @"version";
NSString * const JSON_STORE_KEY_VERSION_NUMBER = @"1.0";
NSString * const JSON_STORE_KEY_DOCUMENT_ID = @"JSONStoreKey";

NSString * const JSON_STORE_KEY_FILE_NAME = @"name";
NSString * const JSON_STORE_KEY_FILE_SIZE = @"size";
NSString * const JSON_STORE_KEY_FILE_IS_ENCRYPTED = @"isEncrypted";

NSString * const JSON_STORE_FILE_ENCRYPTED = @"file is encrypted";

NSString * const JSON_STORE_KEY_FIND_LIKE = @"like";
NSString * const JSON_STORE_KEY_FIND_NOT_LIKE = @"notLike";

NSString * const JSON_STORE_KEY_FIND_RIGHT_LIKE = @"rightLike";
NSString * const JSON_STORE_KEY_FIND_NOT_RIGHT_LIKE = @"notRightLike";

NSString * const JSON_STORE_KEY_FIND_LEFT_LIKE = @"leftLike";
NSString * const JSON_STORE_KEY_FIND_NOT_LEFT_LIKE = @"notLeftLike";

NSString * const JSON_STORE_KEY_FIND_LESS_THAN = @"lessThan";
NSString * const JSON_STORE_KEY_FIND_LESS_OR_EQUAL_THAN = @"lessOrEqualThan";

NSString * const JSON_STORE_KEY_FIND_GREATER_THAN = @"greaterThan";
NSString * const JSON_STORE_KEY_FIND_GREATER_OR_EQUAL_THAN = @"greaterOrEqualThan";

NSString * const JSON_STORE_KEY_FIND_EQUAL = @"equal";
NSString * const JSON_STORE_KEY_FIND_NOT_EQUAL = @"notEqual";

NSString * const JSON_STORE_KEY_INSIDE = @"inside";
NSString * const JSON_STORE_KEY_NOT_INSIDE = @"notInside";

NSString * const JSON_STORE_KEY_BETWEEN = @"between";
NSString * const JSON_STORE_KEY_NOT_BETWEEN = @"notBetween";