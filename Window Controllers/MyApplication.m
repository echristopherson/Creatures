//
//  MyApplication.m
//  Creatures
//
//  Created by Michael Ash on Sat Oct 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "MyApplication.h"
#import "Debug.h"


@implementation MyApplication

- (void)reportException:(NSException *)theException
{
	LogUncaughtException(theException);
}

@end
