//
//  RegionCreateTool.m
//  Creatures
//
//  Created by Michael Ash on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "RegionCreateTool.h"
#import "Region.h"
#import "CreatureController.h"
#import "CreaturesView.h"
#import "Arena.h"


@implementation RegionCreateTool

- (void)clickedInView:(ToolInteractionView *)view at:(int)x :(int)y
{
}

- (void)draggedInView:(ToolInteractionView *)view at:(int)x :(int)y
{
	if(view == [controller view])
	{
		if(inProgress == NO)
		{
			inProgress = YES;
			regionInserted = NO;
			region = [[Region alloc] init];
			startx = x;
			starty = y;
		}

		id arena = [controller arena];
		int ulx = (startx < x) ? startx : x;
		int uly = (starty < y) ? starty : y;
		NSRect rect = NSMakeRect(ulx, uly, abs(startx - x), abs(starty - y));

		if(rect.size.width == 0)
			rect.size.width = 1;
		if(rect.size.height == 0)
			rect.size.height = 1;

		rect = NSIntersectionRect(rect, NSMakeRect(0, 0, [arena xSize] - 1, [arena ySize] - 1));

		if(regionInserted == NO)
		{
			[arena addRegion:region];
			regionInserted = YES;
		}
		[region setRect:rect];
		[[controller view] setNeedsPixmapUpdate];
		[[controller view] setNeedsDisplay:YES];
	}
}

- (void)releasedInView:(ToolInteractionView *)view at:(int)x :(int)y
{
	if(view == [controller view])
	{
		[region release];
		region = nil;
		inProgress = NO;
		regionInserted = NO;
	}
}

@end
