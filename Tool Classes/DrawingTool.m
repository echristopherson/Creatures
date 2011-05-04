//
//  DrawingTool.m
//  Creatures
//
//  Created by Michael Ash on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "DrawingTool.h"
#import "CreatureController.h"


@implementation DrawingTool

- (void)awakeFromNib
{
	[controller setTool:self forButton:GUIObject];
}

- (NSView *)settingsView
{
	return settingsView;
}

@end
