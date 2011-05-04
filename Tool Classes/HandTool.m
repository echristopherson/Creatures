//
//  HandTool.m
//  Creatures
//
//  Created by Michael Ash on Wed Jul 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "HandTool.h"
#import "CreaturesView.h"
#import "CreatureController.h"
#import "FamilyTreeWindowController.h"
#import "FamilyTreeView.h"


@implementation HandTool

- (void)awakeFromNib
{
	[super awakeFromNib];
	NSImage *handCursorImage = [NSImage imageNamed:@"hand_cursor.tiff"];
	MyAssert(handCursorImage != nil, @"Couldn't load hand_cursor.tiff!");

	[GUIObject setImage:handCursorImage];
	[GUIObject setImagePosition:NSImageOnly];
	cursor = [[NSCursor alloc] initWithImage:handCursorImage hotSpot:NSMakePoint(6, 7)];
}

- (void)dealloc
{
	[cursor release];
	
	[super dealloc];
}

- (IBAction)selected:sender
{
	[[[controller view] enclosingScrollView] setDocumentCursor:cursor];
	//[[[[FamilyTreeWindowController controller] treeView] enclosingScrollView] setDocumentCursor:cursor];
}

- (IBAction)deselected:sender
{
	[[[controller view] enclosingScrollView] setDocumentCursor:[NSCursor arrowCursor]];
	//[[[[FamilyTreeWindowController controller] treeView] enclosingScrollView] setDocumentCursor:[NSCursor arrowCursor]];
}

- (void)draggedInView:(ToolInteractionView *)view withDeltas:(int)dx :(int)dy
{
	NSClipView *clipView = [[view enclosingScrollView] contentView];
	NSPoint oldOrigin = [clipView bounds].origin;
	NSPoint newOrigin = [clipView constrainScrollPoint:NSMakePoint(oldOrigin.x - dx, oldOrigin.y - dy)];
	[clipView scrollToPoint:newOrigin];
	[[clipView superview] reflectScrolledClipView:clipView];
}

@end
