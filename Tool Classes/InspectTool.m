//
//  InspectTool.m
//  Creatures
//
//  Created by Michael Ash on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "InspectTool.h"
#import "ComputingCreature.h"
#import "CreatureController.h"
#import "CreaturesView.h"
#import "FamilyTreeWindowController.h"
#import "FamilyTreeView.h"
#import "CreatureInspectorWindowController.h"

@implementation InspectTool

- (void)awakeFromNib
{
	[super awakeFromNib];
	NSImage *inspectorCursorImage = [NSImage imageNamed:@"inspector_cursor.tiff"];
	MyAssert(inspectorCursorImage != nil, @"Couldn't load inspector_cursor.tiff!");

	[GUIObject setImage:[[inspectorCursorImage copy] autorelease]];
	[GUIObject setImagePosition:NSImageOnly];

	[inspectorCursorImage setSize:NSMakeSize(16,16)];
	cursor = [[NSCursor alloc] initWithImage:inspectorCursorImage hotSpot:NSMakePoint(7, 7)];
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

- (void)releasedInView:(ToolInteractionView *)view at:(int)px :(int)py
{
	if(view == [controller view])
	{
		ComputingCreature *c;

		c = [[controller arena] creatureFor:px :py];

		if(c == nil || ![c isCreature])
		{
			NSEnumerator *nearbyEnum = [[[controller arena] creaturesNear:px :py] objectEnumerator];
			NSMutableArray *nearbyCreatures = [NSMutableArray array];
			id obj;
			while((obj = [nearbyEnum nextObject]))
				if([obj isCreature])
					[nearbyCreatures addObject:obj];
			
			if([nearbyCreatures count] != 1)
				return;

			c = [nearbyCreatures lastObject];
		}

		[CreatureInspectorWindowController showWindowWithCreature:c];
	}
}

@end
