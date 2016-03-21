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

/**
 Contains Private JSONStore methods.
 */
@interface JSONStoreCollection()

/**
 Private. Removes documents from the collection using one or more queries. Removed documents are not returned by the different find operations and they do not affect count operations.
 @param queries Array of queries represented as NSDictionaries
 @param markDirty Determines if the documents that are removed are marked as dirty (true) or not (false)
 @param exactMatch Determines if an exact match (true) or a fuzzy search (false) is performed
 @param error Error
 @return Number documents removed, nil if there's a failure
 @private
 */
-(NSNumber*) _removeWithQueries: (NSArray*) queries
                   andMarkDirty: (BOOL) markDirty
                     exactMatch: (BOOL) exactMatch
                          error: (NSError**) error;

/**
 Private. Get all dirty documents in the collection from the given document array.
 @param documents Array of documents that are represented as NSDictionaries
 @param error Error
 @return Array of dirty documents, nil if there's a failure
 @private
 */
-(NSArray*) _allDirtyWithDocuments:(NSArray*) documents
                             error:(NSError**) error;

@end
