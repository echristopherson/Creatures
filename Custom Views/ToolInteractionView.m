//
//  ToolInteractionView.m
//  Creatures
//
//  Created by Michael Ash on Sun Oct 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ToolInteractionView.h"
#import "DrawingTool.h"
#import "CreatureController.h"
#import "NSViewAdditions.h"


@implementation ToolInteractionView

- (void)setController:(CreatureController *)c
{
	controller = c;
}

- (void)centerInView:(int)x :(int)y
{
	NSPoint point = NSMakePoint(x, (pixHeight - y - 1));
	if(NSEqualSizes([self frame].size, [self bounds].size))
	{
		point.x *= zoomFactor;
		point.y *= zoomFactor;
	}	
	[self centerPointInView:point];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if(NSEqualSizes([self frame].size, [self bounds].size))
	{
		localPoint.x /= zoomFactor;
		localPoint.y /= zoomFactor;
	}
	localPoint.y = pixHeight - floor(localPoint.y) - 1;
	if([theEvent clickCount] == 1)
	{
		if([[controller selectedTool] respondsToSelector:@selector(clickedInView:at::)])
			[[controller selectedTool] clickedInView:self at:localPoint.x :localPoint.y];
	}
	else if([theEvent clickCount] == 2)
	{
		if([[controller selectedTool] respondsToSelector:@selector(doubleClickedInView:at::)])
			[[controller selectedTool] doubleClickedInView:self at:localPoint.x :localPoint.y];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	if([[controller selectedTool] respondsToSelector:@selector(draggedInView:at::)])
	{
		NSPoint localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		if(NSEqualSizes([self frame].size, [self bounds].size))
		{
			localPoint.x /= zoomFactor;
			localPoint.y /= zoomFactor;
		}
		localPoint.y = pixHeight - floor(localPoint.y) - 1;
		[[controller selectedTool] draggedInView:self at:localPoint.x :localPoint.y];
	}
	else if([[controller selectedTool] respondsToSelector:@selector(draggedInView:withDeltas::)])
	{
		[[controller selectedTool] draggedInView:self withDeltas:[theEvent deltaX] :[theEvent deltaY]];
	}
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	NSPoint localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if(NSPointInRect(localPoint, [self visibleRect]))
	{
		if(NSEqualSizes([self frame].size, [self bounds].size))
		{
			localPoint.x /= zoomFactor;
			localPoint.y /= zoomFactor;
		}
		localPoint.y = pixHeight - floor(localPoint.y) - 1;
		if([[controller selectedTool] respondsToSelector:@selector(movedInView:at::)])
			[[controller selectedTool] movedInView:self at:localPoint.x :localPoint.y];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if(NSEqualSizes([self frame].size, [self bounds].size))
	{
		localPoint.x /= zoomFactor;
		localPoint.y /= zoomFactor;
	}
	localPoint.y = pixHeight - floor(localPoint.y) - 1;
	if([[controller selectedTool] respondsToSelector:@selector(releasedInView:at::)])
		[[controller selectedTool] releasedInView:self at:localPoint.x :localPoint.y];
}

- (void)keyDown:(NSEvent *)theEvent
{
	if([[controller selectedTool] respondsToSelector:@selector(view:keyPressedInArena:)])
		[[controller selectedTool] view:self keyPressedInArena:[theEvent characters]];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	if([[controller selectedTool] respondsToSelector:@selector(view:modifiersChangedTo:)])
		[[controller selectedTool] view:self modifiersChangedTo:[theEvent modifierFlags]];
}

@end
