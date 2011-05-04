//
//  CornerViewScrollView.m
//  Creatures
//
//  Created by Michael Ash on Wed Oct 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "CornerViewScrollView.h"


@implementation CornerViewScrollView

- (void)awakeFromNib
{
	if([[self superclass] instancesRespondToSelector:_cmd])
		[super awakeFromNib];
	enforceSquare = NO;
}

- (void)setCornerView:(NSView *)view
{
	if(cornerView)
	{
		[cornerView removeFromSuperview];
		cornerView = nil;
	}
	cornerView = view;
	[self addSubview:view];
}

- (void)setEnforceSquareCornerView:(BOOL)e
{
	enforceSquare = e;
}


- (void)tile
{
	[super tile];

	NSScroller *verticalScroller = [self verticalScroller];
	float width = [verticalScroller frame].size.width;
	float vSize;
	if(enforceSquare)
	{
		[cornerView setFrameSize:NSMakeSize(width, width)];
		vSize = width;
	}
	else
	{
		[cornerView setFrameSize:NSMakeSize(width, [cornerView frame].size.height)];
		vSize = [cornerView frame].size.height;
	}

	[verticalScroller setFrameSize:NSMakeSize(width, [verticalScroller frame].size.height - vSize)];
	NSRect frame = [verticalScroller frame];
	NSPoint origin = frame.origin;
	if([self isFlipped])
	{
		[cornerView setFrameOrigin:origin];
		origin.y += [cornerView frame].size.height;
		[verticalScroller setFrameOrigin:origin];
	}
	else
	{
		origin.y += frame.size.height;
		[cornerView setFrameOrigin:origin];
	}
}

@end
