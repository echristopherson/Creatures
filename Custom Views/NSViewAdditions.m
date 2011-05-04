//
//  NSViewAdditions.m
//  Creatures
//
//  Created by Michael Ash on Fri Aug 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSViewAdditions.h"


@implementation NSView (ZoomAndCenterAdditions)

- (void)centerPointInView:(NSPoint)center
{
	NSRect visibleRect = [self visibleRect];
	NSRect scrollToRect = visibleRect;
	scrollToRect.origin.x = center.x - scrollToRect.size.width / 2;
	scrollToRect.origin.y = center.y - scrollToRect.size.height / 2;
	[self scrollRectToVisible:scrollToRect];
}

- (NSPoint)centerVisiblePoint
{
	NSRect enclosingRect = [self visibleRect];
	NSPoint center;
	center.x = enclosingRect.size.width / 2 + enclosingRect.origin.x;
	center.y = enclosingRect.size.height / 2 + enclosingRect.origin.y;
	return center;
}

@end
