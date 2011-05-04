//
//  RegionSelectTool.m
//  Creatures
//
//  Created by Michael Ash on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "RegionSelectTool.h"
#import "CreatureController.h"
#import "CreaturesView.h"
#import "Arena.h"
#import "Region.h"
#import "RegionInspectorController.h"


@implementation RegionSelectTool

- findRegionForPoint:(int)x :(int)y
{
	NSEnumerator *enumerator;
	id obj;

	enumerator = [[[controller arena] regions] objectEnumerator];
	while((obj = [enumerator nextObject]))
	{
		if(NSPointInRect(NSMakePoint(x, y), [obj rect]))
			return obj;
	}

	return nil;
}

- selectedRegion
{
	NSEnumerator *enumerator;
	id obj;

	enumerator = [[[controller arena] regions] objectEnumerator];
	while((obj = [enumerator nextObject]))
	{
		if([obj isSelected])
			return obj;
	}

	return nil;
}

- (void)clickedInView:(ToolInteractionView *)view at:(int)x :(int)y
{
	if(view == [controller view])
	{
		NSEnumerator *enumerator = [[[controller arena] regions] objectEnumerator];
		id obj;
		while((obj = [enumerator nextObject]))
		{
			[obj setIsSelected:NO];
		}
		[[self findRegionForPoint:x :y] setIsSelected:YES];
		[[controller view] setNeedsPixmapUpdate];
		[[controller view] setNeedsDisplay:YES];
	}
}

- (void)doubleClickedInView:(ToolInteractionView *)view at:(int)x :(int)y
{
	if(view == [controller view])
	{
		id region = [self selectedRegion];
		if([region windowController] == nil)
		{
			id windowController = [[RegionInspectorController alloc] initWithRegion:region];
			[region setWindowController:windowController];
			[windowController release];
		}
		[[[region windowController] window] makeKeyAndOrderFront:self];
	}
}

- (void)view:(ToolInteractionView *)view keyPressedInArena:(NSString *)key
{
	if(view == [controller view])
	{
		if([key isEqualToString:@"\177"]) // delete key
		{
			[[controller arena] removeRegion:[self selectedRegion]];
			[[controller view] setNeedsPixmapUpdate];
			[[controller view] setNeedsDisplay:YES];
		}
	}
}

@end
