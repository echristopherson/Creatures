//
//  VirtualMachineError.m
//  Creatures
//
//  Created by Michael Ash on Tue Jun 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "VirtualMachineError.h"


@implementation VirtualMachineError

+ errorWithLine:(int)l character:(int)c message:(NSString *)m
{
	return [[[self alloc] initWithLine:l character:c message:m] autorelease];
}

- initWithLine:(int)l character:(int)c message:(NSString *)m
{
	line = l;
	character = c;
	message = [m retain];
	return self;
}

- (NSString *)message
{
	return message;
}

- (int)line
{
	return line;
}

- (int)character
{
	return character;
}

- (NSComparisonResult)comparePosition:other
{
	if(line < [other line])
		return NSOrderedAscending;
	if([other line] < line)
		return NSOrderedDescending;
	if(character < [other character])
		return NSOrderedAscending;
	if([other character] < character)
		return NSOrderedDescending;
	return NSOrderedSame;
}

- (void)dealloc
{
	[message release];
	[super dealloc];
}

@end
