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


extern NSString * const JSON_STORE_EXCEPTION;

extern NSString * const JSON_STORE_DATABASE_NOT_OPEN_LABEL;

extern NSString * const JSON_STORE_ERROR_OBJ_KEY_ERR;
extern NSString * const JSON_STORE_ERROR_OBJ_KEY_DOCS;

extern NSString * const JSON_STORE_DEFAULT_USER;
extern NSString * const JSON_STORE_DEFAULT_SQLITE_FILE;
extern NSString * const JSON_STORE_DEFAULT_FOLDER_FOR_SQLITE_FILES;
extern NSString * const JSON_STORE_DB_FILE_EXTENSION;

extern NSString * const JSON_STORE_FIELD_ID;
extern NSString * const JSON_STORE_FIELD_JSON;
extern NSString * const JSON_STORE_FIELD_DIRTY;
extern NSString * const JSON_STORE_FIELD_OPERATION;
extern NSString * const JSON_STORE_FIELD_DELETED;

extern NSString * const JSON_STORE_OP_ADD;
extern NSString * const JSON_STORE_OP_STORE;
extern NSString * const JSON_STORE_OP_UPDATE;
extern NSString * const JSON_STORE_OP_DELETE;

extern NSString * const JSON_STORE_VERSION_LABEL;
extern NSString * const JSON_STORE_SECURITY_VERSION_LABEL;
extern NSString * const JSON_STORE_VERSION_2_0;

extern int const JSON_STORE_DEFAULT_TOUCH_ID_GEN_SIZE;
extern int const JSON_STORE_DEFAULT_SALT_SIZE;
extern int const JSON_STORE_DEFAULT_DPK_SIZE;
extern int const JSON_STORE_DEFAULT_IV_SIZE;
extern int const JSON_STORE_DEFAULT_PBKDF2_ITERATIONS;

extern int const JSON_STORE_RC_OK;
extern int const JSON_STORE_RC_JS_TRUE;
extern int const JSON_STORE_RC_JS_FALSE;

extern int const JSON_STORE_PROVISION_TABLE_EXISTS;

extern int const JSON_STORE_PROVISION_TABLE_FAILURE;
extern int const JSON_STORE_PROVISION_TABLE_SCHEMA_MISMATCH;
extern int const JSON_STORE_PROVISION_KEY_FAILURE;

extern int const JSON_STORE_DESTROY_REMOVE_KEYS_FAILED;
extern int const JSON_STORE_DESTROY_REMOVE_FILE_FAILED;
extern int const JSON_STORE_DATABASE_NOT_OPEN;

extern int const JSON_STORE_TRANSACTION_IN_PROGRESS;
extern int const JSON_STORE_NO_TRANSACTION_IN_PROGRESS;
extern int const JSON_STORE_TRANSACTION_FAILURE;
extern int const JSON_STORE_TRANSACTION_FAILURE_DURING_INIT;

extern int const JSON_STORE_TRANSACTION_FAILURE_DURING_CLOSE_ALL;
extern int const JSON_STORE_TRANSACTION_FAILURE_DURING_DESTROY;
extern int const JSON_STORE_TRANSACTION_FAILURE_DURING_REMOVE_COLLECTION;

extern int const JSON_STORE_COULD_NOT_MARK_DOCUMENT_PUSHED;
extern int const JSON_STORE_INVALID_SEARCH_FIELD;
extern int const JSON_STORE_ERROR_CLOSING_ALL;
extern int const JSON_STORE_ERROR_CLEARING_COLLECTION;
extern int const JSON_STORE_ERROR_DURING_DESTROY;
extern int const JSON_STORE_ERROR_CHANGING_PASSWORD;
extern int const JSON_STORE_USERNAME_MISMATCH;
extern int const JSON_STORE_PERSISTENT_STORE_FAILURE;

extern int const JSON_STORE_INVALID_JSON_STRUCTURE;
extern int const JSON_STORE_STORE_DATA_PROTECTION_KEY_FAILURE;
extern int const JSON_STORE_REMOVE_WITH_QUERIES_FAILURE;
extern int const JSON_STORE_REPLACE_DOCUMENTS_FAILURE;
extern int const JSON_STORE_FILE_INFO_ERROR;

extern int const DESTROY_FAILED_FILE_ERROR;
extern int const DESTROY_FAILED_METADATA_REMOVAL_FAILURE;

extern NSString * const JSON_STORE_FLAG_USERNAME;
extern NSString * const JSON_STORE_FLAG_ADDITIONAL_SEARCH_FIELDS;
extern NSString * const JSON_STORE_FLAG_COLLECTION_PASSWORD;
extern NSString * const JSON_STORE_FLAG_DROP_COLLECTION;
extern NSString * const JSON_STORE_FLAG_IS_ADD;
extern NSString * const JSON_STORE_FLAG_IS_REFRESH;
extern NSString * const JSON_STORE_FLAG_IS_ERASE;
extern NSString * const JSON_STORE_FLAG_LIMIT;
extern NSString * const JSON_STORE_FLAG_OFFSET;
extern NSString * const JSON_STORE_FLAG_EXACT;
extern NSString * const JSON_STORE_FLAG_LOCAL_KEYGEN;
extern NSString * const JSON_STORE_FLAG_SECURE_RANDOM;
extern NSString * const JSON_STORE_FLAG_SORT;
extern NSString * const JSON_STORE_FLAG_FILTER;
extern NSString * const JSON_STORE_FLAG_REPLACE_CRITERIA;
extern NSString * const JSON_STORE_FLAG_ADD_NEW;
extern NSString * const JSON_STORE_FLAG_MARK_DIRTY;
extern NSString * const JSON_STORE_FLAG_ANALYTICS;

/* Feature removed from Altair
extern int const JSON_STORE_OS_SECURITY_FAILURE;
extern NSString * const JSON_STORE_FLAG_REQUIRE_OS_SECURITY;
extern NSString * const JSON_STORE_FLAG_OS_SECURITY_MESSAGE;
extern NSString * const JSON_STORE_KEY_TOUCH_ID;
*/

extern NSString * const JSON_STORE_KEY_ASC;
extern NSString * const JSON_STORE_KEY_DESC;

extern NSString * const JSON_STORE_KEY_DPK;
extern NSString * const JSON_STORE_KEY_SALT;
extern NSString * const JSON_STORE_KEY_IV;
extern NSString * const JSON_STORE_KEY_ITERATIONS;
extern NSString * const JSON_STORE_KEY_VERSION;
extern NSString * const JSON_STORE_KEY_VERSION_NUMBER;
extern NSString * const JSON_STORE_KEY_DOCUMENT_ID;

extern NSString * const JSON_STORE_KEY_FILE_NAME;
extern NSString * const JSON_STORE_KEY_FILE_SIZE;
extern NSString * const JSON_STORE_KEY_FILE_IS_ENCRYPTED;

extern NSString * const JSON_STORE_FILE_ENCRYPTED;

extern NSString * const JSON_STORE_KEY_FIND_LIKE;
extern NSString * const JSON_STORE_KEY_FIND_NOT_LIKE;

extern NSString * const JSON_STORE_KEY_FIND_RIGHT_LIKE;
extern NSString * const JSON_STORE_KEY_FIND_NOT_RIGHT_LIKE;

extern NSString * const JSON_STORE_KEY_FIND_LEFT_LIKE;
extern NSString * const JSON_STORE_KEY_FIND_NOT_LEFT_LIKE;

extern NSString * const JSON_STORE_KEY_FIND_LESS_THAN;
extern NSString * const JSON_STORE_KEY_FIND_LESS_OR_EQUAL_THAN;

extern NSString * const JSON_STORE_KEY_FIND_GREATER_THAN;
extern NSString * const JSON_STORE_KEY_FIND_GREATER_OR_EQUAL_THAN;

extern NSString * const JSON_STORE_KEY_FIND_EQUAL;
extern NSString * const JSON_STORE_KEY_FIND_NOT_EQUAL;

extern NSString * const JSON_STORE_KEY_INSIDE;
extern NSString * const JSON_STORE_KEY_NOT_INSIDE;

extern NSString * const JSON_STORE_KEY_BETWEEN;
extern NSString * const JSON_STORE_KEY_NOT_BETWEEN;
