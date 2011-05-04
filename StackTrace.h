//
//  StackTrace.h
//  Creatures
//
//  Created by Michael Ash on Sat Jan 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface StackTrace : NSObject {
	NSString *rawTrace;
	NSString *fullTrace;
}

+ (void)recordRefcountForClass:(Class)class;
+ (void)stopRecodingRefcountForClass:(Class)class;
+ (NSArray *)instanceHistoryTrace:obj;
+ (NSArray *)instanceHistoryCount:obj;
+ (NSArray *)instanceHistory:obj;

id InstanceHistory(id obj);

+ (NSArray *)classHistoryTrace:class;
+ (NSArray *)classHistoryCount:class;

void PrintHistoryForClass(char *className);

+ stackTrace;
+ stackTraceWithException:(NSException *)exception;
- initWithRawTrace:(NSString *)trace;
- (NSString *)fullTrace;

@end
