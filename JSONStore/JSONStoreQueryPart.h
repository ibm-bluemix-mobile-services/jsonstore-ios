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
 Contains JSONStore query part operations.
 */
@interface JSONStoreQueryPart : NSObject

// TO DO : all the property originally marked as @private
// but had no effect neither with doxygen nor with appledoc

/**
 Private. Special case when looking for _id values.
 */
@property (nonatomic, retain) NSMutableArray* _ids;

/**
 Private. NSArray with less than criteria (e.g. [{age: 20}]).
 */
@property (nonatomic, retain) NSMutableArray* _lessThan;

/**
 Private. NSArray with less than or equal to criteria (e.g. [{age: 20}]).
 */
@property (nonatomic, retain) NSMutableArray* _lessOrEqualThan;

/**
 Private. NSArray with greater than criteria (e.g. [{age: 20}]).
 */
@property (nonatomic, retain) NSMutableArray* _greaterThan;

/**
 Private. NSArray with greater than or equal to criteria (e.g. [{age: 20}]).
 */
@property (nonatomic, retain) NSMutableArray* _greaterOrEqualThan;

/**
 Private. NSArray with like criteria (e.g. [{name: @"carlos"}]) that matches right and left of the input.
 */
@property (nonatomic, retain) NSMutableArray* _like;

/**
 Private. NSArray with not like criteria (e.g. [{name: @"carlos"}]) that matches right and left of the input.
 */
@property (nonatomic, retain) NSMutableArray* _notLike;

/**
 Private. NSArray with like criteria (e.g. [{name: @"carlos"}]) that matches only right of the input.
 */
@property (nonatomic, retain) NSMutableArray* _rightLike;

/**
 Private. NSArray with not like criteria (e.g. [{name: @"carlos"}]) that matches only right of the input.
 */
@property (nonatomic, retain) NSMutableArray* _notRightLike;

/**
 Private. NSArray with like criteria (e.g. [{name: @"carlos"}]) that matches only left of the input.
 */
@property (nonatomic, retain) NSMutableArray* _leftLike;

/**
 Private. NSArray with not like criteria (e.g. [{name: @"carlos"}]) that matches only left of the input.
 */
@property (nonatomic, retain) NSMutableArray* _notLeftLike;

/**
 Private. NSArray with equal to criteria (e.g. [{name: @"carlos"}]).
 */
@property (nonatomic, retain) NSMutableArray* _equal;

/**
 Private. NSArray with not equal to criteria (e.g. [{name: @"carlos"}]).
 */
@property (nonatomic, retain) NSMutableArray* _notEqual;

/**
 Private. NSArray with in criteria (e.g. [ [@"carlos", @"dgonz", @"mike"] ]).
 */
@property (nonatomic, retain) NSMutableArray* _inside;

/**
 Private. NSArray with not in criteria (e.g. [ [@"carlos", @"dgonz", @"mike"] ]).
 */
@property (nonatomic, retain) NSMutableArray* _notInside;

/**
 Private. NSArray with between criteria (e.g. [ [50,100] ]).
 */
@property (nonatomic, retain) NSMutableArray* _between;

/**
 Private. NSArray with not between criteria (e.g. [ [50,100] ]).
 */
@property (nonatomic, retain) NSMutableArray* _notBetween;


/**
 Add a less than criteria.
 @param searchField Search field
 @param number Number
 */
-(void) searchField:(NSString*) searchField
           lessThan:(NSNumber*) number;

/**
 Add a less than or equal to criteria.
 @param searchField Search field
 @param number Number
 */
-(void) searchField:(NSString*) searchField
    lessOrEqualThan:(NSNumber*) number;

/**
 Add a greater than criteria.
 @param searchField Search field
 @param number Number
 */
-(void) searchField:(NSString*) searchField
        greaterThan:(NSNumber*) number;

/**
 Add a greater than or equal to criteria.
 @param searchField Search field
 @param number Number
 */
-(void) searchField:(NSString*) searchField
 greaterOrEqualThan:(NSNumber*) number;

/**
 Add a like criteria.
 @param searchField Search field
 @param string String
 */
-(void) searchField:(NSString*) searchField
               like:(NSString*) string;

/**
 Add a not like criteria.
 @param searchField Search field
 @param string String
 */
-(void) searchField:(NSString*) searchField
            notLike:(NSString*) string;

/**
 Add a like criteria that matches only left of the input.
 @param searchField Search field
 @param string String
 */
-(void) searchField:(NSString*) searchField
           leftLike:(NSString*) string;

/**
 Add a not like criteria that matches only left of the input.
 @param searchField Search field
 @param string String
 */
-(void) searchField:(NSString*) searchField
        notLeftLike:(NSString*) string;

/**
 Add a like criteria that matches only right of the input.
 @param searchField Search field
 @param string String
 */
-(void) searchField:(NSString*) searchField
          rightLike:(NSString*) string;

/**
 Add a not like criteria that matches only right of the input.
 @param searchField Search field
 @param string String
 */
-(void) searchField:(NSString*) searchField
       notRightLike:(NSString*) string;

/**
 Add an equal to criteria.
 @param searchField Search field
 @param string String
 */
-(void) searchField:(NSString*) searchField
              equal:(NSString*) string;

/**
 Add a not equal to criteria.
 @param searchField Search field
 @param string String
 */
-(void) searchField:(NSString*) searchField
           notEqual:(NSString*) string;

/**
 Add an in criteria.
 @param searchField Search field
 @param values Array of strings
 */
-(void) searchField:(NSString*) searchField
           insideValues:(NSArray*) values;

/**
 Add a not in criteria.
 @param searchField Search field
 @param values Array of strings
 */
-(void) searchField:(NSString*) searchField
        notInsideValues:(NSArray*) values;

/**
 Add a between criteria.
 @param searchField Search field
 @param number1 First number in the range
 @param number2 Last number in the range
 */
-(void) searchField:(NSString*) searchField
            between:(NSNumber*) number1
                and:(NSNumber*) number2;

/**
 Add a not between criteria.
 @param searchField Search field
 @param number1 First number in the range
 @param number2 Last number in the range
 */
-(void) searchField:(NSString*) searchField
         notBetween:(NSNumber*) number1
                and:(NSNumber*) number2;

@end
