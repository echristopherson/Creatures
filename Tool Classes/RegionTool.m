//
//  RegionTool.m
//  Creatures
//
//  Created by Michael Ash on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "RegionTool.h"
#import "CreatureController.h"
#import "CreaturesView.h"
#import "Arena.h"
#import "Region.h"



@implementation RegionTool

- (IBAction)selected:sender
{
	[[controller arena] setDrawsRegions:YES];
	NSEnumerator *enumerator = [[[controller arena] regions] objectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]))
	{
		[obj setIsSelected:NO];
	}
	[[controller view] setNeedsPixmapUpdate];
	[[controller view] setNeedsDisplay:YES];
}

- (IBAction)deselected:sender
{
	[[controller arena] setDrawsRegions:NO];
	NSEnumerator *enumerator = [[[controller arena] regions] objectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]))
	{
		[obj setIsSelected:NO];
	}
	[[controller view] setNeedsPixmapUpdate];
	[[controller view] setNeedsDisplay:YES];
}

@end
