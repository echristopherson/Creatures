//
//  Barrier.m
//  Creatures
//
//  Created by Michael Ash on Sun Jan 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "Barrier.h"
#import "Arena.h"

@implementation Barrier

- initWithArena:a location:(int)x :(int)y
{
	arena = a;
	if((self = [self init]))
	{
		xLoc = x;
		yLoc = y;

		if(x >= 0 && x < [arena xSize] && y >= 0 && y < [arena ySize] && [arena creatureFor:x :y] == nil)
		{
			[arena addBarrier:self];
			[arena registerCreature:self at:x :y];
		}
		else
		{
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)drawOnPixmap:(PixelUnion *)pixmap width:(int)pixWidth
{
	PixelUnion pixel;

	pixel.components.a = 255.0;
	pixel.components.r = 127.0;
	pixel.components.g = 0.0;
	pixel.components.b = 127.0;
	pixmap[xLoc + ([arena ySize] - yLoc - 1) * pixWidth] = pixel;
}

- (void)die
{
	[arena removeCreature:self at:xLoc :yLoc];
	[arena removeBarrier:self];
}

- (int)xLoc
{
	return xLoc;
}

- (int)yLoc
{
	return yLoc;
}

- (BOOL)isCreature
{
	return NO;
}

- (Pixel24)color
{
	Pixel24 c = {127, 0, 127};
	return c;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInt:xLoc forKey:@"xLoc"];
	[coder encodeInt:yLoc forKey:@"yLoc"];
	[coder encodeConditionalObject:arena forKey:@"arena"];
}

- initWithCoder:(NSCoder *)coder
{
	[super init];

	xLoc = [coder decodeIntForKey:@"xLoc"];
	yLoc = [coder decodeIntForKey:@"yLoc"];
	arena = [coder decodeObjectForKey:@"arena"];

	return self;
}

@end
