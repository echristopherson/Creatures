//
//  ZoomTool.m
//  Creatures
//
//  Created by Michael Ash on Mon Aug 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ZoomTool.h"
#import "CreatureController.h"
#import "CreaturesView.h"
#import "ToolInteractionView.h"
#import "FamilyTreeWindowController.h"
#import "FamilyTreeView.h"


@implementation ZoomTool

- (void)awakeFromNib
{
	[super awakeFromNib];
	NSImage *zoomInCursorImage = [NSImage imageNamed:@"zoom_in_cursor.png"];
	MyAssert(zoomInCursorImage != nil, @"Couldn't load zoom_in_cursor.png!");
	NSImage *zoomOutCursorImage = [NSImage imageNamed:@"zoom_out_cursor.png"];
	MyAssert(zoomOutCursorImage != nil, @"Couldn't load zoom_out_cursor.png!");
	
	[GUIObject setImage:[[zoomInCursorImage copy] autorelease]];
	[GUIObject setImagePosition:NSImageOnly];

	[zoomInCursorImage setSize:NSMakeSize(16,16)];
	zoomInCursor = [[NSCursor alloc] initWithImage:zoomInCursorImage hotSpot:NSMakePoint(7, 7)];
	[zoomOutCursorImage setSize:NSMakeSize(16,16)];
	zoomOutCursor = [[NSCursor alloc] initWithImage:zoomOutCursorImage hotSpot:NSMakePoint(7, 7)];
}

- (IBAction)selected:sender
{
	[[[controller view] enclosingScrollView] setDocumentCursor:zoomInCursor];
	[[[[FamilyTreeWindowController controller] treeView] enclosingScrollView] setDocumentCursor:zoomInCursor];
}

- (IBAction)deselected:sender
{
	[[[controller view] enclosingScrollView] setDocumentCursor:[NSCursor arrowCursor]];
	[[[[FamilyTreeWindowController controller] treeView] enclosingScrollView] setDocumentCursor:[NSCursor arrowCursor]];
}

- (void)clickedInView:(ToolInteractionView *)view at:(int)px :(int)py
{
	if([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask)
		[view zoomOut:self];
	else
		[view zoomIn:self];
	[view centerInView:px :py];
}

- (void)view:(ToolInteractionView *)view modifiersChangedTo:(unsigned int)modifierFlags
{
	if(modifierFlags & NSCommandKeyMask)
	{
		[[[controller view] enclosingScrollView] setDocumentCursor:zoomOutCursor];
		[[[[FamilyTreeWindowController controller] treeView] enclosingScrollView] setDocumentCursor:zoomOutCursor];
	}
	else
	{
		[[[controller view] enclosingScrollView] setDocumentCursor:zoomInCursor];
		[[[[FamilyTreeWindowController controller] treeView] enclosingScrollView] setDocumentCursor:zoomInCursor];
	}
}

@end
