/*
 *  Licensed Materials - Property of IBM
 *  5725-I43 (C) Copyright IBM Corp. 2011, 2013. All Rights Reserved.
 *  US Government Users Restricted Rights - Use, duplication or
 *  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 */

#import <Foundation/Foundation.h>
#import "JSONStoreConstants.h"
#import "JSONStoreQueue.h"


#define _wlGetTimeIntervalSince1970() (long long)([[NSDate date] timeIntervalSince1970] * 1000.0)

#define wlGetTimeIntervalSince1970() [[JSONStore sharedInstance] _isAnalyticsEnabled] ? _wlGetTimeIntervalSince1970() : -1
